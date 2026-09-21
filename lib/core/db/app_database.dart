import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// La base: una sola, SQLite, en la carpeta de datos de la app.
///
/// El esquema es público para que las pruebas lo apliquen en memoria en vez
/// de copiarlo: un esquema duplicado diverge en silencio y una prueba contra
/// un esquema que ya no existe no prueba nada.
class AppDatabase {
  static Database? _instancia;

  static const version = 1;

  static const esquema = [
    '''
    CREATE TABLE tienda (
      id          TEXT PRIMARY KEY,
      nombre      TEXT NOT NULL,
      notas       TEXT,
      updated_at  TEXT NOT NULL,
      deleted_at  TEXT
    );
    ''',
    // Un producto pertenece a UNA tienda (decisión 0001): el mismo arroz en
    // otra tienda es otro producto, con su precio. Comparar es justamente eso.
    '''
    CREATE TABLE producto (
      id          TEXT PRIMARY KEY,
      tienda_id   TEXT NOT NULL,
      nombre      TEXT NOT NULL,
      precio      REAL NOT NULL,
      cantidad    REAL NOT NULL DEFAULT 1,
      medida      TEXT NOT NULL DEFAULT 'unidad',
      imagen      TEXT,
      notas       TEXT,
      updated_at  TEXT NOT NULL,
      deleted_at  TEXT
    );
    ''',
    // Hay UNA compra en curso como máximo (finalizada_en IS NULL). Vive en la
    // base y no en memoria porque una lista de compras se arma en días.
    '''
    CREATE TABLE compra (
      id             TEXT PRIMARY KEY,
      iniciada_en    TEXT NOT NULL,
      finalizada_en  TEXT,
      presupuesto    REAL,
      notas          TEXT,
      updated_at     TEXT NOT NULL
    );
    ''',
    // La línea es una FOTO: lleva copiados el nombre de la tienda, el del
    // producto, el precio y la medida. Un desglose de hace seis meses tiene
    // que decir lo que costó ese día, no lo que cuesta hoy (decisión 0003).
    '''
    CREATE TABLE linea_compra (
      id               TEXT PRIMARY KEY,
      compra_id        TEXT NOT NULL,
      producto_id      TEXT,
      tienda_id        TEXT NOT NULL,
      tienda_nombre    TEXT NOT NULL,
      producto_nombre  TEXT NOT NULL,
      precio           REAL NOT NULL,
      cantidad         REAL NOT NULL,
      medida           TEXT NOT NULL,
      en_carrito       INTEGER NOT NULL DEFAULT 0,
      notas            TEXT,
      updated_at       TEXT NOT NULL
    );
    ''',
    'CREATE INDEX idx_producto_tienda ON producto(tienda_id);',
    'CREATE INDEX idx_linea_compra ON linea_compra(compra_id);',
    'CREATE INDEX idx_compra_finalizada ON compra(finalizada_en);',
  ];

  static Future<void> crearEsquema(DatabaseExecutor db) async {
    for (final sentencia in esquema) {
      await db.execute(sentencia);
    }
  }

  /// En escritorio SQLite no viene con el sistema: se usa el motor empaquetado.
  static void inicializarFactory() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static Future<String> ruta() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'buying_vulpes.db');
  }

  static Future<Database> abrir() async {
    if (_instancia != null) return _instancia!;
    inicializarFactory();
    final db = await openDatabase(
      await ruta(),
      version: version,
      onCreate: (db, _) => crearEsquema(db),
    );
    _instancia = db;
    return db;
  }
}
