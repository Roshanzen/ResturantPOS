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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PosTheme.spacingMedium,
                PosTheme.spacingMedium,
                PosTheme.spacingMedium,
                PosTheme.spacingSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose a table',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PosTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Tap a numbered table to open its menu',
                          style: TextStyle(
                            fontSize: 12,
                            color: PosTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: PosTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF444444), width: 0.5),
                        ),
                        child: Text(
                          '${provider.tables.length} tables',
                          style: const TextStyle(
                            fontSize: 12,
                            color: PosTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add table',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          foregroundColor: PosTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: provider.tables.isEmpty
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(PosTheme.spacingMedium),
                      child: EmptyState(
                        title: 'No tables configured',
                        subtitle:
                            'Add your first table to start taking orders.',
                        actionText: 'Add table',
                        onAction: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NewTableScreen()),
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isMultiColumn = constraints.maxWidth >= 600;
                        if (!isMultiColumn) {
                          // Clean single-column vertical list for mobile phones (360px - 430px)
                          return ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              PosTheme.spacingMedium,
                              PosTheme.spacingSmall,
                              PosTheme.spacingMedium,
                              PosTheme.spacingLarge + 16,
                            ),
                            itemCount: provider.tables.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: PosTheme.spacingMedium),
                            itemBuilder: (context, index) {
                              final table = provider.tables[index];
                              return TableCard(table: table);
                            },
                          );
                        } else {
                          // Multi-column responsive grid for tablets and wide screens
                          final crossAxisCount =
                              (constraints.maxWidth / 320).floor().clamp(2, 4);
                          return GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              PosTheme.spacingMedium,
                              PosTheme.spacingSmall,
                              PosTheme.spacingMedium,
                              PosTheme.spacingLarge + 16,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: PosTheme.spacingMedium,
                              mainAxisSpacing: PosTheme.spacingMedium,
                              mainAxisExtent: 225,
                            ),
                            itemCount: provider.tables.length,
                            itemBuilder: (context, index) {
                              final table = provider.tables[index];
                              return TableCard(table: table);
                            },
                          );
                        }
                      },
                    ),
            ),
          ],
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
    final provider = context.watch<POSProvider>();
    final isFree = table.status == 'free';
    final activeOrder = provider.getActiveOrderForTable(table.id);

    return PosCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        if (isFree) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderBuilderScreen(table: table),
            ),
          );
        } else if (activeOrder != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ActiveOrderScreen(table: table, order: activeOrder),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Table number, Status badge, Edit icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  table.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: PosTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                status: table.status,
                label: table.status == 'active' ? 'Active' : 'Free',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewTableScreen(table: table),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: PosTheme.textMuted),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                splashRadius: 18,
                tooltip: 'Edit table',
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 2. Information: Location / Seats
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined,
                  size: 13, color: PosTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                '${table.location} · ${table.capacity} seats',
                style: const TextStyle(
                  fontSize: 12,
                  color: PosTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // Order count and running total
          Row(
            children: [
              const Icon(Icons.receipt_outlined,
                  size: 13, color: PosTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                '${table.orderCount} order${table.orderCount != 1 ? 's' : ''} · ${provider.formatCurrency(table.runningTotal)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: PosTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // 3. Action Buttons (Cleanly contained INSIDE the card)
          if (!isFree && activeOrder != null) ...[
            const SizedBox(height: 12),
            // View Order (full width secondary outline button)
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ActiveOrderScreen(table: table, order: activeOrder),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text(
                  'View Order',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PosTheme.textPrimary,
                  side: const BorderSide(color: Color(0xFF444444), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                  ),
                  backgroundColor: PosTheme.surfaceColor,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // [ Add Product ] and [ Checkout ] side-by-side
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderBuilderScreen(
                              table: table,
                              existingOrder: activeOrder,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded,
                          size: 14),
                      label: const Text(
                        'Add Product',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PosTheme.primaryColor,
                        side: const BorderSide(
                            color: PosTheme.primaryColor, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              PosTheme.borderRadiusSmall),
                        ),
                        backgroundColor:
                            PosTheme.primaryColor.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
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
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 15),
                      label: const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PosTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              PosTheme.borderRadiusSmall),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isFree) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderBuilderScreen(table: table),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text(
                  'Take Order',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PosTheme.primaryColor.withValues(alpha: 0.15),
                  foregroundColor: PosTheme.primaryColor,
                  side: const BorderSide(
                      color: PosTheme.primaryColor, width: 0.8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderBuilderScreen(table: table),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text(
                  'New Order',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PosTheme.surfaceColor,
                  foregroundColor: PosTheme.textPrimary,
                  side: const BorderSide(color: Color(0xFF444444), width: 1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                  ),
                ),
              ),
            ),
          ],
        ],
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

