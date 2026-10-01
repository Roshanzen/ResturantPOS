import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/pos_provider.dart';
import 'new_menu_item_screen.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final query = _searchController.text.trim();
    final filtered = _selectedCategory == 'All'
        ? provider.menuItems
        : provider.filterMenuItemsByCategory(_selectedCategory);
    final items = query.isEmpty
        ? filtered
        : provider.searchMenuItems(query);

    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Menu & prices'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewMenuItemScreen()));
              if (result == true && mounted) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add item',
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
              SearchField(
                hintText: 'Search food or item code...',
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              if (provider.menuItems.isNotEmpty) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: () {
                      final categorySet = {
                        'All',
                        ...provider.categories.map((c) => c.name),
                        ...provider.menuItems.map((m) => m.category),
                      };
                      final cats = categorySet
                          .where((c) => c.trim().isNotEmpty)
                          .toList();
                      cats.sort((a, b) {
                        if (a == 'All') return -1;
                        if (b == 'All') return 1;
                        return a.toLowerCase().compareTo(b.toLowerCase());
                      });
                      return cats;
                    }()
                        .map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PosFilterChip(
                          label: cat,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: PosTheme.spacingMedium),
              ],
              if (provider.menuItems.isEmpty)
                EmptyState(
                  title: 'No products yet',
                  subtitle: 'Start by adding your first product to the menu.',
                  actionText: 'Add product',
                  onAction: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NewMenuItemScreen()));
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                )
              else if (items.isEmpty)
                const EmptyState(
                  title: 'No menu items found',
                  subtitle: 'Try a different search or add a new item.',
                )
              else
                Column(
                  children: items.map((item) {
                    return MenuItemCard(
                      item: item,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewMenuItemScreen(item: item),
                          ),
                        );
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
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

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;

  const MenuItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<POSProvider>();
    return PosCard(
      onTap: onTap,
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
                  '${item.category} · ${item.preparationMinutes} min prep · ${item.itemCode}',
                  style:
                      const TextStyle(fontSize: 12, color: PosTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: PosTheme.spacingMedium),
          Text(
            provider.formatCurrency(item.price),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PosTheme.textPrimary),
          ),
          const SizedBox(width: PosTheme.spacingMedium),
          StatusBadge(
            status: item.available ? 'completed' : 'cancelled',
            label: item.available ? 'Available' : 'Unavailable',
          ),
        ],
      ),
    );
  }
}
