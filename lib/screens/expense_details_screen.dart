import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';
import 'new_expense_screen.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailsScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();

    // Locate live expense in provider state to reflect updates or deletion
    final currentExpense = provider.expenses.firstWhere(
      (e) => e.id == expense.id,
      orElse: () => expense,
    );

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Expense details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            tooltip: 'Edit expense',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewExpenseScreen(expense: currentExpense),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: PosTheme.errorColor),
            tooltip: 'Delete expense',
            onPressed: () => _confirmDelete(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PosTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentExpense.categoryName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: PosTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentExpense.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: PosTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          provider.formatCurrency(currentExpense.amount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PosTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: PosTheme.spacingMedium),
                    const Divider(),
                    const SizedBox(height: PosTheme.spacingSmall),
                    _buildRow('Date', DateFormat.yMMMd().format(currentExpense.expenseDate)),
                    _buildRow('Payment method', currentExpense.paymentMethod.toUpperCase()),
                    if (currentExpense.referenceNumber != null &&
                        currentExpense.referenceNumber!.isNotEmpty)
                      _buildRow('Reference / Receipt', currentExpense.referenceNumber!),
                    _buildRow('Created by', currentExpense.createdBy),
                    _buildRow(
                      'Created date',
                      DateFormat('dd MMM yyyy, hh:mm a').format(currentExpense.createdAt),
                    ),
                    if (currentExpense.notes != null && currentExpense.notes!.isNotEmpty) ...[
                      const SizedBox(height: PosTheme.spacingSmall),
                      const Text(
                        'Notes',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PosTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentExpense.notes!,
                        style: const TextStyle(
                            fontSize: 13, color: PosTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              Row(
                children: [
                  Expanded(
                    child: PosButton(
                      label: 'Delete expense',
                      backgroundColor: PosTheme.errorColor,
                      isOutlined: true,
                      onPressed: () => _confirmDelete(context, provider),
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacingMedium),
                  Expanded(
                    child: PosButton(
                      label: 'Edit expense',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NewExpenseScreen(expense: currentExpense),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, POSProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteExpense(expense.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense deleted successfully'),
                    backgroundColor: PosTheme.primaryColor,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: PosTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: PosTheme.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PosTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

