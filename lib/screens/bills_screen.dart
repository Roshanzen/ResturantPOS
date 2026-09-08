import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/pos_provider.dart';
import 'checkout_bottom_sheet.dart';
import 'take_order_screen.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final filteredOrders = provider.filterOrdersByStatus(_statusFilter);

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bills & checkout'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) =>
                        const TakeOrderScreen(initialTableId: null)),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New order',
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
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Pending bills',
                      value: provider.pendingCount.toString(),
                      subtext: 'Need checkout',
                      accentColor: PosTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Completed today',
                      value: provider.completedTodayCount.toString(),
                      subtext: 'Across loaded orders',
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Visible total',
                      value: provider.formatCurrency(filteredOrders.fold(
                          0.0, (s, o) => s + o.totalAmount)),
                      subtext: 'Current filter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'Pending', 'Completed', 'Cancelled']
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PosFilterChip(
                              label: s,
                              isSelected: _statusFilter == s,
                              onTap: () {
                                setState(() {
                                  _statusFilter = s;
                                });
                              }),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              if (filteredOrders.isEmpty)
                const EmptyState(
                    title: 'No bills found',
                    subtitle: 'Try changing the filter or create a new order.')
              else
                Column(
                  children: filteredOrders.map((order) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: PosTheme.spacingMedium),
                      child: BillCard(order: order),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BillCard extends StatelessWidget {
  final Order order;

  const BillCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<POSProvider>();
    final isPending = order.status == 'pending';

    return PosCard(
      padding: const EdgeInsets.all(PosTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${order.tableName} · ${order.id}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PosTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(provider.formatRelativeTime(order.createdAt),
              style: const TextStyle(fontSize: 12, color: PosTheme.textMuted)),
          const SizedBox(height: PosTheme.spacing),
          Text('${order.items.length} items',
              style: const TextStyle(
                  fontSize: 12,
                  color: PosTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: PosTheme.spacingSmall),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity} × ${item.menuItem.name}',
                      style: const TextStyle(
                          fontSize: 12, color: PosTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.formatCurrency(item.totalPrice),
                    style: const TextStyle(
                        fontSize: 12,
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
              PriceText(
                  amount: order.totalAmount,
                  style: const TextStyle(fontSize: 15)),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: PosTheme.spacingMedium),
            SizedBox(
              width: double.infinity,
              child: PosButton(
                label: 'Checkout',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => ChangeNotifierProvider.value(
                      value: provider,
                      child: CheckoutBottomSheet(order: order),
                    ),
                  );
                },
                isSmall: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
