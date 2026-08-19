import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_constants.dart';
import '../error/exceptions.dart';

/// Thin wrapper around [FlutterSecureStorage].
///
/// Two responsibilities:
///  - generic read/write/delete for anything that must never touch disk
///    unencrypted (auth tokens, refresh tokens, etc.)
///  - owning the Hive AES encryption key, generating it once on first launch
///    and handing it back on every later launch so [HiveService] can open
///    encrypted boxes.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to write "$key": $e');
    }
  }

  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to read "$key": $e');
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete "$key": $e');
    }
  }

  /// Returns the persisted Hive encryption key, generating and persisting a
  /// fresh 256-bit key on first ever call.
  Future<List<int>> getOrCreateHiveEncryptionKey() async {
    final existing = await read(key: StorageConstants.hiveEncryptionKeyAlias);
    if (existing != null) {
      return base64Url.decode(existing);
    }

    final key = Hive32ByteKeyGenerator.generate();
    await write(
      key: StorageConstants.hiveEncryptionKeyAlias,
      value: base64UrlEncode(key),
    );
    return key;
  }
}

/// Generates a random 256-bit key suitable for Hive's AES cipher.
class Hive32ByteKeyGenerator {
  const Hive32ByteKeyGenerator._();

  static List<int> generate() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }
}
