import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'add_expense_screen.dart';

enum _Period { daily, weekly, monthly, all }

enum _SortOrder { dateDesc, dateAsc, amountDesc, amountAsc }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  _Period _period = _Period.monthly;
  _SortOrder _sort = _SortOrder.dateDesc;
  DateTime _refDate = DateTime.now();
  String? _filterCatId;

  List<Expense> _filter(List<Expense> all) {
    return all.where((e) {
      final matchCat = _filterCatId == null || e.categoryId == _filterCatId;
      bool matchPeriod;
      switch (_period) {
        case _Period.daily:
          matchPeriod = e.date.year == _refDate.year &&
              e.date.month == _refDate.month &&
              e.date.day == _refDate.day;
        case _Period.weekly:
          final start = _refDate.subtract(Duration(days: _refDate.weekday - 1));
          final startDay = DateTime(start.year, start.month, start.day);
          final endDay = startDay.add(const Duration(days: 7));
          matchPeriod = !e.date.isBefore(startDay) && e.date.isBefore(endDay);
        case _Period.monthly:
          matchPeriod = e.date.year == _refDate.year && e.date.month == _refDate.month;
        case _Period.all:
          matchPeriod = true;
      }
      return matchCat && matchPeriod;
    }).toList()
      ..sort((a, b) {
        switch (_sort) {
          case _SortOrder.dateDesc:
            return b.date.compareTo(a.date);
          case _SortOrder.dateAsc:
            return a.date.compareTo(b.date);
          case _SortOrder.amountDesc:
            return b.amount.compareTo(a.amount);
          case _SortOrder.amountAsc:
            return a.amount.compareTo(b.amount);
        }
      });
  }

  void _prevPeriod() {
    setState(() {
      switch (_period) {
        case _Period.daily:
          _refDate = _refDate.subtract(const Duration(days: 1));
        case _Period.weekly:
          _refDate = _refDate.subtract(const Duration(days: 7));
        case _Period.monthly:
          _refDate = DateTime(_refDate.year, _refDate.month - 1);
        case _Period.all:
          break;
      }
    });
  }

  void _nextPeriod() {
    final now = DateTime.now();
    setState(() {
      switch (_period) {
        case _Period.daily:
          final next = _refDate.add(const Duration(days: 1));
          if (!next.isAfter(now)) _refDate = next;
        case _Period.weekly:
          final next = _refDate.add(const Duration(days: 7));
          if (!next.isAfter(now)) _refDate = next;
        case _Period.monthly:
          final next = DateTime(_refDate.year, _refDate.month + 1);
          if (!next.isAfter(now)) _refDate = next;
        case _Period.all:
          break;
      }
    });
  }

  String get _periodLabel {
    switch (_period) {
      case _Period.daily:
        final now = DateTime.now();
        if (_refDate.year == now.year && _refDate.month == now.month && _refDate.day == now.day) return 'Hoy';
        if (_refDate.year == now.year && _refDate.month == now.month && _refDate.day == now.day - 1) return 'Ayer';
        return DateFormat('d MMM yyyy', 'es').format(_refDate);
      case _Period.weekly:
        final start = _refDate.subtract(Duration(days: _refDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'es').format(start)} - ${DateFormat('d MMM', 'es').format(end)}';
      case _Period.monthly:
        return DateFormat('MMMM yyyy', 'es').format(_refDate);
      case _Period.all:
        return 'Todos los registros';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final all = provider.allExpenses;
    final filtered = _filter(all);
    final fmt = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);
    final total = filtered.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (v) {
              setState(() {
                switch (v) {
                  case 'dateDesc': _sort = _SortOrder.dateDesc;
                  case 'dateAsc': _sort = _SortOrder.dateAsc;
                  case 'amountDesc': _sort = _SortOrder.amountDesc;
                  case 'amountAsc': _sort = _SortOrder.amountAsc;
                  case 'clearCat': _filterCatId = null;
                }
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'clearCat', child: Text('Todas las categorías')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'dateDesc', child: Text('Fecha descendente')),
              const PopupMenuItem(value: 'dateAsc', child: Text('Fecha ascendente')),
              const PopupMenuItem(value: 'amountDesc', child: Text('Mayor monto')),
              const PopupMenuItem(value: 'amountAsc', child: Text('Menor monto')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Pestañas de período
          Container(
            color: kPrimary,
            child: Row(
              children: _Period.values.map((p) {
                final label = switch (p) {
                  _Period.daily => 'Diario',
                  _Period.weekly => 'Semanal',
                  _Period.monthly => 'Mensual',
                  _Period.all => 'Todo',
                };
                final selected = _period == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _period = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: selected
                            ? const Border(bottom: BorderSide(color: Colors.white, width: 3))
                            : null,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Navegador de fecha
          if (_period != _Period.all)
            Container(
              color: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _prevPeriod,
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: Text(
                      _periodLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _nextPeriod,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

          // Filtro de categoría
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('Todas', style: TextStyle(fontSize: 12)),
                    selected: _filterCatId == null,
                    onSelected: (_) => setState(() => _filterCatId = null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ...provider.categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text('${cat.icon} ${cat.name}',
                            style: const TextStyle(fontSize: 12)),
                        selected: _filterCatId == cat.id,
                        onSelected: (_) =>
                            setState(() => _filterCatId = cat.id),
                        visualDensity: VisualDensity.compact,
                      ),
                    )),
              ],
            ),
          ),

          // Cabecera de tabla
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Gastos', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kExpense))),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Sin gastos en este período'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      final cat = provider.categoryById(e.categoryId);
                      return Dismissible(
                        key: Key(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) => showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar gasto'),
                            content: Text('¿Eliminar "${e.title}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                            ],
                          ),
                        ),
                        onDismissed: (_) => provider.deleteExpense(e.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('d MMM yyyy', 'es').format(e.date),
                                        style: const TextStyle(fontSize: 12)),
                                    Text(e.paymentMethod,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis),
                                    Text(cat?.name ?? '',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  fmt.format(e.amount),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: kExpense,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Footer totales
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Registros', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('${filtered.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Total Gastos', style: TextStyle(fontSize: 11, color: kExpense)),
                      Text(fmt.format(total),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kExpense)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Promedio', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        filtered.isEmpty ? '\$0' : fmt.format(total / filtered.length),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
