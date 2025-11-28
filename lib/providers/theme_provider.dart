import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Service pour gérer la sauvegarde du thème
class ThemeService {
  static const String _themeModeKey = 'theme_mode';

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString(_themeModeKey);
    
    if (themeModeStr == null) {
      return ThemeMode.light; // Par défaut, thème clair
    }
    
    return ThemeMode.values.firstWhere(
      (mode) => mode.toString() == themeModeStr,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.toString());
  }
}

// Provider du service de thème
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

// Notifier pour gérer le ThemeMode
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeModeNotifier(this._themeService) : super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    state = await _themeService.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _themeService.setThemeMode(mode);
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  void setSystemTheme() {
    setThemeMode(ThemeMode.system);
  }
}

// Provider du ThemeMode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeModeNotifier(themeService);
});

// Provider pour savoir si on est en mode sombre (helper)
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  if (themeMode == ThemeMode.system) {
    // Vérifier le thème du système
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }
  return themeMode == ThemeMode.dark;
});
