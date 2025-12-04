
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Lưu trữ và quản lý ngôn ngữ ứng dụng
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LanguageProvider() {
    loadLanguage();
  }

  // Hàm tải ngôn ngữ đã lưu từ SharedPreferences
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  // Thiết lập ngôn ngữ mới và lưu lại vào SharedPreferences
  Future<void> setLanguage(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }

  // Chuyển đổi qua lại giữa tiếng Anh và tiếng Việt
  Future<void> toggleLanguage() async {
    final newLocale = _locale.languageCode == 'en' 
        ? const Locale('vi') 
        : const Locale('en');
    await setLanguage(newLocale);
  }

  String get currentLanguage => _locale.languageCode;

  String get currentLanguageName {
    return _locale.languageCode == 'en' ? 'English' : 'Vietnamese';
  }
}

