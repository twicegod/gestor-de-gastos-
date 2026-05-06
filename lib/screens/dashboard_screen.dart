import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.expenses;
    final byCategory = provider.totalByCategory;
    final month = provider.filterMonth;
    final fmt = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(month);

    final totalIngresos = expenses.where((e) => e.isIncome).fold(0.0, (s, e) => s + e.amount);
    final totalGastos = expenses.where((e) => !e.isIncome).fold(0.0, (s, e) => s + e.amount);
    final balance = totalIngresos - totalGastos;

    return Scaffold(
      appBar: AppBar(
        title: Text('Resumen — $monthLabel'),
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
          Consumer<ThemeProvider>(
            builder: (_, theme, __) => IconButton(
              icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: theme.isDark ? 'Modo claro' : 'Modo oscuro',
              onPressed: theme.toggle,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Encabezado del mes
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimary, kPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monthLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricCard(label: 'Ingresos', value: fmt.format(totalIngresos), color: kIncome),
                    const SizedBox(width: 8),
                    _MetricCard(label: 'Gastos', value: fmt.format(totalGastos), color: kExpense),
                    const SizedBox(width: 8),
                    _MetricCard(
                      label: 'Balance',
                      value: fmt.format(balance),
                      color: balance >= 0 ? kIncome : kExpense,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Gasto por categoría
          if (byCategory.isNotEmpty) ...[
            const Text('Por categoría',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...byCategory.entries.map((entry) {
              final cat = provider.categoryById(entry.key);
              if (cat == null) return const SizedBox.shrink();
              final budget = provider.budgetForCategory(cat.id);
              final pct = budget != null
                  ? (entry.value / budget.limit).clamp(0.0, 1.0)
                  : null;
              final catColor = Color(cat.color);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: catColor.withValues(alpha: 0.15),
                        child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name,
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            if (pct != null) ...[
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  color: pct >= 1 ? kExpense : catColor,
                                  backgroundColor: catColor.withValues(alpha: 0.1),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(fmt.format(entry.value),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: kExpense)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Últimas transacciones
          if (expenses.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Últimas transacciones',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${expenses.length} en total',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            ...expenses.take(5).map((e) => _ExpenseTile(expense: e, fmt: fmt)),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('Sin gastos este mes',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color == kIncome
                        ? const Color(0xFFA5D6A7)
                        : color == kExpense
                            ? const Color(0xFFEF9A9A)
                            : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final NumberFormat fmt;
  const _ExpenseTile({required this.expense, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cat = context.read<ExpenseProvider>().categoryById(expense.categoryId);
    final catColor = Color(cat?.color ?? 0xFF757575);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(expense: expense),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: catColor.withValues(alpha: 0.15),
          child: Text(cat?.icon ?? '📦', style: const TextStyle(fontSize: 18)),
        ),
        title: Text(expense.title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          '${cat?.name ?? ''} · ${DateFormat('dd/MM/yyyy').format(expense.date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${expense.isIncome ? '+' : '-'}${fmt.format(expense.amount)}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: expense.isIncome ? kIncome : kExpense,
              fontSize: 14),
        ),
      ),
    );
  }
}
