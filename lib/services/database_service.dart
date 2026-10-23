import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/transaction.dart';
import '../models/trend_data.dart';
import '../models/budget.dart';
import '../models/budget_summary.dart';
import '../models/savings_goal.dart';
import 'transaction_change_notifier.dart';

import 'package:flutter/foundation.dart';

class DatabaseService {
  // Singleton: toàn bộ ứng dụng dùng chung một DatabaseService.
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  static Database? _database;

  // Chỉ mở database khi cần và tái sử dụng sau đó.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // Khởi tạo file database và tạo bảng giao dịch.
  Future<Database> _initDatabase() async {
    final databaseDirectory = await getDatabasesPath();

    final databasePath = path.join(databaseDirectory, 'personal_expense.db');

    return openDatabase(
      databasePath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        raw_ocr_text TEXT,
        recipient_name TEXT
      )
    ''');

        await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(category, month)
      )
    ''');

        await _createSavingsGoalsTableIfNotExists(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(category, month)
      )
    ''');
        }

        if (oldVersion < 3) {
          await _createSavingsGoalsTableIfNotExists(db);
        }
        if (oldVersion < 4) {
          await db.execute('''
    ALTER TABLE transactions
    ADD COLUMN recipient_name TEXT
  ''');
        }
      },
      onOpen: (db) async {
        await _createSavingsGoalsTableIfNotExists(db);
      },
    );
  }

  Future<void> _createSavingsGoalsTableIfNotExists(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS savings_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      target_amount REAL NOT NULL,
      saved_amount REAL NOT NULL DEFAULT 0,
      deadline TEXT,
      created_at TEXT NOT NULL
    )
  ''');
  }

  Future<int> insertTransaction(ExpenseTransaction transaction) async {
    final db = await database;
    final data = transaction.toMap()..remove('id');

    final id = await db.insert('transactions', data);

    TransactionChangeNotifier.instance.notifyChanged();

    return id;
  }

  Future<int> updateTransaction(ExpenseTransaction transaction) async {
    final db = await database;

    if (transaction.id == null) {
      throw ArgumentError('Giao dịch chưa có ID.');
    }

    final rowsUpdated = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    if (rowsUpdated > 0) {
      TransactionChangeNotifier.instance.notifyChanged();
    }

    return rowsUpdated;
  }

  // Lấy danh sách giao dịch, mới nhất trước.
  Future<List<ExpenseTransaction>> getTransactions() async {
    final db = await database;

    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    debugPrint('SQLite: tìm thấy ${result.length} giao dịch');
    return result.map((row) => ExpenseTransaction.fromMap(row)).toList();
  }

  // Tìm kiếm và lọc giao dịch.
  Future<List<ExpenseTransaction>> searchTransactions({
    String keyword = '',
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final arguments = <Object>[];

    if (keyword.trim().isNotEmpty) {
      conditions.add('title LIKE ?');
      arguments.add('%${keyword.trim()}%');
    }

    if (type != null) {
      conditions.add('type = ?');
      arguments.add(type.name);
    }

    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      arguments.add(category);
    }

    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      conditions.add('date >= ?');
      arguments.add(start.toIso8601String());
    }

    if (endDate != null) {
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));

      conditions.add('date < ?');
      arguments.add(end.toIso8601String());
    }

    final result = await db.query(
      'transactions',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : arguments,
      orderBy: 'date DESC, id DESC',
    );

    return result.map((row) => ExpenseTransaction.fromMap(row)).toList();
  }

  // Xóa giao dịch theo ID.
  Future<int> deleteTransaction(int id) async {
    final db = await database;

    final rowsDeleted = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rowsDeleted > 0) {
      TransactionChangeNotifier.instance.notifyChanged();
    }

    return rowsDeleted;
  }

  // Lấy tổng thu và tổng chi theo tháng hoặc năm.

  Future<List<TrendData>> getTrendTotals({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {
    final db = await database;

    late final String groupExpression;
    late final String labelExpression;

    switch (period) {
      case 'Tháng':
        groupExpression = "strftime('%Y-%m', date)";
        labelExpression = groupExpression;
        break;

      case 'Năm':
        groupExpression = "strftime('%Y', date)";
        labelExpression = groupExpression;
        break;

      default:
        return [];
    }

    final result = await db.rawQuery(
      '''
    SELECT
      $labelExpression AS period,
      COALESCE(
        SUM(CASE WHEN type = ? THEN amount ELSE 0 END),
        0
      ) AS income,
      COALESCE(
        SUM(CASE WHEN type = ? THEN amount ELSE 0 END),
        0
      ) AS expense
    FROM transactions
    WHERE date >= ? AND date < ?
    GROUP BY $groupExpression
    ORDER BY period ASC
    ''',
      [
        TransactionType.income.name,
        TransactionType.expense.name,
        startDate.toIso8601String(),
        DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
        ).add(const Duration(days: 1)).toIso8601String(),
      ],
    );

    final totalsByPeriod = <String, TrendData>{};

    for (final row in result) {
      final key = row['period']?.toString() ?? '';

      totalsByPeriod[key] = TrendData(
        period: key,
        income: (row['income'] as num?)?.toDouble() ?? 0.0,
        expense: (row['expense'] as num?)?.toDouble() ?? 0.0,
      );
    }

    final periods = <String>[];

    if (period == 'Tháng') {
      var current = DateTime(startDate.year, startDate.month);

      final last = DateTime(endDate.year, endDate.month);

      while (!current.isAfter(last)) {
        periods.add(
          '${current.year.toString().padLeft(4, '0')}-'
          '${current.month.toString().padLeft(2, '0')}',
        );

        current = DateTime(current.year, current.month + 1);
      }
    } else {
      for (var year = startDate.year; year <= endDate.year; year++) {
        periods.add(year.toString());
      }
    }

    return periods.map((key) {
      return totalsByPeriod[key] ??
          TrendData(period: key, income: 0.0, expense: 0.0);
    }).toList();
  }

  // Thống kê tổng thu, tổng chi và số dư trong một khoảng ngày.
  Future<Map<String, double>> getTotalsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final start = DateTime(startDate.year, startDate.month, startDate.day);

    // Bao gồm toàn bộ ngày kết thúc.
    final endExclusive = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(const Duration(days: 1));

    final result = await db.rawQuery(
      '''
      SELECT
        COALESCE(
          SUM(CASE WHEN type = ? THEN amount ELSE 0 END),
          0
        ) AS income,
        COALESCE(
          SUM(CASE WHEN type = ? THEN amount ELSE 0 END),
          0
        ) AS expense
      FROM transactions
      WHERE date >= ? AND date < ?
      ''',
      [
        TransactionType.income.name,
        TransactionType.expense.name,
        start.toIso8601String(),
        endExclusive.toIso8601String(),
      ],
    );

    final income = (result.first['income'] as num).toDouble();
    final expense = (result.first['expense'] as num).toDouble();

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  // Lấy danh sách tổng thu và tổng chi theo từng ngày.
  Future<List<Map<String, dynamic>>> getDailyTotalsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final endExclusive = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(const Duration(days: 1));

    final result = await db.rawQuery(
      '''
      SELECT
        substr(date, 1, 10) AS day,
        COALESCE(
          SUM(CASE WHEN type = ? THEN amount ELSE 0 END),
          0
        ) AS income,
        COALESCE(
          SUM(CASE WHEN type = ? THEN amount ELSE 0 END),
          0
        ) AS expense
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY substr(date, 1, 10)
      ORDER BY day ASC
      ''',
      [
        TransactionType.income.name,
        TransactionType.expense.name,
        start.toIso8601String(),
        endExclusive.toIso8601String(),
      ],
    );

    return result.map((row) {
      return {
        'day': row['day'] as String,
        'income': (row['income'] as num).toDouble(),
        'expense': (row['expense'] as num).toDouble(),
      };
    }).toList();
  }

  // Thống kê chi tiêu theo từng danh mục trong một khoảng ngày.
  Future<List<Map<String, dynamic>>> getTotalsByCategory({
    required DateTime startDate,
    required DateTime endDate,
    required TransactionType type,
  }) async {
    final db = await database;

    final start = DateTime(startDate.year, startDate.month, startDate.day);

    // Bao gồm toàn bộ ngày kết thúc.
    final endExclusive = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(const Duration(days: 1));

    final result = await db.rawQuery(
      '''
    SELECT
      category,
      COALESCE(SUM(amount), 0) AS total
    FROM transactions
    WHERE type = ?
      AND date >= ?
      AND date < ?
    GROUP BY category
    ORDER BY total DESC
    ''',
      [type.name, start.toIso8601String(), endExclusive.toIso8601String()],
    );

    return result.map((row) {
      return {
        'category': row['category'] as String,
        'total': (row['total'] as num).toDouble(),
      };
    }).toList();
  }

  // Lấy danh sách ngân sách của một tháng.
  Future<List<Budget>> getBudgetsByMonth(String month) async {
    final db = await database;

    final result = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
      orderBy: 'category ASC',
    );

    return result.map((row) => Budget.fromMap(row)).toList();
  }

  // Lấy ngân sách và tổng chi tiêu thực tế theo tháng.
  Future<List<BudgetSummary>> getBudgetSummariesByMonth(String month) async {
    final budgets = await getBudgetsByMonth(month);

    final summaries = await Future.wait(
      budgets.map((budget) async {
        final spent = await getExpenseTotalByCategoryAndMonth(
          category: budget.category,
          month: month,
        );

        return BudgetSummary(budget: budget, spent: spent);
      }),
    );

    return summaries;
  }

  // Tính tổng chi tiêu của một danh mục trong tháng.
  Future<double> getExpenseTotalByCategoryAndMonth({
    required String category,
    required String month,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = ?
        AND category = ?
        AND substr(date, 1, 7) = ?
      ''',
      [TransactionType.expense.name, category, month],
    );

    return (result.first['total'] as num).toDouble();
  }

  // Thêm hoặc cập nhật ngân sách theo danh mục và tháng.
  Future<int> saveBudget(Budget budget) async {
    final db = await database;

    final data = budget.toMap()..remove('id');

    return db.insert(
      'budgets',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Cập nhật ngân sách theo ID.
  Future<int> updateBudget(Budget budget) async {
    final db = await database;

    if (budget.id == null) {
      throw ArgumentError('Ngân sách chưa có ID.');
    }

    return db.update(
      'budgets',
      budget.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // Xóa ngân sách theo ID.
  Future<int> deleteBudget(int id) async {
    final db = await database;

    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // Tính tổng tiền theo loại giao dịch.
  Future<double> getTotalByType(TransactionType type) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = ?
      ''',
      [type.name],
    );

    return (result.first['total'] as num).toDouble();
  }

  // Tính tổng thu nhập.
  Future<double> getTotalIncome() {
    return getTotalByType(TransactionType.income);
  }

  // Tính tổng chi tiêu.
  Future<double> getTotalExpense() {
    return getTotalByType(TransactionType.expense);
  }

  // Tính số dư = tổng thu nhập - tổng chi tiêu.
  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpense();

    return income - expense;
  }

  // Lấy danh sách mục tiêu tiết kiệm, mục tiêu mới nhất đứng trước.
  Future<List<SavingsGoal>> getSavingsGoals() async {
    final db = await database;

    final maps = await db.query(
      'savings_goals',
      orderBy: 'created_at DESC, id DESC',
    );

    return maps.map(SavingsGoal.fromMap).toList();
  }

  // Thêm mục tiêu tiết kiệm mới vào SQLite.
  Future<int> insertSavingsGoal(SavingsGoal goal) async {
    final db = await database;

    final data = goal.toMap()..remove('id');

    return db.insert('savings_goals', data);
  }

  // Cập nhật thông tin mục tiêu tiết kiệm đã tồn tại.
  Future<int> updateSavingsGoal(SavingsGoal goal) async {
    if (goal.id == null) {
      throw ArgumentError('Mục tiêu tiết kiệm cần có ID để cập nhật.');
    }

    final db = await database;

    final data = goal.toMap()..remove('id');

    return db.update(
      'savings_goals',
      data,
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // Xóa mục tiêu tiết kiệm theo ID.
  Future<int> deleteSavingsGoal(int id) async {
    final db = await database;

    return db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }
}
