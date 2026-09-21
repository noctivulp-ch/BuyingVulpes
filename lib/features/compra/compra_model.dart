import '../../core/medida.dart';

/// Una salida de compras: se abre al agregar la primera línea y se cierra al
/// finalizar. Una sola en curso a la vez.
class Compra {
  const Compra({
    required this.id,
    required this.iniciadaEn,
    required this.updatedAt,
    this.finalizadaEn,
    this.presupuesto,
    this.notas,
  });

  final String id;
  final DateTime iniciadaEn;
  final DateTime? finalizadaEn;
  final double? presupuesto;
  final String? notas;
  final DateTime updatedAt;

  bool get enCurso => finalizadaEn == null;

  factory Compra.fromMap(Map<String, Object?> m) => Compra(
    id: m['id'] as String,
    iniciadaEn: DateTime.parse(m['iniciada_en'] as String),
    finalizadaEn: m['finalizada_en'] == null ? null : DateTime.parse(m['finalizada_en'] as String),
    presupuesto: (m['presupuesto'] as num?)?.toDouble(),
    notas: m['notas'] as String?,
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'iniciada_en': iniciadaEn.toIso8601String(),
    'finalizada_en': finalizadaEn?.toIso8601String(),
    'presupuesto': presupuesto,
    'notas': notas,
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Un producto dentro de una compra, con TODO copiado: nombre de la tienda,
/// nombre del producto, precio y medida. La compra es una foto del día
/// (decisión 0003); editar el catálogo después no la cambia.
class LineaCompra {
  const LineaCompra({
    required this.id,
    required this.compraId,
    required this.tiendaId,
    required this.tiendaNombre,
    required this.productoNombre,
    required this.precio,
    required this.cantidad,
    required this.medida,
    required this.updatedAt,
    this.productoId,
    this.enCarrito = false,
    this.notas,
  });

  final String id;
  final String compraId;

  /// De qué producto salió. Nulo si el producto se borró después: la línea
  /// sigue valiendo por sí sola.
  final String? productoId;
  final String tiendaId;
  final String tiendaNombre;
  final String productoNombre;
  final double precio;
  final double cantidad;
  final Medida medida;

  /// Marcada: ya está en el carrito. Es la casilla de la lista.
  final bool enCarrito;
  final String? notas;
  final DateTime updatedAt;

  double get subtotal => precio * cantidad;

  factory LineaCompra.fromMap(Map<String, Object?> m) => LineaCompra(
    id: m['id'] as String,
    compraId: m['compra_id'] as String,
    productoId: m['producto_id'] as String?,
    tiendaId: m['tienda_id'] as String,
    tiendaNombre: m['tienda_nombre'] as String,
    productoNombre: m['producto_nombre'] as String,
    precio: (m['precio'] as num).toDouble(),
    cantidad: (m['cantidad'] as num).toDouble(),
    medida: Medida.deNombre(m['medida'] as String),
    enCarrito: (m['en_carrito'] as int) == 1,
    notas: m['notas'] as String?,
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'compra_id': compraId,
    'producto_id': productoId,
    'tienda_id': tiendaId,
    'tienda_nombre': tiendaNombre,
    'producto_nombre': productoNombre,
    'precio': precio,
    'cantidad': cantidad,
    'medida': medida.nombre,
    'en_carrito': enCarrito ? 1 : 0,
    'notas': notas,
    'updated_at': updatedAt.toIso8601String(),
  };

  LineaCompra copyWith({
    double? precio,
    double? cantidad,
    bool? enCarrito,
    String? notas,
    DateTime? updatedAt,
  }) => LineaCompra(
    id: id,
    compraId: compraId,
    productoId: productoId,
    tiendaId: tiendaId,
    tiendaNombre: tiendaNombre,
    productoNombre: productoNombre,
    precio: precio ?? this.precio,
    cantidad: cantidad ?? this.cantidad,
    medida: medida,
    enCarrito: enCarrito ?? this.enCarrito,
    notas: notas ?? this.notas,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
