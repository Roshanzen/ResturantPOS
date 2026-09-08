import 'package:dio/dio.dart';
import 'package:restaurant_pos/app/environment.dart';
import 'package:restaurant_pos/core/security/secure_storage.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorage _secureStorage;
  final bool _enableMockApi;

  ApiClient({
    required Dio dio,
    required SecureStorage secureStorage,
    bool enableMockApi = false,
  })  : _dio = dio,
        _secureStorage = secureStorage,
        _enableMockApi = enableMockApi;

  Future<void> init() async {
    _dio.options.baseUrl = AppEnvironment.current.apiBaseUrl;
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['Content-Type'] = 'application/json';

    final token = await _secureStorage.read('access_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> setAuthToken(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    await _secureStorage.write('access_token', token);
  }

  Future<void> clearAuthToken() async {
    _dio.options.headers.remove('Authorization');
    await _secureStorage.delete('access_token');
  }

  Future<String?> getAuthToken() => _secureStorage.read('access_token');

  Future<Response> _handleRequest(String method, String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (_enableMockApi) {
      AppLogger.d('ApiClient', 'Mock $method $path');
      return _mockResponse(method, path, data);
    }

    try {
      final result = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      return result;
    } catch (e) {
      AppLogger.e('ApiClient', '$method $path failed', error: e);
      rethrow;
    }
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return _handleRequest('GET', path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _handleRequest('POST', path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return _handleRequest('PATCH', path, data: data);
  }

  Future<Response> delete(String path) async {
    return _handleRequest('DELETE', path);
  }

  Response _mockResponse(String method, String path, dynamic data) {
    final requestOptions = RequestOptions(path: path, method: method);

    if (path.endsWith('/auth/login') && method == 'POST') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {
          'access_token':
              'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
          'refresh_token':
              'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    }

    if (path.endsWith('/auth/refresh') && method == 'POST') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {
          'access_token':
              'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
          'refresh_token':
              'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    }

    if (path.endsWith('/auth/me') && method == 'GET') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {
          'id': 'user_001',
          'username': 'cashier',
          'role': 'cashier',
          'branch_id': 'branch_001',
          'terminal_id': 'terminal_001',
        },
      );
    }

    if (path.endsWith('/auth/logout') && method == 'POST') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 204,
        data: null,
      );
    }

    if (path.endsWith('/menu/items') && method == 'GET') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: [],
      );
    }

    if (path.endsWith('/tables') && method == 'GET') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: [],
      );
    }

    if (path.endsWith('/orders') && method == 'GET') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: [],
      );
    }

    if (path.endsWith('/customers') && method == 'GET') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: [],
      );
    }

    if (path.endsWith('/sync/push') && method == 'POST') {
      return Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {
          'results': [],
        },
      );
    }

    return Response(
      requestOptions: requestOptions,
      statusCode: 404,
      data: {
        'error': {
          'code': 'NOT_FOUND',
          'message': 'Mock endpoint not implemented: $method $path'
        }
      },
    );
  }
}
