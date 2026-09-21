import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/db_providers.dart';
import 'producto_dao.dart';
import 'producto_model.dart';

/// El catálogo entero, de todas las tiendas. Agruparlo por tienda es cosa de
/// [productosPorTiendaProvider]; acá solo se escribe y se lee.
class ProductoNotifier extends AsyncNotifier<List<Producto>> {
  Future<ProductoDao> get _dao async => ProductoDao(await ref.read(databaseProvider.future));

  @override
  Future<List<Producto>> build() async =>
      ProductoDao(await ref.watch(databaseProvider.future)).listar();

  Future<void> crear(Producto producto) async {
    final dao = await _dao;
    await dao.insertar(producto);
    state = AsyncData(await dao.listar());
  }

  Future<void> actualizar(Producto producto) async {
    final dao = await _dao;
    await dao.actualizar(producto);
    state = AsyncData(await dao.listar());
  }

  Future<void> archivar(String id) async {
    final dao = await _dao;
    await dao.archivar(id, DateTime.now());
    state = AsyncData(await dao.listar());
  }
}

final productoNotifierProvider = AsyncNotifierProvider<ProductoNotifier, List<Producto>>(
  ProductoNotifier.new,
);

/// Los activos de cada tienda, ya ordenados por nombre por el DAO.
final productosPorTiendaProvider = Provider<Map<String, List<Producto>>>((ref) {
  final todos = ref.watch(productoNotifierProvider).valueOrNull ?? const [];
  final porTienda = <String, List<Producto>>{};
  for (final p in todos) {
    if (!p.activo) continue;
    porTienda.putIfAbsent(p.tiendaId, () => []).add(p);
  }
  return porTienda;
});
