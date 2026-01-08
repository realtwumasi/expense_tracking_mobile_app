import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<Category> _categories = [];
  Map<DateTime, double> _dailySpending = {};

  List<Expense> get expenses => _expenses;
  List<Category> get categories => _categories;
  Map<DateTime, double> get dailySpending => _dailySpending;

  Future<void> loadData() async {
    await loadCategories();
    await loadExpenses();
  }

  Future<void> loadCategories() async {
    _categories = await DatabaseHelper.instance.readAllCategories();
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    _expenses = await DatabaseHelper.instance.readAllExpenses();
    _calculateDailySpending();
    notifyListeners();
  }

  void _calculateDailySpending() {
    _dailySpending = {};
    for (var expense in _expenses) {
      // Normalize date to YYYY-MM-DD (midnight)
      final dateKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (_dailySpending.containsKey(dateKey)) {
        _dailySpending[dateKey] = _dailySpending[dateKey]! + expense.amount;
      } else {
        _dailySpending[dateKey] = expense.amount;
      }
    }
  }

  Future<void> addExpense(Expense expense) async {
    await DatabaseHelper.instance.createExpense(expense);
    _expenses.add(expense); // Optimistic update or reload?
    // Reloading is safer for sorting order
    await loadExpenses(); 
  }

  Future<void> updateExpense(Expense expense) async {
    await DatabaseHelper.instance.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    await loadExpenses();
  }

  List<Expense> getExpensesByDate(DateTime date) {
    return _expenses.where((e) => 
      e.date.year == date.year && 
      e.date.month == date.month && 
      e.date.day == date.day
    ).toList();
  }

  double getTotalSpendingForDate(DateTime date) {
     final dateKey = DateTime(date.year, date.month, date.day);
     return _dailySpending[dateKey] ?? 0.0;
  }
}
