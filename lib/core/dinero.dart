import 'package:intl/intl.dart';

/// La moneda se escribe una sola vez. Colones porque es donde vive la primera
/// instalación; cambiarla es cambiar este símbolo y el separador.
const simboloMoneda = '₡';

final _enteros = NumberFormat('#,##0', 'es_CR');
final _conDecimales = NumberFormat('#,##0.00', 'es_CR');

/// "₡1.800" si es entero, "₡1.812,50" si no. Los precios de la calle son
/// enteros y así se leen; los decimales aparecen solo cuando una cantidad
/// fraccionada los produce, y entonces hay que verlos.
String formatoMonto(double monto) {
  final esEntero = (monto - monto.roundToDouble()).abs() < 0.005;
  return '$simboloMoneda${esEntero ? _enteros.format(monto) : _conDecimales.format(monto)}';
}

/// Una cantidad para leer: "1,5" o "2", nunca "2.0".
String formatoCantidad(double cantidad) {
  final esEntero = (cantidad - cantidad.roundToDouble()).abs() < 0.0005;
  return esEntero ? cantidad.round().toString() : NumberFormat('#,##0.###', 'es_CR').format(cantidad);
}

/// Lo que va en un campo de texto para editar un número: sin separador de
/// miles y con punto decimal, que es lo que `double.parse` entiende.
String numeroParaEditar(double valor) {
  final esEntero = (valor - valor.roundToDouble()).abs() < 0.0005;
  return esEntero ? valor.round().toString() : valor.toString();
}

/// Acepta coma o punto como decimal: en un teclado en español sale coma.
double? parsearNumero(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));
