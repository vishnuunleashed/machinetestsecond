import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_constants.dart';
import 'secure_storage_service.dart';

/// Owns Hive initialization and box access. The encryption key itself is
/// never stored in this class or on disk in the clear — it's fetched from
/// [SecureStorageService] every time a box needs to be opened.
class HiveService {
  final SecureStorageService _secureStorageService;
  late final HiveAesCipher _cipher;
  bool _initialized = false;

  HiveService(this._secureStorageService);

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();
    final key = await _secureStorageService.getOrCreateHiveEncryptionKey();
    _cipher = HiveAesCipher(key);
    _initialized = true;
  }

  Future<Box<T>> openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return Hive.openBox<T>(name, encryptionCipher: _cipher);
  }

  Future<Box> get tasksBox => openBox(StorageConstants.tasksBox);
}
