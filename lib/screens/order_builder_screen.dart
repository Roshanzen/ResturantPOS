import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/order_item.dart';
import '../models/table.dart';
import '../providers/pos_provider.dart';
import 'confirm_order_bottom_sheet.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class OrderBuilderScreen extends StatefulWidget {
  final RestaurantTable table;

  const OrderBuilderScreen({super.key, required this.table});

  @override
  State<OrderBuilderScreen> createState() => _OrderBuilderScreenState();
}

class _OrderBuilderScreenState extends State<OrderBuilderScreen> {
  String _selectedCategory = 'All';
  final Map<String, int> _quantities = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final items = _selectedCategory == 'All'
        ? provider.menuItems
        : provider.filterMenuItemsByCategory(_selectedCategory);

    final categories = [
      'All',
      ...provider.menuItems.map((m) => m.category).toSet().toList()
    ];
    final totalItems = _quantities.values.fold(0, (sum, q) => sum + q);
    final totalAmount = _quantities.entries.fold(0.0, (sum, entry) {
      final item =
          provider.menuItems.firstWhere((m) => m.itemCode == entry.key);
      return sum + (item.price * entry.value);
    });

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Table ${widget.table.name.split(' ').last}'),
        actions: [
          if (totalItems > 0)
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) {
                    final orderItems = _quantities.entries.map((entry) {
                      final item = provider.menuItems
                          .firstWhere((m) => m.itemCode == entry.key);
                      return OrderItem(menuItem: item, quantity: entry.value);
                    }).toList();
                    return ConfirmOrderBottomSheet(
                      table: widget.table,
                      items: orderItems,
                    );
                  },
                ).then((result) {
                  if (result == true) {
                    setState(() => _quantities.clear());
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: PosTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Confirm ($totalItems)',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: PosTheme.spacingMedium,
                  vertical: PosTheme.spacingSmall),
              decoration: const BoxDecoration(
                  color: PosTheme.cardColor,
                  border: Border(
                      bottom:
                          BorderSide(color: Color(0xFF333333), width: 0.5))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Table ${widget.table.name.split(' ').last}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PosTheme.textPrimary),
                    ),
                  ),
                  Text(
                    '${_quantities.length} item${_quantities.length != 1 ? 's' : ''} · ${provider.formatCurrency(totalAmount)}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: PosTheme.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: PosTheme.spacingMedium, vertical: 4),
                children: categories
                    .map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PosFilterChip(
                            label: cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () =>
                                setState(() => _selectedCategory = cat)),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(PosTheme.spacingMedium),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final qty = _quantities[item.itemCode] ?? 0;
                  return MenuOrderItemCard(
                    item: item,
                    quantity: qty,
                    onIncrement: () =>
                        setState(() => _quantities[item.itemCode] = (qty + 1)),
                    onDecrement: () {
                      if (qty > 0) {
                        final newQty = qty - 1;
                        if (newQty == 0) {
                          _quantities.remove(item.itemCode);
                        } else {
                          _quantities[item.itemCode] = newQty;
                        }
                        setState(() {});
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuOrderItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const MenuOrderItemCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<POSProvider>();
    return PosCard(
      padding: const EdgeInsets.symmetric(
          horizontal: PosTheme.cardPadding, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PosTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${item.category} · ${item.preparationMinutes} min · ${item.itemCode}',
                  style:
                      const TextStyle(fontSize: 12, color: PosTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: PosTheme.spacingMedium),
          Text(provider.formatCurrency(item.price),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PosTheme.textPrimary)),
          const SizedBox(width: PosTheme.spacingMedium),
          Row(
            children: [
              GestureDetector(
                onTap: quantity > 0 ? onDecrement : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: quantity > 0
                        ? PosTheme.surfaceColor
                        : PosTheme.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFF444444), width: 0.5),
                  ),
                  child: Icon(Icons.remove_rounded,
                      size: 16,
                      color: quantity > 0
                          ? PosTheme.textPrimary
                          : PosTheme.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PosTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PosTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
