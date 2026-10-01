import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import '../core/database/database_service.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/table.dart';

class POSProvider extends ChangeNotifier {
  final DatabaseService database;

  List<RestaurantTable> _tables = [];
  List<MenuItem> _menuItems = [];
  List<Order> _orders = [];
  List<Customer> _customers = [];
  List<Category> _categories = [];
  List<ExpenseCategory> _expenseCategories = [];
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<RestaurantTable> get tables => _tables;
  List<MenuItem> get menuItems => _menuItems;
  List<Order> get orders => _orders;
  List<Customer> get customers => _customers;
  List<Category> get categories => _categories;
  List<ExpenseCategory> get expenseCategories => _expenseCategories;
  List<Expense> get expenses =>
      _expenses.where((e) => !e.isDeleted).toList();
  String get activeBranchId => 'branch_001';
  bool get isLoading => _isLoading;

  List<Order> get pendingOrders =>
      _orders.where((o) => o.status == 'pending').toList();
  List<Order> get completedOrders =>
      _orders.where((o) => o.status == 'completed').toList();
  List<Order> get cancelledOrders =>
      _orders.where((o) => o.status == 'cancelled').toList();

  int get pendingCount => pendingOrders.length;
  int get completedTodayCount => completedOrders.length;
  int get cancelledCount => cancelledOrders.length;

  double get totalRevenue => _orders
      .where((o) => o.status != 'cancelled')
      .fold(0.0, (sum, o) => sum + o.totalAmount + o.discount);
  double get totalDiscount => _orders
      .where((o) => o.status != 'cancelled')
      .fold(0.0, (sum, o) => sum + o.discount);
  double get netAmount => totalRevenue - totalDiscount;
  int get totalOrdersCount => _orders.length;
  double get averageOrderValue =>
      completedOrders.isNotEmpty ? netAmount / completedOrders.length : 0.0;

  double get totalExpenses =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get todayExpenses {
    final now = DateTime.now();
    return expenses.where((e) =>
        e.expenseDate.year == now.year &&
        e.expenseDate.month == now.month &&
        e.expenseDate.day == now.day).fold(0.0, (sum, e) => sum + e.amount);
  }

  double get netProfit => netAmount - totalExpenses;

  Map<String, double> get expensesByCategory {
    final Map<String, double> map = {};
    for (final e in expenses) {
      map[e.categoryName] = (map[e.categoryName] ?? 0.0) + e.amount;
    }
    return map;
  }

  double get cashCollection => _orders
      .where((o) => o.status == 'completed' && o.paymentMethod == 'cash')
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  double get fonepayCollection => _orders
      .where((o) => o.status == 'completed' && o.paymentMethod == 'fonepay')
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  double get creditCollected => _orders
      .where((o) => o.status == 'completed' && o.paymentMethod == 'credit')
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  double get outstandingCredit =>
      _customers.fold(0.0, (sum, c) => sum + c.creditBalance);

