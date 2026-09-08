import 'package:restaurant_pos/core/result/result.dart';

abstract class SyncQueueRepository {
  Future<Result<void>> enqueueOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    required String idempotencyKey,
  });

  Future<Result<List<SyncQueueItem>>> getPendingOperations();

  Future<Result<void>> markOperationCompleted(String operationId);

  Future<Result<void>> markOperationFailed(String operationId, String error);
}

class SyncQueueItem {
  final int? id;
  final String operationId;
  final String operationType;
  final String entityType;
  final String entityId;
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String status;
  final String? lastError;
  final String idempotencyKey;

  const SyncQueueItem({
    this.id,
    required this.operationId,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    this.nextRetryAt,
    required this.status,
    this.lastError,
    required this.idempotencyKey,
  });
}
