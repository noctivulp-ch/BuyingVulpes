import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import '../../../core/dinero.dart';
import '../../historial/factura_pdf_service.dart';
import '../../historial/historial_provider.dart';
import '../../historial/ui/detalle_compra_screen.dart';
import '../compra_en_curso_notifier.dart';
import '../compra_model.dart';
import '../resumen_compra.dart';
import 'linea_form_dialog.dart';
import 'panel_tiendas.dart';

/// La lista que se está armando: lo pendiente arriba por tienda, el carrito
/// abajo, y las cuentas al pie. El panel de tiendas se abre desde la
/// izquierda y ocupa toda la pantalla.
class CompraScreen extends ConsumerWidget {
  const CompraScreen({super.key});

  Future<void> _finalizar(BuildContext context, WidgetRef ref, ResumenCompra resumen) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => WulfDialogo(
        titulo: const Text('¿Finalizar la compra?'),
        contenido: Text(
          resumen.articulosEnCarrito == resumen.articulos
              ? 'Se guarda en el historial con ${formatoMonto(resumen.totalCarrito)} comprados.'
              : 'Hay ${resumen.articulos - resumen.articulosEnCarrito} producto(s) sin marcar; '
                    'quedan en el desglose como no comprados. '
                    'Comprado: ${formatoMonto(resumen.totalCarrito)}.',
        ),
        acciones: WulfAcciones(
          izquierda: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Seguir')),
          ],
          derecha: [
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Finalizar')),
          ],
        ),
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final cerrada = await ref.read(compraEnCursoProvider.notifier).finalizar();
    if (cerrada == null || !context.mounted) return;
    // El PDF se genera al finalizar, no cuando se pide: así el desglose existe
    // desde el primer momento y abrirlo después es abrir un archivo.
    final detalle = await ref.read(compraDetalladaProvider(cerrada.id).future);
    if (detalle != null) await FacturaPdfService().generar(detalle);
    if (!context.mounted) return;
    mostrarAviso(context, 'Compra guardada en el historial');
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DetalleCompraScreen(compraId: cerrada.id)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(compraEnCursoProvider);
    final laca = lacaDe(context);

    return Scaffold(
      drawer: const PanelTiendas(),
      appBar: AppBar(
        title: const Text('Compra'),
        actions: [
          IconButton(
            tooltip: 'Presupuesto',
            onPressed: () => mostrarPresupuesto(context, ref, estado.valueOrNull?.compra?.presupuesto),
            icon: const WulfIcono('etiqueta', descripcion: null),
          ),
        ],
      ),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WulfFalla(
          mensaje: 'No se pudo leer la lista.',
          error: e,
          onReintentar: () => ref.invalidate(compraEnCursoProvider),
        ),
        data: (datos) => datos.vacia
            ? const _ListaVacia()
            : _Lineas(resumen: datos.resumen),
      ),
      bottomNavigationBar: estado.valueOrNull == null || estado.valueOrNull!.vacia
          ? null
          : _PieDeCuentas(
              resumen: estado.value!.resumen,
              laca: laca,
              onFinalizar: () => _finalizar(context, ref, estado.value!.resumen),
            ),
    );
  }
}

