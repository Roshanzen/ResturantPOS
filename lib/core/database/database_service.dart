import 'package:flutter/foundation.dart';
import 'package:restaurant_pos/core/database/database_service_native.dart';
import 'package:restaurant_pos/core/database/database_service_web.dart';

abstract class DatabaseService {
  Future<void> initialize();
  Future<void> seedInitialData();
  Future<int> insertOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    required String idempotencyKey,
  });
  Future<List<Map<String, dynamic>>> getPendingOperations();
  Future<void> markOperationCompleted(int id);
  Future<void> markOperationFailed(int id, String error);
  Future<void> clearAllData();
  Future<int> insert(String table, Map<String, dynamic> data);
  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<dynamic>? whereArgs});
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs, int? limit, String? orderBy});
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});
}

DatabaseService createDatabaseService() {
  if (kIsWeb) {
    return WebDatabaseService();
  }
  return NativeDatabaseService();
}
