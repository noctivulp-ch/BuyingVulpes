import 'package:buying_vulpes/core/db/app_database.dart';
import 'package:buying_vulpes/core/db/db_providers.dart';
import 'package:buying_vulpes/core/medida.dart';
import 'package:buying_vulpes/features/compra/compra_dao.dart';
import 'package:buying_vulpes/features/compra/compra_en_curso_notifier.dart';
import 'package:buying_vulpes/features/historial/historial_provider.dart';
import 'package:buying_vulpes/features/producto/producto_model.dart';
import 'package:buying_vulpes/features/producto/producto_notifier.dart';
import 'package:buying_vulpes/features/tienda/tienda_model.dart';
import 'package:buying_vulpes/features/tienda/tienda_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// El ciclo de una compra contra una base de verdad (en memoria): abrir al
/// anotar, marcar, editar con foto, finalizar, y que el historial la vea.
///
/// Lo que no puede pasar y acá se vigila: que editar un producto del catálogo
/// cambie una compra ya cerrada. El desglose es una foto (decisión 0003).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late ProviderContainer container;

  final walmart = Tienda(id: 'w', nombre: 'Walmart', updatedAt: DateTime(2026));
  final arroz = Producto(
    id: 'arroz',
    tiendaId: 'w',
    nombre: 'Arroz',
    precio: 1200,
    cantidad: 2,
    medida: Medida.kilogramo,
    updatedAt: DateTime(2026),
  );
  final leche = Producto(id: 'leche', tiendaId: 'w', nombre: 'Leche', precio: 950, updatedAt: DateTime(2026));

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await AppDatabase.crearEsquema(db);
    container = ProviderContainer(overrides: [databaseProvider.overrideWith((ref) async => db)]);
    await container.read(tiendaNotifierProvider.notifier).crear(walmart);
    await container.read(productoNotifierProvider.notifier).crear(arroz);
    await container.read(productoNotifierProvider.notifier).crear(leche);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  CompraEnCursoNotifier carrito() => container.read(compraEnCursoProvider.notifier);
  Future<EstadoCompraEnCurso> estado() => container.read(compraEnCursoProvider.future);

  test('arranca sin compra y la abre al anotar el primer producto', () async {
    expect((await estado()).compra, isNull);

    final anotados = await carrito().agregarProductos([(arroz, walmart), (leche, walmart)]);

    expect(anotados, 2);
    final e = await estado();
    expect(e.compra, isNotNull);
    expect(e.compra!.enCurso, isTrue);
    expect(e.lineas, hasLength(2));
    // Toma del producto precio, cantidad habitual y medida.
    final l = e.lineas.firstWhere((l) => l.productoId == 'arroz');
    expect((l.precio, l.cantidad, l.medida), (1200, 2, Medida.kilogramo));
    expect(l.tiendaNombre, 'Walmart');
  });

  test('un producto ya anotado no se duplica', () async {
    await carrito().agregarProductos([(arroz, walmart)]);
    final otraVez = await carrito().agregarProductos([(arroz, walmart), (leche, walmart)]);
    expect(otraVez, 1);
    expect((await estado()).lineas, hasLength(2));
  });

  test('marcar mueve la línea al carrito y las cuentas lo siguen', () async {
    await carrito().agregarProductos([(arroz, walmart), (leche, walmart)]);
    final id = (await estado()).lineas.firstWhere((l) => l.productoId == 'arroz').id;

    await carrito().marcar(id, enCarrito: true);

    final r = (await estado()).resumen;
    expect(r.totalCarrito, 2400);
    expect(r.totalLista, 2400 + 950);
  });

  test('editar el precio de la línea puede actualizar el producto, y no al revés', () async {
    await carrito().agregarProductos([(arroz, walmart)]);
    final id = (await estado()).lineas.single.id;

    await carrito().editarLinea(id, precio: 1300, cantidad: 1, actualizarProducto: true);

    expect((await estado()).lineas.single.subtotal, 1300);
    final catalogo = await container.read(productoNotifierProvider.future);
    expect(catalogo.firstWhere((p) => p.id == 'arroz').precio, 1300, reason: 'el catálogo aprende el precio');

    // Ahora el catálogo cambia por su cuenta: la línea NO se mueve.
    await container
        .read(productoNotifierProvider.notifier)
        .actualizar(arroz.copyWith(precio: 5000, updatedAt: DateTime.now()));
    expect((await estado()).lineas.single.precio, 1300);
  });

  test('finalizar cierra, va al historial y deja la lista vacía para la próxima', () async {
    await carrito().agregarProductos([(arroz, walmart), (leche, walmart)]);
    await carrito().ponerPresupuesto(5000);
    final id = (await estado()).lineas.first.id;
    await carrito().marcar(id, enCarrito: true);

    final cerrada = await carrito().finalizar();

    expect(cerrada, isNotNull);
    expect(cerrada!.finalizadaEn, isNotNull);
    expect(cerrada.presupuesto, 5000);
    expect((await estado()).vacia, isTrue);

    final hoy = DateTime.now();
    final delMes = await container.read(comprasDelMesProvider(Mes(hoy.year, hoy.month)).future);
    expect(delMes.map((c) => c.id), [cerrada.id]);
    final detalle = await container.read(compraDetalladaProvider(cerrada.id).future);
    expect(detalle!.lineas, hasLength(2), reason: 'las no compradas también quedan en el desglose');
    expect(detalle.resumen.articulosEnCarrito, 1);
  });

  test('sin líneas no hay nada que finalizar', () async {
    expect(await carrito().finalizar(), isNull);
  });

  test('la compra cerrada sobrevive a que el producto se archive', () async {
    await carrito().agregarProductos([(arroz, walmart)]);
    final cerrada = (await carrito().finalizar())!;

    await container.read(productoNotifierProvider.notifier).archivar('arroz');

    final lineas = await CompraDao(db).lineasDe(cerrada.id);
    expect(lineas.single.productoNombre, 'Arroz');
    expect(lineas.single.precio, 1200);
  });
}
