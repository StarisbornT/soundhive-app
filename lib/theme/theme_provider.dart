import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode themeMode;
  final bool isLoading;

  ThemeState({
    required this.themeMode,
    this.isLoading = true,
  });
}

// We use a FutureProvider to get the SharedPreferences instance
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // This will be overridden in main.dart
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;
  static const _themeKey = 'app_theme_mode';

  // Default to light and loading: true
  ThemeModeNotifier(this._prefs)
      : super(ThemeState(themeMode: ThemeMode.dark, isLoading: true)) {
    _init();
  }

  void _init() {
    final savedTheme = _prefs.getString(_themeKey);

    if (savedTheme == 'light') {
      state = ThemeState(themeMode: ThemeMode.light, isLoading: false);
    } else {
      // Default to DARK
      state = ThemeState(themeMode: ThemeMode.dark, isLoading: false);
    }
  }


  Future<void> toggleTheme(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = ThemeState(themeMode: mode, isLoading: false);

    // Save to disk
    await _prefs.setString(_themeKey, isDark ? 'dark' : 'light');
  }
}