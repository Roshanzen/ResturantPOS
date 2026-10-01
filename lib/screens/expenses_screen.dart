import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';
import 'expense_details_screen.dart';
import 'new_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _dateFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<Expense> _applyFilters(List<Expense> all) {
    var filtered = all;
    final now = DateTime.now();

    switch (_dateFilter) {
      case 'Today':
        filtered = filtered.where((e) =>
            e.expenseDate.year == now.year &&
            e.expenseDate.month == now.month &&
            e.expenseDate.day == now.day).toList();
        break;
      case 'This week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        filtered = filtered.where((e) => !e.expenseDate.isBefore(start)).toList();
        break;
      case 'This month':
        filtered = filtered.where((e) =>
            e.expenseDate.year == now.year &&
            e.expenseDate.month == now.month).toList();
        break;
      case 'All':
      default:
        break;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.categoryName.toLowerCase().contains(query) ||
            (e.referenceNumber != null &&
                e.referenceNumber!.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final allExpenses = provider.expenses;
    final filteredExpenses = _applyFilters(allExpenses);
    final filteredTotal = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewExpenseScreen()),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add expense',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: PosTheme.primaryColor),
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
              // Summary KPI Cards
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Total expenses',
                      value: provider.formatCurrency(provider.totalExpenses),
                      subtext: '${provider.expenses.length} records',
                      accentColor: PosTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Today',
                      value: provider.formatCurrency(provider.todayExpenses),
                      subtext: 'Today\'s expenses',
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Filter total',
                      value: provider.formatCurrency(filteredTotal),
                      subtext: '${filteredExpenses.length} entries',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacingSmall),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Net sales',
                      value: provider.formatCurrency(provider.netAmount),
                      subtext: 'Total revenue',
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Net profit',
                      value: provider.formatCurrency(provider.netProfit),
                      subtext: 'Net sales - Expenses',
                      accentColor: provider.netProfit >= 0
                          ? PosTheme.primaryColor
                          : PosTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // Search
              SearchField(
                hintText: 'Search by description or category...',
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // Date Filters
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'Today', 'This week', 'This month'].map((f) {
                    final isSelected = _dateFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PosFilterChip(
                        label: f,
                        isSelected: isSelected,
                        onTap: () => setState(() => _dateFilter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: PosTheme.spacingLarge),

              // Dynamic List or Empty State
              if (allExpenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 48, color: PosTheme.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'No expenses yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: PosTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PosButton(
                          label: 'Add expense',
                          isSmall: true,
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NewExpenseScreen()),
                            );
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else if (filteredExpenses.isEmpty)
                const EmptyState(
                  title: 'No matching expenses',
                  subtitle: 'Try changing your search or date filter.',
                )
              else
                Column(
                  children: filteredExpenses.map((expense) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: PosTheme.spacingSmall),
                      child: ExpenseCard(
                        expense: expense,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExpenseDetailsScreen(expense: expense),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const ExpenseCard({super.key, required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<POSProvider>();

    return PosCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: PosTheme.cardPadding, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      expense.categoryName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PosTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: PosTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.paymentMethod.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PosTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: PosTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(expense.expenseDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: PosTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PosTheme.spacingMedium),
          Text(
            provider.formatCurrency(expense.amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: PosTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: PosTheme.textMuted),
        ],
      ),
    );
  }
}

