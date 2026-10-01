import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:restaurant_pos/core/database/database_service.dart';

class NativeDatabaseService implements DatabaseService {
  final String dbName;
  static const int _dbVersion = 4;
  Database? _instance;

  NativeDatabaseService({this.dbName = 'restaurant_pos.db'});

  Future<Database> get _db async {
    if (_instance != null) return _instance!;
    _instance = await _openDatabase();
    return _instance!;
  }

  Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path =
        dbName == inMemoryDatabasePath ? inMemoryDatabasePath : join(dbPath, dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await _migrateToV3(db);
        }
        if (oldVersion < 4) {
          await _migrateToV4(db);
        }
      },
    );
  }

  Future<void> _migrateToV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(name, branch_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        title TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        expense_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        reference_number TEXT,
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _migrateToV3(Database db) async {
    await db.execute('ALTER TABLE menu_items ADD COLUMN barcode TEXT UNIQUE');
    await db.execute('ALTER TABLE menu_items ADD COLUMN cost_price_minor INTEGER');
    await db.execute('ALTER TABLE menu_items ADD COLUMN tax_minor INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE menu_items ADD COLUMN discount_minor INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE menu_items ADD COLUMN stock_quantity INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE menu_items ADD COLUMN minimum_stock_level INTEGER');
    await db.execute('ALTER TABLE menu_items ADD COLUMN unit TEXT');
    await db.execute('ALTER TABLE menu_items ADD COLUMN description TEXT');
    await db.execute('ALTER TABLE menu_items ADD COLUMN image_path TEXT');

    await db.execute('''
      CREATE TABLE product_prices (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        price_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'NPR',
        updated_at TEXT NOT NULL,
        UNIQUE(product_id, branch_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        quantity_delta INTEGER NOT NULL,
        reason TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        last_error TEXT,
        idempotency_key TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL,
        idempotency_key TEXT NOT NULL UNIQUE,
        branch_id TEXT NOT NULL,
        terminal_id TEXT NOT NULL,
        cashier_id TEXT NOT NULL,
        table_id TEXT NOT NULL,
        customer_id TEXT,
        order_type TEXT NOT NULL,
        status TEXT NOT NULL,
        business_date TEXT NOT NULL,
        subtotal_minor INTEGER NOT NULL,
        discount_minor INTEGER NOT NULL DEFAULT 0,
        service_charge_minor INTEGER NOT NULL DEFAULT 0,
        tax_minor INTEGER NOT NULL DEFAULT 0,
        grand_total_minor INTEGER NOT NULL,
        paid_amount_minor INTEGER NOT NULL DEFAULT 0,
        balance_minor INTEGER NOT NULL,
        currency TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        server_version TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        void_reason TEXT,
        audit_metadata TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        menu_item_id TEXT NOT NULL,
        name_snapshot TEXT NOT NULL,
        sku_snapshot TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price_minor INTEGER NOT NULL,
        discount_minor INTEGER NOT NULL DEFAULT 0,
        tax_minor INTEGER NOT NULL DEFAULT 0,
        line_total_minor INTEGER NOT NULL,
        kitchen_status TEXT,
        void_status TEXT,
        notes TEXT,
        modifiers TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        requested_amount_minor INTEGER NOT NULL,
        authorized_amount_minor INTEGER NOT NULL,
        tendered_amount_minor INTEGER NOT NULL,
        change_amount_minor INTEGER NOT NULL DEFAULT 0,
        gateway_reference TEXT,
        status TEXT NOT NULL,
        idempotency_key TEXT NOT NULL UNIQUE,
        failure_reason TEXT,
        refund_amount_minor INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        user_id TEXT NOT NULL,
        terminal_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_events (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        role TEXT,
        terminal_id TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        previous_state TEXT,
        new_state TEXT,
        reason TEXT,
        timestamp TEXT NOT NULL,
        correlation_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE menu_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        item_code TEXT NOT NULL UNIQUE,
        barcode TEXT UNIQUE,
        category TEXT NOT NULL,
        price_minor INTEGER NOT NULL,
        cost_price_minor INTEGER,
        tax_minor INTEGER NOT NULL DEFAULT 0,
        discount_minor INTEGER NOT NULL DEFAULT 0,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        minimum_stock_level INTEGER,
        unit TEXT,
        description TEXT,
        image_path TEXT,
        available INTEGER NOT NULL DEFAULT 1,
        preparation_minutes INTEGER NOT NULL DEFAULT 5,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE product_prices (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        price_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'NPR',
        updated_at TEXT NOT NULL,
        UNIQUE(product_id, branch_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        quantity_delta INTEGER NOT NULL,
        reason TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        email TEXT,
        total_visits INTEGER NOT NULL DEFAULT 0,
        total_spent_minor INTEGER NOT NULL DEFAULT 0,
        credit_balance_minor INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'NPR',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tables (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT NOT NULL DEFAULT 'Indoor',
        capacity INTEGER NOT NULL DEFAULT 4,
        status TEXT NOT NULL DEFAULT 'free',
        order_count INTEGER NOT NULL DEFAULT 0,
        running_total_minor INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(name, branch_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        title TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        expense_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        reference_number TEXT,
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  @override
  Future<void> initialize() async {
    await _db;
  }

  @override
  Future<void> seedInitialData() async {
    // Production database initializes clean with zero demo records.
  }


  @override
  Future<int> insertOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    required String idempotencyKey,
  }) async {
    final db = await _db;
    final operationId =
        'op_${DateTime.now().millisecondsSinceEpoch}_${idempotencyKey.hashCode}';
    return await db.insert('sync_queue', {
      'operation_id': operationId,
      'operation_type': operationType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'idempotency_key': idempotencyKey,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    return await db.query(
      'sync_queue',
      where:
          'status = ? OR (status = ? AND next_retry_at IS NOT NULL AND next_retry_at <= ?)',
      whereArgs: ['pending', 'failed', now],
      orderBy: 'created_at ASC',
    );
  }

  @override
  Future<void> markOperationCompleted(int id) async {
    final db = await _db;
    await db.update(
      'sync_queue',
      {'status': 'completed', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markOperationFailed(int id, String error) async {
    final db = await _db;
    await db.update(
      'sync_queue',
      {
        'status': 'failed',
        'retry_count': 1,
        'next_retry_at':
            DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
        'last_error': error,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAllData() async {
    final db = await _db;
    await db.delete('expenses');
    await db.delete('expense_categories');
    await db.delete('categories');
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('payments');
    await db.delete('audit_events');
    await db.delete('menu_items');
    await db.delete('customers');
    await db.delete('tables');
    await db.delete('sync_queue');
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await _db;
    return await db.insert(table, data);
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await _db;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where,
      List<dynamic>? whereArgs,
      int? limit,
      String? orderBy}) async {
    final db = await _db;
    return await db.query(table,
        where: where, whereArgs: whereArgs, limit: limit, orderBy: orderBy);
  }

  @override
  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await _db;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
