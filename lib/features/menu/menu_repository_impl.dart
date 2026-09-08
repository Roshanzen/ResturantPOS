import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/errors/pos_exception.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/features/menu/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  final DatabaseService database;

  const MenuRepositoryImpl(this.database);

  @override
  Future<Result<List<MenuItem>>> getMenuItems() async {
    try {
      final rows = await database.query('menu_items', orderBy: 'name ASC');
      final items = rows.map((row) {
        return MenuItem(
          id: row['id'] as String,
          name: row['name'] as String,
          sku: row['item_code'] as String,
          description: null,
          category: row['category'] as String,
          priceMinor: row['price_minor'] as int,
          currency: row['currency'] as String,
          preparationMinutes: row['preparation_minutes'] as int,
          available: (row['available'] as int) == 1,
          version: 1,
          updatedAt: DateTime.parse(row['updated_at'] as String),
        );
      }).toList();
      return Success(items);
    } catch (e) {
      AppLogger.e('MenuRepository', 'Failed to load menu', error: e);
      return Failure(
          PosException('Failed to load menu: $e', code: 'MENU_LOAD_ERROR'));
    }
  }

  @override
  Future<Result<MenuItem>> createMenuItem(CreateMenuItemDto dto) async {
    try {
      final id = 'MN-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final now = DateTime.now().toIso8601String();
      await database.insert('menu_items', {
        'id': id,
        'name': dto.name,
        'item_code': dto.sku,
        'category': dto.category,
        'price_minor': dto.priceMinor,
        'currency': dto.currency,
        'preparation_minutes': dto.preparationMinutes,
        'available': dto.available ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      });
      final item = MenuItem(
        id: id,
        name: dto.name,
        sku: dto.sku,
        description: dto.description,
        category: dto.category,
        priceMinor: dto.priceMinor,
        currency: dto.currency,
        preparationMinutes: dto.preparationMinutes,
        available: dto.available,
        version: 1,
        updatedAt: DateTime.now(),
      );
      return Success(item);
    } catch (e) {
      AppLogger.e('MenuRepository', 'Failed to create menu item', error: e);
      return Failure(PosException('Failed to create menu item: $e',
          code: 'MENU_CREATE_ERROR'));
    }
  }

  @override
  Future<Result<MenuItem>> updateMenuItem(
      String id, UpdateMenuItemDto dto) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'menu_items',
        {
          if (dto.name != null) 'name': dto.name,
          if (dto.description != null) 'description': dto.description,
          if (dto.category != null) 'category': dto.category,
          if (dto.priceMinor != null) 'price_minor': dto.priceMinor,
          if (dto.preparationMinutes != null)
            'preparation_minutes': dto.preparationMinutes,
          if (dto.available != null) 'available': dto.available! ? 1 : 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      final rows = await database.query('menu_items',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PosException('Menu item not found', code: 'MENU_NOT_FOUND'));
      }
      final row = rows.first;
      final item = MenuItem(
        id: row['id'] as String,
        name: row['name'] as String,
        sku: row['item_code'] as String,
        description: row['description'] as String?,
        category: row['category'] as String,
        priceMinor: row['price_minor'] as int,
        currency: row['currency'] as String,
        preparationMinutes: row['preparation_minutes'] as int,
        available: (row['available'] as int) == 1,
        version: 1,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
      return Success(item);
    } catch (e) {
      AppLogger.e('MenuRepository', 'Failed to update menu item', error: e);
      return Failure(PosException('Failed to update menu item: $e',
          code: 'MENU_UPDATE_ERROR'));
    }
  }

  @override
  Future<Result<void>> deleteMenuItem(String id) async {
    try {
      await database.delete('menu_items', where: 'id = ?', whereArgs: [id]);
      return const Success(null);
    } catch (e) {
      AppLogger.e('MenuRepository', 'Failed to delete menu item', error: e);
      return Failure(PosException('Failed to delete menu item: $e',
          code: 'MENU_DELETE_ERROR'));
    }
  }
}
