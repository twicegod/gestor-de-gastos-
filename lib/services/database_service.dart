import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/budget.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const _keyCat = 'categories';
  static const _keyExp = 'expenses';
  static const _keyBud = 'budgets';
  static const _keySeeded = 'categories_seeded';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── INIT: inserta categorías por defecto solo la primera vez ──
  Future<void> seedDefaults() async {
    final prefs = await _prefs;
    if (prefs.getBool(_keySeeded) == true) return;
    final cats = Category.defaults.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList(_keyCat, cats);
    await prefs.setBool(_keySeeded, true);
  }

  // ── CATEGORÍAS ──────────────────────────────────────────────
  Future<List<Category>> getCategories() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_keyCat) ?? [];
    return raw.map((s) => Category.fromMap(jsonDecode(s))).toList();
  }

  Future<void> insertCategory(Category category) async {
    final prefs = await _prefs;
    final list = await getCategories();
    list.removeWhere((c) => c.id == category.id);
    list.add(category);
    await prefs.setStringList(
        _keyCat, list.map((c) => jsonEncode(c.toMap())).toList());
  }

  Future<void> deleteCategory(String id) async {
    final prefs = await _prefs;
    final list = await getCategories();
    list.removeWhere((c) => c.id == id);
    await prefs.setStringList(
        _keyCat, list.map((c) => jsonEncode(c.toMap())).toList());
  }

  // ── GASTOS ──────────────────────────────────────────────────
  Future<List<Expense>> getExpenses() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_keyExp) ?? [];
    final list = raw.map((s) => Expense.fromMap(jsonDecode(s))).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> insertExpense(Expense expense) async {
    final prefs = await _prefs;
    final list = await getExpenses();
    list.removeWhere((e) => e.id == expense.id);
    list.add(expense);
    await prefs.setStringList(
        _keyExp, list.map((e) => jsonEncode(e.toMap())).toList());
  }

  Future<void> updateExpense(Expense expense) => insertExpense(expense);

  Future<void> deleteExpense(String id) async {
    final prefs = await _prefs;
    final list = await getExpenses();
    list.removeWhere((e) => e.id == id);
    await prefs.setStringList(
        _keyExp, list.map((e) => jsonEncode(e.toMap())).toList());
  }

  // ── PRESUPUESTOS ─────────────────────────────────────────────
  Future<List<Budget>> getBudgets(int month, int year) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_keyBud) ?? [];
    return raw
        .map((s) => Budget.fromMap(jsonDecode(s)))
        .where((b) => b.month == month && b.year == year)
        .toList();
  }

  Future<void> insertBudget(Budget budget) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_keyBud) ?? [];
    final list = raw.map((s) => Budget.fromMap(jsonDecode(s))).toList();
    list.removeWhere((b) => b.id == budget.id);
    list.add(budget);
    await prefs.setStringList(
        _keyBud, list.map((b) => jsonEncode(b.toMap())).toList());
  }

  Future<void> deleteBudget(String id) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_keyBud) ?? [];
    final list = raw.map((s) => Budget.fromMap(jsonDecode(s))).toList();
    list.removeWhere((b) => b.id == id);
    await prefs.setStringList(
        _keyBud, list.map((b) => jsonEncode(b.toMap())).toList());
  }
}
