import 'package:sqflite/sqflite.dart';

import 'producto_model.dart';

class ProductoDao {
  ProductoDao(this._db);

  final DatabaseExecutor _db;

  /// Todos, archivados incluidos: la lista base no filtra.
  Future<List<Producto>> listar() async {
    final filas = await _db.query('producto', orderBy: 'nombre COLLATE NOCASE');
    return filas.map(Producto.fromMap).toList();
  }

  Future<void> insertar(Producto producto) => _db.insert('producto', producto.toMap());

  Future<void> actualizar(Producto producto) =>
      _db.update('producto', producto.toMap(), where: 'id = ?', whereArgs: [producto.id]);

  Future<void> archivar(String id, DateTime cuando) => _db.update(
    'producto',
    {'deleted_at': cuando.toIso8601String(), 'updated_at': cuando.toIso8601String()},
    where: 'id = ?',
    whereArgs: [id],
  );
}
