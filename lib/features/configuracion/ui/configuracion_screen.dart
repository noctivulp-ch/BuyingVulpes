import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import '../preferencias_notifier.dart';

/// Cómo se ve la app: tema, acento y los efectos que se pueden apagar.
/// Cada bloque es un pozo con su título; sin diálogos, se elige en el sitio.
class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferenciasProvider).valueOrNull ?? const Preferencias();
    final notifier = ref.read(preferenciasProvider.notifier);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(WulfSpacing.rim),
        children: [
          _Bloque(
            titulo: 'Tema',
            hijo: SegmentedButton<ModoTema>(
              segments: const [
                ButtonSegment(value: ModoTema.claro, label: Text('Claro')),
                ButtonSegment(value: ModoTema.oscuro, label: Text('Oscuro')),
                ButtonSegment(value: ModoTema.sistema, label: Text('Sistema')),
              ],
              selected: {prefs.modoTema},
              onSelectionChanged: (s) => notifier.cambiarModoTema(s.first),
            ),
          ),
          const SizedBox(height: WulfSpacing.pared),
          _Bloque(
            titulo: 'Acento',
            descripcion: 'El metal de los botones, el foco y las marcas. Peltre es el más neutro.',
            hijo: SegmentedButton<WulfAcento>(
              segments: const [
                ButtonSegment(value: WulfAcento.oro, label: Text('Oro')),
                ButtonSegment(value: WulfAcento.jade, label: Text('Jade')),
                ButtonSegment(value: WulfAcento.peltre, label: Text('Peltre')),
              ],
              selected: {prefs.acento},
              onSelectionChanged: (s) => notifier.cambiarAcento(s.first),
            ),
          ),
          const SizedBox(height: WulfSpacing.pared),
          _Bloque(
            titulo: 'Optimización',
            descripcion: 'Adornos que cuestan pintar. Apagarlos no cambia lo que la app hace.',
            hijo: Column(
              children: [
                for (final efecto in WulfEfectoPesado.values)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: !prefs.efectosApagados.contains(efecto),
                    onChanged: (encendido) => notifier.alternarEfecto(efecto, apagado: !encendido),
                    title: Text(efecto.etiqueta),
                    subtitle: Text(efecto.explicacion, style: tema.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.titulo, required this.hijo, this.descripcion});
  final String titulo;
  final String? descripcion;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return WulfPozo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: tema.textTheme.titleMedium),
          if (descripcion != null) ...[
            const SizedBox(height: 2),
            Text(descripcion!, style: tema.textTheme.bodySmall),
          ],
          const SizedBox(height: WulfSpacing.unidad),
          hijo,
        ],
      ),
    );
  }
}
