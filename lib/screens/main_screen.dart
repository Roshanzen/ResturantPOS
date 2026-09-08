import 'package:flutter/material.dart';
import 'analytics_screen.dart';
import 'bills_screen.dart';
import 'customers_screen.dart';
import 'menu_screen.dart';
import 'take_order_screen.dart';
import '../theme/pos_theme.dart';
import '../widgets/bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BillsScreen(),
    MenuScreen(),
    TakeOrderScreen(),
    CustomersScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: PosBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
