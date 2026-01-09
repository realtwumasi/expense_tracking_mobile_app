import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Bumped for Grocery category
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add Grocery category for existing users
      await db.insert('categories', Category(
        id: 'grocery',
        name: 'Grocery',
        iconCodePoint: Icons.shopping_cart.codePoint,
        iconFontFamily: Icons.shopping_cart.fontFamily,
        iconFontPackage: Icons.shopping_cart.fontPackage,
        colorValue: Colors.green.toARGB32(),
      ).toMap());
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // Create Categories Table
    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  iconCodePoint $intType,
  iconFontFamily $textNullable,
  iconFontPackage $textNullable,
  colorValue $intType
)
''');

    // Create Expenses Table
    await db.execute('''
CREATE TABLE expenses (
  id $idType,
  amount $doubleType,
  categoryId $textType,
  date $textType,
  description $textNullable,
  timestamp $textType,
  FOREIGN KEY (categoryId) REFERENCES categories (id)
)
''');

    // Create Indexes
    await db.execute('CREATE INDEX idx_expenses_date ON expenses (date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses (categoryId)');
    await db.execute('CREATE INDEX idx_expenses_timestamp ON expenses (timestamp)');

    // Insert Default Categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      Category(
        id: 'food',
        name: 'Food',
        iconCodePoint: Icons.fastfood.codePoint,
        iconFontFamily: Icons.fastfood.fontFamily,
        iconFontPackage: Icons.fastfood.fontPackage,
        colorValue: Colors.orange.toARGB32(),
      ),
      Category(
        id: 'transport',
        name: 'Transport',
        iconCodePoint: Icons.directions_bus.codePoint,
        iconFontFamily: Icons.directions_bus.fontFamily,
        iconFontPackage: Icons.directions_bus.fontPackage,
        colorValue: Colors.blue.toARGB32(),
      ),
      Category(
        id: 'grocery',
        name: 'Grocery',
        iconCodePoint: Icons.shopping_cart.codePoint,
        iconFontFamily: Icons.shopping_cart.fontFamily,
        iconFontPackage: Icons.shopping_cart.fontPackage,
        colorValue: Colors.green.toARGB32(),
      ),
      Category(
        id: 'internet',
        name: 'Internet',
        iconCodePoint: Icons.wifi.codePoint,
        iconFontFamily: Icons.wifi.fontFamily,
        iconFontPackage: Icons.wifi.fontPackage,
        colorValue: Colors.indigo.toARGB32(),
      ),
      Category(
        id: 'utilities',
        name: 'Utilities',
        iconCodePoint: Icons.lightbulb.codePoint,
        iconFontFamily: Icons.lightbulb.fontFamily,
        iconFontPackage: Icons.lightbulb.fontPackage,
        colorValue: Colors.yellow[700]!.toARGB32(),
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        iconCodePoint: Icons.movie.codePoint,
        iconFontFamily: Icons.movie.fontFamily,
        iconFontPackage: Icons.movie.fontPackage,
        colorValue: Colors.pink.toARGB32(),
      ),
      Category(
        id: 'health',
        name: 'Health',
        iconCodePoint: Icons.local_hospital.codePoint,
        iconFontFamily: Icons.local_hospital.fontFamily,
        iconFontPackage: Icons.local_hospital.fontPackage,
        colorValue: Colors.red.toARGB32(),
      ),
      Category(
        id: 'other',
        name: 'Other',
        iconCodePoint: Icons.category.codePoint,
        iconFontFamily: Icons.category.fontFamily,
        iconFontPackage: Icons.category.fontPackage,
        colorValue: Colors.grey.toARGB32(),
      ),
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  // CRUD for Expenses
  Future<String> createExpense(Expense expense) async {
    final db = await instance.database;
    await db.insert('expenses', expense.toMap());
    return expense.id;
  }

  Future<Expense> readExpense(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'expenses',
      columns: ['id', 'amount', 'categoryId', 'date', 'description', 'timestamp'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Expense>> readAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC, timestamp DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<List<Expense>> readExpensesByDay(DateTime day) async {
    final db = await instance.database;
    // Store dates as ISO8601 strings in database, so we search by prefix or exact string if we stored date only?
    // Expense model stores full ISO string.
    // For "Daily" view, we need to match the YYYY-MM-DD part.
    // SQLite string comparison.
    final dayStr = day.toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    final result = await db.query(
      'expenses',
      where: 'date LIKE ?',
      whereArgs: ['$dayStr%'],
      orderBy: 'timestamp DESC',
    );
     return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD for Categories
  Future<List<Category>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => Category.fromMap(json)).toList();
  }
}
