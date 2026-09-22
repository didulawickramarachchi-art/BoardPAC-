import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (_) => ThemeModeNotifier(SecureStorageService()),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _storageKey = 'app_theme_mode';
  final SecureStorageService _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    unawaited(_load());
  }

  Future<void> _load() async {
    final saved = await _storage.read(_storageKey);
    if (!mounted) return;
    state = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(_storageKey, mode.name);
  }
}
