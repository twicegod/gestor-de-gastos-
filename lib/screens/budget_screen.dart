import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final categories = provider.categories;
    final month = provider.filterMonth;
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(month).toUpperCase();
    final fmt = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

    double totalBudget = 0;
    double totalSpent = 0;
    for (final cat in categories) {
      final budget = provider.budgetForCategory(cat.id);
      if (budget != null) {
        totalBudget += budget.limit;
        totalSpent += provider.spentInCategory(cat.id);
      }
    }
    final remaining = totalBudget - totalSpent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
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
        ],
      ),
      body: Column(
        children: [
          // Header mes
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) {
                final cat = categories[i];
                final budget = provider.budgetForCategory(cat.id);
                final spent = provider.spentInCategory(cat.id);
                final pct = budget != null ? (spent / budget.limit).clamp(0.0, 1.0) : 0.0;
                final over = budget != null && spent > budget.limit;
                final catColor = Color(cat.color);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: catColor.withValues(alpha: 0.15),
                        child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(cat.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                if (budget != null)
                                  Text(fmt.format(budget.limit),
                                      style: const TextStyle(fontWeight: FontWeight.bold))
                                else
                                  TextButton(
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0)),
                                    onPressed: () => _showSetBudgetDialog(context, cat),
                                    child: const Text('+ Fijar límite',
                                        style: TextStyle(fontSize: 12, color: kPrimary)),
                                  ),
                              ],
                            ),
                            if (budget != null) ...[
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  color: over ? kExpense : catColor,
                                  backgroundColor: catColor.withValues(alpha: 0.12),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Gastado ${fmt.format(spent)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const Spacer(),
                                  Text(
                                    over
                                        ? 'Excedido ${fmt.format(spent - budget.limit)}'
                                        : 'Restante ${fmt.format(budget.limit - spent)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: over ? kExpense : kIncome,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => provider.deleteBudget(budget.id),
                                    child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer totales
          if (totalBudget > 0)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E),
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _FooterCell(label: 'Presupuesto', value: fmt.format(totalBudget), color: Colors.white),
                  _FooterCell(label: 'Gastos', value: fmt.format(totalSpent), color: Colors.red[300]!),
                  _FooterCell(
                    label: 'Restante',
                    value: fmt.format(remaining),
                    color: remaining >= 0 ? const Color(0xFF69F0AE) : Colors.red[300]!,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context, Category cat) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${cat.icon} ${cat.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Límite mensual',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v == null || v <= 0) return;
              context.read<ExpenseProvider>().setBudget(categoryId: cat.id, limit: v);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _FooterCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FooterCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
