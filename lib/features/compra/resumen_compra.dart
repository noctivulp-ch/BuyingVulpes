import 'compra_model.dart';

/// Las cuentas de una compra, calculadas y nada más. Sin Flutter, sin base:
/// se prueban con listas en memoria y las usan igual la pantalla y el PDF.
class ResumenCompra {
  ResumenCompra(this.lineas, {this.presupuesto});

  final List<LineaCompra> lineas;
  final double? presupuesto;

  /// Todo lo anotado, esté o no en el carrito.
  double get totalLista => lineas.fold(0, (s, l) => s + l.subtotal);

  /// Solo lo marcado: lo que se va a pagar.
  double get totalCarrito => lineas.where((l) => l.enCarrito).fold(0, (s, l) => s + l.subtotal);

  double get totalPendiente => totalLista - totalCarrito;

  int get articulos => lineas.length;
  int get articulosEnCarrito => lineas.where((l) => l.enCarrito).length;

  /// Cuánto queda del presupuesto después del carrito; nulo sin presupuesto.
  double? get restante => presupuesto == null ? null : presupuesto! - totalCarrito;

  /// La lista completa se pasa del presupuesto: conviene saberlo antes de
  /// llegar a la caja, no en la caja.
  bool get listaExcedePresupuesto => presupuesto != null && totalLista > presupuesto!;

  bool get carritoExcedePresupuesto => presupuesto != null && totalCarrito > presupuesto!;

  /// Agrupadas por tienda, en el orden en que aparecen. Las de una misma
  /// tienda se recorren juntas en el pasillo; separarlas por tienda es lo que
  /// hace útil una lista de varias tiendas.
  List<GrupoPorTienda> get porTienda {
    final grupos = <String, GrupoPorTienda>{};
    for (final l in lineas) {
      grupos.putIfAbsent(l.tiendaId, () => GrupoPorTienda(l.tiendaId, l.tiendaNombre)).lineas.add(l);
    }
    return grupos.values.toList();
  }
}

class GrupoPorTienda {
  GrupoPorTienda(this.tiendaId, this.tiendaNombre);

  final String tiendaId;
  final String tiendaNombre;
  final List<LineaCompra> lineas = [];

  double get total => lineas.fold(0, (s, l) => s + l.subtotal);
  double get totalCarrito => lineas.where((l) => l.enCarrito).fold(0, (s, l) => s + l.subtotal);
  List<LineaCompra> get pendientes => [for (final l in lineas) if (!l.enCarrito) l];
  List<LineaCompra> get enCarrito => [for (final l in lineas) if (l.enCarrito) l];
}
