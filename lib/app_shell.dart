import 'package:flutter/material.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import 'features/compra/ui/compra_screen.dart';
import 'features/historial/ui/historial_screen.dart';

/// Las dos ventanas de la app, y cómo se pasa de una a otra.
///
/// En teléfono una barra abajo; con más ancho, el rail de Wulfenite a la
/// izquierda. Es la única pieza que sabe que existen dos pantallas.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _actual = 0;

  static const _pantallas = [CompraScreen(), HistorialScreen()];

  @override
  Widget build(BuildContext context) {
    final compacto = WulfAncho.de(context).esCompacto;
    final cuerpo = IndexedStack(index: _actual, children: _pantallas);

    if (compacto) {
      return Scaffold(
        body: cuerpo,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _actual,
          onDestinationSelected: (i) => setState(() => _actual = i),
          destinations: const [
            NavigationDestination(
              icon: WulfIcono('lista', descripcion: null),
              label: 'Compra',
            ),
            NavigationDestination(
              icon: WulfIcono('calendario', descripcion: null),
              label: 'Historial',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          WulfRail(
            destinos: const [
              WulfDestino(etiqueta: 'Compra', icono: WulfIcono('lista', descripcion: null)),
              WulfDestino(etiqueta: 'Historial', icono: WulfIcono('calendario', descripcion: null)),
            ],
            seleccionado: _actual,
            onSeleccionar: (i) => setState(() => _actual = i),
          ),
          Expanded(child: cuerpo),
        ],
      ),
    );
  }
}
