import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/db/db_providers.dart';
import '../../core/mes.dart';
import '../compra/compra_dao.dart';
import '../compra/compra_model.dart';
import '../compra/libro_compras.dart';
import '../compra/resumen_compra.dart';

export '../../core/mes.dart';

/// Ejecuta [leer] contra el libro que cubre [mes]: la base principal si es el
/// libro abierto (está adjunto), o el archivo cerrado de ese año abierto solo
/// para leer y cerrado al terminar. Es lo que hace que mirar 2024 no
/// requiera restaurar nada (decisión 0007).
Future<T> _enElLibroDe<T>(Ref ref, Mes mes, T Function() vacio, Future<T> Function(DatabaseExecutor) leer) async {
  final db = await ref.watch(databaseProvider.future);
  final libros = await ref.watch(libroComprasServiceProvider.future);
  final libro = await libros.libroDe(db, mes);
  if (libro == null) return vacio();
  if (!libro.cerrado) return leer(db);
  final cerrado = await libros.abrirParaLeer(libro);
  try {
    return await leer(cerrado);
  } finally {
    await cerrado.close();
  }
}

/// Las compras finalizadas de un mes. Solo lectura: el historial no se edita.
final comprasDelMesProvider = FutureProvider.family<List<Compra>, Mes>((ref, mes) {
  return _enElLibroDe(
    ref,
    mes,
    () => const [],
    (db) => CompraDao(db).finalizadasEntre(mes.primero, mes.siguiente),
  );
});

/// Una compra cerrada con sus líneas y sus cuentas, para el detalle y el PDF.
class CompraDetallada {
  const CompraDetallada({required this.compra, required this.lineas});
  final Compra compra;
  final List<LineaCompra> lineas;
  ResumenCompra get resumen => ResumenCompra(lineas, presupuesto: compra.presupuesto);
}

/// Con qué libro buscarla: el año de su fecha. Sin el mes la búsqueda tendría
/// que abrir todos los libros cerrados uno por uno.
class ClaveDeCompra {
  const ClaveDeCompra(this.id, this.mes);
  final String id;
  final Mes mes;

  @override
  bool operator ==(Object other) => other is ClaveDeCompra && other.id == id && other.mes == mes;
  @override
  int get hashCode => Object.hash(id, mes);
}

final compraDetalladaProvider = FutureProvider.family<CompraDetallada?, ClaveDeCompra>((ref, clave) {
  return _enElLibroDe(ref, clave.mes, () => null, (db) async {
    final dao = CompraDao(db);
    final compra = await dao.obtener(clave.id);
    if (compra == null) return null;
    return CompraDetallada(compra: compra, lineas: await dao.lineasDe(clave.id));
  });
});
