import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import '../../../core/dinero.dart';
import '../../../core/medida.dart';
import '../imagen_producto_service.dart';
import '../producto_model.dart';
import '../producto_notifier.dart';

const _uuid = Uuid();

/// Crear o editar un producto de una tienda. Devuelve el guardado, o nulo.
Future<Producto?> mostrarFormularioProducto(
  BuildContext context, {
  required String tiendaId,
  Producto? producto,
}) {
  return showDialog<Producto>(
    context: context,
    builder: (_) => _ProductoFormDialog(tiendaId: tiendaId, producto: producto),
  );
}

class _ProductoFormDialog extends ConsumerStatefulWidget {
  const _ProductoFormDialog({required this.tiendaId, this.producto});
  final String tiendaId;
  final Producto? producto;

  @override
  ConsumerState<_ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends ConsumerState<_ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.producto?.nombre ?? '');
  late final _precio = TextEditingController(
    text: widget.producto == null ? '' : numeroParaEditar(widget.producto!.precio),
  );
  late final _cantidad = TextEditingController(
    text: widget.producto == null ? '1' : numeroParaEditar(widget.producto!.cantidad),
  );
  late final _notas = TextEditingController(text: widget.producto?.notas ?? '');
  late Medida _medida = widget.producto?.medida ?? Medida.unidad;
  late String? _imagen = widget.producto?.imagen;
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _cantidad.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen({required bool camara}) async {
    final nombre = await ImagenProductoService().elegir(camara: camara);
    if (nombre != null && mounted) setState(() => _imagen = nombre);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final ahora = DateTime.now();
    final notas = _notas.text.trim().isEmpty ? null : _notas.text.trim();
    final notifier = ref.read(productoNotifierProvider.notifier);
    final Producto guardado;
    if (_esEdicion) {
      guardado = widget.producto!.copyWith(
        nombre: _nombre.text.trim(),
        precio: parsearNumero(_precio.text)!,
        cantidad: parsearNumero(_cantidad.text)!,
        medida: _medida,
        imagen: _imagen,
        quitarImagen: _imagen == null,
        notas: notas,
        updatedAt: ahora,
      );
      await notifier.actualizar(guardado);
    } else {
      guardado = Producto(
        id: _uuid.v4(),
        tiendaId: widget.tiendaId,
        nombre: _nombre.text.trim(),
        precio: parsearNumero(_precio.text)!,
        cantidad: parsearNumero(_cantidad.text)!,
        medida: _medida,
        imagen: _imagen,
        notas: notas,
        updatedAt: ahora,
      );
      await notifier.crear(guardado);
    }
    if (mounted) Navigator.of(context).pop(guardado);
  }

  Future<void> _archivar() async {
    setState(() => _guardando = true);
    await ref.read(productoNotifierProvider.notifier).archivar(widget.producto!.id);
    if (mounted) Navigator.of(context).pop();
  }

  String? _validarNumero(String? v, {bool cero = false}) {
    final n = parsearNumero(v ?? '');
    if (n == null) return 'Número inválido';
    if (!cero && n <= 0) return 'Mayor que cero';
    if (cero && n < 0) return 'No puede ser negativo';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final formulario = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ControlDeImagen(
            imagen: _imagen,
            ocupado: _guardando,
            onGaleria: () => _elegirImagen(camara: false),
            onCamara: () => _elegirImagen(camara: true),
            onQuitar: _imagen == null ? null : () => setState(() => _imagen = null),
          ),
          const SizedBox(height: WulfSpacing.unidad),
          TextFormField(
            controller: _nombre,
            autofocus: !_esEdicion,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: WulfSpacing.unidad),
          // Precio y medida en la misma fila: el precio es POR la medida, y
          // verlos juntos es lo que evita anotar ₡1.200 sin saber si es el
          // kilo o el paquete.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _precio,
                  decoration: InputDecoration(labelText: 'Precio ($simboloMoneda)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _validarNumero(v, cero: true),
                ),
              ),
              const SizedBox(width: WulfSpacing.unidad),
              Expanded(
                child: DropdownButtonFormField<Medida>(
                  initialValue: _medida,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Por'),
                  items: [
                    for (final m in Medida.values)
                      DropdownMenuItem(value: m, child: Text(m.nombre, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (m) => setState(() => _medida = m ?? _medida),
                ),
              ),
            ],
          ),
          const SizedBox(height: WulfSpacing.unidad),
          TextFormField(
            controller: _cantidad,
            decoration: InputDecoration(
              labelText: 'Cantidad habitual',
              suffixText: _medida.plural,
              helperText: 'Lo que se suele llevar; se cambia en la lista',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => _validarNumero(v),
          ),
          const SizedBox(height: WulfSpacing.unidad),
          TextFormField(
            controller: _notas,
            decoration: const InputDecoration(labelText: 'Notas'),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );

    return WulfDialogo(
      titulo: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      contenido: formulario,
      acciones: WulfAcciones(
        izquierda: [
          TextButton(
            onPressed: _guardando ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          if (_esEdicion)
            TextButton(onPressed: _guardando ? null : _archivar, child: const Text('Quitar')),
        ],
        derecha: [
          FilledButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}

class _ControlDeImagen extends StatelessWidget {
  const _ControlDeImagen({
    required this.imagen,
    required this.ocupado,
    required this.onGaleria,
    required this.onCamara,
    required this.onQuitar,
  });

  final String? imagen;
  final bool ocupado;
  final VoidCallback onGaleria;
  final VoidCallback onCamara;
  final VoidCallback? onQuitar;

  static const _lado = 72.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _lado,
          height: _lado,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(WulfRadius.pozo),
            child: ImagenProducto(nombre: imagen),
          ),
        ),
        const SizedBox(width: WulfSpacing.gapCelda),
        Expanded(
          child: Wrap(
            spacing: WulfSpacing.unidad,
            children: [
              TextButton.icon(
                onPressed: ocupado ? null : onGaleria,
                icon: const WulfIcono('imagen', descripcion: null, tamano: WulfIconoTamano.chico),
                label: const Text('Galería'),
              ),
              // La cámara en escritorio no existe como tal; el selector la
              // convierte en el mismo diálogo de archivos, así que no estorba.
              if (Platform.isAndroid || Platform.isIOS)
                TextButton(onPressed: ocupado ? null : onCamara, child: const Text('Cámara')),
              if (onQuitar != null) TextButton(onPressed: ocupado ? null : onQuitar, child: const Text('Quitar')),
            ],
          ),
        ),
      ],
    );
  }
}

/// La foto de un producto, o su hueco. Resuelve el nombre contra la carpeta
/// de imágenes; si el archivo no está, muestra el hueco sin quejarse.
class ImagenProducto extends StatelessWidget {
  const ImagenProducto({super.key, required this.nombre});
  final String? nombre;

  @override
  Widget build(BuildContext context) {
    final laca = lacaDe(context);
    final hueco = ColoredBox(
      color: laca.pozoContacto,
      child: const Center(child: WulfIcono('imagen', descripcion: null)),
    );
    if (nombre == null) return hueco;
    return FutureBuilder<File>(
      future: ImagenProductoService().archivoDe(nombre!),
      builder: (context, snap) {
        final archivo = snap.data;
        if (archivo == null || !archivo.existsSync()) return hueco;
        return Image.file(archivo, fit: BoxFit.cover, errorBuilder: (_, _, _) => hueco);
      },
    );
  }
}
