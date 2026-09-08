import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/core/database/database_service_native.dart';
import 'package:restaurant_pos/models/customer.dart';
import 'package:restaurant_pos/models/menu_item.dart';
import 'package:restaurant_pos/models/order_item.dart';
import 'package:restaurant_pos/models/table.dart';
import 'package:restaurant_pos/providers/pos_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('POSProvider', () {
    late POSProvider provider;
    late NativeDatabaseService database;

    setUp(() async {
      database = NativeDatabaseService();
      await database.initialize();
      await database.seedInitialData();
      provider = POSProvider(database: database);
      await provider.init();
    });

    test('initializes with database data', () async {
      expect(provider.tables.length, greaterThanOrEqualTo(1));
      expect(provider.menuItems.length, greaterThanOrEqualTo(1));
      expect(provider.customers.length, greaterThanOrEqualTo(1));
    });

    test('getTableById returns correct table', () {
      final table = provider.getTableById('table_1');
      expect(table, isNotNull);
      expect(table!.name, 'Table 1');
    });

    test('getTableById returns null for unknown id', () {
      final table = provider.getTableById('unknown');
      expect(table, isNull);
    });

    test('getMenuItemByCode returns correct item', () {
      final item = provider.getMenuItemByCode('MN-103');
      expect(item, isNotNull);
      expect(item!.name, 'Chocolate Truffle Cake');
    });

    test('searchMenuItems filters by name', () {
      final results = provider.searchMenuItems('Chicken');
      expect(results.length, greaterThan(1));
      expect(results.any((m) => m.name == 'Chicken Sekuwa'), isTrue);
    });

    test('searchMenuItems filters by item code', () {
      final results = provider.searchMenuItems('MN-103');
      expect(results.length, 1);
      expect(results.first.name, 'Chocolate Truffle Cake');
    });

    test('searchMenuItems returns all for empty query', () {
      final results = provider.searchMenuItems('');
      expect(results.length, provider.menuItems.length);
    });

    test('filterMenuItemsByCategory returns correct items', () {
      final results = provider.filterMenuItemsByCategory('Cake');
      expect(results.length, greaterThan(1));
      expect(results.every((m) => m.category == 'Cake'), isTrue);
    });

    test('filterOrdersByStatus returns all for All', () {
      final results = provider.filterOrdersByStatus('All');
      expect(results.length, provider.orders.length);
    });

    test('createOrder creates pending order and updates table', () async {
      final initialPending = provider.pendingCount;
      final order = await provider.createOrder(
        tableId: 'table_5',
        tableName: 'Table 5',
        items: [OrderItem(menuItem: provider.menuItems.first, quantity: 1)],
      );
      expect(order.status, 'pending');
      expect(provider.pendingCount, initialPending + 1);
      final table = provider.getTableById('table_5');
      expect(table!.status, 'active');
    });

    test('checkoutOrder completes order and updates table', () async {
      final pendingOrders = provider.pendingOrders.toList();
      if (pendingOrders.isEmpty) {
        final order = await provider.createOrder(
          tableId: 'table_5',
          tableName: 'Table 5',
          items: [OrderItem(menuItem: provider.menuItems.first, quantity: 1)],
        );
        await provider.checkoutOrder(order.id, 'cash');
      } else {
        await provider.checkoutOrder(pendingOrders.first.id, 'cash');
      }
      final completed = provider.completedOrders.length;
      expect(completed, greaterThan(0));
    });

    test('cancelOrder marks order as cancelled', () async {
      final pendingOrders = provider.pendingOrders.toList();
      if (pendingOrders.isEmpty) return;
      await provider.cancelOrder(pendingOrders.first.id);
      final updated =
          provider.orders.firstWhere((o) => o.status == 'cancelled');
      expect(updated.status, 'cancelled');
    });

    test('addCustomer adds new customer', () async {
      final initialCount = provider.customers.length;
      await provider.addCustomer(Customer(
        id: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test User',
        phone: '9800000000',
        address: 'Test',
        initials: 'TU',
      ));
      expect(provider.customers.length, initialCount + 1);
    });

    test('searchCustomers filters by name', () {
      final results = provider.searchCustomers('Aayush');
      expect(results.length, 1);
      expect(results.first.name, 'Aayush Shrestha');
    });

    test('searchCustomers filters by phone', () {
      final results = provider.searchCustomers('9801894321');
      expect(results.length, 1);
    });

    test('analytics calculate correctly', () {
      expect(provider.totalOrdersCount, greaterThanOrEqualTo(0));
      expect(provider.completedTodayCount, greaterThanOrEqualTo(0));
      expect(provider.pendingCount, greaterThanOrEqualTo(0));
      expect(provider.cancelledCount, greaterThanOrEqualTo(0));
      expect(
          provider.totalOrdersCount,
          equals(provider.completedTodayCount +
              provider.pendingCount +
              provider.cancelledCount));
    });

    test('top selling items returns sorted list', () {
      final top = provider.getTopSellingItems();
      expect(top.isNotEmpty, isTrue);
      for (int i = 0; i < top.length - 1; i++) {
        expect(top[i].value >= top[i + 1].value, isTrue);
      }
    });

    test('formatCurrency formats correctly', () {
      expect(provider.formatCurrency(100.0), 'Rs. 100.00');
      expect(provider.formatCurrency(1234.5), 'Rs. 1,234.50');
    });

    test('formatRelativeTime returns correct strings', () {
      final now = DateTime.now();
      expect(
          provider
              .formatRelativeTime(now.subtract(const Duration(seconds: 30))),
          'a moment ago');
      expect(
          provider
              .formatRelativeTime(now.subtract(const Duration(minutes: 30))),
          '30 minutes ago');
    });

    test('payment collections calculate correctly', () {
      expect(provider.cashCollection, greaterThanOrEqualTo(0));
      expect(provider.fonepayCollection, greaterThanOrEqualTo(0));
      expect(provider.creditCollected, greaterThanOrEqualTo(0));
    });
  });

  group('OrderItem', () {
    test('totalPrice calculates correctly', () {
      final item = MenuItem(
          id: '1',
          name: 'Test',
          itemCode: 'T1',
          price: 100.0,
          category: 'Test',
          stockQuantity: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now());
      final orderItem = OrderItem(menuItem: item, quantity: 3);
      expect(orderItem.totalPrice, 300.0);
    });

    test('totalPrice is 0 for quantity 0', () {
      final item = MenuItem(
          id: '1',
          name: 'Test',
          itemCode: 'T1',
          price: 100.0,
          category: 'Test',
          stockQuantity: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now());
      final orderItem = OrderItem(menuItem: item, quantity: 0);
      expect(orderItem.totalPrice, 0.0);
    });
  });

  group('RestaurantTable', () {
    test('copyWith creates updated copy', () {
      final table = RestaurantTable(
          id: '1',
          name: 'Table 1',
          status: 'free',
          orderCount: 0,
          runningTotal: 0.0);
      final updated = table.copyWith(status: 'active', orderCount: 1);
      expect(updated.status, 'active');
      expect(updated.orderCount, 1);
      expect(table.status, 'free');
    });
  });

  group('Customer', () {
    test('copyWith creates updated copy', () {
      final customer = Customer(
          id: '1', name: 'Test', phone: '123', address: 'Addr', initials: 'T');
      final updated = customer.copyWith(totalSpent: 500.0, totalVisits: 3);
      expect(updated.totalSpent, 500.0);
      expect(updated.totalVisits, 3);
    });
  });
}
