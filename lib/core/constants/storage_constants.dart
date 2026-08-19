/// Central place for local-storage keys/box names so features never hardcode
/// string literals when talking to Hive or Secure Storage.
class StorageConstants {
  const StorageConstants._();

  // flutter_secure_storage keys
  static const String hiveEncryptionKeyAlias = 'hive_encryption_key';
  static const String themeModeKey = 'theme_mode';

  // Hive box names
  static const String tasksBox = 'tasks_box';
}
