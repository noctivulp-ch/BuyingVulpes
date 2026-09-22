
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/mes.dart';

/// Libros de compras rodantes — la "máquina de escribir" (decisión 0007).
///
/// Las compras no viven en la base principal: viven en **libros**, archivos
/// SQLite con las tablas `compra` y `linea_compra`. Un libro recibe compras
/// durante **un año calendario**; la primera compra del año siguiente abre
/// otro. Como una máquina de escribir: la hoja llena se deja atrás y se sigue
/// en la siguiente. **Ningún dato se mueve ni se borra jamás**: cerrar un libro
/// es dejar de escribirle.
///
/// El libro abierto se adjunta con `ATTACH` bajo el alias [aliasLibro]. Como
/// `compra` y `linea_compra` NO existen en la base principal, SQLite resuelve
/// los nombres sin calificar contra el adjunto: `CompraDao` consulta `compra`
/// como siempre y las escrituras caen en el archivo del año.
///
/// Los libros cerrados se leen **sin restaurarlos**: el historial abre el
/// archivo del año que se está mirando en modo lectura, consulta y lo cierra.
class LibroCompras {
  const LibroCompras({
    required this.id,
    required this.archivo,
    required this.anio,
    required this.fechaInicio,
    required this.fechaFin,
    required this.diasConCompras,
    required this.cerrado,
  });

  final String id;
  final String archivo;

  /// El año calendario que cubre. Es el criterio de rotación y lo que hace
  /// trivial saber qué libro tiene un mes dado.
  final int anio;
  final DateTime fechaInicio;

  /// Solo en libros cerrados: la fecha de su última compra.
  final DateTime? fechaFin;
  final int diasConCompras;
  final bool cerrado;

  static LibroCompras deFila(Map<String, Object?> f) => LibroCompras(
    id: f['id'] as String,
    archivo: f['archivo'] as String,
    anio: f['anio'] as int,
    fechaInicio: DateTime.parse(f['fecha_inicio'] as String),
    fechaFin: f['fecha_fin'] == null ? null : DateTime.parse(f['fecha_fin'] as String),
    diasConCompras: f['dias_con_compras'] as int,
    cerrado: (f['cerrado'] as int) == 1,
  );
}

const _uuid = Uuid();

/// Alias con el que se adjunta el libro abierto.
const aliasLibro = 'libro';

