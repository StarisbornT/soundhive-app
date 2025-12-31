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
      : super(ThemeState(themeMode: ThemeMode.light, isLoading: true)) {
    _init();
  }

  void _init() {
    // SharedPreferences is faster, we read the string saved
    final savedTheme = _prefs.getString(_themeKey);

    if (savedTheme == 'dark') {
      state = ThemeState(themeMode: ThemeMode.dark, isLoading: false);
    } else {
      // Default to light if nothing is saved or if 'light' is saved
      state = ThemeState(themeMode: ThemeMode.light, isLoading: false);
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = ThemeState(themeMode: mode, isLoading: false);

    // Save to disk
    await _prefs.setString(_themeKey, isDark ? 'dark' : 'light');
  }
}