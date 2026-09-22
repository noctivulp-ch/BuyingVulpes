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
///
/// Sin scroll de pantalla: el calendario llena lo que le toca y la lista de
/// compras se desplaza sola en su parte. De pie, calendario arriba y lista
/// abajo; con ancho, calendario a la izquierda y lista a la derecha.
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
          final calendario = CalendarioMes(
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
          );
          final compras = _ListaDeCompras(
            titulo: _dia == null ? 'Compras del mes' : 'Compras del ${DateFormat('d MMMM', 'es').format(_dia!)}',
            compras: delDia,
          );

          final ancho = WulfAncho.de(context);
          return Padding(
            padding: const EdgeInsets.all(WulfSpacing.rim),
            child: ancho.esCompacto
                ? Column(
                    children: [
                      // Más alto para el calendario que para la lista: es lo
                      // que se toca; la lista se desplaza por su cuenta.
                      Expanded(flex: 5, child: calendario),
                      const SizedBox(height: WulfSpacing.gapCelda),
                      Expanded(flex: 4, child: compras),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: calendario),
                      const SizedBox(width: WulfSpacing.gapCelda),
                      Expanded(child: compras),
                    ],
                  ),
          );
        },
      ),
    );
  }

  static bool _mismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ListaDeCompras extends StatelessWidget {
  const _ListaDeCompras({required this.titulo, required this.compras});
  final String titulo;
  final List<Compra> compras;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo, style: tema.textTheme.titleMedium),
        const SizedBox(height: WulfSpacing.unidad),
        Expanded(
          child: compras.isEmpty
              ? const Center(child: Text('Nada por acá.'))
              : ListView.separated(
                  itemCount: compras.length,
                  separatorBuilder: (_, _) => const SizedBox(height: WulfSpacing.unidad),
                  itemBuilder: (_, i) => _FilaCompra(compra: compras[i]),
                ),
        ),
      ],
    );
  }
}

class _FilaCompra extends ConsumerWidget {
  const _FilaCompra({required this.compra});
  final Compra compra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(compraDetalladaProvider(ClaveDeCompra(compra.id, Mes.de(compra.finalizadaEn!)))).valueOrNull;
    final resumen = detalle?.resumen;
    final tema = Theme.of(context);
    return WulfPozo(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DetalleCompraScreen(clave: ClaveDeCompra(compra.id, Mes.de(compra.finalizadaEn!)))),
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
