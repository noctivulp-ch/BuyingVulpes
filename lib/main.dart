import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import 'app_shell.dart';
import 'features/configuracion/preferencias_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: BuyingVulpesApp()));
}

class BuyingVulpesApp extends ConsumerWidget {
  const BuyingVulpesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Jade de fábrica y no oro: es otra app de la misma casa y tiene que
    // verse de la familia sin confundirse con VulpTiketing en el mismo
    // teléfono. Desde Configuración se cambia.
    final prefs = ref.watch(preferenciasProvider).valueOrNull ?? const Preferencias();
    final efectos = WulfEfectos(apagados: prefs.efectosApagados);
    return MaterialApp(
      title: 'BuyingVulpes',
      theme: buildWulfTheme(prefs.acento, efectos: efectos),
      darkTheme: buildWulfTheme(prefs.acento, brightness: Brightness.dark, efectos: efectos),
      themeMode: prefs.modoTema.themeMode,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AppShell(),
    );
  }
}
