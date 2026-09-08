import 'dart:developer' as developer;

class AppLogger {
  static bool _enabled = false;

  static void init({required bool enabled}) {
    _enabled = enabled;
  }

  static void d(String tag, String message) {
    if (_enabled) {
      developer.log(message, name: tag);
    }
  }

  static void e(String tag, String message,
      {dynamic error, StackTrace? stackTrace}) {
    if (_enabled) {
      developer.log(message, name: tag, error: error, stackTrace: stackTrace);
    }
  }

  static void w(String tag, String message) {
    if (_enabled) {
      developer.log(message, name: '$tag [WARN]');
    }
  }
}
