import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/errors/pos_exception.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/features/orders/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final DatabaseService database;

  const OrdersRepositoryImpl(this.database);

  @override
  Future<Result<Order>> createOrder(CreateOrderRequest request) async {
    try {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final orderId = 'ORD-${now.millisecondsSinceEpoch % 100000}';
      final subtotalMinor =
          request.items.fold(0, (sum, item) => sum + item.quantity * 100);
      final discountMinor = request.discountMinor ?? 0;
      final grandTotalMinor = subtotalMinor - discountMinor;

      await database.insert('orders', {
        'id': orderId,
        'order_number': orderId,
        'idempotency_key': request.idempotencyKey,
        'branch_id': 'branch_001',
        'terminal_id': 'terminal_001',
        'cashier_id': 'user_001',
        'table_id': request.tableId,
        'customer_id': request.customerId,
        'order_type': request.orderType,
        'status': 'submitted',
        'business_date': now.toIso8601String().split('T')[0],
        'subtotal_minor': subtotalMinor,
        'discount_minor': discountMinor,
        'service_charge_minor': 0,
        'tax_minor': 0,
        'grand_total_minor': grandTotalMinor,
        'paid_amount_minor': 0,
        'balance_minor': grandTotalMinor,
        'currency': 'NPR',
        'notes': request.notes,
        'created_at': nowIso,
        'updated_at': nowIso,
        'server_version': '1',
        'sync_status': 'pending',
      });

      for (final item in request.items) {
        final itemId = 'OI-${now.millisecondsSinceEpoch}-${item.menuItemId}';
        await database.insert('order_items', {
          'id': itemId,
          'order_id': orderId,
          'menu_item_id': item.menuItemId,
          'name_snapshot': 'Menu Item',
          'sku_snapshot': item.menuItemId,
          'quantity': item.quantity,
          'unit_price_minor': 100,
          'discount_minor': 0,
          'tax_minor': 0,
          'line_total_minor': item.quantity * 100,
          'kitchen_status': 'pending',
          'void_status': null,
          'notes': item.notes,
          'modifiers': item.modifiers,
        });
      }

      final order = _mapOrder({
        'id': orderId,
        'order_number': orderId,
        'idempotency_key': request.idempotencyKey,
        'branch_id': 'branch_001',
        'terminal_id': 'terminal_001',
        'cashier_id': 'user_001',
        'table_id': request.tableId,
        'customer_id': request.customerId,
        'order_type': request.orderType,
        'status': 'submitted',
        'business_date': now.toIso8601String().split('T')[0],
        'subtotal_minor': subtotalMinor,
        'discount_minor': discountMinor,
        'service_charge_minor': 0,
        'tax_minor': 0,
        'grand_total_minor': grandTotalMinor,
        'paid_amount_minor': 0,
        'balance_minor': grandTotalMinor,
        'currency': 'NPR',
        'notes': request.notes,
        'created_at': nowIso,
        'updated_at': nowIso,
        'server_version': '1',
        'sync_status': 'pending',
      });
      AppLogger.d('OrdersRepository', 'Order created: ${order.id}');
      return Success(order);
    } catch (e) {
      AppLogger.e('OrdersRepository', 'Failed to create order', error: e);
      return Failure(PosException('Failed to create order: $e',
          code: 'ORDER_CREATE_ERROR'));
    }
  }

  @override
  Future<Result<Order>> getOrder(String id) async {
    try {
      final rows = await database.query('orders',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PosException('Order not found', code: 'ORDER_NOT_FOUND'));
      }
      final order = _mapOrder(rows.first);
      return Success(order);
    } catch (e) {
      AppLogger.e('OrdersRepository', 'Failed to get order', error: e);
      return Failure(
          PosException('Failed to get order: $e', code: 'ORDER_LOAD_ERROR'));
    }
  }

  @override
  Future<Result<List<Order>>> getOrders(
      {String? status, String? tableId}) async {
    try {
      String? where;
      List<dynamic>? whereArgs;
      if (status != null && tableId != null) {
        where = 'status = ? AND table_id = ?';
        whereArgs = [status, tableId];
      } else if (status != null) {
        where = 'status = ?';
        whereArgs = [status];
      } else if (tableId != null) {
        where = 'table_id = ?';
        whereArgs = [tableId];
      }

      final rows = await database.query('orders',
          where: where, whereArgs: whereArgs, orderBy: 'created_at DESC');
      final orders = rows.map((row) => _mapOrder(row)).toList();
      return Success(orders);
    } catch (e) {
      AppLogger.e('OrdersRepository', 'Failed to load orders', error: e);
      return Failure(
          PosException('Failed to load orders: $e', code: 'ORDERS_LOAD_ERROR'));
    }
  }

  @override
  Future<Result<Order>> updateOrderStatus(String id, String status,
      {String? reason}) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'orders',
        {'status': status, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      final rows = await database.query('orders',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PosException('Order not found', code: 'ORDER_NOT_FOUND'));
      }
      final order = _mapOrder(rows.first);
      return Success(order);
    } catch (e) {
      AppLogger.e('OrdersRepository', 'Failed to update order status',
          error: e);
      return Failure(PosException('Failed to update order status: $e',
          code: 'ORDER_UPDATE_ERROR'));
    }
  }

  @override
  Future<Result<Order>> cancelOrder(String id, String reason) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'orders',
        {'status': 'cancelled', 'void_reason': reason, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      final rows = await database.query('orders',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PosException('Order not found', code: 'ORDER_NOT_FOUND'));
      }
      final order = _mapOrder(rows.first);
      return Success(order);
    } catch (e) {
      AppLogger.e('OrdersRepository', 'Failed to cancel order', error: e);
      return Failure(PosException('Failed to cancel order: $e',
          code: 'ORDER_CANCEL_ERROR'));
    }
  }

  @override
  Future<Result<Order>> voidOrder(String id, String reason) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'orders',
        {'status': 'voided', 'void_reason': reason, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      final rows = await database.query('orders',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PosException('Order not found', code: 'ORDER_NOT_FOUND'));
      }
      final order = _mapOrder(rows.first);
      return Success(order);
    } catch (e) {
      AppLogger.e('OrdersRepository', 'Failed to void order', error: e);
      return Failure(
          PosException('Failed to void order: $e', code: 'ORDER_VOID_ERROR'));
    }
  }

  Order _mapOrder(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      idempotencyKey: json['idempotency_key'] as String,
      branchId: json['branch_id'] as String,
      terminalId: json['terminal_id'] as String,
      cashierId: json['cashier_id'] as String,
      tableId: json['table_id'] as String,
      customerId: json['customer_id'] as String?,
      orderType: json['order_type'] as String,
      status: json['status'] as String,
      businessDate: DateTime.parse(json['business_date'] as String),
      subtotalMinor: json['subtotal_minor'] as int,
      discountMinor: json['discount_minor'] as int,
      serviceChargeMinor: json['service_charge_minor'] as int,
      taxMinor: json['tax_minor'] as int,
      grandTotalMinor: json['grand_total_minor'] as int,
      paidAmountMinor: json['paid_amount_minor'] as int,
      balanceMinor: json['balance_minor'] as int,
      currency: json['currency'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      serverVersion: json['server_version'] as String?,
      syncStatus: json['sync_status'] as String,
      voidReason: json['void_reason'] as String?,
      auditMetadata: json['audit_metadata'] as String?,
    );
  }
}
