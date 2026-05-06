import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../services/database_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final _db = DatabaseService();
  final _uuid = const Uuid();

  List<Expense> _expenses = [];
  List<Category> _categories = [];
  List<Budget> _budgets = [];

  String? _filterCategoryId;
  DateTime _filterMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Devuelve todos los gastos sin filtro de categoría ni mes (para la pantalla de transacciones)
  List<Expense> get allExpenses => List.unmodifiable(_expenses);

  // Devuelve gastos del mes activo (para dashboard/informes/presupuesto)
  List<Expense> get expenses => _expenses.where((e) {
        final matchCat = _filterCategoryId == null || e.categoryId == _filterCategoryId;
        final matchMonth = e.date.year == _filterMonth.year && e.date.month == _filterMonth.month;
        return matchCat && matchMonth;
      }).toList();

  List<Category> get categories => _categories;
  List<Budget> get budgets => _budgets;
  DateTime get filterMonth => _filterMonth;
  String? get filterCategoryId => _filterCategoryId;

  Future<void> init() async {
    await _db.seedDefaults();
    await loadCategories();
    await loadExpenses();
    await loadBudgets();
  }

  // ── FILTROS ──────────────────────────────────────────────────
  void setFilterMonth(DateTime month) {
    _filterMonth = DateTime(month.year, month.month);
    loadBudgets();
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  // ── GASTOS ──────────────────────────────────────────────────
  Future<void> loadExpenses() async {
    _expenses = await _db.getExpenses();
    notifyListeners();
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required String categoryId,
    required DateTime date,
    String paymentMethod = 'Efectivo',
    bool isIncome = false,
    String? note,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      categoryId: categoryId,
      date: date,
      paymentMethod: paymentMethod,
      isIncome: isIncome,
      note: note,
    );
    await _db.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _db.deleteExpense(id);
    await loadExpenses();
  }

  // ── CATEGORÍAS ──────────────────────────────────────────────
  Future<void> loadCategories() async {
    _categories = await _db.getCategories();
    notifyListeners();
  }

  Future<void> addCategory({
    required String name,
    required String icon,
    required int color,
  }) async {
    final category = Category(id: _uuid.v4(), name: name, icon: icon, color: color);
    await _db.insertCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await loadCategories();
  }

  // ── PRESUPUESTOS ─────────────────────────────────────────────
  Future<void> loadBudgets() async {
    _budgets = await _db.getBudgets(_filterMonth.month, _filterMonth.year);
    notifyListeners();
  }

  Future<void> setBudget({required String categoryId, required double limit}) async {
    final budget = Budget(
      id: _uuid.v4(),
      categoryId: categoryId,
      limit: limit,
      month: _filterMonth.month,
      year: _filterMonth.year,
    );
    await _db.insertBudget(budget);
    await loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
    await loadBudgets();
  }

  // ── ESTADÍSTICAS (mes activo) ────────────────────────────────
  double get totalCurrentMonth => expenses.fold(0, (s, e) => s + e.amount);

  Map<String, double> get totalByCategory {
    final Map<String, double> result = {};
    for (final e in expenses) {
      result[e.categoryId] = (result[e.categoryId] ?? 0) + e.amount;
    }
    return result;
  }

  double spentInCategory(String categoryId) => expenses
      .where((e) => e.categoryId == categoryId)
      .fold(0, (s, e) => s + e.amount);

  Budget? budgetForCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }

  Category? categoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
