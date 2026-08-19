import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_constants.dart';
import '../di/injection_container.dart';
import '../storage/secure_storage_service.dart';

final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// A single persisted app-wide preference, not a screen's loading/error/data
/// state — plain [Notifier] rather than [BaseNotifier].
class ThemeModeNotifier extends Notifier<ThemeMode> {
  late final SecureStorageService _secureStorageService;

  @override
  ThemeMode build() {
    _secureStorageService = sl<SecureStorageService>();
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final saved =
        await _secureStorageService.read(key: StorageConstants.themeModeKey);
    if (saved == null) return;
    state = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _secureStorageService.write(
      key: StorageConstants.themeModeKey,
      value: mode.name,
    );
  }
}
