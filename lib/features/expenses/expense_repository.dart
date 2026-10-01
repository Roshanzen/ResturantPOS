import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/models/expense.dart';
import 'package:restaurant_pos/models/expense_category.dart';

abstract class ExpenseRepository {
  Future<Result<List<ExpenseCategory>>> getExpenseCategories({String? branchId});
  Future<Result<ExpenseCategory>> createExpenseCategory(ExpenseCategory category);
  Future<Result<List<Expense>>> getExpenses({String? branchId, DateTime? startDate, DateTime? endDate});
  Future<Result<Expense>> getExpenseById(String id);
  Future<Result<Expense>> createExpense(Expense expense);
  Future<Result<Expense>> updateExpense(Expense expense);
  Future<Result<void>> deleteExpense(String id);
}

