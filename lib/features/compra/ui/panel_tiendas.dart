import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import '../../../core/dinero.dart';
import '../../producto/producto_model.dart';
import '../../producto/producto_notifier.dart';
import '../../producto/ui/producto_form_dialog.dart';
import '../../tienda/tienda_model.dart';
import '../../tienda/tienda_notifier.dart';
import '../../tienda/ui/tienda_form_dialog.dart';
import '../compra_en_curso_notifier.dart';

/// El panel lateral: las tiendas con sus productos, para elegir qué anotar.
///
/// Abre a pantalla completa —es un cajón, pero cuando está abierto es la
/// ventana— y permite marcar varios productos de varias tiendas antes de
/// agregarlos de una vez. Crear tienda y crear producto viven acá mismo:
/// una lista de compras se arma con lo que hay y con lo que falta.
class PanelTiendas extends ConsumerStatefulWidget {
  const PanelTiendas({super.key});

  @override
  ConsumerState<PanelTiendas> createState() => _PanelTiendasState();
}

class _PanelTiendasState extends ConsumerState<PanelTiendas> {
  /// Productos marcados, con su tienda: es lo que se agrega al cerrar.
  final Map<String, (Producto, Tienda)> _marcados = {};

  /// Tiendas desplegadas. Se abre sola la que se acaba de crear.
  final Set<String> _abiertas = {};

  Future<void> _nuevaTienda() async {
    final tienda = await mostrarFormularioTienda(context);
    if (tienda != null && mounted) setState(() => _abiertas.add(tienda.id));
  }

  Future<void> _nuevoProducto(Tienda tienda) async {
    final producto = await mostrarFormularioProducto(context, tiendaId: tienda.id);
    // Lo recién creado queda marcado: si se creó desde acá, es porque se va a
    // comprar.
    if (producto != null && mounted) setState(() => _marcados[producto.id] = (producto, tienda));
  }

  Future<void> _agregarMarcados() async {
    final elegidos = _marcados.values.toList();
    final agregados = await ref.read(compraEnCursoProvider.notifier).agregarProductos(elegidos);
    if (!mounted) return;
    Navigator.of(context).pop();
    final omitidos = elegidos.length - agregados;
    mostrarAviso(
      context,
      omitidos == 0
          ? 'Se anotaron $agregados producto(s)'
          : 'Se anotaron $agregados; $omitidos ya estaban en la lista',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiendas = ref.watch(tiendasActivasProvider);
    final productos = ref.watch(productosPorTiendaProvider);
    final anotados = ref.watch(compraEnCursoProvider).valueOrNull?.productosAnotados ?? const {};
    final laca = lacaDe(context);

    return Drawer(
      // Todo el ancho: abierto, el panel ES la pantalla.
      width: MediaQuery.sizeOf(context).width,
      backgroundColor: laca.bandeja,
      child: SafeArea(
        child: Column(
          children: [
            _Cabecera(onCerrar: () => Navigator.of(context).pop(), onNuevaTienda: _nuevaTienda),
            Expanded(
              child: tiendas.isEmpty
                  ? _SinTiendas(onCrear: _nuevaTienda)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        WulfSpacing.rim,
                        0,
                        WulfSpacing.rim,
                        WulfSpacing.rim,
                      ),
                      children: [
                        for (final tienda in tiendas) ...[
                          _TiendaExpandible(
                            tienda: tienda,
                            productos: productos[tienda.id] ?? const [],
                            abierta: _abiertas.contains(tienda.id),
                            marcados: _marcados.keys.toSet(),
                            anotados: anotados,
                            onAbrir: () => setState(() {
                              _abiertas.contains(tienda.id)
                                  ? _abiertas.remove(tienda.id)
                                  : _abiertas.add(tienda.id);
                            }),
                            onMarcar: (p, marcado) => setState(() {
                              marcado ? _marcados[p.id] = (p, tienda) : _marcados.remove(p.id);
                            }),
                            onEditarProducto: (p) =>
                                mostrarFormularioProducto(context, tiendaId: tienda.id, producto: p),
                            onNuevoProducto: () => _nuevoProducto(tienda),
                            onEditarTienda: () => mostrarFormularioTienda(context, tienda: tienda),
                          ),
                          const SizedBox(height: WulfSpacing.pared),
                        ],
                      ],
                    ),
            ),
            if (_marcados.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(WulfSpacing.rim),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _agregarMarcados,
                    child: Text('Anotar ${_marcados.length} en la lista'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.onCerrar, required this.onNuevaTienda});
  final VoidCallback onCerrar;
  final VoidCallback onNuevaTienda;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(WulfSpacing.unidad, WulfSpacing.unidad, WulfSpacing.rim, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onCerrar,
            tooltip: 'Volver a la lista',
            icon: const WulfIcono('volver', descripcion: null),
          ),
          Expanded(child: Text('Tiendas', style: Theme.of(context).textTheme.titleLarge)),
          TextButton.icon(
            onPressed: onNuevaTienda,
            icon: const WulfIcono('anadir', descripcion: null, tamano: WulfIconoTamano.chico),
            label: const Text('Tienda'),
          ),
        ],
      ),
    );
  }
}

