import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos/core/database/database_service_native.dart';
import 'package:restaurant_pos/models/order_item.dart';
import 'package:restaurant_pos/providers/pos_provider.dart';
import 'package:restaurant_pos/screens/take_order_screen.dart';
import 'package:restaurant_pos/widgets/common.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _seedTestFixture(NativeDatabaseService database) async {
  final now = DateTime.now().toIso8601String();
  await database.insert('categories', {
    'id': 'cat_cake',
    'name': 'Cake',
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
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Take Order Responsive Layout Tests', () {
    late NativeDatabaseService database;
    late POSProvider provider;

    setUp(() async {
      database = NativeDatabaseService(dbName: 'take_order_test.db');
      await database.initialize();
      await database.clearAllData();
      await _seedTestFixture(database);

      provider = POSProvider(database: database);
      await provider.init();

      // Create an active order on Table 1
      await provider.createOrder(
        tableId: 'table_1',
        tableName: 'Table 1',
        items: [
          OrderItem(menuItem: provider.menuItems.first, quantity: 1),
        ],
      );
    });

    tearDown(() async {
      await database.close();
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: ThemeData(
          fontFamily: 'Inter',
        ),
        home: ChangeNotifierProvider<POSProvider>.value(
          value: provider,
          child: const Scaffold(
            body: TakeOrderScreen(),
          ),
        ),
      );
    }

    final testResolutions = [
      const Size(360, 800),
      const Size(375, 812),
      const Size(390, 844),
      const Size(412, 915),
      const Size(430, 932),
    ];

    for (final size in testResolutions) {
      testWidgets('Renders TakeOrderScreen without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Take order'), findsWidgets);
        expect(find.text('Choose a table'), findsOneWidget);
        expect(find.text('Table 1'), findsOneWidget);
        expect(find.text('Table 5'), findsOneWidget);

        // Active table action buttons
        expect(find.text('View Order'), findsOneWidget);
        expect(find.text('Add Product'), findsOneWidget);
        expect(find.text('Checkout'), findsOneWidget);

        // Free table action button
        expect(find.text('Take Order'), findsOneWidget);
      });
    }

    testWidgets('TableCard visually contains View Order, Add Product, and Checkout buttons', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Find TableCard for Table 1
      final table1Finder = find.ancestor(
        of: find.text('Table 1'),
        matching: find.byType(PosCard),
      );
      expect(table1Finder, findsOneWidget);

      final cardRect = tester.getRect(table1Finder);

      // Get Rect of View Order, Add Product, and Checkout
      final viewOrderFinder = find.widgetWithText(OutlinedButton, 'View Order');
      final addProductFinder = find.widgetWithText(OutlinedButton, 'Add Product');
      final checkoutFinder = find.widgetWithText(ElevatedButton, 'Checkout');

      expect(viewOrderFinder, findsOneWidget);
      expect(addProductFinder, findsOneWidget);
      expect(checkoutFinder, findsOneWidget);

      final viewOrderRect = tester.getRect(viewOrderFinder);
      final addProductRect = tester.getRect(addProductFinder);
      final checkoutRect = tester.getRect(checkoutFinder);

      // Verify all buttons are strictly inside the card boundaries
      expect(viewOrderRect.top, greaterThanOrEqualTo(cardRect.top));
      expect(viewOrderRect.bottom, lessThanOrEqualTo(cardRect.bottom));
      expect(viewOrderRect.left, greaterThanOrEqualTo(cardRect.left));
      expect(viewOrderRect.right, lessThanOrEqualTo(cardRect.right));

      expect(addProductRect.top, greaterThanOrEqualTo(cardRect.top));
      expect(addProductRect.bottom, lessThanOrEqualTo(cardRect.bottom));
      expect(addProductRect.left, greaterThanOrEqualTo(cardRect.left));
      expect(addProductRect.right, lessThanOrEqualTo(cardRect.right));

      expect(checkoutRect.top, greaterThanOrEqualTo(cardRect.top));
      expect(checkoutRect.bottom, lessThanOrEqualTo(cardRect.bottom));
      expect(checkoutRect.left, greaterThanOrEqualTo(cardRect.left));
      expect(checkoutRect.right, lessThanOrEqualTo(cardRect.right));

      // Verify Add Product and Checkout are arranged side-by-side (same vertical band)
      expect((addProductRect.top - checkoutRect.top).abs(), lessThan(5.0));
      expect(addProductRect.right, lessThanOrEqualTo(checkoutRect.left + 10.0));
    });

    testWidgets('Renders responsive multi-column grid on tablet screen (768x1024)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Table 1'), findsOneWidget);
      expect(find.text('Table 5'), findsOneWidget);
    });
  });
}
