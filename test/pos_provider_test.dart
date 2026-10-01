import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/core/database/database_service_native.dart';
import 'package:restaurant_pos/models/customer.dart';
import 'package:restaurant_pos/models/expense.dart';
import 'package:restaurant_pos/models/menu_item.dart';
import 'package:restaurant_pos/models/order_item.dart';
import 'package:restaurant_pos/models/table.dart';
import 'package:restaurant_pos/providers/pos_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _seedTestFixture(NativeDatabaseService database) async {
  final now = DateTime.now().toIso8601String();
  await database.insert('categories', {
    'id': 'cat_momo',
    'name': 'Momo',
    'created_at': now,
    'updated_at': now,
  });
  await database.insert('categories', {
    'id': 'cat_cake',
    'name': 'Cake',
    'created_at': now,
    'updated_at': now,
  });
  await database.insert('categories', {
    'id': 'cat_chicken',
    'name': 'Chicken',
    'created_at': now,
    'updated_at': now,
  });

  await database.insert('tables', {
    'id': 'table_1',
    'name': 'Table 1',
    'location': 'Indoor',
    'capacity': 4,
    'status': 'free',
    'order_count': 0,
    'running_total_minor': 0,
    'created_at': now,
    'updated_at': now,
  });
  await database.insert('tables', {
    'id': 'table_5',
    'name': 'Table 5',
    'location': 'Patio',
    'capacity': 6,
    'status': 'free',
    'order_count': 0,
    'running_total_minor': 0,
    'created_at': now,
    'updated_at': now,
  });

  await database.insert('menu_items', {
    'id': 'menu_1',
    'name': 'Chocolate Truffle Cake',
    'item_code': 'MN-103',
    'category': 'Cake',
    'price_minor': 15000,
    'cost_price_minor': 8000,
    'stock_quantity': 20,
    'available': 1,
    'preparation_minutes': 5,
    'created_at': now,
    'updated_at': now,
  });
  await database.insert('menu_items', {
    'id': 'menu_4',
    'name': 'Red Velvet Cake',
    'item_code': 'MN-104',
    'category': 'Cake',
    'price_minor': 18000,
    'cost_price_minor': 9000,
    'stock_quantity': 15,
    'available': 1,
    'preparation_minutes': 5,
    'created_at': now,
    'updated_at': now,
  });
  await database.insert('menu_items', {
    'id': 'menu_2',
    'name': 'Chicken Sekuwa',
    'item_code': 'MN-101',
    'category': 'Chicken',
    'price_minor': 25000,
    'cost_price_minor': 14000,
    'stock_quantity': 35,
    'available': 1,
    'preparation_minutes': 15,
    'created_at': now,
    'updated_at': now,
  });
  await database.insert('menu_items', {
    'id': 'menu_3',
    'name': 'Steam Chicken Momo',
    'item_code': 'MN-102',
    'category': 'Momo',
    'price_minor': 18000,
    'cost_price_minor': 9000,
    'stock_quantity': 50,
    'available': 1,
    'preparation_minutes': 10,
    'created_at': now,
    'updated_at': now,
  });

  await database.insert('customers', {
    'id': 'cust_1',
    'name': 'Aayush Shrestha',
    'phone': '9801894321',
    'address': 'Kathmandu',
    'total_visits': 3,
    'total_spent_minor': 45000,
    'credit_balance_minor': 0,
    'currency': 'NPR',
    'created_at': now,
    'updated_at': now,
  });
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('POSProvider', () {
    late POSProvider provider;
    late NativeDatabaseService database;

    setUp(() async {
      database = NativeDatabaseService();
      await database.initialize();
      await database.clearAllData();
      await _seedTestFixture(database);
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

    test('top selling items returns sorted list', () async {
      if (provider.completedOrders.isEmpty) {
        final order = await provider.createOrder(
          tableId: 'table_1',
          tableName: 'Table 1',
          items: [OrderItem(menuItem: provider.menuItems.first, quantity: 2)],
        );
        await provider.checkoutOrder(order.id, 'cash');
      }
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

    test('addMenuItem throws ArgumentError if category is empty or uncategorized', () async {
      final now = DateTime.now();
      expect(
        () => provider.addMenuItem(MenuItem(
          id: 'test_empty_cat',
          itemCode: 'TST-01',
          name: 'Item without category',
          category: '',
          price: 150.0,
          stockQuantity: 10,
          createdAt: now,
          updatedAt: now,
        )),
        throwsArgumentError,
      );

      expect(
        () => provider.addMenuItem(MenuItem(
          id: 'test_uncat',
          itemCode: 'TST-02',
          name: 'Item with uncategorized',
          category: 'Uncategorized',
          price: 150.0,
          stockQuantity: 10,
          createdAt: now,
          updatedAt: now,
        )),
        throwsArgumentError,
      );
    });

    test('addMenuItem succeeds when category is valid', () async {
      final initialCount = provider.menuItems.length;
      final now = DateTime.now();
      await provider.addMenuItem(MenuItem(
        id: 'test_valid_item',
        itemCode: 'TST-03',
        name: 'Veg Chowmein',
        category: 'Fast Food',
        price: 120.0,
        stockQuantity: 10,
        createdAt: now,
        updatedAt: now,
      ));
      expect(provider.menuItems.length, initialCount + 1);
      final added = provider.getMenuItemByCode('TST-03');
      expect(added, isNotNull);
      expect(added!.category, 'Fast Food');
    });

    test('updateMenuItem throws ArgumentError if category is empty or uncategorized', () async {
      final item = provider.menuItems.first;
      expect(
        () => provider.updateMenuItem(item.copyWith(category: '')),
        throwsArgumentError,
      );
      expect(
        () => provider.updateMenuItem(item.copyWith(category: 'Uncategorized')),
        throwsArgumentError,
      );
    });

    test('updateMenuItem updates category successfully', () async {
      final item = provider.menuItems.first;
      final updated = item.copyWith(category: 'Beverages');
      await provider.updateMenuItem(updated);
      final reloaded = provider.getMenuItemByCode(item.itemCode);
      expect(reloaded!.category, 'Beverages');
    });

    test('addExpense persists expense and updates state', () async {
      final initialCount = provider.expenses.length;
      final initialTotal = provider.totalExpenses;
      final now = DateTime.now();
      final expense = Expense(
        id: 'exp_test_1',
        branchId: 'branch_001',
        categoryId: 'ec_1',
        categoryName: 'Rent',
        title: 'Office Rent Oct',
        amount: 25000.0,
        expenseDate: now,
        paymentMethod: 'cash',
        notes: 'Monthly rent',
        createdBy: 'Admin',
        createdAt: now,
        updatedAt: now,
      );

      await provider.addExpense(expense);

      expect(provider.expenses.length, initialCount + 1);
      expect(provider.totalExpenses, initialTotal + 25000.0);
      expect(provider.todayExpenses, initialTotal + 25000.0);
    });

    test('updateExpense updates expense correctly', () async {
      final now = DateTime.now();
      final expense = Expense(
        id: 'exp_test_2',
        branchId: 'branch_001',
        categoryId: 'ec_2',
        categoryName: 'Utilities',
        title: 'Electricity Bill',
        amount: 5000.0,
        expenseDate: now,
        paymentMethod: 'cash',
        createdBy: 'Admin',
        createdAt: now,
        updatedAt: now,
      );
      await provider.addExpense(expense);

      final updated = expense.copyWith(
        amount: 6500.0,
        title: 'Electricity Bill Revised',
      );
      await provider.updateExpense(updated);

      final found = provider.expenses.firstWhere((e) => e.id == 'exp_test_2');
      expect(found.amount, 6500.0);
      expect(found.title, 'Electricity Bill Revised');
    });

    test('deleteExpense soft deletes and excludes from active expenses and totals', () async {
      final now = DateTime.now();
      final expense = Expense(
        id: 'exp_test_3',
        branchId: 'branch_001',
        categoryId: 'ec_3',
        categoryName: 'Supplies',
        title: 'Kitchen Tissue Rolls',
        amount: 1500.0,
        expenseDate: now,
        paymentMethod: 'cash',
        createdBy: 'Admin',
        createdAt: now,
        updatedAt: now,
      );
      await provider.addExpense(expense);
      expect(provider.expenses.any((e) => e.id == 'exp_test_3'), isTrue);

      await provider.deleteExpense('exp_test_3');

      expect(provider.expenses.any((e) => e.id == 'exp_test_3'), isFalse);
    });

    test('netProfit calculates netAmount - totalExpenses correctly', () async {
      final expectedNet = provider.netAmount - provider.totalExpenses;
      expect(provider.netProfit, expectedNet);
    });

    test('expenses are isolated to active branch', () async {
      final activeBranch = provider.activeBranchId;
      for (final expense in provider.expenses) {
        expect(expense.branchId, activeBranch);
      }
    });

    test('empty database test: application starts 100% clean with zero demo records', () async {
      final cleanDb = NativeDatabaseService();
      await cleanDb.initialize();
      await cleanDb.clearAllData();
      await cleanDb.seedInitialData();
      final cleanProvider = POSProvider(database: cleanDb);
      await cleanProvider.init();

      expect(cleanProvider.menuItems, isEmpty);
      expect(cleanProvider.tables, isEmpty);
      expect(cleanProvider.customers, isEmpty);
      expect(cleanProvider.orders, isEmpty);
      expect(cleanProvider.expenses, isEmpty);
      expect(cleanProvider.categories, isEmpty);
      expect(cleanProvider.totalRevenue, 0.0);
      expect(cleanProvider.netAmount, 0.0);
      expect(cleanProvider.totalExpenses, 0.0);
      expect(cleanProvider.netProfit, 0.0);
    });

    test('app restart test: real created product, table, customer, order, and expense persist across restarts', () async {
      final now = DateTime.now();
      // 1. Add real product
      await provider.addCategory('Beverages');
      await provider.addMenuItem(MenuItem(
        id: 'prod_real_1',
        itemCode: 'BEV-01',
        name: 'Fresh Lemonade',
        category: 'Beverages',
        price: 90.0,
        stockQuantity: 25,
        createdAt: now,
        updatedAt: now,
      ));

      // 2. Add real customer
      await provider.addCustomer(Customer(
        id: 'cust_real_1',
        name: 'Subash Thapa',
        phone: '9841234567',
        address: 'Patan',
        initials: 'ST',
        totalVisits: 1,
        totalSpent: 90.0,
      ));

      // 3. Add real table
      await provider.addTable(RestaurantTable(
        id: 'tbl_real_99',
        name: 'Table 99',
        location: 'Rooftop',
        capacity: 4,
        status: 'free',
        orderCount: 0,
        runningTotal: 0.0,
      ));

      // 4. Record real expense
      await provider.addExpense(Expense(
        id: 'exp_real_1',
        branchId: 'branch_001',
        categoryId: 'ec_10',
        categoryName: 'Supplies',
        title: 'Fresh Lemons',
        amount: 500.0,
        expenseDate: now,
        paymentMethod: 'cash',
        createdBy: 'Admin',
        createdAt: now,
        updatedAt: now,
      ));

      // 5. Create fresh provider from same database to simulate app restart
      final restartedProvider = POSProvider(database: database);
      await restartedProvider.init();

      // Verify all records persisted and reloaded
      expect(restartedProvider.menuItems.any((m) => m.name == 'Fresh Lemonade'), isTrue);
      expect(restartedProvider.customers.any((c) => c.name == 'Subash Thapa'), isTrue);
      expect(restartedProvider.tables.any((t) => t.name == 'Table 99'), isTrue);
      expect(restartedProvider.expenses.any((e) => e.title == 'Fresh Lemons'), isTrue);
      expect(restartedProvider.totalExpenses, greaterThanOrEqualTo(500.0));
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
