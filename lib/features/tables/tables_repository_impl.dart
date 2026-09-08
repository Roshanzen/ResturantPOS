import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/errors/pos_exception.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/features/tables/tables_repository.dart';

class TablesRepositoryImpl implements TablesRepository {
  final DatabaseService database;

  const TablesRepositoryImpl(this.database);

  @override
  Future<Result<List<RestaurantTable>>> getTables() async {
    try {
      final rows = await database.query('tables', orderBy: 'name ASC');
      final tables = rows.map((row) {
        return RestaurantTable(
          id: row['id'] as String,
          name: row['name'] as String,
          floor: row['location'] as String,
          capacity: row['capacity'] as int,
          status: row['status'] as String,
          activeOrderId: null,
          reservationStatus: null,
          version: 1,
          updatedAt: DateTime.parse(row['updated_at'] as String),
        );
      }).toList();
      return Success(tables);
    } catch (e) {
      AppLogger.e('TablesRepository', 'Failed to load tables', error: e);
      return Failure(
          PosException('Failed to load tables: $e', code: 'TABLES_LOAD_ERROR'));
    }
  }

  @override
  Future<Result<RestaurantTable>> updateTableStatus(
      String tableId, String status) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'tables',
        {'status': status, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [tableId],
      );
      final rows = await database.query('tables',
          where: 'id = ?', whereArgs: [tableId], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PosException('Table not found', code: 'TABLE_NOT_FOUND'));
      }
      final row = rows.first;
      final table = RestaurantTable(
        id: row['id'] as String,
        name: row['name'] as String,
        floor: row['location'] as String,
        capacity: row['capacity'] as int,
        status: row['status'] as String,
        activeOrderId: null,
        reservationStatus: null,
        version: 1,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
      return Success(table);
    } catch (e) {
      AppLogger.e('TablesRepository', 'Failed to update table', error: e);
      return Failure(PosException('Failed to update table: $e',
          code: 'TABLE_UPDATE_ERROR'));
    }
  }
}
