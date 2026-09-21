import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import '../../../core/dinero.dart';
import '../../compra/compra_model.dart';
import '../../compra/resumen_compra.dart';
import '../factura_pdf_service.dart';
import '../historial_provider.dart';

/// Una compra cerrada: por tienda, con lo comprado y lo que no, y el PDF.
class DetalleCompraScreen extends ConsumerWidget {
  const DetalleCompraScreen({super.key, required this.compraId});
  final String compraId;

  Future<void> _abrirPdf(BuildContext context, CompraDetallada detalle) async {
    final archivo = await FacturaPdfService().generar(detalle);
    final resultado = await OpenFilex.open(archivo.path);
    if (!context.mounted) return;
    mostrarAviso(
      context,
      resultado.type == ResultType.done ? 'PDF: ${archivo.path}' : 'Guardado en ${archivo.path}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(compraDetalladaProvider(compraId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra'),
        actions: [
          if (detalle.valueOrNull != null)
            IconButton(
              tooltip: 'Desglose en PDF',
              onPressed: () => _abrirPdf(context, detalle.value!),
              icon: const WulfIcono('archivo', descripcion: null),
            ),
        ],
      ),
      body: detalle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WulfFalla(mensaje: 'No se pudo leer la compra.', error: e),
        data: (d) => d == null ? const Center(child: Text('Esta compra ya no existe.')) : _Cuerpo(d),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo(this.detalle);
  final CompraDetallada detalle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final compra = detalle.compra;
    final resumen = detalle.resumen;
    final cuando = compra.finalizadaEn ?? compra.iniciadaEn;

    return ListView(
      padding: const EdgeInsets.all(WulfSpacing.rim),
      children: [
        Text(DateFormat("EEEE d 'de' MMMM 'de' y, HH:mm", 'es').format(cuando), style: tema.textTheme.titleMedium),
        const SizedBox(height: WulfSpacing.gapCelda),
        _Totales(resumen: resumen, presupuesto: compra.presupuesto),
        const SizedBox(height: WulfSpacing.gapCelda),
        for (final g in resumen.porTienda) ...[
          _Grupo(grupo: g),
          const SizedBox(height: WulfSpacing.pared),
        ],
      ],
    );
  }
}

class _Totales extends StatelessWidget {
  const _Totales({required this.resumen, required this.presupuesto});
  final ResumenCompra resumen;
  final double? presupuesto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Widget fila(String e, String v, {bool fuerte = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(e),
          Text(v, style: fuerte ? tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) : null),
        ],
      ),
    );
    return WulfPozo(
      child: Column(
        children: [
          fila('Comprado', formatoMonto(resumen.totalCarrito), fuerte: true),
          fila('Anotado', formatoMonto(resumen.totalLista)),
          fila('Sin comprar', formatoMonto(resumen.totalPendiente)),
          if (presupuesto != null) ...[
            fila('Presupuesto', formatoMonto(presupuesto!)),
            fila(
              resumen.totalCarrito <= presupuesto! ? 'Sobró' : 'Se pasó',
              formatoMonto((presupuesto! - resumen.totalCarrito).abs()),
              fuerte: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.grupo});
  final GrupoPorTienda grupo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final laca = lacaDe(context);
    return WulfPozo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(grupo.tiendaNombre, style: tema.textTheme.titleSmall)),
              Text(formatoMonto(grupo.totalCarrito), style: tema.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: WulfSpacing.unidad),
          for (final LineaCompra l in grupo.lineas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  WulfIcono(
                    l.enCarrito ? 'correcto' : 'quitar',
                    descripcion: l.enCarrito ? 'comprado' : 'no comprado',
                    tamano: WulfIconoTamano.chico,
                    color: l.enCarrito ? tema.colorScheme.primary : laca.textoAtenuadoEnBandeja,
                  ),
                  const SizedBox(width: WulfSpacing.unidad),
                  Expanded(
                    child: Text(
                      '${l.productoNombre} · ${formatoCantidad(l.cantidad)} ${l.medida.abreviatura}'
                      '${l.notas == null ? '' : ' · ${l.notas}'}',
                      style: l.enCarrito ? null : TextStyle(color: laca.textoAtenuadoEnBandeja),
                    ),
                  ),
                  Text(formatoMonto(l.subtotal)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
