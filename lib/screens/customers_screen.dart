import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/pos_provider.dart';
import 'customer_details_screen.dart';
import 'new_customer_screen.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final filtered = provider.searchCustomers(_searchController.text);

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewCustomerScreen()));
              if (result == true && mounted) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('New customer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: PosTheme.primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(PosTheme.spacingMedium),
              child: SearchField(
                hintText: 'Search by name, phone, or address...',
                controller: _searchController,
                onChanged: (q) => setState(() {}),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      title: 'No customers found',
                      subtitle: 'Try a different search or add a new customer.')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: PosTheme.spacingMedium),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: PosTheme.spacingSmall),
                          child: CustomerCard(customer: customer),
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

class CustomerCard extends StatelessWidget {
  final Customer customer;

  const CustomerCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CustomerDetailsScreen(customer: customer)));
      },
      child: PosCard(
        padding: const EdgeInsets.all(PosTheme.cardPadding),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PosTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  customer.initials,
                  style: const TextStyle(
                      color: PosTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: PosTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PosTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${customer.phone} · ${customer.totalVisits} visit${customer.totalVisits != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: PosTheme.textMuted),
                  ),
                  Text(customer.address,
                      style: const TextStyle(
                          fontSize: 12, color: PosTheme.textMuted)),
                ],
              ),
            ),
            Text(
              context.read<POSProvider>().formatCurrency(customer.totalSpent),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PosTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
