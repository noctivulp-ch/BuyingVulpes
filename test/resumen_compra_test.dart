import 'package:buying_vulpes/core/medida.dart';
import 'package:buying_vulpes/features/compra/compra_model.dart';
import 'package:buying_vulpes/features/compra/resumen_compra.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las cuentas de la compra. Son lo que se mira en el pasillo y lo que dice el
/// desglose meses después; si se equivocan, la app miente en silencio con un
/// número que parece correcto.
void main() {
  LineaCompra linea({
    required String tienda,
    required String nombre,
    required double precio,
    double cantidad = 1,
    bool enCarrito = false,
  }) => LineaCompra(
    id: '$tienda-$nombre',
    compraId: 'c',
    tiendaId: tienda,
    tiendaNombre: tienda,
    productoNombre: nombre,
    precio: precio,
    cantidad: cantidad,
    medida: Medida.unidad,
    enCarrito: enCarrito,
    updatedAt: DateTime(2026),
  );

  final lineas = [
    linea(tienda: 'Walmart', nombre: 'Arroz', precio: 1200, cantidad: 2, enCarrito: true),
    linea(tienda: 'Walmart', nombre: 'Leche', precio: 950),
    linea(tienda: 'Feria', nombre: 'Tomate', precio: 800, cantidad: 1.5, enCarrito: true),
  ];

  test('el subtotal es precio por cantidad, y admite fracciones', () {
    expect(lineas[2].subtotal, 1200);
  });

  test('lista, carrito y pendiente', () {
    final r = ResumenCompra(lineas);
    expect(r.totalLista, 2400 + 950 + 1200);
    expect(r.totalCarrito, 2400 + 1200);
    expect(r.totalPendiente, 950);
    expect(r.articulos, 3);
    expect(r.articulosEnCarrito, 2);
  });

  test('el presupuesto se compara con el carrito y con la lista por separado', () {
    // La lista entera excede, el carrito todavía no: hay que avisar de lo
    // primero ANTES de llegar a la caja.
    final r = ResumenCompra(lineas, presupuesto: 4000);
    expect(r.restante, 4000 - 3600);
    expect(r.listaExcedePresupuesto, isTrue);
    expect(r.carritoExcedePresupuesto, isFalse);
    expect(ResumenCompra(lineas).restante, isNull);
  });

  test('agrupa por tienda en orden de aparición, con pendientes y carrito', () {
    final grupos = ResumenCompra(lineas).porTienda;
    expect(grupos.map((g) => g.tiendaNombre), ['Walmart', 'Feria']);
    expect(grupos[0].pendientes.map((l) => l.productoNombre), ['Leche']);
    expect(grupos[0].enCarrito.map((l) => l.productoNombre), ['Arroz']);
    expect(grupos[0].total, 3350);
    expect(grupos[0].totalCarrito, 2400);
  });
}
