import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense; // si viene con gasto = modo edición

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _selectedCategoryId;
  String _paymentMethod = 'Efectivo';
  DateTime _date = DateTime.now();
  bool _isIncome = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _amountCtrl.text = e.amount.toStringAsFixed(e.amount.truncateToDouble() == e.amount ? 0 : 2);
      _titleCtrl.text = e.title;
      _noteCtrl.text = e.note ?? '';
      _selectedCategoryId = e.categoryId;
      _paymentMethod = e.paymentMethod;
      _date = e.date;
      _isIncome = e.isIncome;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showError('Ingresa un monto válido');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Ingresa una descripción');
      return;
    }
    if (_selectedCategoryId == null) {
      _showError('Selecciona una categoría');
      return;
    }
    final provider = context.read<ExpenseProvider>();
    if (_isEditing) {
      await provider.updateExpense(Expense(
        id: widget.expense!.id,
        title: _titleCtrl.text.trim(),
        amount: amount,
        categoryId: _selectedCategoryId!,
        date: _date,
        paymentMethod: _paymentMethod,
        isIncome: _isIncome,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ));
    } else {
      await provider.addExpense(
        title: _titleCtrl.text.trim(),
        amount: amount,
        categoryId: _selectedCategoryId!,
        date: _date,
        paymentMethod: _paymentMethod,
        isIncome: _isIncome,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      // Alerta de presupuesto al agregar gasto
      if (!_isIncome && mounted) {
        final budget = provider.budgetForCategory(_selectedCategoryId!);
        if (budget != null) {
          final spent = provider.spentInCategory(_selectedCategoryId!);
          if (spent >= budget.limit) {
            final cat = provider.categoryById(_selectedCategoryId!);
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Presupuesto superado'),
                ]),
                content: Text(
                  'Has superado el presupuesto de ${cat?.name ?? 'esta categoría'}.\n'
                  'Gastado: \$${spent.toStringAsFixed(0)} / Límite: \$${budget.limit.toStringAsFixed(0)}',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _changeDate(int days) {
    final next = _date.add(Duration(days: days));
    if (!next.isAfter(DateTime.now())) setState(() => _date = next);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _showCategoryPicker(BuildContext context, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, sc) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seleccionar categoría',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddCategoryDialog(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final selected = cat.id == _selectedCategoryId;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategoryId = cat.id);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(cat.color).withValues(alpha: 0.15)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? Border.all(color: Color(cat.color), width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(cat.color).withValues(alpha: 0.2),
                            radius: 24,
                            child: Text(cat.icon,
                                style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(height: 6),
                          Text(cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedIcon = '💰';
    int selectedColor = 0xFF1565C0;
    final icons = ['💰', '🛒', '🎁', '✈️', '🏋️', '🎓', '💻', '🐾', '🌮', '🎵', '🏠', '💊'];
    final colors = [0xFF1565C0, 0xFFE53935, 0xFF43A047, 0xFFFB8C00, 0xFF8E24AA, 0xFF00ACC1, 0xFFD81B60, 0xFF757575];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nueva categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Icono'),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: icons.map((ic) => GestureDetector(
                  onTap: () => setS(() => selectedIcon = ic),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: selectedIcon == ic ? Border.all(color: kPrimary, width: 2) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(ic, style: const TextStyle(fontSize: 22)),
                  ),
                )).toList()),
                const SizedBox(height: 12),
                const Text('Color'),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: colors.map((c) => GestureDetector(
                  onTap: () => setS(() => selectedColor = c),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: selectedColor == c ? Border.all(color: Colors.black, width: 2) : null,
                    ),
                  ),
                )).toList()),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await context.read<ExpenseProvider>().addCategory(
                    name: nameCtrl.text.trim(), icon: selectedIcon, color: selectedColor);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final categories = provider.categories;
    final selectedCat = _selectedCategoryId != null
        ? provider.categoryById(_selectedCategoryId!)
        : null;
    final isToday = _date.year == DateTime.now().year &&
        _date.month == DateTime.now().month &&
        _date.day == DateTime.now().day;
    final dateLabel = isToday
        ? 'Hoy'
        : DateFormat('dd/MM/yyyy').format(_date);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar transacción' : 'Nueva transacción')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                const SizedBox(height: 8),

                // Toggle GASTO / INGRESO
                Center(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('GASTO'),
                        icon: Icon(Icons.arrow_upward, size: 16),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('INGRESO'),
                        icon: Icon(Icons.arrow_downward, size: 16),
                      ),
                    ],
                    selected: {_isIncome},
                    onSelectionChanged: (s) => setState(() => _isIncome = s.first),
                    style: ButtonStyle(
                      iconColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return _isIncome ? kIncome : kExpense;
                        }
                        return null;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo monto
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _isIncome ? kIncome : kExpense,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: _isIncome ? kIncome : kExpense),
                    border: const UnderlineInputBorder(),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: kPrimary, width: 2)),
                    hintText: '0',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 32),
                  ),
                  onChanged: (v) {
                    final num = double.tryParse(v.replaceAll(',', '.'));
                    if (num != null) {
                      // no reformatear mientras escribe
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Campo descripción
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kPrimary, width: 2)),
                  ),
                ),
                const SizedBox(height: 8),

                // Fila categoría
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: selectedCat != null
                        ? Color(selectedCat.color).withValues(alpha: 0.2)
                        : Colors.grey[200],
                    child: Text(
                      selectedCat?.icon ?? '📦',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    selectedCat?.name ?? 'Seleccionar categoría',
                    style: TextStyle(
                      color: selectedCat == null ? Colors.grey : null,
                    ),
                  ),
                  subtitle: const Text('Categoría'),
                  trailing: const Icon(Icons.chevron_right, color: kPrimary),
                  onTap: () => categories.isEmpty
                      ? _showAddCategoryDialog(context)
                      : _showCategoryPicker(context, categories),
                ),
                const Divider(height: 1),

                // Fila método de pago
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.account_balance_wallet, color: kPrimary, size: 20),
                  ),
                  title: Text(_paymentMethod),
                  subtitle: const Text('Método de pago'),
                  trailing: const Icon(Icons.chevron_right, color: kPrimary),
                  onTap: () => _showPaymentMethodPicker(),
                ),
                const Divider(height: 1),

                // Fila fecha
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.calendar_today, color: kPrimary, size: 20),
                  ),
                  title: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: kPrimary),
                        onPressed: () => _changeDate(-1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Text(
                            dateLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: _date.day == DateTime.now().day &&
                                  _date.month == DateTime.now().month
                              ? Colors.grey
                              : kPrimary,
                        ),
                        onPressed: () => _changeDate(1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  subtitle: const Text('Fecha'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month, color: kPrimary),
                    onPressed: _pickDate,
                  ),
                ),
                const Divider(height: 1),

                // Nota
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.notes, color: kPrimary, size: 20),
                  ),
                  title: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nota (opcional)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón guardar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'ACTUALIZAR' : 'GUARDAR',
                    style: const TextStyle(fontSize: 16, letterSpacing: 1.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Método de pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...Expense.paymentMethods.map((method) => ListTile(
                leading: Icon(
                  method == 'Efectivo' ? Icons.payments_outlined
                    : method == 'Banco' ? Icons.account_balance_outlined
                    : Icons.credit_card_outlined,
                  color: kPrimary,
                ),
                title: Text(method),
                trailing: _paymentMethod == method
                    ? const Icon(Icons.check, color: kPrimary)
                    : null,
                onTap: () {
                  setState(() => _paymentMethod = method);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
