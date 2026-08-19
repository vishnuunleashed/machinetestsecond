/// Thrown by data sources. Repositories catch these and convert them into
/// [Failure]s so the domain/presentation layers never see raw exceptions.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local cache error']);
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
}

class SecureStorageException implements Exception {
  final String message;
  const SecureStorageException([this.message = 'Secure storage error']);
}
