import 'package:buying_vulpes/app_shell.dart';
import 'package:buying_vulpes/core/db/app_database.dart';
import 'package:buying_vulpes/core/db/db_providers.dart';
import 'package:buying_vulpes/features/compra/compra_model.dart';
import 'package:buying_vulpes/features/historial/factura_pdf_service.dart';
import 'package:buying_vulpes/features/historial/historial_provider.dart';
import 'package:buying_vulpes/core/medida.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

/// Que la app abra vacía y se pueda empezar desde cero: sin tiendas, sin
/// compra, y que el camino a crear la primera tienda esté a la vista. Es el
/// primer minuto de quien la instala.
/// Unos cuadros y ya, en vez de `pumpAndSettle`: hay indicadores de carga que
/// animan sin fin y `settle` se queda esperándolos diez minutos.
Future<void> asentar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    // Tiempo REAL entre cuadros: la base contesta en otro isolate y `pump`
    // no la espera.
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Toda prueba de pantalla corre dentro de `runAsync`: la base es SQLite de
/// verdad en otro isolate, y bajo el reloj falso de `testWidgets` esa espera
/// no termina nunca — la prueba se colgaba cuatro minutos hasta que el
/// corredor la mataba.
void pruebaDePantalla(String nombre, Future<void> Function(WidgetTester) cuerpo) {
  testWidgets(nombre, (tester) => tester.runAsync(() => cuerpo(tester)));
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('es');
  });

  Future<ProviderContainer> montar(WidgetTester tester, {Size tamano = const Size(412, 915)}) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await AppDatabase.crearEsquema(db);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWith((ref) async => db)]);
    addTearDown(() async {
      container.dispose();
      // Que terminen las consultas en vuelo antes de cerrar: cerrar con una
      // pendiente lanza "already been closed" después de la prueba.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildWulfTheme(WulfAcento.jade),
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const AppShell(),
        ),
      ),
    );
    await asentar(tester);
    return container;
  }

  pruebaDePantalla('abre con la lista vacía y el panel de tiendas ocupa toda la pantalla', (tester) async {
    await montar(tester);
    expect(find.text('La lista está vacía.'), findsOneWidget);

    await tester.tap(find.text('Tiendas'));
    await asentar(tester);

    expect(find.text('Todavía no hay tiendas.'), findsOneWidget);
    final drawer = tester.getRect(find.byType(Drawer));
    expect(drawer.width, 412, reason: 'abierto, el panel ES la pantalla');
  });

  pruebaDePantalla('crear la primera tienda desde el panel', (tester) async {
    await montar(tester);
    await tester.tap(find.text('Tiendas'));
    await asentar(tester);
    await tester.tap(find.text('Crear tienda'));
    await asentar(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Walmart');
    await tester.tap(find.text('Guardar'));
    await asentar(tester);

    expect(find.text('Walmart'), findsOneWidget);
    expect(find.text('0 producto(s)'), findsOneWidget);
  });

  pruebaDePantalla('con ancho de tablet aparece el rail en vez de la barra de abajo', (tester) async {
    await montar(tester, tamano: const Size(900, 700));
    expect(find.byType(WulfRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  test('el PDF se construye con el ₡ y las dos secciones', () async {
    final compra = Compra(
      id: 'c',
      iniciadaEn: DateTime(2026, 9, 21, 10),
      finalizadaEn: DateTime(2026, 9, 21, 11),
      presupuesto: 5000,
      updatedAt: DateTime(2026, 9, 21, 11),
    );
    final lineas = [
      LineaCompra(
        id: 'l1', compraId: 'c', tiendaId: 'w', tiendaNombre: 'Walmart', productoNombre: 'Arroz',
        precio: 1200, cantidad: 2, medida: Medida.kilogramo, enCarrito: true, updatedAt: DateTime(2026),
      ),
      LineaCompra(
        id: 'l2', compraId: 'c', tiendaId: 'f', tiendaNombre: 'Feria', productoNombre: 'Tomate',
        precio: 800, cantidad: 1.5, medida: Medida.kilogramo, updatedAt: DateTime(2026),
      ),
    ];
    final bytes = await FacturaPdfService().construir(CompraDetallada(compra: compra, lineas: lineas));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000), reason: 'lleva las fuentes incrustadas');
  });
}
