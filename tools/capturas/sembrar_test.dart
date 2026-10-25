// Siembra la base de demostración de las capturas del README. No es una
// prueba: corre con `flutter test` solo para poder usar el esquema y los DAO
// de la app en vez de copiarlos. La lanza tools/capturas/capturas.sh.
//
// Tiendas y productos inventados: el repo es público y no lleva compras de
// nadie.
import 'dart:io';

import 'package:buying_vulpes/core/db/app_database.dart';
import 'package:buying_vulpes/core/medida.dart';
import 'package:buying_vulpes/features/compra/compra_dao.dart';
import 'package:buying_vulpes/features/compra/compra_model.dart';
import 'package:buying_vulpes/features/compra/libro_compras.dart';
import 'package:buying_vulpes/features/producto/producto_dao.dart';
import 'package:buying_vulpes/features/producto/producto_model.dart';
import 'package:buying_vulpes/features/tienda/tienda_dao.dart';
import 'package:buying_vulpes/features/tienda/tienda_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('sembrar la base de demostración', () async {
    final directorio = Platform.environment['CAPTURAS_BASE']!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await openDatabase(
      p.join(directorio, 'buying_vulpes.db'),
      version: AppDatabase.version,
      onCreate: (db, _) => AppDatabase.crearEsquema(db),
    );
    await LibroComprasService(directorio: directorio).adjuntarAbierto(db);

    final ahora = DateTime.now();
    const tiendas = {'t-mercado': 'Mercado central', 't-super': 'Supermercado', 't-panaderia': 'Panadería'};
    for (final t in tiendas.entries) {
      await TiendaDao(db).insertar(Tienda(id: t.key, nombre: t.value, updatedAt: ahora));
    }

    // (tienda, nombre, precio, cantidad, medida, cantidad en la lista, ya en el carrito)
    const productos = [
      ('t-mercado', 'Tomate', 1450.0, 1.0, Medida.kilogramo, 1.5, true),
      ('t-mercado', 'Aguacate', 600.0, 1.0, Medida.unidad, 3.0, true),
      ('t-mercado', 'Cebolla', 1100.0, 1.0, Medida.kilogramo, 1.0, false),
      ('t-mercado', 'Huevos', 2900.0, 1.0, Medida.docena, 1.0, false),
      ('t-super', 'Arroz', 1850.0, 2.0, Medida.kilogramo, 1.0, true),
      ('t-super', 'Frijoles negros', 1300.0, 900.0, Medida.gramo, 2.0, false),
      ('t-super', 'Leche', 1050.0, 1.0, Medida.litro, 4.0, false),
      ('t-super', 'Café molido', 3200.0, 500.0, Medida.gramo, 1.0, true),
      ('t-panaderia', 'Pan baguette', 900.0, 1.0, Medida.unidad, 2.0, false),
      ('t-panaderia', 'Galletas de avena', 1600.0, 1.0, Medida.paquete, 1.0, false),
    ];
    final compra = Compra(id: 'c-demo', iniciadaEn: ahora, updatedAt: ahora, presupuesto: 30000);
    await CompraDao(db).insertarCompra(compra);
    for (var i = 0; i < productos.length; i++) {
      final (tienda, nombre, precio, cantidad, medida, enLista, enCarrito) = productos[i];
      await ProductoDao(db).insertar(Producto(
        id: 'p$i',
        tiendaId: tienda,
        nombre: nombre,
        precio: precio,
        cantidad: cantidad,
        medida: medida,
        updatedAt: ahora,
      ));
      await CompraDao(db).insertarLinea(LineaCompra(
        id: 'l$i',
        compraId: compra.id,
        productoId: 'p$i',
        tiendaId: tienda,
        tiendaNombre: tiendas[tienda]!,
        productoNombre: nombre,
        precio: precio,
        cantidad: enLista,
        medida: medida,
        enCarrito: enCarrito,
        updatedAt: ahora,
      ));
    }
    await LibroComprasService(directorio: directorio).desadjuntar(db);
    await db.close();
  });
}
