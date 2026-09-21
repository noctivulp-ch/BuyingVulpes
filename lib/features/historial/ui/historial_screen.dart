import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import '../../../core/dinero.dart';
import '../../compra/compra_model.dart';
import '../historial_provider.dart';
import 'calendario_mes.dart';
import 'detalle_compra_screen.dart';

/// Las compras finalizadas, por mes. Tocar un día lista las de ese día;
/// tocar una abre su desglose.
class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  late DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _dia;

  @override
  Widget build(BuildContext context) {
    final compras = ref.watch(comprasDelMesProvider(Mes(_mes.year, _mes.month)));
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: compras.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WulfFalla(
          mensaje: 'No se pudo leer el historial.',
          error: e,
          onReintentar: () => ref.invalidate(comprasDelMesProvider),
        ),
        data: (lista) {
          final diasConCompras = {for (final c in lista) c.finalizadaEn!.day};
          final delDia = _dia == null
              ? lista
              : [for (final c in lista) if (_mismoDia(c.finalizadaEn!, _dia!)) c];
          return ListView(
            padding: const EdgeInsets.all(WulfSpacing.rim),
            children: [
              CalendarioMes(
                mes: _mes,
                hoy: DateTime.now(),
                diasConCompras: diasConCompras,
                seleccionado: _dia,
                onMes: (m) => setState(() {
                  _mes = m;
                  _dia = null;
                }),
                // Tocar el día elegido lo suelta: vuelve a verse el mes entero.
                onDia: (d) => setState(() => _dia = (_dia != null && _mismoDia(_dia!, d)) ? null : d),
              ),
              const SizedBox(height: WulfSpacing.gapCelda),
              Text(
                _dia == null ? 'Compras del mes' : 'Compras del ${DateFormat('d MMMM', 'es').format(_dia!)}',
                style: tema.textTheme.titleMedium,
              ),
              const SizedBox(height: WulfSpacing.unidad),
              if (delDia.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: WulfSpacing.gapCelda),
                  child: Text('Nada por acá.', textAlign: TextAlign.center),
                ),
              for (final c in delDia) ...[
                _FilaCompra(compra: c),
                const SizedBox(height: WulfSpacing.unidad),
              ],
            ],
          );
        },
      ),
    );
  }

  static bool _mismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _FilaCompra extends ConsumerWidget {
  const _FilaCompra({required this.compra});
  final Compra compra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(compraDetalladaProvider(compra.id)).valueOrNull;
    final resumen = detalle?.resumen;
    final tema = Theme.of(context);
    return WulfPozo(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DetalleCompraScreen(compraId: compra.id)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat("EEEE d, HH:mm", 'es').format(compra.finalizadaEn!), style: tema.textTheme.titleSmall),
                if (resumen != null)
                  Text(
                    '${resumen.articulosEnCarrito} de ${resumen.articulos} comprados · '
                    '${resumen.porTienda.map((g) => g.tiendaNombre).join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (resumen != null)
            Text(
              formatoMonto(resumen.totalCarrito),
              style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
