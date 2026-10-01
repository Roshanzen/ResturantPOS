import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/errors/pos_exception.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/features/expenses/expense_repository.dart';
import 'package:restaurant_pos/models/expense.dart';
import 'package:restaurant_pos/models/expense_category.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final DatabaseService database;

  const ExpenseRepositoryImpl(this.database);

  @override
  Future<Result<List<ExpenseCategory>>> getExpenseCategories({String? branchId}) async {
    try {
      final rows = await database.query(
        'expense_categories',
        where: branchId != null ? 'branch_id = ?' : null,
        whereArgs: branchId != null ? [branchId] : null,
        orderBy: 'name ASC',
      );
      final categories = rows.map((r) => ExpenseCategory.fromMap(r)).toList();
      return Success(categories);
    } catch (e) {
      AppLogger.e('ExpenseRepository', 'Failed to load expense categories', error: e);
      return Failure(PosException('Failed to load expense categories: $e', code: 'EXPENSE_CATEGORY_ERROR'));
    }
  }

  @override
  Future<Result<ExpenseCategory>> createExpenseCategory(ExpenseCategory category) async {
    try {
      await database.insert('expense_categories', category.toMap());
      return Success(category);
    } catch (e) {
      AppLogger.e('ExpenseRepository', 'Failed to create expense category', error: e);
      return Failure(PosException('Failed to create expense category: $e', code: 'EXPENSE_CATEGORY_CREATE_ERROR'));
    }
  }

  @override
  Future<Result<List<Expense>>> getExpenses({String? branchId, DateTime? startDate, DateTime? endDate}) async {
    try {
      final rows = await database.query(
        'expenses',
        where: branchId != null ? 'branch_id = ? AND is_deleted = 0' : 'is_deleted = 0',
        whereArgs: branchId != null ? [branchId] : null,
        orderBy: 'expense_date DESC',
      );
      var expenses = rows.map((r) => Expense.fromMap(r)).toList();

      if (startDate != null) {
        expenses = expenses.where((e) => !e.expenseDate.isBefore(startDate)).toList();
      }
      if (endDate != null) {
        expenses = expenses.where((e) => !e.expenseDate.isAfter(endDate)).toList();
      }

      return Success(expenses);
    } catch (e) {
      AppLogger.e('ExpenseRepository', 'Failed to load expenses', error: e);
      return Failure(PosException('Failed to load expenses: $e', code: 'EXPENSE_LOAD_ERROR'));
    }
  }

  @override
  Future<Result<Expense>> getExpenseById(String id) async {
    try {
      final rows = await database.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) {
        return Failure(PosException('Expense not found', code: 'EXPENSE_NOT_FOUND'));
      }
      return Success(Expense.fromMap(rows.first));
    } catch (e) {
      AppLogger.e('ExpenseRepository', 'Failed to get expense', error: e);
      return Failure(PosException('Failed to get expense: $e', code: 'EXPENSE_GET_ERROR'));
    }
  }

  @override
  Future<Result<Expense>> createExpense(Expense expense) async {
    try {
      await database.insert('expenses', expense.toMap());
      return Success(expense);
    } catch (e) {
      AppLogger.e('ExpenseRepository', 'Failed to create expense', error: e);
      return Failure(PosException('Failed to create expense: $e', code: 'EXPENSE_CREATE_ERROR'));
    }
  }

  @override
  Future<Result<Expense>> updateExpense(Expense expense) async {
    try {
      await database.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      return Success(expense);
    } catch (e) {
      AppLogger.e('ExpenseRepository', 'Failed to update expense', error: e);
      return Failure(PosException('Failed to update expense: $e', code: 'EXPENSE_UPDATE_ERROR'));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String id) async {
    try {
      // Soft-delete for financial records
      await database.update(
        'expenses',
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Success(null);
    } catch (e) {
      AppLogger.e('ExpenseRepository', 'Failed to delete expense', error: e);
      return Failure(PosException('Failed to delete expense: $e', code: 'EXPENSE_DELETE_ERROR'));
    }
  }
}

