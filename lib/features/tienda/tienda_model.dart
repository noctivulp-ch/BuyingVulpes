/// Un lugar donde se compra. Es el eje del catálogo: todo producto es de una
/// tienda (decisión 0001).
class Tienda {
  const Tienda({
    required this.id,
    required this.nombre,
    required this.updatedAt,
    this.notas,
    this.deletedAt,
  });

  final String id;
  final String nombre;
  final String? notas;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get activa => deletedAt == null;

  factory Tienda.fromMap(Map<String, Object?> m) => Tienda(
    id: m['id'] as String,
    nombre: m['nombre'] as String,
    notas: m['notas'] as String?,
    updatedAt: DateTime.parse(m['updated_at'] as String),
    deletedAt: m['deleted_at'] == null ? null : DateTime.parse(m['deleted_at'] as String),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': nombre,
    'notas': notas,
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  Tienda copyWith({String? nombre, String? notas, DateTime? updatedAt}) => Tienda(
    id: id,
    nombre: nombre ?? this.nombre,
    notas: notas ?? this.notas,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt,
  );
}
