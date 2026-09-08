import 'package:flutter/material.dart';
import '../theme/pos_theme.dart';

class PosBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PosBottomNav(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: const Color(0xFF333333), width: 0.5),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        selectedItemColor: PosTheme.primaryColor,
        unselectedItemColor: PosTheme.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 22,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded,
                  color: PosTheme.primaryColor),
              label: 'Bills'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_rounded),
              activeIcon: Icon(Icons.restaurant_menu_rounded,
                  color: PosTheme.primaryColor),
              label: 'Menu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              activeIcon: Icon(Icons.shopping_cart_rounded,
                  color: PosTheme.primaryColor),
              label: 'Order'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              activeIcon:
                  Icon(Icons.people_rounded, color: PosTheme.primaryColor),
              label: 'Customers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon:
                  Icon(Icons.bar_chart_rounded, color: PosTheme.primaryColor),
              label: 'Analytics'),
        ],
      ),
    );
  }
}
