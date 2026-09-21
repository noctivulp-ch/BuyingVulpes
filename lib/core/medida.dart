/// En qué se mide lo que se compra. El precio de un producto es POR esta
/// medida, y la cantidad de una línea va en ella: 1,5 kg a ₡1.200 el kilo son
/// ₡1.800 (decisión 0002).
///
/// Cerrada a propósito. Un campo libre deja "kg", "Kg", "kilo" y "kilos" en
/// el mismo catálogo, y eso rompe cualquier comparación. Si falta una medida,
/// se agrega acá y a todo lo demás le llega sola.
enum Medida {
  unidad('unidad', 'u', 'unidades'),
  kilogramo('kilogramo', 'kg', 'kilogramos'),
  gramo('gramo', 'g', 'gramos'),
  litro('litro', 'L', 'litros'),
  mililitro('mililitro', 'ml', 'mililitros'),
  paquete('paquete', 'paq', 'paquetes'),
  docena('docena', 'doc', 'docenas');

  const Medida(this.nombre, this.abreviatura, this.plural);

  /// Como se guarda en la base y como se lee en singular.
  final String nombre;

  /// Lo que va pegado al número en una lista: "1,5 kg".
  final String abreviatura;
  final String plural;

  /// Con cuántos decimales tiene sentido escribir la cantidad. Medio kilo
  /// existe; media docena también; media unidad de leche, no.
  bool get admiteFraccion => this != unidad && this != paquete;

  static Medida deNombre(String nombre) =>
      Medida.values.firstWhere((m) => m.nombre == nombre, orElse: () => Medida.unidad);
}
