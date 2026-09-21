import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import 'app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: BuyingVulpesApp()));
}

class BuyingVulpesApp extends StatelessWidget {
  const BuyingVulpesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuyingVulpes',
      // Jade y no oro: es otra app de la misma casa y tiene que verse de la
      // familia sin confundirse con VulpTiketing en el mismo teléfono.
      theme: buildWulfTheme(WulfAcento.jade),
      darkTheme: buildWulfTheme(WulfAcento.jade, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AppShell(),
    );
  }
}
