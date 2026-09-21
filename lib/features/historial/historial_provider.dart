import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/db_providers.dart';
import '../compra/compra_dao.dart';
import '../compra/compra_model.dart';
import '../compra/resumen_compra.dart';

/// Un mes del calendario, como clave de familia.
class Mes {
  const Mes(this.anio, this.mes);
  final int anio;
  final int mes;

  DateTime get primero => DateTime(anio, mes);
  DateTime get siguiente => DateTime(anio, mes + 1);

  @override
  bool operator ==(Object other) => other is Mes && other.anio == anio && other.mes == mes;
  @override
  int get hashCode => Object.hash(anio, mes);
}

/// Las compras finalizadas de un mes. Solo lectura: el historial no se edita.
final comprasDelMesProvider = FutureProvider.family<List<Compra>, Mes>((ref, mes) async {
  final dao = CompraDao(await ref.watch(databaseProvider.future));
  return dao.finalizadasEntre(mes.primero, mes.siguiente);
});

/// Una compra cerrada con sus líneas y sus cuentas, para el detalle y el PDF.
class CompraDetallada {
  const CompraDetallada({required this.compra, required this.lineas});
  final Compra compra;
  final List<LineaCompra> lineas;
  ResumenCompra get resumen => ResumenCompra(lineas, presupuesto: compra.presupuesto);
}

final compraDetalladaProvider = FutureProvider.family<CompraDetallada?, String>((ref, id) async {
  final dao = CompraDao(await ref.watch(databaseProvider.future));
  final compra = await dao.obtener(id);
  if (compra == null) return null;
  return CompraDetallada(compra: compra, lineas: await dao.lineasDe(id));
});
