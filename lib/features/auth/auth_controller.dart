import 'package:flutter/foundation.dart';
import 'package:restaurant_pos/core/errors/pos_exception.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/security/secure_storage.dart';
import 'package:restaurant_pos/features/auth/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthRepository authRepository;
  final SecureStorage secureStorage;

  AuthStatus _status = AuthStatus.initial;
  String? _userId;
  String? _userName;
  String? _role;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get role => _role;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthController({required this.authRepository, required this.secureStorage});

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await authRepository.isAuthenticated();
    result.when(
      success: (isAuth) {
        if (isAuth) {
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
        notifyListeners();
      },
      failure: (e, _) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = e is PosException ? e.message : e.toString();
        notifyListeners();
      },
      loading: () {},
      empty: () {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      },
    );
  }

  Future<void> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authRepository.login(username, password);
      result.when(
        success: (_) {
          _status = AuthStatus.authenticated;
          AppLogger.d('Auth', 'Login successful for $username');
          notifyListeners();
        },
        failure: (e, _) {
          _status = AuthStatus.error;
          _errorMessage = e is PosException ? e.message : e.toString();
          AppLogger.e('Auth',
              'Login failed: ${e is PosException ? e.message : e.toString()}');
          notifyListeners();
        },
        loading: () {},
        empty: () {},
      );
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Unexpected error during login';
      AppLogger.e('Auth', 'Login exception', error: e);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await authRepository.logout();
      _userId = null;
      _userName = null;
      _role = null;
      _status = AuthStatus.unauthenticated;
      AppLogger.d('Auth', 'Logout successful');
      notifyListeners();
    } catch (e) {
      AppLogger.e('Auth', 'Logout error', error: e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
}
