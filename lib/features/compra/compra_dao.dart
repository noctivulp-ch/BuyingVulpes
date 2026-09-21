import 'package:sqflite/sqflite.dart';

import 'compra_model.dart';

/// Filas de `compra` y `linea_compra`. Una compra con sus líneas se lee y se
/// escribe junta porque no tiene sentido una sin la otra.
class CompraDao {
  CompraDao(this._db);

  final DatabaseExecutor _db;

  Future<Compra?> enCurso() async {
    final filas = await _db.query('compra', where: 'finalizada_en IS NULL', limit: 1);
    return filas.isEmpty ? null : Compra.fromMap(filas.first);
  }

  Future<Compra?> obtener(String id) async {
    final filas = await _db.query('compra', where: 'id = ?', whereArgs: [id]);
    return filas.isEmpty ? null : Compra.fromMap(filas.first);
  }

  Future<List<LineaCompra>> lineasDe(String compraId) async {
    final filas = await _db.query(
      'linea_compra',
      where: 'compra_id = ?',
      whereArgs: [compraId],
      orderBy: 'tienda_nombre COLLATE NOCASE, updated_at',
    );
    return filas.map(LineaCompra.fromMap).toList();
  }

  Future<void> insertarCompra(Compra compra) => _db.insert('compra', compra.toMap());

  Future<void> actualizarCompra(Compra compra) =>
      _db.update('compra', compra.toMap(), where: 'id = ?', whereArgs: [compra.id]);

  Future<void> insertarLinea(LineaCompra linea) => _db.insert('linea_compra', linea.toMap());

  Future<void> actualizarLinea(LineaCompra linea) =>
      _db.update('linea_compra', linea.toMap(), where: 'id = ?', whereArgs: [linea.id]);

  /// Físico: una línea de la compra en curso que se quita no es historial.
  Future<void> borrarLinea(String id) => _db.delete('linea_compra', where: 'id = ?', whereArgs: [id]);

  /// Las finalizadas entre dos fechas, más recientes primero. Es lo que llena
  /// el calendario de un mes.
  Future<List<Compra>> finalizadasEntre(DateTime desde, DateTime hasta) async {
    final filas = await _db.query(
      'compra',
      where: 'finalizada_en >= ? AND finalizada_en < ?',
      whereArgs: [desde.toIso8601String(), hasta.toIso8601String()],
      orderBy: 'finalizada_en DESC',
    );
    return filas.map(Compra.fromMap).toList();
  }
}
