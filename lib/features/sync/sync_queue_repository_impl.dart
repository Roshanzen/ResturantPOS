import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/features/sync/sync_queue_repository.dart';

class SyncQueueRepositoryImpl implements SyncQueueRepository {
  final DatabaseService database;

  const SyncQueueRepositoryImpl(this.database);

  @override
  Future<Result<void>> enqueueOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    required String idempotencyKey,
  }) async {
    try {
      await database.insertOperation(
        operationType: operationType,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      return const Success(null);
    } catch (e) {
      return Failure(Exception('Failed to enqueue operation: $e'),
          code: 'SYNC_ENQUEUE_ERROR');
    }
  }

  @override
  Future<Result<List<SyncQueueItem>>> getPendingOperations() async {
    try {
      final entities = await database.getPendingOperations();
      final items = entities
          .map((e) => SyncQueueItem(
                id: e['id'] as int?,
                operationId: e['operation_id'] as String,
                operationType: e['operation_type'] as String,
                entityType: e['entity_type'] as String,
                entityId: e['entity_id'] as String,
                payload: e['payload'] as String,
                createdAt: DateTime.parse(e['created_at'] as String),
                retryCount: e['retry_count'] as int,
                nextRetryAt: e['next_retry_at'] != null
                    ? DateTime.parse(e['next_retry_at'] as String)
                    : null,
                status: e['status'] as String,
                lastError: e['last_error'] as String?,
                idempotencyKey: e['idempotency_key'] as String,
              ))
          .toList();
      return Success(items);
    } catch (e) {
      return Failure(Exception('Failed to get pending operations: $e'),
          code: 'SYNC_LOAD_ERROR');
    }
  }

  @override
  Future<Result<void>> markOperationCompleted(String operationId) async {
    try {
      final id = int.tryParse(operationId);
      if (id == null) {
        return Failure(Exception('Invalid operation ID'),
            code: 'SYNC_COMPLETE_ERROR');
      }
      await database.markOperationCompleted(id);
      return const Success(null);
    } catch (e) {
      return Failure(Exception('Failed to mark operation completed: $e'),
          code: 'SYNC_COMPLETE_ERROR');
    }
  }

  @override
  Future<Result<void>> markOperationFailed(
      String operationId, String error) async {
    try {
      final id = int.tryParse(operationId);
      if (id == null) {
        return Failure(Exception('Invalid operation ID'),
            code: 'SYNC_FAIL_ERROR');
      }
      await database.markOperationFailed(id, error);
      return const Success(null);
    } catch (e) {
      return Failure(Exception('Failed to mark operation failed: $e'),
          code: 'SYNC_FAIL_ERROR');
    }
  }
}