/// Esquema de un libro: solo las tablas de compras, con sus índices. Se
/// reutiliza tal cual para cada libro nuevo.
const esquemaLibro = [
  // Hay UNA compra en curso como máximo (finalizada_en IS NULL). Vive en el
  // libro y no en memoria porque una lista de compras se arma en días.
  '''
  CREATE TABLE IF NOT EXISTS compra (
    id             TEXT PRIMARY KEY,
    iniciada_en    TEXT NOT NULL,
    finalizada_en  TEXT,
    presupuesto    REAL,
    notas          TEXT,
    updated_at     TEXT NOT NULL
  );
  ''',
  // La línea es una FOTO: lleva copiados el nombre de la tienda, el del
  // producto, el precio y la medida (decisión 0003). Sin REFERENCES al
  // catálogo: un libro tiene que poder leerse suelto.
  '''
  CREATE TABLE IF NOT EXISTS linea_compra (
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
  'CREATE INDEX IF NOT EXISTS idx_linea_compra ON linea_compra(compra_id);',
  'CREATE INDEX IF NOT EXISTS idx_compra_finalizada ON compra(finalizada_en);',
];

/// Columnas agregadas a las tablas del libro después de que hubiera libros
/// escritos, por tabla. Vacío hoy; el día que se sume una, se pone acá y todo
/// libro se pone al día **al adjuntarse o abrirse**, no en la migración de la
/// base principal (que solo ve el libro abierto).
const _columnasNuevasDelLibro = <String, Map<String, String>>{};

/// Pone al día el esquema de un libro ya escrito preguntando qué columnas
/// tiene: los libros no llevan número de versión propio.
Future<void> ponerAlDiaEsquemaDeLibro(DatabaseExecutor db, {String? alias}) async {
  final prefijo = alias == null ? '' : '$alias.';
  for (final tabla in _columnasNuevasDelLibro.entries) {
    final columnas = await db.rawQuery('PRAGMA ${prefijo}table_info(${tabla.key})');
    if (columnas.isEmpty) continue;
    final presentes = {for (final c in columnas) c['name'] as String};
    for (final columna in tabla.value.entries) {
      if (presentes.contains(columna.key)) continue;
      await db.execute(columna.value.replaceFirst('TABLE ${tabla.key}', 'TABLE $prefijo${tabla.key}'));
    }
  }
}

/// Aplica el esquema de un libro a una base cualquiera. En producción cada
/// libro es su propio archivo; una prueba puede aplicarlo sobre la base en
/// memoria y consultar igual.
Future<void> aplicarEsquemaLibro(DatabaseExecutor db) async {
  for (final sentencia in esquemaLibro) {
    await db.execute(sentencia);
  }
}

/// Gestiona qué libro está abierto, lo adjunta, lo rota cuando cambia el año,
/// y abre los cerrados para leerlos.
class LibroComprasService {
  LibroComprasService({required this.directorio});

  /// Carpeta donde viven los libros: la misma de la base principal.
  final String directorio;

  String rutaDe(String archivo) => p.join(directorio, archivo);

  static String _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();
  static String _nombreAbierto(int anio) => 'compras-$anio.db';

  Future<LibroCompras?> libroAbierto(DatabaseExecutor db) async {
    final filas = await db.query('libro_compras', where: 'cerrado = 0', limit: 1);
    return filas.isEmpty ? null : LibroCompras.deFila(filas.first);
  }

  Future<List<LibroCompras>> todos(DatabaseExecutor db) async {
    final filas = await db.query('libro_compras', orderBy: 'anio');
    return filas.map(LibroCompras.deFila).toList();
  }

  /// El libro que cubre un mes, abierto o cerrado; nulo si no hay.
  Future<LibroCompras?> libroDe(DatabaseExecutor db, Mes mes) async {
    final filas = await db.query('libro_compras', where: 'anio = ?', whereArgs: [mes.anio], limit: 1);
    return filas.isEmpty ? null : LibroCompras.deFila(filas.first);
  }

  /// Crea el archivo de un libro con su esquema y lo registra en el índice.
  Future<LibroCompras> _crear(DatabaseExecutor db, DateTime primeraFecha) async {
    final archivo = _nombreAbierto(primeraFecha.year);
    // Aparte, no adjunto: no se puede aplicar DDL sobre una base que todavía
    // no está adjunta.
    final nuevo = await databaseFactory.openDatabase(
      rutaDe(archivo),
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await aplicarEsquemaLibro(nuevo);
    await nuevo.close();

    final libro = LibroCompras(
      id: _uuid.v4(),
      archivo: archivo,
      anio: primeraFecha.year,
      fechaInicio: primeraFecha,
      fechaFin: null,
      diasConCompras: 0,
      cerrado: false,
    );
    await db.insert('libro_compras', {
      'id': libro.id,
      'archivo': archivo,
      'anio': libro.anio,
      'fecha_inicio': _soloFecha(primeraFecha),
      'fecha_fin': null,
      'dias_con_compras': 0,
      'cerrado': 0,
    });
    return libro;
  }

  /// Deja SIEMPRE un libro adjunto, creándolo si no existe: una app recién
  /// instalada consulta `compra` antes de anotar nada, y sin libro moriría con
  /// `no such table`. Crearlo vacío no adelanta nada: es el mismo archivo.
  Future<void> adjuntarAbierto(Database db) async {
    final libro = await libroAbierto(db) ?? await _crear(db, DateTime.now());
    await _adjuntar(db, libro.archivo);
  }

  /// `PRAGMA database_list` es la única forma de saberlo: preguntar por la
  /// tabla no distingue "no hay libro" de "libro adjunto pero vacío".
  Future<bool> estaAdjunto(DatabaseExecutor db) async {
    final esquemas = await db.rawQuery('PRAGMA database_list');
    return esquemas.any((e) => e['name'] == aliasLibro);
  }

  /// Idempotente y tolerante a dos llamadas a la vez: un segundo ATTACH sobre
  /// la misma conexión muere con `already in use`, y sqflite comparte la
  /// conexión entre aperturas del mismo archivo. Comprobar antes no alcanza
  /// (hay un `await` en medio): el fallo se acepta solo si, al mirar de nuevo,
  /// el libro quedó adjunto.
  Future<void> _adjuntar(Database db, String archivo) async {
    if (await estaAdjunto(db)) await desadjuntar(db);
    try {
      await db.execute("ATTACH DATABASE '${rutaDe(archivo)}' AS $aliasLibro");
    } catch (_) {
      if (!await estaAdjunto(db)) rethrow;
    }
    await ponerAlDiaEsquemaDeLibro(db, alias: aliasLibro);
  }

  Future<void> desadjuntar(Database db) async {
    try {
      await db.execute('DETACH DATABASE $aliasLibro');
    } catch (_) {}
  }

  /// Se llama ANTES de abrir una compra con fecha [fecha]. Deja adjunto el
  /// libro que debe recibirla: si el año cambió, cierra el actual y abre el
  /// del año nuevo. Devuelve el libro que quedó abierto.
  ///
  /// Se rota al ABRIR la compra y no al finalizarla, para que una compra nunca
  /// quede con sus líneas en un libro y su cierre en otro.
  Future<LibroCompras> prepararPara(Database db, DateTime fecha) async {
    final actual = await libroAbierto(db);
    if (actual == null) {
      final libro = await _crear(db, fecha);
      await _adjuntar(db, libro.archivo);
      return libro;
    }
    if (actual.anio == fecha.year) return actual;

    await _cerrar(db, actual);
    final libro = await _crear(db, fecha);
    await _adjuntar(db, libro.archivo);
    return libro;
  }

  /// Recalcula `dias_con_compras` y la última fecha del libro abierto a partir
  /// de lo que hay de verdad dentro. Contar en vez de incrementar es exacto y
  /// da igual cuántas veces se llame.
  Future<void> recontarDias(Database db) async {
    final libro = await libroAbierto(db);
    if (libro == null) return;
    final r = (await db.rawQuery(
      'SELECT COUNT(DISTINCT date(finalizada_en)) AS dias FROM compra WHERE finalizada_en IS NOT NULL',
    )).first;
    await db.update(
      'libro_compras',
      {'dias_con_compras': (r['dias'] as int?) ?? 0},
      where: 'id = ?',
      whereArgs: [libro.id],
    );
  }

  /// Cierra un libro: lo desadjunta y actualiza el índice. El archivo conserva
  /// su nombre (`compras-2026.db`): ya dice qué es.
  Future<void> _cerrar(Database db, LibroCompras libro) async {
    await desadjuntar(db);
    await db.update(
      'libro_compras',
      {'fecha_fin': _soloFecha(DateTime(libro.anio, 12, 31)), 'cerrado': 1},
      where: 'id = ?',
      whereArgs: [libro.id],
    );
  }

  /// Abre un libro cerrado para leerlo, sin adjuntarlo ni restaurarlo. Quien
  /// lo abre lo cierra.
  Future<Database> abrirParaLeer(LibroCompras libro) async {
    final db = await databaseFactory.openDatabase(
      rutaDe(libro.archivo),
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    return db;
  }
}

/// Los libros viven en la misma carpeta que la base principal. Una prueba que
/// necesite otra carpeta lo sobreescribe.
final libroComprasServiceProvider = FutureProvider<LibroComprasService>((ref) async {
  return LibroComprasService(directorio: p.dirname(await AppDatabase.ruta()));
});
