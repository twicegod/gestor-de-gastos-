import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';
import '../models/category.dart';

class PdfService {
  static Future<void> exportReport({
    required List<Expense> expenses,
    required List<Category> categories,
    required DateTime month,
  }) async {
    final fmt = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(month);
    final doc = pw.Document();

    // Agrupar por categoría
    final Map<String, double> byCategory = {};
    for (final e in expenses) {
      if (!e.isIncome) {
        byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
      }
    }
    final totalGastos = byCategory.values.fold(0.0, (s, v) => s + v);
    final totalIngresos = expenses.where((e) => e.isIncome).fold(0.0, (s, e) => s + e.amount);
    final balance = totalIngresos - totalGastos;

    Category? catById(String id) {
      try {
        return categories.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    final sortedEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Encabezado
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1565C0'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Gestor de Gastos',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Informe de $monthLabel',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 13)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Resumen 3 métricas
          pw.Row(
            children: [
              _metricBox('Ingresos', fmt.format(totalIngresos), PdfColor.fromHex('#2E7D32')),
              pw.SizedBox(width: 8),
              _metricBox('Gastos', fmt.format(totalGastos), PdfColor.fromHex('#C62828')),
              pw.SizedBox(width: 8),
              _metricBox('Balance', fmt.format(balance),
                  balance >= 0 ? PdfColor.fromHex('#1565C0') : PdfColor.fromHex('#C62828')),
            ],
          ),
          pw.SizedBox(height: 20),

          // Tabla por categoría
          if (sortedEntries.isNotEmpty) ...[
            pw.Text('Gastos por categoría',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _cell('Categoría', bold: true),
                    _cell('Monto', bold: true, align: pw.TextAlign.right),
                    _cell('%', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                ...sortedEntries.map((entry) {
                  final cat = catById(entry.key);
                  final pct = totalGastos > 0 ? entry.value / totalGastos * 100 : 0.0;
                  return pw.TableRow(children: [
                    _cell(cat?.name ?? 'Otros'),
                    _cell(fmt.format(entry.value), align: pw.TextAlign.right),
                    _cell('${pct.toStringAsFixed(1)}%', align: pw.TextAlign.right),
                  ]);
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('TOTAL', bold: true),
                    _cell(fmt.format(totalGastos), bold: true, align: pw.TextAlign.right),
                    _cell('100%', bold: true, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Detalle de transacciones
          pw.Text('Detalle de transacciones',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _cell('Fecha', bold: true),
                  _cell('Descripción', bold: true),
                  _cell('Categoría', bold: true),
                  _cell('Monto', bold: true, align: pw.TextAlign.right),
                ],
              ),
              ...expenses.map((e) {
                final cat = catById(e.categoryId);
                final color = e.isIncome ? PdfColor.fromHex('#2E7D32') : PdfColor.fromHex('#C62828');
                return pw.TableRow(children: [
                  _cell(DateFormat('dd/MM/yyyy').format(e.date)),
                  _cell(e.title),
                  _cell(cat?.name ?? 'Otros'),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: pw.Text(
                      '${e.isIncome ? '+' : '-'}${fmt.format(e.amount)}',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ]);
              }),
            ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'informe_${DateFormat('yyyy_MM').format(month)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Informe de $monthLabel',
    );
  }

  static pw.Widget _metricBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 10, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(String text,
      {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}
