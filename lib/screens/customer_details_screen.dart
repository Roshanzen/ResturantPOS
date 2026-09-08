import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final customerOrders =
        provider.orders.where((o) => o.customerId == customer.id).toList();

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: Text(customer.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PosTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: PosTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Center(
                    child: Text(
                      customer.initials,
                      style: const TextStyle(
                          color: PosTheme.primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Total spent',
                      value: provider.formatCurrency(customer.totalSpent),
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Visits',
                      value: customer.totalVisits.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              _buildInfoRow('Phone', customer.phone),
              _buildInfoRow('Address', customer.address),
              _buildInfoRow('Credit balance',
                  provider.formatCurrency(customer.creditBalance)),
              const SizedBox(height: PosTheme.spacingLarge),
              const Text('Recent orders',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PosTheme.textPrimary)),
              const SizedBox(height: PosTheme.spacingMedium),
              if (customerOrders.isEmpty)
                const EmptyState(
                    title: 'No orders yet', icon: Icons.receipt_long_rounded)
              else
                ...customerOrders.map((order) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: PosTheme.spacingSmall),
                    child: PosCard(
                      padding: const EdgeInsets.all(PosTheme.cardPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${order.tableName} · ${order.id}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: PosTheme.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${order.items.length} items',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: PosTheme.textMuted)),
                              ],
                            ),
                          ),
                          StatusBadge(status: order.status),
                          const SizedBox(width: 8),
                          Text(provider.formatCurrency(order.totalAmount),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: PosTheme.textPrimary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, color: PosTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PosTheme.textPrimary)),
        ],
      ),
    );
  }
}
