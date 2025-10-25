import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = const Color(0xFF6366F1);

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  ThemeProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final themeModeStr = await _storageService.getThemeMode();
    _themeMode = _parseThemeMode(themeModeStr);

    // Load accent color from preferences
    final accentColorValue = await _storageService.getPreference<int>(
      'accent_color',
    );
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }

    notifyListeners();
  }

  ThemeMode _parseThemeMode(String themeModeStr) {
    switch (themeModeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _storageService.setThemeMode(_themeModeToString(themeMode));
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _storageService.storePreference('accent_color', color.toARGB32());
    notifyListeners();
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  // Check if dark mode is enabled
  bool isDarkMode(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  // Get current theme data
  ThemeData getThemeData(BuildContext context) {
    final isDark = isDarkMode(context);

    if (isDark) {
      return ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: _accentColor,
          secondary: _accentColor.withValues(alpha: 0.8),
        ),
      );
    } else {
      return ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: _accentColor,
          secondary: _accentColor.withValues(alpha: 0.8),
        ),
      );
    }
  }

  // Reset to default theme
  Future<void> resetTheme() async {
    await setThemeMode(ThemeMode.system);
    await setAccentColor(const Color(0xFF6366F1));
  }
}
