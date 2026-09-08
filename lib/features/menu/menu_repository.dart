import 'package:restaurant_pos/core/result/result.dart';

abstract class MenuRepository {
  Future<Result<List<MenuItem>>> getMenuItems();
  Future<Result<MenuItem>> createMenuItem(CreateMenuItemDto dto);
  Future<Result<MenuItem>> updateMenuItem(String id, UpdateMenuItemDto dto);
  Future<Result<void>> deleteMenuItem(String id);
}

class MenuItem {
  final String id;
  final String name;
  final String sku;
  final String? description;
  final String category;
  final int priceMinor;
  final String currency;
  final int preparationMinutes;
  final bool available;
  final int version;
  final DateTime updatedAt;

  const MenuItem({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    required this.category,
    required this.priceMinor,
    required this.currency,
    required this.preparationMinutes,
    required this.available,
    required this.version,
    required this.updatedAt,
  });
}

class CreateMenuItemDto {
  final String name;
  final String sku;
  final String? description;
  final String category;
  final int priceMinor;
  final String currency;
  final int preparationMinutes;
  final bool available;

  const CreateMenuItemDto({
    required this.name,
    required this.sku,
    this.description,
    required this.category,
    required this.priceMinor,
    required this.currency,
    required this.preparationMinutes,
    required this.available,
  });
}

class UpdateMenuItemDto {
  final String? name;
  final String? description;
  final String? category;
  final int? priceMinor;
  final int? preparationMinutes;
  final bool? available;

  const UpdateMenuItemDto({
    this.name,
    this.description,
    this.category,
    this.priceMinor,
    this.preparationMinutes,
    this.available,
  });
}
