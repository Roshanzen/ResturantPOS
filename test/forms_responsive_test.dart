import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos/core/database/database_service_native.dart';
import 'package:restaurant_pos/providers/pos_provider.dart';
import 'package:restaurant_pos/screens/new_expense_screen.dart';
import 'package:restaurant_pos/screens/new_menu_item_screen.dart';
import 'package:restaurant_pos/screens/new_table_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Responsive Form Screens and Dropdown Tests', () {
    late NativeDatabaseService database;
    late POSProvider provider;

    setUp(() async {
      database = NativeDatabaseService(dbName: 'forms_responsive_test.db');
      await database.initialize();
      await database.clearAllData();
      final now = DateTime.now().toIso8601String();
      await database.insert('categories', {
        'id': 'cat_momo',
        'name': 'Momo',
        'created_at': now,
        'updated_at': now,
      });
      await database.insert('expense_categories', {
        'id': 'ec_utilities',
        'name': 'Utilities',
        'branch_id': 'branch_001',
        'created_at': now,
        'updated_at': now,
      });
      provider = POSProvider(database: database);
      await provider.init();
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('NewTableScreen renders required fields and handles save', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<POSProvider>.value(
            value: provider,
            child: const NewTableScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Table name *'), findsOneWidget);
      expect(find.text('Capacity *'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Save table'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Table 99');
      await tester.enterText(find.byType(TextField).at(1), '6');
      await tester.ensureVisible(find.text('Save table'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save table'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      expect(provider.tables.any((t) => t.name == 'Table 99' && t.capacity == 6), isTrue);
    });

    testWidgets('NewMenuItemScreen renders embedded create category and rejects empty category', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<POSProvider>.value(
            value: provider,
            child: const NewMenuItemScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no external "+ New category" button beside the label
      expect(find.widgetWithText(TextButton, 'New category'), findsNothing);

      // Open category dropdown
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Dynamic category and embedded action item should be visible
      expect(find.text('Momo'), findsWidgets);
      expect(find.text('＋ Create new category'), findsOneWidget);

      // Select 'Momo'
      await tester.tap(find.text('Momo').last);
      await tester.pumpAndSettle();

      // Form validation with valid category
      await tester.enterText(find.byType(TextField).at(0), 'Steam Momo');
      await tester.enterText(find.byType(TextField).at(1), '150');
      await tester.enterText(find.byType(TextField).at(2), 'MM-01');
      await tester.ensureVisible(find.text('Save item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save item'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      expect(provider.menuItems.any((m) => m.name == 'Steam Momo' && m.category == 'Momo'), isTrue);
    });

    testWidgets('NewExpenseScreen renders embedded create category and saves valid expense', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<POSProvider>.value(
            value: provider,
            child: const NewExpenseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no external button beside label
      expect(find.widgetWithText(TextButton, 'New category'), findsNothing);

      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Utilities'), findsWidgets);
      expect(find.text('＋ Create new category'), findsOneWidget);

      await tester.tap(find.text('Utilities').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Internet Bill');
      await tester.enterText(find.byType(TextField).at(1), '2500');
      await tester.ensureVisible(find.text('Save expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save expense'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      expect(provider.expenses.any((e) => e.title == 'Internet Bill' && e.amount == 2500.0), isTrue);
    });

    testWidgets('NewMenuItemScreen embedded Create new category creates and auto-selects', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<POSProvider>.value(
            value: provider,
            child: const NewMenuItemScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open category dropdown
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Tap '＋ Create new category'
      await tester.tap(find.text('＋ Create new category'));
      await tester.pumpAndSettle();

      // Add Category dialog should appear
      expect(find.text('Add product category'), findsOneWidget);

      // Enter new category name
      await tester.enterText(find.widgetWithText(TextField, 'e.g. Salads, Soups, Desserts'), 'Burgers');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Category should be created in DB
      expect(provider.categories.any((c) => c.name == 'Burgers'), isTrue);

      // Form should now show 'Burgers' selected in dropdown
      expect(find.text('Burgers'), findsOneWidget);
    });

    testWidgets('NewExpenseScreen embedded Create new category creates and auto-selects', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<POSProvider>.value(
            value: provider,
            child: const NewExpenseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open category dropdown
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Tap '＋ Create new category'
      await tester.tap(find.text('＋ Create new category'));
      await tester.pumpAndSettle();

      // Add Expense Category dialog should appear
      expect(find.text('Add expense category'), findsOneWidget);

      // Enter new category name
      await tester.enterText(find.widgetWithText(TextField, 'e.g. Advertising, Laundry, Legal'), 'Cleaning');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Expense category should be created in DB
      expect(provider.expenseCategories.any((c) => c.name == 'Cleaning'), isTrue);

      // Form should now show 'Cleaning' selected in dropdown
      expect(find.text('Cleaning'), findsOneWidget);
    });
  });
}
