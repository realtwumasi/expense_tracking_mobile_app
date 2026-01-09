import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../database/database_helper.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<Category> _categories = [];
  Map<DateTime, double> _dailySpending = {};
  Map<DateTime, List<Expense>> _expensesByDate = {};

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
    _calculateSummaries();
    notifyListeners();
  }

  void _calculateSummaries() {
    _dailySpending = {};
    _expensesByDate = {};
    
    for (var expense in _expenses) {
      // Normalize date to YYYY-MM-DD (midnight)
      final dateKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
      
      // Update Spending
      _dailySpending[dateKey] = (_dailySpending[dateKey] ?? 0.0) + expense.amount;

      // Update List Cache
      if (!_expensesByDate.containsKey(dateKey)) {
        _expensesByDate[dateKey] = [];
      }
      _expensesByDate[dateKey]!.add(expense);
    }
  }

  // CRUD methods (unchanged...)
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
    final dateKey = DateTime(date.year, date.month, date.day);
    return _expensesByDate[dateKey] ?? [];
  }

  double getTotalSpendingForDate(DateTime date) {
     final dateKey = DateTime(date.year, date.month, date.day);
     return _dailySpending[dateKey] ?? 0.0;
  }
  Future<void> exportExpensesToCsv() async {
    List<List<dynamic>> rows = [];
    // Header
    rows.add(['Date', 'Time', 'Amount', 'Category', 'Description']);

    for (var expense in _expenses) {
      final category = _categories.firstWhere(
        (c) => c.id == expense.categoryId,
        orElse: () => _categories.first,
      );
      
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        DateFormat('HH:mm').format(expense.date),
        expense.amount,
        category.name,
        expense.description ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/expenses_backup_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(path)], text: 'My Expense Backup');
  }
}
