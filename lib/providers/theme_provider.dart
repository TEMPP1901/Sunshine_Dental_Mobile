import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Hàm tải chế độ giao diện đã lưu từ SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  // Lưu và thay đổi chế độ giao diện
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }

  // Kiểm tra đang ở chế độ dark mode hay không
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Chuyển đổi giữa light và dark mode
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}
