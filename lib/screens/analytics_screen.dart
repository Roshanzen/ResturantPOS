import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';
import 'expenses_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Daily service analytics'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesScreen()),
              );
            },
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: const Text('Expenses',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: PosTheme.warningColor),
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
              const SectionHeader(title: 'KPI overview'),
              const SizedBox(height: PosTheme.spacingSmall),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: PosTheme.spacingMedium,
                mainAxisSpacing: PosTheme.spacingMedium,
                children: [
                  MetricCard(
                      label: 'Total revenue',
                      value: provider.formatCurrency(provider.totalRevenue)),
                  MetricCard(
                      label: 'Net sales',
                      value: provider.formatCurrency(provider.netAmount)),
                  MetricCard(
                      label: 'Operating expenses',
                      value: provider.formatCurrency(provider.totalExpenses),
                      subtext: '${provider.expenses.length} recorded',
                      accentColor: PosTheme.warningColor),
                  MetricCard(
                      label: 'Net profit',
                      value: provider.formatCurrency(provider.netProfit),
                      subtext: 'Sales - Expenses',
                      accentColor: provider.netProfit >= 0
                          ? PosTheme.primaryColor
                          : PosTheme.errorColor),
                  MetricCard(
                      label: 'Discounts',
                      value: provider.formatCurrency(provider.totalDiscount)),
                  MetricCard(
                      label: 'Orders',
                      value: provider.totalOrdersCount.toString(),
                      subtext: 'Total orders'),
                ],
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              const SectionHeader(title: 'Payment collections'),
              const SizedBox(height: PosTheme.spacingSmall),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Cash',
                      value: provider.formatCurrency(provider.cashCollection),
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Fonepay',
                      value:
                          provider.formatCurrency(provider.fonepayCollection),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacing),
              MetricCard(
                label: 'Credit collected',
                value: provider.formatCurrency(provider.creditCollected),
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              PosCard(
                padding: const EdgeInsets.all(PosTheme.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Credit analytics',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PosTheme.textPrimary)),
                    const SizedBox(height: PosTheme.spacingSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Outstanding credit',
                            style: TextStyle(
                                fontSize: 13, color: PosTheme.textSecondary)),
                        Text(
                            provider.formatCurrency(provider.outstandingCredit),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: PosTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: PosTheme.spacingSmall),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.track_changes_rounded, size: 16),
                      label: const Text('Track collections',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                        'Completed credit sales are included in collected credit. Pending credit remains outstanding until checkout.',
                        style:
                            TextStyle(fontSize: 11, color: PosTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              SectionHeader(
                title: 'Operating expenses',
                actionText: 'Manage expenses',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                  );
                },
              ),
              const SizedBox(height: PosTheme.spacingSmall),
              if (provider.expenses.isEmpty)
                PosCard(
                  padding: const EdgeInsets.all(PosTheme.cardPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'No operating expenses recorded',
                        style: TextStyle(
                            fontSize: 13, color: PosTheme.textMuted),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ExpensesScreen()),
                          );
                        },
                        child: const Text('Add expense'),
                      ),
                    ],
                  ),
                )
              else
                PosCard(
                  padding: const EdgeInsets.all(PosTheme.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: PosTheme.textSecondary,
                            ),
                          ),
                          Text(
                            provider.formatCurrency(provider.totalExpenses),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: PosTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      ...provider.expensesByCategory.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(
                                      fontSize: 13, color: PosTheme.textPrimary)),
                              Text(
                                provider.formatCurrency(entry.value),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PosTheme.textSecondary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              const SizedBox(height: PosTheme.spacingLarge),
              const Text('Hourly sales velocity',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PosTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Completed sales from the last 24 hours.',
                  style: TextStyle(fontSize: 12, color: PosTheme.textMuted)),
              const SizedBox(height: PosTheme.spacingMedium),
              _HourlySalesChart(provider: provider),
              const SizedBox(height: PosTheme.spacingLarge),
              const SectionHeader(title: 'Order status'),
              const SizedBox(height: PosTheme.spacingSmall),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Completed',
                      value: provider.completedTodayCount.toString(),
                      accentColor: PosTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Pending',
                      value: provider.pendingCount.toString(),
                      accentColor: PosTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: PosTheme.spacing),
                  Expanded(
                    child: MetricCard(
                      label: 'Cancelled',
                      value: provider.cancelledCount.toString(),
                      accentColor: PosTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              const Text('Top-selling items',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PosTheme.textPrimary)),
              const SizedBox(height: PosTheme.spacingMedium),
              if (provider.getTopSellingItems().isEmpty)
                const EmptyState(
                  title: 'Not enough data yet',
                  subtitle: 'Completed orders will populate top selling items.',
                  icon: Icons.trending_up_rounded,
                )
              else
                ...provider.getTopSellingItems().map((entry) {
                final item = entry.key;
                final sold = entry.value;
                final revenue = item.price * sold;
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
                            Text('$sold sold · ${item.category}',
                                style: const TextStyle(
                                    fontSize: 12, color: PosTheme.textMuted)),
                          ],
                        ),
                      ),
                      Text(
                        provider.formatCurrency(revenue),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PosTheme.textPrimary),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HourlySalesChart extends StatelessWidget {
  final POSProvider provider;

  const _HourlySalesChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final hourly = provider.getHourlySales();
    final entries = hourly.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return const EmptyState(
          title: 'Not enough data yet',
          subtitle: 'Completed sales from the last 24 hours will appear here.',
          icon: Icons.show_chart_rounded);
    }
    final maxValue =
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: entries.map((entry) {
        final time = entry.key;
        final value = entry.value;
        final barWidth = maxValue > 0 ? (value / maxValue) : 0.0;
        final timeParts = time.split(':');
        final hour = int.parse(timeParts[0]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final displayTime = '$displayHour:00 $period';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                  width: 64,
                  child: Text(displayTime,
                      style: const TextStyle(
                          fontSize: 12,
                          color: PosTheme.textMuted,
                          fontWeight: FontWeight.w500))),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                          color: PosTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    FractionallySizedBox(
                      widthFactor: barWidth,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: PosTheme.primaryColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                  width: 80,
                  child: Text(provider.formatCurrency(value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12,
                          color: PosTheme.textPrimary,
                          fontWeight: FontWeight.w600))),
            ],
          ),
        );
      }).toList(),
    );
  }
}
