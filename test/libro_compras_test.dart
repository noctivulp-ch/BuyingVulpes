import 'dart:io';

import 'package:buying_vulpes/core/db/app_database.dart';
import 'package:buying_vulpes/core/db/db_providers.dart';
import 'package:buying_vulpes/core/medida.dart';
import 'package:buying_vulpes/features/compra/compra_dao.dart';
import 'package:buying_vulpes/features/compra/compra_model.dart';
import 'package:buying_vulpes/features/compra/libro_compras.dart';
import 'package:buying_vulpes/features/historial/historial_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// La máquina de escribir (decisión 0007): un libro por año, la hoja llena se
/// deja atrás, y se lee sin restaurar.
///
/// Lo que se vigila:
/// - Que el libro rote al cambiar el año, y NO antes.
/// - Que nada se mueva ni se borre al rotar: el libro cerrado sigue teniendo
///   sus compras y el historial las lee abriéndolo aparte.
/// - Que la migración v1 → v2 mueva las compras al primer libro sin perder
///   una, y que no borre nada si las cuentas no cuadran.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory carpeta;
  late Database db;
  late LibroComprasService libros;

  setUp(() async {
    carpeta = Directory.systemTemp.createTempSync('bv-libro');
    db = await databaseFactory.openDatabase(
      p.join(carpeta.path, 'principal.db'),
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await AppDatabase.crearEsquema(db);
    libros = LibroComprasService(directorio: carpeta.path);
  });

  tearDown(() async {
    await libros.desadjuntar(db);
    await db.close();
    carpeta.deleteSync(recursive: true);
  });

  Future<void> comprar(DatabaseExecutor db, String id, DateTime cuando) async {
    final dao = CompraDao(db);
    await dao.insertarCompra(Compra(id: id, iniciadaEn: cuando, finalizadaEn: cuando, updatedAt: cuando));
    await dao.insertarLinea(
      LineaCompra(
        id: 'l-$id', compraId: id, tiendaId: 't', tiendaNombre: 'Feria', productoNombre: 'Tomate',
        precio: 800, cantidad: 1, medida: Medida.kilogramo, enCarrito: true, updatedAt: cuando,
      ),
    );
  }

  test('adjuntar sin libro crea el del año, y no adjunta dos veces', () async {
    await libros.adjuntarAbierto(db);
    await libros.adjuntarAbierto(db); // idempotente

    final abierto = await libros.libroAbierto(db);
    expect(abierto, isNotNull);
    expect(abierto!.anio, DateTime.now().year);
    expect(File(libros.rutaDe(abierto.archivo)).existsSync(), isTrue);
    expect(await libros.estaAdjunto(db), isTrue);
    // Y `compra` resuelve contra el adjunto sin calificar.
    expect(await db.query('compra'), isEmpty);
  });

  test('dentro del mismo año no rota; al cambiar de año cierra y abre otro', () async {
    final libro2026 = await libros.prepararPara(db, DateTime(2026, 3, 1));
    await comprar(db, 'c1', DateTime(2026, 3, 1));
    expect((await libros.prepararPara(db, DateTime(2026, 11, 30))).id, libro2026.id);

    final libro2027 = await libros.prepararPara(db, DateTime(2027, 1, 2));

    expect(libro2027.id, isNot(libro2026.id));
    expect(libro2027.anio, 2027);
    final todos = await libros.todos(db);
    expect(todos.map((l) => (l.anio, l.cerrado)), [(2026, true), (2027, false)]);
    // El libro cerrado conserva su compra: nada se movió ni se borró.
    final cerrado = await libros.abrirParaLeer(todos.first);
    expect(await cerrado.query('compra'), hasLength(1));
    await cerrado.close();
    // Y el adjunto es el nuevo, vacío.
    expect(await db.query('compra'), isEmpty);
  });

  test('el historial lee un año cerrado abriendo su libro aparte', () async {
    await libros.prepararPara(db, DateTime(2026, 5, 10));
    await comprar(db, 'vieja', DateTime(2026, 5, 10));
    await libros.recontarDias(db);
    await libros.prepararPara(db, DateTime(2027, 1, 5));
    await comprar(db, 'nueva', DateTime(2027, 1, 5));

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
        libroComprasServiceProvider.overrideWith((ref) async => libros),
      ],
    );
    addTearDown(container.dispose);

    final mayo2026 = await container.read(comprasDelMesProvider(const Mes(2026, 5)).future);
    expect(mayo2026.map((c) => c.id), ['vieja']);
    final enero2027 = await container.read(comprasDelMesProvider(const Mes(2027, 1)).future);
    expect(enero2027.map((c) => c.id), ['nueva']);
    expect(await container.read(comprasDelMesProvider(const Mes(2025, 1)).future), isEmpty);

    final detalle = await container.read(
      compraDetalladaProvider(const ClaveDeCompra('vieja', Mes(2026, 5))).future,
    );
    expect(detalle!.lineas.single.productoNombre, 'Tomate');
    // Leer el cerrado no lo dejó adjunto ni cambió el abierto.
    expect((await libros.libroAbierto(db))!.anio, 2027);
  });

  group('v1 → v2: las compras se mudan al primer libro', () {
    Future<Database> baseV1() async {
      final v1 = await databaseFactory.openDatabase(
        p.join(carpeta.path, 'v1.db'),
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await v1.execute(
        'CREATE TABLE tienda (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, notas TEXT, updated_at TEXT NOT NULL, deleted_at TEXT)',
      );
      // Las tablas de compras tal como estaban en v1: en la base principal.
      await aplicarEsquemaLibro(v1);
      await comprar(v1, 'a', DateTime(2026, 9, 1));
      await comprar(v1, 'b', DateTime(2026, 9, 3));
      return v1;
    }

    test('copia todas las compras y líneas, registra el libro y borra las tablas viejas', () async {
      final v1 = await baseV1();
      await AppDatabase.migrarComprasALibro(v1, carpeta.path);

      final indice = await LibroComprasService(directorio: carpeta.path).todos(v1);
      expect(indice.single.anio, 2026);
      expect(indice.single.diasConCompras, 2);
      expect(indice.single.cerrado, isFalse);
      final tablas = (await v1.rawQuery("SELECT name FROM sqlite_master WHERE type='table'"))
          .map((r) => r['name'])
          .toSet();
      expect(tablas, isNot(contains('compra')));

      final libro = await databaseFactory.openDatabase(
        p.join(carpeta.path, indice.single.archivo),
        options: OpenDatabaseOptions(singleInstance: false),
      );
      expect(await libro.query('compra'), hasLength(2));
      expect(await libro.query('linea_compra'), hasLength(2));
      await libro.close();
      await v1.close();
    });

    test('una base v1 sin compras no deja libros vacíos por ahí', () async {
      final v1 = await databaseFactory.openDatabase(
        p.join(carpeta.path, 'v1-vacia.db'),
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await aplicarEsquemaLibro(v1);
      await AppDatabase.migrarComprasALibro(v1, carpeta.path);
      expect(await LibroComprasService(directorio: carpeta.path).todos(v1), isEmpty);
      expect(carpeta.listSync().where((f) => f.path.contains('compras-')), isEmpty);
      await v1.close();
    });
  });
}
