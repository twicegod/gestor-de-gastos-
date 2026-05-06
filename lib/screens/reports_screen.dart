import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import '../providers/expense_provider.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final byCategory = provider.totalByCategory;
    final total = provider.totalCurrentMonth;
    final month = provider.filterMonth;
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(month);
    final fmt = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final cat = provider.categoryById(e.key);
      final color = Color(cat?.color ?? 0xFF757575);
      final pct = total > 0 ? (e.value / total * 100) : 0.0;
      return PieChartSectionData(
        value: e.value,
        color: color,
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: i == 0 ? 65 : 58,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Informes — $monthLabel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => provider.setFilterMonth(
                DateTime(month.year, month.month - 1)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.setFilterMonth(
                DateTime(month.year, month.month + 1)),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exportar PDF',
            onPressed: total == 0
                ? null
                : () => PdfService.exportReport(
                      expenses: provider.expenses,
                      categories: provider.categories,
                      month: month,
                    ),
          ),
        ],
      ),
      body: total == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Sin gastos en este período',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Gráfico de dona con total en el centro
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Distribución',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Spacer(),
                            Text(monthLabel,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sections: sections,
                                  centerSpaceRadius: 52,
                                  sectionsSpace: 2,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Total',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  Text(
                                    fmt.format(total),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: kExpense),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Leyenda
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: entries.map((e) {
                            final cat = provider.categoryById(e.key);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(cat?.color ?? 0xFF757575),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(cat?.name ?? 'Otros',
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cabecera tabla
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 3, child: Text('Cantidad', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('%', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Filas
                ...entries.map((e) {
                  final cat = provider.categoryById(e.key);
                  final pct = total > 0 ? e.value / total * 100 : 0.0;
                  final color = Color(cat?.color ?? 0xFF757575);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Text(cat?.icon ?? '📦',
                                    style: const TextStyle(fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 4,
                                child: Text(cat?.name ?? 'Otros',
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  fmt.format(e.value),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kExpense,
                                      fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${pct.toStringAsFixed(1)}%',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              color: color,
                              backgroundColor: color.withValues(alpha: 0.1),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 4),
                // Fila total
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                          flex: 4,
                          child: Text('TOTAL',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                        flex: 3,
                        child: Text(fmt.format(total),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kExpense,
                                fontSize: 14)),
                      ),
                      const Expanded(
                          flex: 2,
                          child: Text('100%',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
