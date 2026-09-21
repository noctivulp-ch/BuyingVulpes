import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/db_providers.dart';
import 'tienda_dao.dart';
import 'tienda_model.dart';

/// Las tiendas, con exactamente las operaciones de su ciclo de vida: crear,
/// renombrar, archivar. No hay borrado físico ni "restaurar" todavía porque
/// nadie los ha pedido, y un método que no se usa es deuda desde el día uno.
class TiendaNotifier extends AsyncNotifier<List<Tienda>> {
  /// El DAO se construye en cada llamada y nunca se guarda en un campo: un
  /// campo asignado en `build()` sobrevive a que la conexión se reemplace.
  Future<TiendaDao> get _dao async => TiendaDao(await ref.read(databaseProvider.future));

  @override
  Future<List<Tienda>> build() async => TiendaDao(await ref.watch(databaseProvider.future)).listar();

  Future<void> crear(Tienda tienda) async {
    final dao = await _dao;
    await dao.insertar(tienda);
    state = AsyncData(await dao.listar());
  }

  Future<void> actualizar(Tienda tienda) async {
    final dao = await _dao;
    await dao.actualizar(tienda);
    state = AsyncData(await dao.listar());
  }

  Future<void> archivar(String id) async {
    final dao = await _dao;
    await dao.archivar(id, DateTime.now());
    state = AsyncData(await dao.listar());
  }
}

final tiendaNotifierProvider = AsyncNotifierProvider<TiendaNotifier, List<Tienda>>(
  TiendaNotifier.new,
);

/// Solo las activas, que es lo que ven las pantallas. Quién ve una archivada
/// es presentación, no dato: la lista base no filtra.
final tiendasActivasProvider = Provider<List<Tienda>>((ref) {
  final todas = ref.watch(tiendaNotifierProvider).valueOrNull ?? const [];
  return [for (final t in todas) if (t.activa) t];
});
