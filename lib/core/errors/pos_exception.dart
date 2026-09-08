class PosException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const PosException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'PosException: $message${code != null ? " ($code)" : ""}';
}

class NetworkException extends PosException {
  const NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class AuthException extends PosException {
  const AuthException(String message, {String? code})
      : super(message, code: code);
}

class ValidationException extends PosException {
  final Map<String, String>? fieldErrors;

  const ValidationException(String message, {this.fieldErrors, String? code})
      : super(message, code: code);
}

class ConflictException extends PosException {
  final String? serverVersion;

  const ConflictException(String message, {this.serverVersion, String? code})
      : super(message, code: code);
}

class PaymentException extends PosException {
  const PaymentException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}
