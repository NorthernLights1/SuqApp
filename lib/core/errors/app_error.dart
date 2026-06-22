sealed class AppError implements Exception {
  const AppError(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkError extends AppError {
  const NetworkError([super.message = 'No internet connection.']);
}

final class AuthError extends AppError {
  const AuthError([super.message = 'Authentication failed.']);
}

final class PermissionError extends AppError {
  const PermissionError([super.message = 'You do not have permission to perform this action.']);
}

final class NotFoundError extends AppError {
  const NotFoundError([super.message = 'The requested resource was not found.']);
}

final class ValidationError extends AppError {
  const ValidationError(super.message);
}

final class SyncError extends AppError {
  const SyncError([super.message = 'Sync failed. Changes saved locally.']);
}
