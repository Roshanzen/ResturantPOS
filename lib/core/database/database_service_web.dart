import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_pos/core/database/database_service.dart';

class WebDatabaseService implements DatabaseService {
  static const String _storageKey = 'restaurant_pos_db';
  Map<String, List<Map<String, dynamic>>> _data = {};
  int _nextId = 1;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final decoded = json.decode(stored) as Map<String, dynamic>;
      _data = decoded.map((key, value) {
        final list = (value as List).cast<Map<String, dynamic>>();
        return MapEntry(key, list);
      });
    } else {
      _data = {};
    }
    _nextId = _data.values.fold(0, (max, list) {
          final ids = list
              .where((e) => e['id'] is int)
              .map((e) => e['id'] as int)
              .toList();
          return ids.isNotEmpty ? ids.reduce((a, b) => a > b ? a : b) : max;
        }) +
        1;
    _initialized = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_data);
    await prefs.setString(_storageKey, encoded);
  }

  @override
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  @override
  Future<void> seedInitialData() async {
    await _ensureInitialized();
    // Production database initializes clean with zero demo records.
  }


  @override
  Future<int> insertOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    required String idempotencyKey,
  }) async {
    await _ensureInitialized();
    final operationId =
        'op_${DateTime.now().millisecondsSinceEpoch}_${idempotencyKey.hashCode}';
    final id = _nextId++;
    _data.putIfAbsent('sync_queue', () => []).add({
      'id': id,
      'operation_id': operationId,
      'operation_type': operationType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
      'next_retry_at': null,
      'last_error': null,
      'idempotency_key': idempotencyKey,
    });
    await _persist();
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    await _ensureInitialized();
    final now = DateTime.now().toIso8601String();
    final list = _data['sync_queue'] ?? [];
    return list.where((item) {
      final status = item['status'] as String;
      final nextRetry = item['next_retry_at'] as String?;
      if (status == 'pending') return true;
      if (status == 'failed' &&
          nextRetry != null &&
          nextRetry.compareTo(now) <= 0) return true;
      return false;
    }).toList();
  }

  @override
  Future<void> markOperationCompleted(int id) async {
    await _ensureInitialized();
    final list = _data['sync_queue'] ?? [];
    for (final item in list) {
      if (item['id'] == id) {
        item['status'] = 'completed';
        item['updated_at'] = DateTime.now().toIso8601String();
        break;
      }
    }
    await _persist();
  }

  @override
  Future<void> markOperationFailed(int id, String error) async {
    await _ensureInitialized();
    final list = _data['sync_queue'] ?? [];
    for (final item in list) {
      if (item['id'] == id) {
        item['status'] = 'failed';
        item['retry_count'] = 1;
        item['next_retry_at'] =
            DateTime.now().add(const Duration(minutes: 5)).toIso8601String();
        item['last_error'] = error;
        item['updated_at'] = DateTime.now().toIso8601String();
        break;
      }
    }
    await _persist();
  }

  @override
  Future<void> clearAllData() async {
    _data = {};
    await _persist();
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    await _ensureInitialized();
    _data.putIfAbsent(table, () => []).add(data);
    await _persist();
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<dynamic>? whereArgs}) async {
    await _ensureInitialized();
    final list = _data[table] ?? [];
    for (final item in list) {
      if (_matchesWhere(item, where, whereArgs)) {
        item.addAll(data);
      }
    }
    await _persist();
    return 1;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where,
      List<dynamic>? whereArgs,
      int? limit,
      String? orderBy}) async {
    await _ensureInitialized();
    var list = List<Map<String, dynamic>>.from(_data[table] ?? []);
    if (where != null && whereArgs != null) {
      list =
          list.where((item) => _matchesWhere(item, where, whereArgs)).toList();
    }
    if (orderBy != null) {
      list.sort((a, b) {
        final aVal = a[orderBy];
        final bVal = b[orderBy];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return -1;
        if (bVal == null) return 1;
        return aVal.toString().compareTo(bVal.toString());
      });
    }
    if (limit != null) {
      list = list.take(limit).toList();
    }
    return list;
  }

  @override
  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    await _ensureInitialized();
    final list = _data[table] ?? [];
    final initialLength = list.length;
    _data[table] =
        list.where((item) => !_matchesWhere(item, where, whereArgs)).toList();
    await _persist();
    return initialLength - _data[table]!.length;
  }

  bool _matchesWhere(
      Map<String, dynamic> item, String? where, List<dynamic>? whereArgs) {
    if (where == null || whereArgs == null || whereArgs.isEmpty) return true;
    final column = where.replaceAll('?', '').trim();
    final value = whereArgs.first;
    final itemValue = item[column];
    if (itemValue == null && value == null) return true;
    if (itemValue == null || value == null) return false;
    return itemValue.toString() == value.toString();
  }
}