class _ListaVacia extends StatelessWidget {
  const _ListaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WulfSpacing.rim),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('La lista está vacía.', textAlign: TextAlign.center),
            const SizedBox(height: WulfSpacing.unidad),
            const Text('Abrí las tiendas y marcá lo que hace falta.', textAlign: TextAlign.center),
            const SizedBox(height: WulfSpacing.gapCelda),
            FilledButton.icon(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const WulfIcono('menu', descripcion: null, tamano: WulfIconoTamano.chico),
              label: const Text('Tiendas'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pendientes por tienda arriba, carrito abajo. Marcar mueve la línea de una
/// sección a la otra: es la casilla de la que hablaba el pedido.
class _Lineas extends ConsumerWidget {
  const _Lineas({required this.resumen});
  final ResumenCompra resumen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final grupos = resumen.porTienda;
    final hayPendientes = grupos.any((g) => g.pendientes.isNotEmpty);
    final hayCarrito = grupos.any((g) => g.enCarrito.isNotEmpty);

    void marcar(LineaCompra l, bool v) =>
        ref.read(compraEnCursoProvider.notifier).marcar(l.id, enCarrito: v);

    return ListView(
      padding: const EdgeInsets.all(WulfSpacing.rim),
      children: [
        if (hayPendientes) ...[
          Text('Por comprar', style: tema.textTheme.titleMedium),
          const SizedBox(height: WulfSpacing.unidad),
          for (final g in grupos)
            if (g.pendientes.isNotEmpty) ...[
              _GrupoTienda(nombre: g.tiendaNombre, lineas: g.pendientes, onMarcar: marcar),
              const SizedBox(height: WulfSpacing.pared),
            ],
        ],
        if (hayCarrito) ...[
          const SizedBox(height: WulfSpacing.unidad),
          Text('En el carrito', style: tema.textTheme.titleMedium),
          const SizedBox(height: WulfSpacing.unidad),
          for (final g in grupos)
            if (g.enCarrito.isNotEmpty) ...[
              _GrupoTienda(nombre: g.tiendaNombre, lineas: g.enCarrito, onMarcar: marcar),
              const SizedBox(height: WulfSpacing.pared),
            ],
        ],
      ],
    );
  }
}

class _GrupoTienda extends StatelessWidget {
  const _GrupoTienda({required this.nombre, required this.lineas, required this.onMarcar});
  final String nombre;
  final List<LineaCompra> lineas;
  final void Function(LineaCompra, bool) onMarcar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return WulfPozo(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(WulfSpacing.paddingCelda, WulfSpacing.pared, WulfSpacing.paddingCelda, 0),
            child: Text(nombre, style: tema.textTheme.labelLarge),
          ),
          for (final l in lineas)
            CheckboxListTile(
              value: l.enCarrito,
              onChanged: (v) => onMarcar(l, v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l.productoNombre),
              subtitle: Text(
                '${formatoCantidad(l.cantidad)} ${l.medida.abreviatura} × ${formatoMonto(l.precio)}'
                '${l.notas == null ? '' : ' · ${l.notas}'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              secondary: TextButton(
                onPressed: () => mostrarFormularioLinea(context, l),
                child: Text(formatoMonto(l.subtotal)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Las tres cifras que se miran en el pasillo: lo anotado, lo que ya va en el
/// carrito, y cuánto queda del presupuesto. Y el botón de cerrar.
class _PieDeCuentas extends StatelessWidget {
  const _PieDeCuentas({required this.resumen, required this.laca, required this.onFinalizar});
  final ResumenCompra resumen;
  final WulfLaca laca;
  final VoidCallback onFinalizar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final restante = resumen.restante;
    final alerta = tema.colorScheme.error;

    Widget cifra(String etiqueta, String valor, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: tema.textTheme.bodySmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(WulfSpacing.rim, 0, WulfSpacing.rim, WulfSpacing.pared),
        child: WulfPozo(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  cifra('Lista', formatoMonto(resumen.totalLista),
                      color: resumen.listaExcedePresupuesto ? alerta : null),
                  cifra('Carrito', formatoMonto(resumen.totalCarrito),
                      color: resumen.carritoExcedePresupuesto ? alerta : null),
                  if (restante != null)
                    cifra(
                      restante >= 0 ? 'Queda' : 'Pasado',
                      formatoMonto(restante.abs()),
                      color: restante < 0 ? alerta : null,
                    )
                  else
                    cifra('Presupuesto', '—'),
                ],
              ),
              const SizedBox(height: WulfSpacing.pared),
              FilledButton(
                onPressed: onFinalizar,
                child: Text('Finalizar compra · ${resumen.articulosEnCarrito}/${resumen.articulos}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
