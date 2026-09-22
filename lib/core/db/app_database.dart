import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../features/compra/libro_compras.dart';

/// La base principal: el catálogo y el índice de libros. Las compras NO están
/// acá: viven en los libros rodantes (decisión 0007), uno por año, que se
/// adjuntan al abrir.
///
/// El esquema es público para que las pruebas lo apliquen en memoria en vez
/// de copiarlo: un esquema duplicado diverge en silencio y una prueba contra
/// un esquema que ya no existe no prueba nada.
class AppDatabase {
  static Database? _instancia;

  /// v1: todo en una base. v2: las compras se mudan a su primer libro.
  static const version = 2;

  static const _createTienda = '''
    CREATE TABLE tienda (
      id          TEXT PRIMARY KEY,
      nombre      TEXT NOT NULL,
      notas       TEXT,
      updated_at  TEXT NOT NULL,
      deleted_at  TEXT
    );
    ''';

  // Un producto pertenece a UNA tienda (decisión 0001): el mismo arroz en
  // otra tienda es otro producto, con su precio. Comparar es justamente eso.
  static const _createProducto = '''
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
    ''';

  /// Índice de libros. El nombre del archivo (`compras-2026.db`) es para que
  /// una persona entienda la carpeta; ESTA tabla es la fuente de verdad.
  static const _createLibroCompras = '''
    CREATE TABLE libro_compras (
      id                TEXT PRIMARY KEY,
      archivo           TEXT NOT NULL,
      anio              INTEGER NOT NULL,
      fecha_inicio      TEXT NOT NULL,
      fecha_fin         TEXT,
      dias_con_compras  INTEGER NOT NULL DEFAULT 0,
      cerrado           INTEGER NOT NULL DEFAULT 0
    );
    ''';

  static const esquema = [
    _createTienda,
    _createProducto,
    _createLibroCompras,
    'CREATE INDEX idx_producto_tienda ON producto(tienda_id);',
    'CREATE INDEX idx_libro_compras_anio ON libro_compras(anio);',
  ];

  static Future<void> crearEsquema(DatabaseExecutor db) async {
    for (final sentencia in esquema) {
      await db.execute(sentencia);
    }
  }

  /// v1 -> v2: las compras se mudan de la base principal a su primer libro.
  /// Es la ÚNICA vez que se mueven datos: de acá en adelante nacen en su libro.
  ///
  /// Público para que la prueba de migración la aplique sobre una base v1 de
  /// verdad. Copia, comprueba que las cuentas cuadran, y solo entonces borra
  /// las tablas viejas: si algo no cuadra, no se borra nada.
  static Future<void> migrarComprasALibro(Database db, String directorio) async {
    await db.execute(_createLibroCompras);
    await db.execute('CREATE INDEX IF NOT EXISTS idx_libro_compras_anio ON libro_compras(anio);');

    final compras = await db.query('compra', orderBy: 'iniciada_en');
    if (compras.isEmpty) {
      await db.execute('DROP TABLE IF EXISTS linea_compra');
      await db.execute('DROP TABLE IF EXISTS compra');
      return;
    }

    // Todas al libro del año de la primera: una base v1 no llevaba más de un
    // año de uso, y partirlas por año acá sería resolver un caso que no
    // existió. Si alguna fuera de otro año, el libro la conserva igual.
    final lineas = await db.query('linea_compra');
    final primera = DateTime.parse(compras.first['iniciada_en'] as String);
    final servicio = LibroComprasService(directorio: directorio);
    final archivo = 'compras-${primera.year}.db';
    final libro = await databaseFactory.openDatabase(
      servicio.rutaDe(archivo),
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await aplicarEsquemaLibro(libro);
    await libro.transaction((txn) async {
      for (final fila in compras) {
        await txn.insert('compra', fila);
      }
      for (final fila in lineas) {
        await txn.insert('linea_compra', fila);
      }
    });
    final copiadas = (await libro.rawQuery('SELECT COUNT(*) c FROM compra')).first['c'] as int;
    final copiadasLineas = (await libro.rawQuery('SELECT COUNT(*) c FROM linea_compra')).first['c'] as int;
    final dias = (await libro.rawQuery(
      'SELECT COUNT(DISTINCT date(finalizada_en)) d FROM compra WHERE finalizada_en IS NOT NULL',
    )).first['d'] as int;
    await libro.close();
    if (copiadas != compras.length || copiadasLineas != lineas.length) {
      throw StateError(
        'migracion v2: el libro quedo con $copiadas/${compras.length} compras y '
        '$copiadasLineas/${lineas.length} lineas — no se borra nada',
      );
    }

    await db.insert('libro_compras', {
      'id': const Uuid().v4(),
      'archivo': archivo,
      'anio': primera.year,
      'fecha_inicio': DateTime(primera.year, primera.month, primera.day).toIso8601String(),
      'fecha_fin': null,
      'dias_con_compras': dias,
      'cerrado': 0,
    });
    await db.execute('DROP TABLE linea_compra');
    await db.execute('DROP TABLE compra');
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
    final rutaBase = await ruta();
    final db = await openDatabase(
      rutaBase,
      version: version,
      onCreate: (db, _) => crearEsquema(db),
      onUpgrade: (db, viejo, nuevo) async {
        if (viejo < 2) await migrarComprasALibro(db, p.dirname(rutaBase));
      },
    );
    // Desde acá `SELECT * FROM compra` resuelve contra el libro del año.
    await LibroComprasService(directorio: p.dirname(rutaBase)).adjuntarAbierto(db);
    // Se asigna al FINAL, con la base ya usable: antes, otro lector se la
    // llevaría a medio preparar, sin el libro adjunto.
    _instancia = db;
    return db;
  }

  static Future<void> close() async {
    final db = _instancia;
    _instancia = null;
    if (db == null) return;
    // Soltar el libro ANTES de cerrar: sqflite comparte la conexión entre
    // aperturas del mismo archivo, y volvería con el alias tomado.
    await LibroComprasService(directorio: p.dirname(await ruta())).desadjuntar(db);
    await db.close();
  }
}
