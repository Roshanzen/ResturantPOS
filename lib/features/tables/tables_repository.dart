import 'package:restaurant_pos/core/result/result.dart';

abstract class TablesRepository {
  Future<Result<List<RestaurantTable>>> getTables();
  Future<Result<RestaurantTable>> updateTableStatus(
      String tableId, String status);
}

class RestaurantTable {
  final String id;
  final String name;
  final String floor;
  final int capacity;
  final String status;
  final String? activeOrderId;
  final String? reservationStatus;
  final int version;
  final DateTime updatedAt;

  const RestaurantTable({
    required this.id,
    required this.name,
    required this.floor,
    required this.capacity,
    required this.status,
    this.activeOrderId,
    this.reservationStatus,
    required this.version,
    required this.updatedAt,
  });
}
