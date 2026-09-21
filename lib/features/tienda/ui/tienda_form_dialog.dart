import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import '../tienda_model.dart';
import '../tienda_notifier.dart';

const _uuid = Uuid();

/// Crear o renombrar una tienda. Devuelve la tienda guardada, o nulo.
Future<Tienda?> mostrarFormularioTienda(BuildContext context, {Tienda? tienda}) {
  return showDialog<Tienda>(context: context, builder: (_) => _TiendaFormDialog(tienda: tienda));
}

class _TiendaFormDialog extends ConsumerStatefulWidget {
  const _TiendaFormDialog({this.tienda});
  final Tienda? tienda;

  @override
  ConsumerState<_TiendaFormDialog> createState() => _TiendaFormDialogState();
}

class _TiendaFormDialogState extends ConsumerState<_TiendaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.tienda?.nombre ?? '');
  late final _notas = TextEditingController(text: widget.tienda?.notas ?? '');
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final ahora = DateTime.now();
    final notas = _notas.text.trim().isEmpty ? null : _notas.text.trim();
    final notifier = ref.read(tiendaNotifierProvider.notifier);
    final Tienda guardada;
    if (widget.tienda == null) {
      guardada = Tienda(id: _uuid.v4(), nombre: _nombre.text.trim(), notas: notas, updatedAt: ahora);
      await notifier.crear(guardada);
    } else {
      guardada = widget.tienda!.copyWith(nombre: _nombre.text.trim(), notas: notas, updatedAt: ahora);
      await notifier.actualizar(guardada);
    }
    if (mounted) Navigator.of(context).pop(guardada);
  }

  @override
  Widget build(BuildContext context) {
    return WulfDialogo(
      titulo: Text(widget.tienda == null ? 'Nueva tienda' : 'Editar tienda'),
      contenido: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombre,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: WulfSpacing.unidad),
            TextFormField(
              controller: _notas,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      acciones: WulfAcciones(
        izquierda: [
          TextButton(
            onPressed: _guardando ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
        derecha: [
          FilledButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
