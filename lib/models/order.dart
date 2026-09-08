import '../models/order_item.dart';

class Order {
  final String id;
  final String tableId;
  final String tableName;
  final String? customerId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String? note;
  final String? paymentMethod;
  final double discount;

  Order({
    required this.id,
    required this.tableId,
    required this.tableName,
    this.customerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.note,
    this.paymentMethod,
    this.discount = 0.0,
  });

  Order copyWith({
    String? id,
    String? tableId,
    String? tableName,
    String? customerId,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    String? note,
    String? paymentMethod,
    double? discount,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discount: discount ?? this.discount,
    );
  }
}
