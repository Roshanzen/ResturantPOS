import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class NewExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const NewExpenseScreen({super.key, this.expense});

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  bool get isEditing => widget.expense != null;

  final List<String> _paymentMethods = const ['cash', 'fonepay', 'credit', 'card'];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(2);
      _selectedDate = e.expenseDate;
      _paymentMethod = e.paymentMethod;
      _referenceController.text = e.referenceNumber ?? '';
      _notesController.text = e.notes ?? '';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.expense != null && _selectedCategory == null) {
      final categories = context.read<POSProvider>().expenseCategories;
      final match = categories.where((c) => c.id == widget.expense!.categoryId);
      if (match.isNotEmpty) {
        _selectedCategory = match.first;
      } else {
        _selectedCategory = ExpenseCategory(
          id: widget.expense!.categoryId,
          name: widget.expense!.categoryName,
          branchId: widget.expense!.branchId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PosTheme.primaryColor,
              surface: PosTheme.cardColor,
              onSurface: PosTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final categories = provider.expenseCategories;

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit expense' : 'Add expense'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PosTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Expense Category *
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expense category *',
                    style: TextStyle(fontSize: 13, color: PosTheme.textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddExpenseCategoryDialog(context, provider),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                    label: const Text('New category', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: PosTheme.primaryColor,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory != null &&
                        categories.any((c) => c.id == _selectedCategory!.id)
                    ? categories.firstWhere((c) => c.id == _selectedCategory!.id)
                    : _selectedCategory,
                hint: const Text(
                  'Select category',
                  style: TextStyle(color: PosTheme.textMuted, fontSize: 14),
                ),
                dropdownColor: PosTheme.surfaceColor,
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    color: PosTheme.textSecondary),
                style: const TextStyle(
                    color: PosTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: PosTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem<ExpenseCategory>(
                    value: cat,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (cat) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 2. Title / Description *
              TextField(
                controller: _titleController,
                style: const TextStyle(
                    color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Description / Title *',
                  hintText: 'e.g. Electricity bill for September',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 3. Amount *
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs.) *',
                  hintText: '0.00',
                  prefixText: 'Rs. ',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 4. Date *
              const Text(
                'Expense date *',
                style: TextStyle(fontSize: 13, color: PosTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: PosTheme.inputBackground,
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                    border: Border.all(
                        color: const Color(0xFF444444), width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: const TextStyle(
                            color: PosTheme.textPrimary, fontSize: 14),
                      ),
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: PosTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 5. Payment method
              const Text(
                'Payment method',
                style: TextStyle(fontSize: 13, color: PosTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: _paymentMethods.map((m) {
                  final isSelected = _paymentMethod == m;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMethod = m),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: m != _paymentMethods.last ? 6 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? PosTheme.primaryColor.withValues(alpha: 0.2)
                              : PosTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(
                              PosTheme.borderRadiusSmall),
                          border: Border.all(
                            color: isSelected
                                ? PosTheme.primaryColor
                                : const Color(0xFF444444),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          m.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? PosTheme.primaryColor
                                : PosTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 6. Reference / Receipt Number
              TextField(
                controller: _referenceController,
                style: const TextStyle(
                    color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Reference / receipt number',
                  hintText: 'e.g. REC-89214',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 7. Notes
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(
                    color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional remarks or vendor details',
                ),
              ),
              const SizedBox(height: PosTheme.spacingLarge),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: PosButton(
                  label: _isLoading
                      ? 'Saving...'
                      : (isEditing ? 'Update expense' : 'Save expense'),
                  onPressed: _isLoading ? null : _saveExpense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (_selectedCategory == null) {
      _showError('Please select an expense category.');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a description/title for this expense.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid expense amount.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<POSProvider>();
      final ref = _referenceController.text.trim();
      final notes = _notesController.text.trim();

      if (isEditing) {
        final updatedExpense = widget.expense!.copyWith(
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          title: title,
          amount: amount,
          expenseDate: _selectedDate,
          paymentMethod: _paymentMethod,
          referenceNumber: ref.isEmpty ? null : ref,
          notes: notes.isEmpty ? null : notes,
          updatedAt: DateTime.now(),
        );
        await provider.updateExpense(updatedExpense);
      } else {
        final newExpense = Expense(
          id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
          branchId: 'branch_001',
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          title: title,
          amount: amount,
          expenseDate: _selectedDate,
          paymentMethod: _paymentMethod,
          referenceNumber: ref.isEmpty ? null : ref,
          notes: notes.isEmpty ? null : notes,
          createdBy: 'cashier',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await provider.addExpense(newExpense);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(e is ArgumentError ? e.message.toString() : 'Failed to save expense');
      }
    }
  }

  void _showAddExpenseCategoryDialog(BuildContext context, POSProvider provider) {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: PosTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PosTheme.borderRadius),
        ),
        title: const Text('Add expense category',
            style: TextStyle(color: PosTheme.textPrimary, fontSize: 16)),
        content: TextField(
          controller: catController,
          autofocus: true,
          style: const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'e.g. Advertising, Laundry, Legal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel',
                style: TextStyle(color: PosTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = catController.text.trim();
              if (newName.isNotEmpty) {
                await provider.addExpenseCategory(newName);
                final created = provider.expenseCategories.firstWhere(
                  (c) => c.name.toLowerCase() == newName.toLowerCase(),
                  orElse: () => ExpenseCategory(
                    id: 'ec_${DateTime.now().millisecondsSinceEpoch}',
                    name: newName,
                    branchId: provider.activeBranchId,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                setState(() {
                  _selectedCategory = created;
                });
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PosTheme.errorColor,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
