import 'package:restaurant_pos/core/errors/pos_exception.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/networking/api_client.dart';
import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/core/security/secure_storage.dart';
import 'package:restaurant_pos/features/auth/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final SecureStorage secureStorage;

  const AuthRepositoryImpl(this.apiClient, this.secureStorage);

  @override
  Future<Result<void>> login(String username, String password) async {
    try {
      AppLogger.d('AuthRepository', 'Login attempt for $username');

      final response = await apiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;

        await secureStorage.write('access_token', token);
        await secureStorage.write('refresh_token', refreshToken);
        await apiClient.setAuthToken(token);

        AppLogger.d('AuthRepository', 'Login successful');
        return const Success(null);
      } else {
        return Failure(
            AuthException('Invalid credentials', code: 'INVALID_CREDENTIALS'));
      }
    } on AuthException catch (e) {
      return Failure(e);
    } catch (e) {
      AppLogger.e('AuthRepository', 'Login failed', error: e);
      return Failure(AuthException('Login failed: $e', code: 'LOGIN_ERROR'));
    }
  }

  @override
  Future<Result<void>> refreshToken() async {
    try {
      final refreshToken = await secureStorage.read('refresh_token');
      if (refreshToken == null) {
        return Failure(AuthException('No refresh token available',
            code: 'NO_REFRESH_TOKEN'));
      }

      final response = await apiClient.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String;

        await secureStorage.write('access_token', token);
        await secureStorage.write('refresh_token', newRefreshToken);
        await apiClient.setAuthToken(token);

        return const Success(null);
      } else {
        return Failure(
            AuthException('Token refresh failed', code: 'REFRESH_ERROR'));
      }
    } catch (e) {
      return Failure(
          AuthException('Token refresh failed: $e', code: 'REFRESH_ERROR'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } catch (e) {
      AppLogger.w('AuthRepository', 'Logout request failed: $e');
    } finally {
      await secureStorage.deleteAll();
      await apiClient.clearAuthToken();
    }
    return const Success(null);
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final token = await secureStorage.read('access_token');
      if (token == null) return const Success(false);

      final response = await apiClient.get('/auth/me');
      return Success(response.statusCode == 200);
    } catch (e) {
      return const Success(false);
    }
  }

  @override
  Future<Result<void>> saveSession(String token, String refreshToken) async {
    try {
      await secureStorage.write('access_token', token);
      await secureStorage.write('refresh_token', refreshToken);
      await apiClient.setAuthToken(token);
      return const Success(null);
    } catch (e) {
      return Failure(
          AuthException('Failed to save session', code: 'SESSION_ERROR'));
    }
  }
}
