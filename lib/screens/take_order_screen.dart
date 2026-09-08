import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/table.dart';
import '../providers/pos_provider.dart';
import 'bills_screen.dart';
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
                    childAspectRatio: 1.1,
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
    final isFree = table.status == 'free';

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderBuilderScreen(table: table)));
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
                Text(table.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PosTheme.textPrimary)),
                StatusBadge(
                    status: table.status,
                    label: table.status == 'active' ? 'Active' : 'Free'),
              ],
            ),
            Text('${table.location} · ${table.capacity} seats',
                style:
                    const TextStyle(fontSize: 12, color: PosTheme.textMuted)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${table.orderCount} order${table.orderCount != 1 ? 's' : ''} · ${context.read<POSProvider>().formatCurrency(table.runningTotal)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: PosTheme.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
                if (isFree)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: PosTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_rounded,
                        size: 18, color: PosTheme.primaryColor),
                  )
                else
                  Icon(Icons.edit_rounded, size: 18, color: PosTheme.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