  POSProvider({required this.database});

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _loadFromDatabase();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromDatabase() async {
    final menuRows = await database.query('menu_items', orderBy: 'name ASC');
    final List<MenuItem> menuItems = menuRows.map<MenuItem>((row) {
      return MenuItem(
        id: row['id'] as String,
        name: row['name'] as String,
        itemCode: row['item_code'] as String,
        barcode: row['barcode'] as String?,
        category: row['category'] as String,
        price: ((row['price_minor'] as int?) ?? 0) / 100.0,
        costPrice: row['cost_price_minor'] != null
            ? (row['cost_price_minor'] as int) / 100.0
            : null,
        tax: row['tax_minor'] != null
            ? (row['tax_minor'] as int) / 100.0
            : null,
        discount: row['discount_minor'] != null
            ? (row['discount_minor'] as int) / 100.0
            : null,
        stockQuantity: (row['stock_quantity'] as int?) ?? 0,
        minimumStockLevel: row['minimum_stock_level'] as int?,
        unit: row['unit'] as String?,
        description: row['description'] as String?,
        imagePath: row['image_path'] as String?,
        available: (row['available'] as int?) == 1,
        preparationMinutes: (row['preparation_minutes'] as int?) ?? 5,
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : DateTime.now(),
        updatedAt: row['updated_at'] != null
            ? DateTime.parse(row['updated_at'] as String)
            : DateTime.now(),
      );
    }).toList();
    _menuItems = menuItems;

    final tableRows = await database.query('tables', orderBy: 'name ASC');
    _tables = tableRows.map((row) {
      return RestaurantTable(
        id: row['id'] as String,
        name: row['name'] as String,
        status: row['status'] as String,
        orderCount: row['order_count'] as int,
        runningTotal: (row['running_total_minor'] as int) / 100.0,
        location: row['location'] as String,
        capacity: row['capacity'] as int,
      );
    }).toList();

    final customerRows = await database.query('customers', orderBy: 'name ASC');
    _customers = customerRows.map((row) {
      return Customer(
        id: row['id'] as String,
        name: row['name'] as String,
        phone: row['phone'] as String,
        address: row['address'] as String,
        initials: _extractInitials(row['name'] as String),
        totalVisits: row['total_visits'] as int,
        totalSpent: (row['total_spent_minor'] as int) / 100.0,
        creditBalance: (row['credit_balance_minor'] as int) / 100.0,
      );
    }).toList();

    final orderRows =
        await database.query('orders', orderBy: 'created_at DESC');
    _orders = [];
    for (final orderRow in orderRows) {
      final orderId = orderRow['id'] as String;
      final itemRows = await database.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

        final orderItems = itemRows.map<OrderItem>((itemRow) {
        final menuItem = _menuItems.firstWhere(
          (m) => m.id == itemRow['menu_item_id'],
          orElse: () => MenuItem(
            id: itemRow['menu_item_id'] as String,
            name: itemRow['name_snapshot'] as String,
            itemCode: itemRow['sku_snapshot'] as String,
            price: (itemRow['unit_price_minor'] as int) / 100.0,
            category: 'Unknown',
            stockQuantity: 0,
            preparationMinutes: 5,
            available: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return OrderItem(
          menuItem: menuItem,
          quantity: itemRow['quantity'] as int,
        );
      }).toList();

      final paymentRows = await database.query(
        'payments',
        where: 'order_id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      final paymentMethod = paymentRows.isNotEmpty
          ? (paymentRows.first['payment_method'] as String?)
          : (orderRow['paid_amount_minor'] != null &&
                  (orderRow['paid_amount_minor'] as int) > 0
              ? 'cash'
              : null);

      _orders.add(Order(
        id: orderRow['id'] as String,
        tableId: orderRow['table_id'] as String,
        tableName: _getTableName(orderRow['table_id'] as String),
        customerId: orderRow['customer_id'] as String?,
        items: orderItems,
        totalAmount: (orderRow['grand_total_minor'] as int) / 100.0,
        status: orderRow['status'] as String,
        createdAt: DateTime.parse(orderRow['created_at'] as String),
        note: orderRow['notes'] as String?,
        paymentMethod: paymentMethod,
        discount: (orderRow['discount_minor'] as int) / 100.0,
      ));
    }

    final categoryRows = await database.query('categories', orderBy: 'name ASC');
    _categories = categoryRows.map((r) => Category.fromMap(r)).toList();
    final existingCatNames =
        _categories.map((c) => c.name.toLowerCase()).toSet();
    for (final item in _menuItems) {
      if (item.category.isNotEmpty &&
          !existingCatNames.contains(item.category.toLowerCase())) {
        final newCat = Category(
          id: 'cat_${item.category.toLowerCase().replaceAll(' ', '_')}',
          name: item.category,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _categories.add(newCat);
        existingCatNames.add(item.category.toLowerCase());
      }
    }
    _categories.sort((a, b) => a.name.compareTo(b.name));

    final expenseCatRows =
        await database.query('expense_categories', orderBy: 'name ASC');
    _expenseCategories =
        expenseCatRows.map((r) => ExpenseCategory.fromMap(r)).toList();

    final expenseRows = await database.query('expenses',
        where: 'is_deleted = ?', whereArgs: [0], orderBy: 'expense_date DESC');
    _expenses = expenseRows.map((r) => Expense.fromMap(r)).toList();
  }

  RestaurantTable? getTableById(String id) {
    try {
      return _tables.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  MenuItem? getMenuItemByCode(String code) {
    try {
      return _menuItems.firstWhere((m) => m.itemCode == code);
    } catch (e) {
      return null;
    }
  }

  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  String _getTableName(String tableId) {
    final table = getTableById(tableId);
    return table?.name ?? 'Unknown Table';
  }

  String _extractInitials(String name) {
    return name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  Future<void> updateTableStatus(String tableId, String status,
      {int orderCount = 0, double total = 0.0}) async {
    final now = DateTime.now().toIso8601String();
    await database.update(
      'tables',
      {
        'status': status,
        'order_count': orderCount,
        'running_total_minor': (total * 100).round(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [tableId],
    );
    final idx = _tables.indexWhere((t) => t.id == tableId);
    if (idx >= 0) {
      _tables[idx] = _tables[idx].copyWith(
        status: status,
        orderCount: orderCount,
        runningTotal: total,
      );
      notifyListeners();
    }
  }

  Future<void> addTable(RestaurantTable table) async {
    final now = DateTime.now().toIso8601String();
    await database.insert('tables', {
      'id': table.id,
      'name': table.name,
      'location': table.location,
      'capacity': table.capacity,
      'status': table.status,
      'order_count': table.orderCount,
      'running_total_minor': (table.runningTotal * 100).round(),
      'created_at': now,
      'updated_at': now,
    });
    _tables.add(table);
    _tables.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateTable(String tableId,
      {String? name, String? location, int? capacity}) async {
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{'updated_at': now};
    if (name != null) updates['name'] = name;
    if (location != null) updates['location'] = location;
    if (capacity != null) updates['capacity'] = capacity;

    await database.update(
      'tables',
      updates,
      where: 'id = ?',
      whereArgs: [tableId],
    );

    final idx = _tables.indexWhere((t) => t.id == tableId);
    if (idx >= 0) {
      _tables[idx] = _tables[idx].copyWith(
        name: name ?? _tables[idx].name,
        location: location ?? _tables[idx].location,
        capacity: capacity ?? _tables[idx].capacity,
      );
      notifyListeners();
    }
  }

  Order? getActiveOrderForTable(String tableId) {
    try {
      return _orders.firstWhere(
          (o) => o.tableId == tableId && o.status == 'pending');
    } catch (e) {
      return null;
    }
  }

  Future<void> addItemsToOrder(
      String orderId, List<OrderItem> newItems) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final order = _orders[idx];
    final now = DateTime.now().toIso8601String();

    final itemRows = await database.query('order_items',
        where: 'order_id = ?', whereArgs: [orderId]);

    final Map<String, int> mergedQuantities = {};
    final Map<String, MenuItem> itemMenuMap = {};

    for (final row in itemRows) {
      final menuItemId = row['menu_item_id'] as String;
      final quantity = row['quantity'] as int;
      mergedQuantities[menuItemId] = quantity;

      final existingMenuItem = _menuItems.firstWhere(
        (m) => m.id == menuItemId,
        orElse: () => MenuItem(
          id: menuItemId,
          name: row['name_snapshot'] as String,
          itemCode: row['sku_snapshot'] as String,
          price: (row['unit_price_minor'] as int) / 100.0,
          category: 'Unknown',
          stockQuantity: 0,
          preparationMinutes: 5,
          available: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      itemMenuMap[menuItemId] = existingMenuItem;
    }

    for (final item in newItems) {
      mergedQuantities[item.menuItem.id] = item.quantity;
      itemMenuMap[item.menuItem.id] = item.menuItem;
    }

    await database.delete('order_items',
        where: 'order_id = ?', whereArgs: [orderId]);

    double newTotal = 0.0;
    for (final entry in mergedQuantities.entries) {
      final menuItem = itemMenuMap[entry.key]!;
      final unitPriceMinor = (menuItem.price * 100).round();
      final lineTotalMinor = unitPriceMinor * entry.value;
      newTotal += menuItem.price * entry.value;

      final itemId =
          'OI-${DateTime.now().millisecondsSinceEpoch}-${entry.key}';
      await database.insert('order_items', {
        'id': itemId,
        'order_id': orderId,
        'menu_item_id': entry.key,
        'name_snapshot': menuItem.name,
        'sku_snapshot': menuItem.itemCode,
        'quantity': entry.value,
        'unit_price_minor': unitPriceMinor,
        'discount_minor': 0,
        'tax_minor': 0,
        'line_total_minor': lineTotalMinor,
        'kitchen_status': 'pending',
        'void_status': null,
        'notes': null,
        'modifiers': null,
      });
    }

    final subtotalMinor = (newTotal * 100).round();
    final discountMinor = (order.discount * 100).round();
    final grandTotalMinor = subtotalMinor - discountMinor;

    await database.update(
      'orders',
      {
        'subtotal_minor': subtotalMinor,
        'discount_minor': discountMinor,
        'grand_total_minor': grandTotalMinor,
        'balance_minor': grandTotalMinor,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );

    final updatedItems = mergedQuantities.entries.map((entry) {
      return OrderItem(
        menuItem: itemMenuMap[entry.key]!,
        quantity: entry.value,
      );
    }).toList();

    _orders[idx] = Order(
      id: order.id,
      tableId: order.tableId,
      tableName: order.tableName,
      customerId: order.customerId,
      items: updatedItems,
      totalAmount: newTotal - order.discount,
      status: order.status,
      createdAt: order.createdAt,
      note: order.note,
      paymentMethod: order.paymentMethod,
      discount: order.discount,
    );

    notifyListeners();
  }

  Future<void> addMenuItem(MenuItem item) async {
    final trimmedCategory = item.category.trim();
    if (trimmedCategory.isEmpty ||
        trimmedCategory.toLowerCase() == 'uncategorized' ||
        trimmedCategory.toLowerCase() == 'select category' ||
        trimmedCategory.toLowerCase() == 'null') {
      throw ArgumentError('Please select a category.');
    }
    final now = DateTime.now().toIso8601String();
    await database.insert('menu_items', {
      'id': item.id,
      'name': item.name,
      'item_code': item.itemCode,
      'barcode': item.barcode,
      'category': item.category,
      'price_minor': (item.price * 100).round(),
      'cost_price_minor':
          item.costPrice != null ? (item.costPrice! * 100).round() : null,
      'tax_minor': item.tax != null ? (item.tax! * 100).round() : 0,
      'discount_minor':
          item.discount != null ? (item.discount! * 100).round() : 0,
      'stock_quantity': item.stockQuantity,
      'minimum_stock_level': item.minimumStockLevel,
      'unit': item.unit,
      'description': item.description,
      'image_path': item.imagePath,
      'preparation_minutes': item.preparationMinutes,
      'available': item.available ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    });
    _menuItems.add(item);
    if (!_categories.any((c) => c.name.toLowerCase() == item.category.toLowerCase())) {
      final newCat = Category(
        id: 'cat_${item.category.toLowerCase().replaceAll(' ', '_')}',
        name: item.category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _categories.add(newCat);
      _categories.sort((a, b) => a.name.compareTo(b.name));
    }
    notifyListeners();
  }

  Future<void> updateMenuItem(MenuItem item) async {
    final trimmedCategory = item.category.trim();
    if (trimmedCategory.isEmpty ||
        trimmedCategory.toLowerCase() == 'uncategorized' ||
        trimmedCategory.toLowerCase() == 'select category' ||
        trimmedCategory.toLowerCase() == 'null') {
      throw ArgumentError('Please select a category.');
    }
    final now = DateTime.now().toIso8601String();
    await database.update(
      'menu_items',
      {
        'name': item.name,
        'item_code': item.itemCode,
        'barcode': item.barcode,
        'category': item.category,
        'price_minor': (item.price * 100).round(),
        'cost_price_minor':
            item.costPrice != null ? (item.costPrice! * 100).round() : null,
        'tax_minor': item.tax != null ? (item.tax! * 100).round() : 0,
        'discount_minor':
            item.discount != null ? (item.discount! * 100).round() : 0,
        'stock_quantity': item.stockQuantity,
        'minimum_stock_level': item.minimumStockLevel,
        'unit': item.unit,
        'description': item.description,
        'image_path': item.imagePath,
        'preparation_minutes': item.preparationMinutes,
        'available': item.available ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
    final idx = _menuItems.indexWhere((m) => m.id == item.id);
    if (idx >= 0) {
      _menuItems[idx] = item;
    }
    if (!_categories.any((c) => c.name.toLowerCase() == item.category.toLowerCase())) {
      final newCat = Category(
        id: 'cat_${item.category.toLowerCase().replaceAll(' ', '_')}',
        name: item.category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _categories.add(newCat);
      _categories.sort((a, b) => a.name.compareTo(b.name));
    }
    notifyListeners();
  }

  Future<void> updateMenuItemAvailability(String itemId, bool available) async {
    final now = DateTime.now().toIso8601String();
    await database.update(
      'menu_items',
      {'available': available ? 1 : 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [itemId],
    );
    final idx = _menuItems.indexWhere((m) => m.id == itemId);
    if (idx >= 0) {
      _menuItems[idx] = _menuItems[idx].copyWith(available: available);
      notifyListeners();
    }
  }

  Future<Expense> addExpense(Expense expense) async {
    if (expense.title.trim().isEmpty) {
      throw ArgumentError('Expense description is required.');
    }
    if (expense.categoryName.trim().isEmpty) {
      throw ArgumentError('Please select an expense category.');
    }
    if (expense.amount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }

    final expenseMap = expense.toMap();
    await database.insert('expenses', expenseMap);
    _expenses.insert(0, expense);
    notifyListeners();
    return expense;
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.title.trim().isEmpty) {
      throw ArgumentError('Expense description is required.');
    }
    if (expense.categoryName.trim().isEmpty) {
      throw ArgumentError('Please select an expense category.');
    }
    if (expense.amount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }

    final updated = expense.copyWith(updatedAt: DateTime.now());
    await database.update(
      'expenses',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx >= 0) {
      _expenses[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final now = DateTime.now().toIso8601String();
    await database.update(
      'expenses',
      {'is_deleted': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [expenseId],
    );
    final idx = _expenses.indexWhere((e) => e.id == expenseId);
    if (idx >= 0) {
      _expenses[idx] = _expenses[idx].copyWith(isDeleted: true);
      notifyListeners();
    }
  }

  Future<void> addExpenseCategory(String name, {String branchId = 'branch_001'}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final id = 'ec_${DateTime.now().millisecondsSinceEpoch}';
    final category = ExpenseCategory(
      id: id,
      name: trimmed,
      branchId: branchId,
      createdAt: now,
      updatedAt: now,
    );
    await database.insert('expense_categories', category.toMap());
    _expenseCategories.add(category);
    _expenseCategories.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final category = Category(
      id: id,
      name: trimmed,
      createdAt: now,
      updatedAt: now,
    );
    await database.insert('categories', category.toMap());
    _categories.add(category);
    _categories.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  List<Expense> filterExpensesByDateRange(DateTime start, DateTime end) {
    return expenses.where((e) {
      return !e.expenseDate.isBefore(start) && !e.expenseDate.isAfter(end);
    }).toList();
  }

  List<Expense> filterExpensesByCategory(String categoryName) {
    if (categoryName.toLowerCase() == 'all') return expenses;
    return expenses.where((e) => e.categoryName.toLowerCase() == categoryName.toLowerCase()).toList();
  }

  Future<Order> createOrder({
    required String tableId,
    required String tableName,
    required List<OrderItem> items,
    String? note,
    double discount = 0.0,
  }) async {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final orderId = 'ORD-${now.millisecondsSinceEpoch % 100000}';
    final subtotalMinor = items.fold(
        0,
        (sum, item) =>
            sum + (item.menuItem.price * 100).round() * item.quantity);
    final discountMinor = (discount * 100).round();
    final grandTotalMinor = subtotalMinor - discountMinor;

    await database.insert('orders', {
      'id': orderId,
      'order_number': orderId,
      'idempotency_key': orderId,
      'branch_id': 'branch_001',
      'terminal_id': 'terminal_001',
      'cashier_id': 'user_001',
      'table_id': tableId,
      'customer_id': null,
      'order_type': 'dine_in',
      'status': 'pending',
      'business_date': now.toIso8601String().split('T')[0],
      'subtotal_minor': subtotalMinor,
      'discount_minor': discountMinor,
      'service_charge_minor': 0,
      'tax_minor': 0,
      'grand_total_minor': grandTotalMinor,
      'paid_amount_minor': 0,
      'balance_minor': grandTotalMinor,
      'currency': 'NPR',
      'notes': note,
      'created_at': nowIso,
      'updated_at': nowIso,
      'sync_status': 'pending',
    });

    for (final item in items) {
      final itemId = 'OI-${now.millisecondsSinceEpoch}-${item.menuItem.id}';
      final unitPriceMinor = (item.menuItem.price * 100).round();
      final lineTotalMinor = unitPriceMinor * item.quantity;
      await database.insert('order_items', {
        'id': itemId,
        'order_id': orderId,
        'menu_item_id': item.menuItem.id,
        'name_snapshot': item.menuItem.name,
        'sku_snapshot': item.menuItem.itemCode,
        'quantity': item.quantity,
        'unit_price_minor': unitPriceMinor,
        'discount_minor': 0,
        'tax_minor': 0,
        'line_total_minor': lineTotalMinor,
        'kitchen_status': 'pending',
        'void_status': null,
        'notes': item.note,
        'modifiers': null,
      });
    }

    await updateTableStatus(tableId, 'active',
        orderCount: pendingOrders.length + 1,
        total: _calculateTableTotal(tableId));

    final order = Order(
      id: orderId,
      tableId: tableId,
      tableName: tableName,
      customerId: null,
      items: items,
      totalAmount: grandTotalMinor / 100.0,
      status: 'pending',
      createdAt: now,
      note: note,
      paymentMethod: null,
      discount: discount,
    );

    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  Future<void> checkoutOrder(String orderId, String paymentMethod,
      {double discount = 0.0}) async {
    final now = DateTime.now().toIso8601String();
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx < 0) return;

    final order = _orders[orderIdx];
    final grandTotalMinor = (order.totalAmount * 100).round();
    final paidAmountMinor = grandTotalMinor;

    await database.update(
      'orders',
      {
        'status': 'completed',
        'paid_amount_minor': paidAmountMinor,
        'balance_minor': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );

    await database.insert('payments', {
      'id': 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      'order_id': orderId,
      'payment_method': paymentMethod,
      'requested_amount_minor': grandTotalMinor,
      'authorized_amount_minor': grandTotalMinor,
      'tendered_amount_minor': grandTotalMinor,
      'change_amount_minor': 0,
      'gateway_reference': null,
      'status': 'completed',
      'idempotency_key': 'pay-${DateTime.now().millisecondsSinceEpoch}',
      'failure_reason': null,
      'refund_amount_minor': 0,
      'created_at': now,
      'updated_at': now,
      'user_id': 'user_001',
      'terminal_id': 'terminal_001',
    });

    _orders[orderIdx] = order.copyWith(
      status: 'completed',
      paymentMethod: paymentMethod,
      discount: order.discount + discount,
    );

    final pendingCount = _orders
        .where((o) => o.tableId == order.tableId && o.status == 'pending')
        .length;

    await updateTableStatus(order.tableId, pendingCount > 0 ? 'active' : 'free',
        orderCount: pendingCount, total: _calculateTableTotal(order.tableId));

    if (order.customerId != null) {
      final customerIdx =
          _customers.indexWhere((c) => c.id == order.customerId);
      if (customerIdx >= 0) {
        final newSpent = _customers[customerIdx].totalSpent + order.totalAmount;
        final newVisits = _customers[customerIdx].totalVisits + 1;
        _customers[customerIdx] = _customers[customerIdx].copyWith(
          totalSpent: newSpent,
          totalVisits: newVisits,
        );
        await database.update(
          'customers',
          {
            'total_visits': newVisits,
            'total_spent_minor': (newSpent * 100).round(),
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [order.customerId],
        );
      }
    }

    notifyListeners();
  }

  Future<void> cancelOrder(String orderId) async {
    final now = DateTime.now().toIso8601String();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final order = _orders[idx];
    await database.update(
      'orders',
      {'status': 'cancelled', 'updated_at': now},
      where: 'id = ?',
      whereArgs: [orderId],
    );

    _orders[idx] = order.copyWith(status: 'cancelled');

    final pendingCount = _orders
        .where((o) => o.tableId == order.tableId && o.status == 'pending')
        .length;

    await updateTableStatus(order.tableId, pendingCount > 0 ? 'active' : 'free',
        orderCount: pendingCount);

    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    final now = DateTime.now().toIso8601String();
    await database.insert('customers', {
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'email': null,
      'total_visits': customer.totalVisits,
      'total_spent_minor': (customer.totalSpent * 100).round(),
      'credit_balance_minor': (customer.creditBalance * 100).round(),
      'currency': 'NPR',
      'created_at': now,
      'updated_at': now,
    });
    _customers.add(customer);
    notifyListeners();
  }

  double _calculateTableTotal(String tableId) {
    return _orders
        .where((o) => o.tableId == tableId)
        .fold<double>(0.0, (sum, o) => sum + o.totalAmount);
  }

  List<MenuItem> searchMenuItems(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return _menuItems;
    return _menuItems.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.itemCode.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q);
    }).toList();
  }

  List<MenuItem> filterMenuItemsByCategory(String category) {
    if (category == 'All') return _menuItems;
    return _menuItems.where((m) => m.category == category).toList();
  }

  List<Customer> searchCustomers(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();
  }

  List<Order> filterOrdersByStatus(String status) {
    if (status.toLowerCase() == 'all') return _orders;
    final target = status.toLowerCase();
    return _orders.where((o) => o.status.toLowerCase() == target).toList();
  }

  List<MapEntry<MenuItem, int>> getTopSellingItems() {
    final Map<MenuItem, int> salesMap = {};
    for (final order in _orders.where((o) => o.status == 'completed')) {
      for (final item in order.items) {
        final current = salesMap[item.menuItem] ?? 0;
        salesMap[item.menuItem] = current + item.quantity;
      }
    }
    final sorted = salesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  Map<String, double> getHourlySales() {
    final Map<String, double> hourly = {};
    for (int i = 0; i < 24; i++) {
      final hour = i.toString().padLeft(2, '0');
      hourly['$hour:00'] = 0.0;
    }
    for (final order in _orders.where((o) => o.status == 'completed')) {
      final hour = order.createdAt.hour.toString().padLeft(2, '0');
      final key = '$hour:00';
      hourly[key] = (hourly[key] ?? 0.0) + order.totalAmount;
    }
    return hourly;
  }

  String formatCurrency(double amount) {
    final f = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    return f.format(amount);
  }

  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'a moment ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return DateFormat.yMMMd().format(dateTime);
  }
}