class _SinTiendas extends StatelessWidget {
  const _SinTiendas({required this.onCrear});
  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WulfSpacing.rim),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Todavía no hay tiendas.', textAlign: TextAlign.center),
            const SizedBox(height: WulfSpacing.unidad),
            const Text(
              'Creá la primera y después sus productos, con precio y medida.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WulfSpacing.gapCelda),
            FilledButton(onPressed: onCrear, child: const Text('Crear tienda')),
          ],
        ),
      ),
    );
  }
}

class _TiendaExpandible extends StatelessWidget {
  const _TiendaExpandible({
    required this.tienda,
    required this.productos,
    required this.abierta,
    required this.marcados,
    required this.anotados,
    required this.onAbrir,
    required this.onMarcar,
    required this.onEditarProducto,
    required this.onNuevoProducto,
    required this.onEditarTienda,
  });

  final Tienda tienda;
  final List<Producto> productos;
  final bool abierta;
  final Set<String> marcados;
  final Set<String> anotados;
  final VoidCallback onAbrir;
  final void Function(Producto, bool) onMarcar;
  final ValueChanged<Producto> onEditarProducto;
  final VoidCallback onNuevoProducto;
  final VoidCallback onEditarTienda;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final enEsta = productos.where((p) => marcados.contains(p.id)).length;
    return WulfPozo(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: onAbrir,
            onLongPress: onEditarTienda,
            leading: WulfIcono(abierta ? 'chevron-abajo' : 'chevron-derecha', descripcion: null),
            title: Text(tienda.nombre, style: tema.textTheme.titleMedium),
            subtitle: Text(
              enEsta > 0
                  ? '${productos.length} producto(s) · $enEsta marcado(s)'
                  : '${productos.length} producto(s)',
            ),
            trailing: IconButton(
              tooltip: 'Nuevo producto en ${tienda.nombre}',
              onPressed: onNuevoProducto,
              icon: const WulfIcono('anadir-circulo', descripcion: null),
            ),
          ),
          if (abierta) ...[
            if (productos.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(WulfSpacing.paddingCelda, 0, WulfSpacing.paddingCelda, WulfSpacing.paddingCelda),
                child: Text('Sin productos todavía. El botón de la derecha crea el primero.'),
              ),
            for (final p in productos)
              CheckboxListTile(
                value: marcados.contains(p.id),
                onChanged: (v) => onMarcar(p, v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(p.nombre),
                subtitle: Text(
                  '${formatoMonto(p.precio)} / ${p.medida.abreviatura}'
                  '${anotados.contains(p.id) ? ' · ya en la lista' : ''}',
                ),
                // Editar es el gesto secundario: el toque marca, que es lo
                // que se hace veinte veces por lista.
                secondary: IconButton(
                  tooltip: 'Editar ${p.nombre}',
                  onPressed: () => onEditarProducto(p),
                  icon: const WulfIcono('editar', descripcion: null, tamano: WulfIconoTamano.chico),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
