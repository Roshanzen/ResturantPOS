import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_item.dart';
import '../models/table.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class ConfirmOrderBottomSheet extends StatefulWidget {
  final RestaurantTable table;
  final List<OrderItem> items;

  const ConfirmOrderBottomSheet(
      {super.key, required this.table, required this.items});

  @override
  State<ConfirmOrderBottomSheet> createState() =>
      _ConfirmOrderBottomSheetState();
}

class _ConfirmOrderBottomSheetState extends State<ConfirmOrderBottomSheet> {
  String _selectedTableId = '';
  String _note = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTableId = widget.table.id;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<POSProvider>();
    final subtotal =
        widget.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final total = subtotal;

    return Container(
      decoration: const BoxDecoration(
        color: PosTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(PosTheme.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Confirm order',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PosTheme.textPrimary)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: PosTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              const Text('Table',
                  style: TextStyle(
                      fontSize: 12,
                      color: PosTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: PosTheme.inputBackground,
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTableId,
                    isExpanded: true,
                    dropdownColor: PosTheme.surfaceColor,
                    style: const TextStyle(
                        color: PosTheme.textPrimary, fontSize: 14),
                    items: provider.tables.map((t) {
                      return DropdownMenuItem(
                          value: t.id,
                          child: Text('${t.name} (${t.location})'));
                    }).toList(),
                    onChanged: (v) => setState(
                        () => _selectedTableId = v ?? _selectedTableId),
                  ),
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              const Text('Order items',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PosTheme.textPrimary)),
              const SizedBox(height: 8),
              ...widget.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${item.quantity} × ${item.menuItem.name}',
                            style: const TextStyle(
                                fontSize: 13, color: PosTheme.textPrimary)),
                      ),
                      Text(
                        provider.formatCurrency(item.totalPrice),
                        style: const TextStyle(
                            fontSize: 13,
                            color: PosTheme.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: PosTheme.spacing),
              const Divider(),
              _buildRow('Subtotal', provider.formatCurrency(subtotal)),
              const SizedBox(height: 4),
              _buildRow('Discount', provider.formatCurrency(0)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PosTheme.textPrimary)),
                  Text(provider.formatCurrency(total),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PosTheme.primaryColor)),
                ],
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                onChanged: (v) => setState(() => _note = v),
                maxLines: 2,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Optional note',
                  hintText: 'No sugar, extra ice',
                ),
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              Row(
                children: [
                  Expanded(
                    child: PosButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context),
                        isOutlined: true,
                        isSmall: true),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: PosButton(
                      label: _isLoading ? 'Creating...' : 'Confirm Order',
                      onPressed: _isLoading
                          ? null
                          : () {
                              final table =
                                  provider.getTableById(_selectedTableId) ??
                                      widget.table;
                              provider.createOrder(
                                tableId: table.id,
                                tableName: table.name,
                                items: widget.items,
                                note: _note.isEmpty ? null : _note,
                              );
                              Navigator.pop(context);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Order created successfully!'),
                                    backgroundColor: PosTheme.primaryColor),
                              );
                            },
                      isSmall: true,
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

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: PosTheme.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                color: PosTheme.textPrimary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
