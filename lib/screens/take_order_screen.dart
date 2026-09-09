import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/table.dart';
import '../providers/pos_provider.dart';
import 'bills_screen.dart';
import 'checkout_bottom_sheet.dart';
import 'new_table_screen.dart';
import 'order_builder_screen.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class TakeOrderScreen extends StatefulWidget {
  final String? initialTableId;

  const TakeOrderScreen({super.key, this.initialTableId});

  @override
  State<TakeOrderScreen> createState() => _TakeOrderScreenState();
}

class _TakeOrderScreenState extends State<TakeOrderScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Take order'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BillsScreen()),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text('View bills',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style:
                TextButton.styleFrom(foregroundColor: PosTheme.textSecondary),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Choose a table',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: PosTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Tap a numbered table to open its menu',
                            style: TextStyle(
                                fontSize: 13, color: PosTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: PosTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF444444), width: 0.5),
                        ),
                        child: Text('${provider.tables.length} tables',
                            style: const TextStyle(
                                fontSize: 12,
                                color: PosTheme.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NewTableScreen()),
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add table',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          foregroundColor: PosTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              if (provider.tables.isEmpty)
                const EmptyState(
                  title: 'No tables yet',
                  subtitle: 'Add your first table to start taking orders.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.tables.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: PosTheme.spacingMedium,
                    mainAxisSpacing: PosTheme.spacingMedium,
                  ),
                  itemBuilder: (context, index) {
                    final table = provider.tables[index];
                    return TableCard(table: table);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TableCard extends StatelessWidget {
  final RestaurantTable table;

  const TableCard({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<POSProvider>();
    final isFree = table.status == 'free';
    final activeOrder = provider.getActiveOrderForTable(table.id);

    return GestureDetector(
      onTap: () {
        if (isFree) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OrderBuilderScreen(table: table)));
        } else if (activeOrder != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ActiveOrderScreen(table: table, order: activeOrder)));
        }
      },
      child: PosCard(
        padding: const EdgeInsets.all(PosTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(table.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PosTheme.textPrimary)),
                ),
                Row(
                  children: [
                    StatusBadge(
                        status: table.status,
                        label: table.status == 'active' ? 'Active' : 'Free'),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    NewTableScreen(table: table)));
                      },
                      icon: Icon(Icons.edit_rounded,
                          size: 16, color: PosTheme.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            Text('${table.location} · ${table.capacity} seats',
                style:
                    const TextStyle(fontSize: 12, color: PosTheme.textMuted)),
            Text(
              '${table.orderCount} order${table.orderCount != 1 ? 's' : ''} · ${context.read<POSProvider>().formatCurrency(table.runningTotal)}',
              style: const TextStyle(
                  fontSize: 12,
                  color: PosTheme.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
            if (!isFree && activeOrder != null)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ActiveOrderScreen(
                                  table: table, order: activeOrder)));
                    },
                    child: const Text('View Order'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => OrderBuilderScreen(
                                  table: table,
                                  existingOrder: activeOrder)));
                    },
                    child: const Text('Add Product'),
                  ),
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => ChangeNotifierProvider.value(
                          value: provider,
                          child: CheckoutBottomSheet(order: activeOrder),
                        ),
                      );
                    },
                    child: const Text('Checkout'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ActiveOrderScreen extends StatefulWidget {
  final RestaurantTable table;
  final Order order;

  const ActiveOrderScreen({super.key, required this.table, required this.order});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: Text('${widget.table.name} · ${widget.order.id}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PosTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: widget.order.status),
                  Text(
                    provider.formatRelativeTime(widget.order.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: PosTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              Text('${widget.order.items.length} item${widget.order.items.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: PosTheme.textSecondary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: PosTheme.spacingSmall),
              ...widget.order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity} × ${item.menuItem.name}',
                          style: const TextStyle(
                              fontSize: 13, color: PosTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
              const SizedBox(height: PosTheme.spacingSmall),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PosTheme.textPrimary)),
                  Text(provider.formatCurrency(widget.order.totalAmount),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PosTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderBuilderScreen(
                              table: widget.table,
                              existingOrder: widget.order,
                            ),
                          ),
                        );
                      },
                      child: const Text('Add Product'),
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: PosButton(
                      label: 'Checkout',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) =>
                              ChangeNotifierProvider.value(
                            value: provider,
                            child: CheckoutBottomSheet(order: widget.order),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacing),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Order?'),
                            content: Text(
                                'Are you sure you want to cancel order ${widget.order.id}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Keep Order'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  provider.cancelOrder(widget.order.id);
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Order cancelled successfully'),
                                        backgroundColor:
                                            PosTheme.primaryColor),
                                  );
                                },
                                child: const Text('Cancel Order',
                                    style: TextStyle(
                                        color: PosTheme.errorColor)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Cancel Order'),
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
}

