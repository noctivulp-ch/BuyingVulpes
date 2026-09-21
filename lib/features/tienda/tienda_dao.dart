import 'package:sqflite/sqflite.dart';

import 'tienda_model.dart';

/// Filas de `tienda`, y nada más: la regla de negocio vive en el Notifier.
class TiendaDao {
  TiendaDao(this._db);

  final DatabaseExecutor _db;

  Future<List<Tienda>> listar() async {
    final filas = await _db.query('tienda', orderBy: 'nombre COLLATE NOCASE');
    return filas.map(Tienda.fromMap).toList();
  }

  Future<void> insertar(Tienda tienda) => _db.insert('tienda', tienda.toMap());

  Future<void> actualizar(Tienda tienda) =>
      _db.update('tienda', tienda.toMap(), where: 'id = ?', whereArgs: [tienda.id]);

  /// Borrado lógico. Una tienda con compras en el historial no puede
  /// desaparecer de verdad: el desglose la nombra.
  Future<void> archivar(String id, DateTime cuando) => _db.update(
    'tienda',
    {'deleted_at': cuando.toIso8601String(), 'updated_at': cuando.toIso8601String()},
    where: 'id = ?',
    whereArgs: [id],
  );
}
