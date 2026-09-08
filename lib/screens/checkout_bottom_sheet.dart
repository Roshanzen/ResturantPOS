import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class CheckoutBottomSheet extends StatefulWidget {
  final Order order;

  const CheckoutBottomSheet({super.key, required this.order});

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  String _paymentMethod = 'cash';
  final TextEditingController _discountController =
      TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _discountController.text = widget.order.discount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<POSProvider>();
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final netAmount = widget.order.totalAmount - discount;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: PosTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
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
                  const Text('Checkout',
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
              Text('${widget.order.tableName} · ${widget.order.id}',
                  style: const TextStyle(
                      fontSize: 14, color: PosTheme.textSecondary)),
              const SizedBox(height: PosTheme.spacingLarge),
              ...widget.order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity} × ${item.menuItem.name}',
                          style: const TextStyle(
                              fontSize: 13, color: PosTheme.textPrimary),
                        ),
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
              _buildRow(
                  'Subtotal',
                  provider.formatCurrency(
                      widget.order.totalAmount + widget.order.discount)),
              const SizedBox(height: 4),
              _buildRow('Discount',
                  provider.formatCurrency(widget.order.discount + discount),
                  isNegative: true),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PosTheme.textPrimary)),
                  Text(provider.formatCurrency(netAmount),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PosTheme.primaryColor)),
                ],
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              const Text('Payment method',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PosTheme.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: ['cash', 'fonepay', 'credit']
                    .map(
                      (m) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMethod = m),
                          child: Container(
                            margin:
                                EdgeInsets.only(right: m != 'credit' ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _paymentMethod == m
                                  ? PosTheme.primaryColor.withValues(alpha: 0.2)
                                  : PosTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                  PosTheme.borderRadiusSmall),
                              border: Border.all(
                                  color: _paymentMethod == m
                                      ? PosTheme.primaryColor
                                      : const Color(0xFF444444),
                                  width: 1),
                            ),
                            child: Text(
                              m.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _paymentMethod == m
                                    ? PosTheme.primaryColor
                                    : PosTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Discount (Rs.)',
                  hintText: '0.00',
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
                      label: _isLoading ? 'Processing...' : 'Confirm Checkout',
                      onPressed: _isLoading
                          ? null
                          : () {
                              provider.checkoutOrder(
                                  widget.order.id, _paymentMethod,
                                  discount: discount);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Order completed successfully!'),
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

  Widget _buildRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color:
                    isNegative ? PosTheme.errorColor : PosTheme.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                color: isNegative ? PosTheme.errorColor : PosTheme.textPrimary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
