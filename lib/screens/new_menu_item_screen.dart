import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class NewMenuItemScreen extends StatefulWidget {
  final MenuItem? item;

  const NewMenuItemScreen({super.key, this.item});

  @override
  State<NewMenuItemScreen> createState() => _NewMenuItemScreenState();
}

class _NewMenuItemScreenState extends State<NewMenuItemScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepController = TextEditingController(text: '5');
  final _stockController = TextEditingController(text: '0');
  String? _category;
  bool _available = true;
  bool _isLoading = false;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _codeController.text = widget.item!.itemCode;
      _priceController.text = widget.item!.price.toStringAsFixed(2);
      _prepController.text = widget.item!.preparationMinutes.toString();
      _stockController.text = widget.item!.stockQuantity.toString();
      _category = widget.item!.category;
      _available = widget.item!.available;
    }
  }

  static const String _createNewCategorySentinel = '__ACTION_CREATE_NEW_CATEGORY__';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();

    // Load available categories dynamically from existing category source
    final List<String> availableCategories = provider.categories
        .map((Category c) => c.name)
        .where((String name) =>
            name.trim().isNotEmpty &&
            name.trim().toLowerCase() != 'uncategorized')
        .toSet()
        .toList();

    // If existing item has a category not in the list, keep it visible
    if (_category != null &&
        _category!.trim().isNotEmpty &&
        _category != _createNewCategorySentinel &&
        !availableCategories.contains(_category)) {
      availableCategories.insert(0, _category!);
    }
    availableCategories.sort();

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit menu item' : 'Add menu item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: PosTheme.spacingMedium,
            vertical: PosTheme.spacingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Product Name
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Chicken Momo',
                  filled: true,
                  fillColor: PosTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 2. Category (Required - workflow: Name -> Category -> Price)
              const Text(
                'Category *',
                style: TextStyle(fontSize: 13, color: PosTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: ValueKey(_category),
                isExpanded: true,
                initialValue: (_category != null &&
                        _category != _createNewCategorySentinel &&
                        availableCategories.contains(_category))
                    ? _category
                    : null,
                hint: const Text(
                  'Select category',
                  style: TextStyle(color: PosTheme.textMuted, fontSize: 14),
                ),
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    color: PosTheme.textSecondary),
                dropdownColor: PosTheme.surfaceColor,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
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
                items: [
                  ...availableCategories.map((c) {
                    return DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(
                            color: PosTheme.textPrimary, fontSize: 14),
                      ),
                    );
                  }),
                  const DropdownMenuItem<String>(
                    value: _createNewCategorySentinel,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            size: 16, color: PosTheme.primaryColor),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '＋ Create new category',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: PosTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) async {
                  if (v == _createNewCategorySentinel) {
                    final created =
                        await _showAddCategoryDialog(context, provider);
                    if (created != null && created.isNotEmpty) {
                      setState(() {
                        _category = created;
                      });
                    } else {
                      setState(() {});
                    }
                  } else {
                    setState(() {
                      _category = v;
                    });
                  }
                },
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 3. Price
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Price (Rs.) *',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // 4. Other existing fields: Item code
              TextField(
                controller: _codeController,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Item code *',
                  hintText: 'e.g. MN-103',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // Prep time
              TextField(
                controller: _prepController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Prep time (minutes)',
                  hintText: '5',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // Stock quantity
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Stock quantity',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),

              // Availability toggle
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

              // Save button
              SizedBox(
                width: double.infinity,
                child: PosButton(
                  label: _isLoading
                      ? 'Saving...'
                      : (isEditing ? 'Update item' : 'Save item'),
                  onPressed: _isLoading ? null : _saveMenuItem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMenuItem() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final priceText = _priceController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter a product name.');
      return;
    }

    // MANDATORY CATEGORY VALIDATION
    if (_category == null ||
        _category!.trim().isEmpty ||
        _category == _createNewCategorySentinel ||
        _category!.trim().toLowerCase() == 'uncategorized' ||
        _category!.trim().toLowerCase() == 'select category') {
      _showError('Please select a category.');
      return;
    }

    if (code.isEmpty) {
      _showError('Please enter an item code.');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('Please enter a valid price.');
      return;
    }

    final prep = int.tryParse(_prepController.text.trim()) ?? 5;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<POSProvider>();

      if (isEditing) {
        final updatedItem = widget.item!.copyWith(
          name: name,
          itemCode: code,
          category: _category!.trim(),
          price: price,
          preparationMinutes: prep,
          stockQuantity: stock,
          available: _available,
          updatedAt: DateTime.now(),
        );
        await provider.updateMenuItem(updatedItem);
      } else {
        final newItem = MenuItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          itemCode: code,
          category: _category!.trim(),
          price: price,
          stockQuantity: stock,
          preparationMinutes: prep,
          available: _available,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await provider.addMenuItem(newItem);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(e is ArgumentError ? e.message.toString() : 'Failed to save product');
      }
    }
  }

  Future<String?> _showAddCategoryDialog(BuildContext context, POSProvider provider) {
    final catController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: PosTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PosTheme.borderRadius),
        ),
        title: const Text('Add product category',
            style: TextStyle(color: PosTheme.textPrimary, fontSize: 16)),
        content: TextField(
          controller: catController,
          autofocus: true,
          style: const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'e.g. Salads, Soups, Desserts',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, null),
            child: const Text('Cancel',
                style: TextStyle(color: PosTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = catController.text.trim();
              if (newName.isNotEmpty) {
                await provider.addCategory(newName);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx, newName);
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
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _prepController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
