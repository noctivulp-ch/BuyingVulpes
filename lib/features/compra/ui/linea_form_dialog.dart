import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wulf_flutter/wulf_flutter.dart';

import '../../../core/dinero.dart';
import '../compra_en_curso_notifier.dart';
import '../compra_model.dart';

/// Editar una línea de la lista: cantidad, precio de hoy y nota.
Future<void> mostrarFormularioLinea(BuildContext context, LineaCompra linea) {
  return showDialog<void>(context: context, builder: (_) => _LineaFormDialog(linea: linea));
}

class _LineaFormDialog extends ConsumerStatefulWidget {
  const _LineaFormDialog({required this.linea});
  final LineaCompra linea;

  @override
  ConsumerState<_LineaFormDialog> createState() => _LineaFormDialogState();
}

class _LineaFormDialogState extends ConsumerState<_LineaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _cantidad = TextEditingController(text: numeroParaEditar(widget.linea.cantidad));
  late final _precio = TextEditingController(text: numeroParaEditar(widget.linea.precio));
  late final _notas = TextEditingController(text: widget.linea.notas ?? '');

  /// Encendido de fábrica: si el precio de la góndola cambió, lo normal es
  /// querer recordarlo la próxima vez (decisión 0004).
  bool _actualizarProducto = true;
  bool _guardando = false;

  @override
  void dispose() {
    _cantidad.dispose();
    _precio.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final precio = parsearNumero(_precio.text)!;
    await ref
        .read(compraEnCursoProvider.notifier)
        .editarLinea(
          widget.linea.id,
          cantidad: parsearNumero(_cantidad.text),
          precio: precio,
          notas: _notas.text.trim().isEmpty ? null : _notas.text.trim(),
          actualizarProducto: _actualizarProducto && precio != widget.linea.precio,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _quitar() async {
    setState(() => _guardando = true);
    await ref.read(compraEnCursoProvider.notifier).quitarLinea(widget.linea.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final linea = widget.linea;
    final precioCambio = (parsearNumero(_precio.text) ?? linea.precio) != linea.precio;
    return WulfDialogo(
      titulo: Text(linea.productoNombre),
      contenido: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(linea.tiendaNombre, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: WulfSpacing.unidad),
            TextFormField(
              controller: _cantidad,
              autofocus: true,
              decoration: InputDecoration(labelText: 'Cantidad', suffixText: linea.medida.plural),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = parsearNumero(v ?? '');
                return (n == null || n <= 0) ? 'Mayor que cero' : null;
              },
            ),
            const SizedBox(height: WulfSpacing.unidad),
            TextFormField(
              controller: _precio,
              decoration: InputDecoration(
                labelText: 'Precio por ${linea.medida.nombre} ($simboloMoneda)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = parsearNumero(v ?? '');
                return (n == null || n < 0) ? 'Número inválido' : null;
              },
            ),
            if (linea.productoId != null && precioCambio)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _actualizarProducto,
                onChanged: (v) => setState(() => _actualizarProducto = v),
                title: const Text('Guardar este precio en el producto'),
              ),
            const SizedBox(height: WulfSpacing.unidad),
            TextFormField(
              controller: _notas,
              decoration: const InputDecoration(labelText: 'Nota'),
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
          TextButton(onPressed: _guardando ? null : _quitar, child: const Text('Quitar')),
        ],
        derecha: [
          FilledButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}

/// Poner o quitar el presupuesto de la compra en curso.
Future<void> mostrarPresupuesto(BuildContext context, WidgetRef ref, double? actual) async {
  final controlador = TextEditingController(text: actual == null ? '' : numeroParaEditar(actual));
  final resultado = await showDialog<_ResultadoPresupuesto>(
    context: context,
    builder: (dialogContext) => WulfDialogo(
      titulo: const Text('Presupuesto'),
      contenido: TextField(
        controller: controlador,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Cuánto se puede gastar ($simboloMoneda)',
          helperText: 'Vacío para no llevar presupuesto',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      acciones: WulfAcciones(
        izquierda: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        ],
        derecha: [
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              _ResultadoPresupuesto(parsearNumero(controlador.text)),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  controlador.dispose();
  if (resultado == null) return;
  await ref.read(compraEnCursoProvider.notifier).ponerPresupuesto(resultado.valor);
}

/// Envuelto para distinguir "canceló" (nulo) de "lo dejó vacío" (valor nulo).
class _ResultadoPresupuesto {
  const _ResultadoPresupuesto(this.valor);
  final double? valor;
}
