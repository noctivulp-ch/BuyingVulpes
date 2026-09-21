import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/dinero.dart';
import '../compra/compra_model.dart';
import 'historial_provider.dart';

/// El desglose de una compra en PDF: una tabla por tienda, lo comprado y lo
/// que quedó sin comprar, totales y presupuesto. Todo lo que hace falta para
/// comparar dos compras seis meses después.
///
/// Solo genera y guarda. Abrirlo o compartirlo es de la pantalla.
class FacturaPdfService {
  static final _fecha = DateFormat("EEEE d 'de' MMMM 'de' y, HH:mm", 'es');
  static final _archivo = DateFormat('yyyy-MM-dd_HHmm');

  /// Las fuentes de fábrica del generador no tienen el ₡: los montos salían
  /// sin moneda. Noto Sans recortada a lo que se escribe, 42 KB entre las dos.
  Future<pw.ThemeData> _tema() async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  /// Carpeta donde quedan los desgloses, dentro de los documentos de la app.
  Future<Directory> carpeta() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'BuyingVulpes', 'compras'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> generar(CompraDetallada detalle) async {
    final bytes = await construir(detalle);
    final cuando = detalle.compra.finalizadaEn ?? detalle.compra.iniciadaEn;
    final archivo = File(p.join((await carpeta()).path, 'compra_${_archivo.format(cuando)}.pdf'));
    await archivo.writeAsBytes(bytes);
    return archivo;
  }

  /// Público para probar el contenido sin tocar el disco.
  Future<List<int>> construir(CompraDetallada detalle) async {
    final compra = detalle.compra;
    final resumen = detalle.resumen;
    final doc = pw.Document(theme: await _tema());
    final cuando = compra.finalizadaEn ?? compra.iniciadaEn;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (contexto) => [
          pw.Text('Compra', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text(_capitalizar(_fecha.format(cuando))),
          pw.SizedBox(height: 4),
          pw.Text(
            '${resumen.articulos} artículo(s) en ${resumen.porTienda.length} tienda(s) · '
            '${resumen.articulosEnCarrito} comprado(s)',
          ),
          if (compra.notas != null && compra.notas!.isNotEmpty) pw.Text('Notas: ${compra.notas}'),
          pw.SizedBox(height: 16),
          for (final grupo in resumen.porTienda) ...[
            pw.Text(grupo.tiendaNombre, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            _tabla(grupo.lineas),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Tienda: ${formatoMonto(grupo.total)} · comprado ${formatoMonto(grupo.totalCarrito)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          pw.Divider(),
          _totales(resumen.totalLista, resumen.totalCarrito, compra.presupuesto),
          pw.SizedBox(height: 24),
          pw.Text(
            'BuyingVulpes',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _tabla(List<LineaCompra> lineas) => pw.TableHelper.fromTextArray(
    headers: const ['', 'Producto', 'Cantidad', 'Precio', 'Subtotal', 'Notas'],
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    cellAlignments: {
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
      4: pw.Alignment.centerRight,
    },
    columnWidths: {
      0: const pw.FixedColumnWidth(18),
      1: const pw.FlexColumnWidth(3),
      5: const pw.FlexColumnWidth(2),
    },
    data: [
      for (final l in lineas)
        [
          l.enCarrito ? '✓' : '–',
          l.productoNombre,
          '${formatoCantidad(l.cantidad)} ${l.medida.abreviatura}',
          formatoMonto(l.precio),
          formatoMonto(l.subtotal),
          l.notas ?? '',
        ],
    ],
  );

  pw.Widget _totales(double lista, double carrito, double? presupuesto) {
    pw.Widget fila(String etiqueta, String valor, {bool fuerte = false}) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(etiqueta),
        pw.Text(valor, style: pw.TextStyle(fontWeight: fuerte ? pw.FontWeight.bold : null)),
      ],
    );
    return pw.Column(
      children: [
        fila('Total de la lista', formatoMonto(lista)),
        fila('Total comprado', formatoMonto(carrito), fuerte: true),
        fila('Quedó sin comprar', formatoMonto(lista - carrito)),
        if (presupuesto != null) ...[
          fila('Presupuesto', formatoMonto(presupuesto)),
          fila(
            carrito <= presupuesto ? 'Sobró del presupuesto' : 'Se pasó del presupuesto',
            formatoMonto((presupuesto - carrito).abs()),
            fuerte: true,
          ),
        ],
      ],
    );
  }

  static String _capitalizar(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
