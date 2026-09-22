import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/db_providers.dart';
import '../historial/historial_provider.dart';
import '../producto/producto_model.dart';
import '../producto/producto_notifier.dart';
import '../tienda/tienda_model.dart';
import 'compra_dao.dart';
import 'compra_model.dart';
import 'libro_compras.dart';
import 'resumen_compra.dart';

const _uuid = Uuid();

/// La compra abierta con sus líneas, tal como está en la base.
class EstadoCompraEnCurso {
  const EstadoCompraEnCurso({this.compra, this.lineas = const []});

  /// Nula hasta que se agrega la primera línea: una app recién abierta no
  /// tiene una compra fantasma esperando.
  final Compra? compra;
  final List<LineaCompra> lineas;

  bool get vacia => lineas.isEmpty;
  ResumenCompra get resumen => ResumenCompra(lineas, presupuesto: compra?.presupuesto);

  /// Para marcar en el panel de tiendas qué ya está anotado.
  Set<String> get productosAnotados => {for (final l in lineas) if (l.productoId != null) l.productoId!};
}

/// La lista que se está armando: agregar, marcar, editar, quitar, presupuesto
/// y finalizar. Vive en la base, no en memoria — se arma en días.
///
/// No sabe de PDF ni de pantallas. Finalizar solo cierra la compra; el
/// desglose lo genera quien lo pida con [FacturaPdfService].
class CompraEnCursoNotifier extends AsyncNotifier<EstadoCompraEnCurso> {
  Future<CompraDao> get _dao async => CompraDao(await ref.read(databaseProvider.future));

  @override
  Future<EstadoCompraEnCurso> build() async {
    final dao = CompraDao(await ref.watch(databaseProvider.future));
    return _leer(dao);
  }

  Future<EstadoCompraEnCurso> _leer(CompraDao dao) async {
    final compra = await dao.enCurso();
    if (compra == null) return const EstadoCompraEnCurso();
    return EstadoCompraEnCurso(compra: compra, lineas: await dao.lineasDe(compra.id));
  }

  Future<Compra> _abrirSiHaceFalta(CompraDao dao) async {
    final abierta = await dao.enCurso();
    if (abierta != null) return abierta;
    final ahora = DateTime.now();
    // ANTES de insertar: deja adjunto el libro del año, rotando si cambió
    // (decisión 0007). Se rota al abrir la compra y no al cerrarla, para que
    // nunca quede partida entre dos libros.
    final db = await ref.read(databaseProvider.future);
    final libros = await ref.read(libroComprasServiceProvider.future);
    await libros.prepararPara(db, ahora);
    final nueva = Compra(id: _uuid.v4(), iniciadaEn: ahora, updatedAt: ahora);
    await dao.insertarCompra(nueva);
    return nueva;
  }

  /// Anota productos con su tienda. Toma del producto el precio y la cantidad
  /// habitual; después se cambian en la línea. Un producto ya anotado no se
  /// duplica: se ignora, y quien llama puede decirlo.
  Future<int> agregarProductos(List<(Producto, Tienda)> elegidos) async {
    final dao = await _dao;
    final compra = await _abrirSiHaceFalta(dao);
    final anotados = (await dao.lineasDe(compra.id)).map((l) => l.productoId).toSet();
    var agregados = 0;
    for (final (producto, tienda) in elegidos) {
      if (anotados.contains(producto.id)) continue;
      await dao.insertarLinea(
        LineaCompra(
          id: _uuid.v4(),
          compraId: compra.id,
          productoId: producto.id,
          tiendaId: tienda.id,
          tiendaNombre: tienda.nombre,
          productoNombre: producto.nombre,
          precio: producto.precio,
          cantidad: producto.cantidad,
          medida: producto.medida,
          updatedAt: DateTime.now(),
        ),
      );
      agregados++;
    }
    state = AsyncData(await _leer(dao));
    return agregados;
  }

  Future<void> marcar(String lineaId, {required bool enCarrito}) async {
    final dao = await _dao;
    final linea = _lineaLocal(lineaId);
    if (linea == null) return;
    await dao.actualizarLinea(linea.copyWith(enCarrito: enCarrito, updatedAt: DateTime.now()));
    state = AsyncData(await _leer(dao));
  }

  /// Cambia precio, cantidad o nota de la línea. Con [actualizarProducto] el
  /// precio nuevo se guarda también en el producto: es como se mantiene el
  /// catálogo al día sin ir a editarlo aparte (decisión 0004).
  Future<void> editarLinea(
    String lineaId, {
    double? precio,
    double? cantidad,
    String? notas,
    bool actualizarProducto = false,
  }) async {
    final dao = await _dao;
    final linea = _lineaLocal(lineaId);
    if (linea == null) return;
    await dao.actualizarLinea(
      linea.copyWith(precio: precio, cantidad: cantidad, notas: notas, updatedAt: DateTime.now()),
    );
    if (actualizarProducto && linea.productoId != null && precio != null) {
      final productos = ref.read(productoNotifierProvider).valueOrNull ?? const [];
      final producto = productos.where((p) => p.id == linea.productoId).firstOrNull;
      if (producto != null) {
        await ref
            .read(productoNotifierProvider.notifier)
            .actualizar(producto.copyWith(precio: precio, updatedAt: DateTime.now()));
      }
    }
    state = AsyncData(await _leer(dao));
  }

  Future<void> quitarLinea(String lineaId) async {
    final dao = await _dao;
    await dao.borrarLinea(lineaId);
    state = AsyncData(await _leer(dao));
  }

  /// Nulo quita el presupuesto.
  Future<void> ponerPresupuesto(double? presupuesto) async {
    final dao = await _dao;
    final compra = await _abrirSiHaceFalta(dao);
    await dao.actualizarCompra(
      Compra(
        id: compra.id,
        iniciadaEn: compra.iniciadaEn,
        presupuesto: presupuesto,
        notas: compra.notas,
        updatedAt: DateTime.now(),
      ),
    );
    state = AsyncData(await _leer(dao));
  }

  /// Cierra la compra y la manda al historial. Devuelve la compra cerrada
  /// para quien quiera el PDF; nulo si no había nada que cerrar.
  Future<Compra?> finalizar() async {
    final dao = await _dao;
    final compra = await dao.enCurso();
    if (compra == null) return null;
    if ((await dao.lineasDe(compra.id)).isEmpty) return null;
    final ahora = DateTime.now();
    final cerrada = Compra(
      id: compra.id,
      iniciadaEn: compra.iniciadaEn,
      finalizadaEn: ahora,
      presupuesto: compra.presupuesto,
      notas: compra.notas,
      updatedAt: ahora,
    );
    await dao.actualizarCompra(cerrada);
    // El libro lleva la cuenta de sus días con compras; se recuenta, no se
    // incrementa, para que dé igual cuántas veces se llame.
    final libros = await ref.read(libroComprasServiceProvider.future);
    await libros.recontarDias(await ref.read(databaseProvider.future));
    ref.invalidate(comprasDelMesProvider);
    state = AsyncData(await _leer(dao));
    return cerrada;
  }

  LineaCompra? _lineaLocal(String id) =>
      state.valueOrNull?.lineas.where((l) => l.id == id).firstOrNull;
}

final compraEnCursoProvider = AsyncNotifierProvider<CompraEnCursoNotifier, EstadoCompraEnCurso>(
  CompraEnCursoNotifier.new,
);
