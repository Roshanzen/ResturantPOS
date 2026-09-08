import 'package:restaurant_pos/core/result/result.dart';

abstract class AuthRepository {
  Future<Result<void>> login(String username, String password);
  Future<Result<void>> refreshToken();
  Future<Result<void>> logout();
  Future<Result<bool>> isAuthenticated();
  Future<Result<void>> saveSession(String token, String refreshToken);
}
