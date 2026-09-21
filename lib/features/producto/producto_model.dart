import '../../core/medida.dart';

/// Algo que se compra en UNA tienda, con su precio por medida y la cantidad
/// que se suele llevar (decisiones 0001 y 0002).
class Producto {
  const Producto({
    required this.id,
    required this.tiendaId,
    required this.nombre,
    required this.precio,
    required this.updatedAt,
    this.cantidad = 1,
    this.medida = Medida.unidad,
    this.imagen,
    this.notas,
    this.deletedAt,
  });

  final String id;
  final String tiendaId;
  final String nombre;

  /// Por [medida]: el kilo, el litro, la unidad.
  final double precio;

  /// La que se lleva normalmente. Es lo que la línea toma al agregarlo, y se
  /// puede cambiar en la línea sin tocar el producto.
  final double cantidad;
  final Medida medida;

  /// Ruta de la foto dentro de la carpeta de imágenes de la app, o null.
  final String? imagen;
  final String? notas;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get activo => deletedAt == null;

  factory Producto.fromMap(Map<String, Object?> m) => Producto(
    id: m['id'] as String,
    tiendaId: m['tienda_id'] as String,
    nombre: m['nombre'] as String,
    precio: (m['precio'] as num).toDouble(),
    cantidad: (m['cantidad'] as num).toDouble(),
    medida: Medida.deNombre(m['medida'] as String),
    imagen: m['imagen'] as String?,
    notas: m['notas'] as String?,
    updatedAt: DateTime.parse(m['updated_at'] as String),
    deletedAt: m['deleted_at'] == null ? null : DateTime.parse(m['deleted_at'] as String),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'tienda_id': tiendaId,
    'nombre': nombre,
    'precio': precio,
    'cantidad': cantidad,
    'medida': medida.nombre,
    'imagen': imagen,
    'notas': notas,
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  Producto copyWith({
    String? nombre,
    double? precio,
    double? cantidad,
    Medida? medida,
    String? imagen,
    bool quitarImagen = false,
    String? notas,
    DateTime? updatedAt,
  }) => Producto(
    id: id,
    tiendaId: tiendaId,
    nombre: nombre ?? this.nombre,
    precio: precio ?? this.precio,
    cantidad: cantidad ?? this.cantidad,
    medida: medida ?? this.medida,
    imagen: quitarImagen ? null : (imagen ?? this.imagen),
    notas: notas ?? this.notas,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt,
  );
}
