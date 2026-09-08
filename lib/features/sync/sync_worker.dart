import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/networking/api_client.dart';

class SyncWorker {
  final ApiClient apiClient;
  final DatabaseService database;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  SyncWorker({required this.apiClient, required this.database});

  void start() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnectivity = results.any(
        (r) => r != ConnectivityResult.none,
      );
      if (hasConnectivity) {
        _processQueue();
      }
    });

    _processQueue();
    AppLogger.d('SyncWorker', 'Sync worker started');
  }

  void stop() {
    _subscription?.cancel();
    AppLogger.d('SyncWorker', 'Sync worker stopped');
  }

  Future<void> _processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await database.getPendingOperations();
      for (final item in pending) {
        await _processOperation(item);
      }
    } catch (e, s) {
      AppLogger.e('SyncWorker', 'Sync queue processing failed',
          error: e, stackTrace: s);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processOperation(Map<String, dynamic> item) async {
    try {
      AppLogger.d('SyncWorker',
          'Processing ${item['operation_type']} for ${item['entity_type']}:${item['entity_id']}');

      final response = await apiClient.post('/sync/push', data: {
        'operationType': item['operation_type'],
        'entityType': item['entity_type'],
        'entityId': item['entity_id'],
        'payload': item['payload'],
        'idempotencyKey': item['idempotency_key'],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await database.markOperationCompleted(item['id'] as int);
        AppLogger.d(
            'SyncWorker', 'Operation ${item['operation_id']} completed');
      } else {
        await database.markOperationFailed(
            item['id'] as int, 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e('SyncWorker', 'Operation ${item['operation_id']} failed',
          error: e);
      await database.markOperationFailed(item['id'] as int, e.toString());
    }
  }
}
