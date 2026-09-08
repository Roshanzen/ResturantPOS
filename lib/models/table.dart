class RestaurantTable {
  final String id;
  final String name;
  final String status;
  final int orderCount;
  final double runningTotal;
  final String location;
  final int capacity;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.status,
    required this.orderCount,
    required this.runningTotal,
    this.location = 'Indoor',
    this.capacity = 4,
  });

  RestaurantTable copyWith({
    String? id,
    String? name,
    String? status,
    int? orderCount,
    double? runningTotal,
    String? location,
    int? capacity,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      orderCount: orderCount ?? this.orderCount,
      runningTotal: runningTotal ?? this.runningTotal,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
    );
  }
}
