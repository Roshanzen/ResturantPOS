class MenuItem {
  final String id;
  final String name;
  final String itemCode;
  final String? barcode;
  final String category;
  final double price;
  final double? costPrice;
  final double? tax;
  final double? discount;
  final int stockQuantity;
  final int? minimumStockLevel;
  final String? unit;
  final String? description;
  final String? imagePath;
  final bool available;
  final int preparationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.itemCode,
    this.barcode,
    required this.category,
    required this.price,
    this.costPrice,
    this.tax,
    this.discount,
    required this.stockQuantity,
    this.minimumStockLevel,
    this.unit,
    this.description,
    this.imagePath,
    this.available = true,
    this.preparationMinutes = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    String? itemCode,
    String? barcode,
    String? category,
    double? price,
    double? costPrice,
    double? tax,
    double? discount,
    int? stockQuantity,
    int? minimumStockLevel,
    String? unit,
    String? description,
    String? imagePath,
    bool? available,
    int? preparationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      itemCode: itemCode ?? this.itemCode,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      available: available ?? this.available,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
