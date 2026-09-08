import 'package:restaurant_pos/core/result/result.dart';

abstract class OrdersRepository {
  Future<Result<Order>> createOrder(CreateOrderRequest request);
  Future<Result<Order>> getOrder(String id);
  Future<Result<List<Order>>> getOrders({String? status, String? tableId});
  Future<Result<Order>> updateOrderStatus(String id, String status,
      {String? reason});
  Future<Result<Order>> cancelOrder(String id, String reason);
  Future<Result<Order>> voidOrder(String id, String reason);
}

class Order {
  final String id;
  final String orderNumber;
  final String idempotencyKey;
  final String branchId;
  final String terminalId;
  final String cashierId;
  final String tableId;
  final String? customerId;
  final String orderType;
  final String status;
  final DateTime businessDate;
  final int subtotalMinor;
  final int discountMinor;
  final int serviceChargeMinor;
  final int taxMinor;
  final int grandTotalMinor;
  final int paidAmountMinor;
  final int balanceMinor;
  final String currency;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverVersion;
  final String syncStatus;
  final String? voidReason;
  final String? auditMetadata;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.idempotencyKey,
    required this.branchId,
    required this.terminalId,
    required this.cashierId,
    required this.tableId,
    this.customerId,
    required this.orderType,
    required this.status,
    required this.businessDate,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.serviceChargeMinor,
    required this.taxMinor,
    required this.grandTotalMinor,
    required this.paidAmountMinor,
    required this.balanceMinor,
    required this.currency,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.serverVersion,
    required this.syncStatus,
    this.voidReason,
    this.auditMetadata,
  });
}

class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String nameSnapshot;
  final String skuSnapshot;
  final int quantity;
  final int unitPriceMinor;
  final int discountMinor;
  final int taxMinor;
  final int lineTotalMinor;
  final String? kitchenStatus;
  final String? voidStatus;
  final String? notes;
  final String? modifiers;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.nameSnapshot,
    required this.skuSnapshot,
    required this.quantity,
    required this.unitPriceMinor,
    required this.discountMinor,
    required this.taxMinor,
    required this.lineTotalMinor,
    this.kitchenStatus,
    this.voidStatus,
    this.notes,
    this.modifiers,
  });
}

class CreateOrderRequest {
  final String idempotencyKey;
  final String tableId;
  final String? customerId;
  final String orderType;
  final List<CreateOrderItemRequest> items;
  final String? notes;
  final int? discountMinor;

  const CreateOrderRequest({
    required this.idempotencyKey,
    required this.tableId,
    this.customerId,
    required this.orderType,
    required this.items,
    this.notes,
    this.discountMinor,
  });
}

class CreateOrderItemRequest {
  final String menuItemId;
  final int quantity;
  final String? notes;
  final String? modifiers;

  const CreateOrderItemRequest({
    required this.menuItemId,
    required this.quantity,
    this.notes,
    this.modifiers,
  });
}
