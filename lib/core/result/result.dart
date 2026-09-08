sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(Exception error, String? code) failure,
    required R Function() loading,
    required R Function() empty,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else if (this is Failure<T>) {
      final failureResult = this as Failure<T>;
      return failure(failureResult.error, failureResult.code);
    } else if (this is Loading<T>) {
      return loading();
    } else if (this is Empty<T>) {
      return empty();
    }
    throw UnsupportedError('Unknown Result subtype');
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final Exception error;
  final String? code;
  const Failure(this.error, {this.code});
}

class Loading<T> extends Result<T> {
  const Loading();
}

class Empty<T> extends Result<T> {
  const Empty();
}
