import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class NewMenuItemScreen extends StatefulWidget {
  const NewMenuItemScreen({super.key});

  @override
  State<NewMenuItemScreen> createState() => _NewMenuItemScreenState();
}

class _NewMenuItemScreenState extends State<NewMenuItemScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepController = TextEditingController(text: '5');
  final _stockController = TextEditingController(text: '0');
  String _category = 'General';
  bool _available = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final categories =
        provider.menuItems.map((m) => m.category).toSet().toList();
    categories.sort();
    final selectedCategory = categories.contains(_category)
        ? _category
        : (categories.isNotEmpty ? categories.first : 'General');

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add menu item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PosTheme.spacingMedium),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'e.g. Chocolate Truffle Cake'),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _codeController,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                    labelText: 'Item code', hintText: 'e.g. MN-103'),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                    labelText: 'Price (Rs.)', hintText: '0.00'),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _prepController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                    labelText: 'Prep time (minutes)', hintText: '5'),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                    labelText: 'Stock quantity', hintText: '0'),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Category',
                      style: TextStyle(
                          fontSize: 13, color: PosTheme.textSecondary))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                dropdownColor: PosTheme.surfaceColor,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: PosTheme.inputBackground,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(PosTheme.borderRadiusSmall),
                      borderSide: BorderSide.none),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available',
                      style:
                          TextStyle(fontSize: 14, color: PosTheme.textPrimary)),
                  Switch(
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                    activeThumbColor: PosTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              SizedBox(
                width: double.infinity,
                child: PosButton(
                  label: _isLoading ? 'Saving...' : 'Save item',
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_nameController.text.isEmpty ||
                              _codeController.text.isEmpty ||
                              _priceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please fill required fields'),
                                  backgroundColor: PosTheme.errorColor),
                            );
                            return;
                          }
                          final price =
                              double.tryParse(_priceController.text) ?? 0.0;
                          final prep = int.tryParse(_prepController.text) ?? 5;
                           final stock =
                              int.tryParse(_stockController.text) ?? 0;
                          final item = MenuItem(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: _nameController.text.trim(),
                            itemCode: _codeController.text.trim(),
                            price: price,
                            category: _category,
                            stockQuantity: stock,
                            preparationMinutes: prep,
                            available: _available,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          context.read<POSProvider>().addMenuItem(item);
                          Navigator.pop(context, true);
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
