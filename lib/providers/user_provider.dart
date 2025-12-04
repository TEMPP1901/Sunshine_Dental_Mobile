import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  UserProvider() {
    _loadUser();
  }

  // Hàm load user từ SharedPreferences khi khởi tạo
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      try {
        _user = jsonDecode(userStr);
        notifyListeners();
      } catch (e) {
        _user = null;
      }
    }
  }

  // Thiết lập user mới và lưu vào SharedPreferences
  Future<void> setUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    _user = userData;
    await prefs.setString('user', jsonEncode(userData));
    notifyListeners();
  }

  // Cập nhật dữ liệu user
  Future<void> updateUser(Map<String, dynamic> updates) async {
    if (_user != null) {
      _user = {..._user!, ...updates};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user));
      notifyListeners();
    }
  }

  // Xóa dữ liệu user khỏi trạng thái ứng dụng
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
