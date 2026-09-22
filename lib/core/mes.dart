/// Un mes del calendario, como clave: del historial, y del libro que lo cubre.
class Mes {
  const Mes(this.anio, this.mes);

  Mes.de(DateTime fecha) : this(fecha.year, fecha.month);

  final int anio;
  final int mes;

  DateTime get primero => DateTime(anio, mes);
  DateTime get siguiente => DateTime(anio, mes + 1);

  @override
  bool operator ==(Object other) => other is Mes && other.anio == anio && other.mes == mes;
  @override
  int get hashCode => Object.hash(anio, mes);
}
