import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign In
import '../services/api_service.dart';
import '../models/auth_models.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // scopes: ['email', 'profile'], // Thường không cần khai báo nếu chỉ login cơ bản
  );

  UserProvider() {
    _loadUser();
  }

  // --- 1. LOGIN EMAIL ---
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _apiService.post(
        '/api/auth/login',
        data: request.toJson(),
      );
      await _handleLoginSuccess(response.data);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- 2. LOGIN PHONE + PASSWORD ---
  Future<bool> loginPhonePassword(String phone, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiService.post(
        '/api/auth/login-phone/password',
        data: {'phone': phone, 'password': password},
      );
      await _handleLoginSuccess(response.data);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- 3. LOGIN PHONE + OTP (STEP 1) ---
  Future<bool> sendOtp(String phone) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _apiService.post(
        '/api/auth/login-phone/step1',
        data: {'phone': phone},
      );
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- 4. LOGIN PHONE + OTP (STEP 2) ---
  Future<bool> loginPhoneOtp(String phone, String otp) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiService.post(
        '/api/auth/login-phone/step2',
        data: {'phone': phone, 'otp': otp},
      );
      await _handleLoginSuccess(response.data);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- 5. FORGOT PASSWORD ---
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _apiService.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- 6. SIGN UP ---
  Future<int?> signUp({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    String? avatarUrl,
    String locale = 'vi',
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiService.post(
        '/api/auth/sign-up',
        data: {
          'fullName': fullName,
          'username': username,
          'email': email,
          'phone': phone,
          'password': password,
          'avatarUrl': avatarUrl,
          'locale': locale,
        },
      );
      return response.data['userId'];
    } on DioException catch (e) {
      _handleError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // --- 7. LOGIN WITH GOOGLE (MỚI THÊM) ---
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // 1. Mở popup đăng nhập Google Native
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User hủy đăng nhập
        _setLoading(false);
        return false;
      }

      // 2. Lấy Authentication (idToken, accessToken)
      // Thêm await vào
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint("Google ID Token: ${googleAuth.idToken}");

      // 3. Gửi Token xuống Backend để verify và lấy JWT
      // Lưu ý: Backend cần có API nhận idToken này.
      // Nếu Backend chưa có, bạn cần tạo thêm endpoint /api/auth/google-mobile
      final response = await _apiService.post(
        '/api/auth/google-mobile',
        data: {
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'fullName': googleUser.displayName,
          'avatarUrl': googleUser.photoUrl,
        },
      );

      await _handleLoginSuccess(response.data);
      return true;
    } catch (e) {
      // Logout Google để lần sau chọn lại tk khác được
      _googleSignIn.signOut();
      _errorMessage = 'Google Login Failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- 8. UPLOAD AVATAR ---
  Future<bool> uploadAvatar(int userId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      await _apiService.patchFormData('/api/users/$userId/avatar', formData);
      return true;
    } catch (e) {
      debugPrint('Upload avatar failed: $e');
      return false;
    }
  }

  // --- HELPER HANDLERS ---
  Future<void> _handleLoginSuccess(dynamic data) async {
    final String token = data['accessToken'] ?? data['token'];

    final List<String> rawRoles = (data['roles'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final normalizedRoles = rawRoles
        .map(
          (r) => r
              .replaceAll(RegExp(r'^ROLE_', caseSensitive: false), '')
              .toUpperCase(),
        )
        .toList();

    final Map<String, dynamic> userDataMap = {
      'userId': data['userId'],
      'username': data['username'] ?? data['email'],
      'fullName': data['fullName'],
      'email': data['email'],
      'phone': data['phone'],
      'avatarUrl': data['avatarUrl'],
      'roles': normalizedRoles,
      'hasPassword': true,
    };
    await _saveAuthData(token, userDataMap);
  }

  void _handleError(DioException e) {
    if (e.response != null) {
      final msg = e.response?.data['message'];
      if (msg is List) {
        _errorMessage = msg.join('\n');
      } else {
        _errorMessage = msg ?? 'Thao tác thất bại (${e.response?.statusCode})';
      }
    } else {
      _errorMessage = 'Lỗi kết nối mạng.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('user');
    await prefs.remove('roles');
    await _googleSignIn.signOut(); // Logout Google luôn
    _user = null;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    final token = prefs.getString('accessToken');
    if (userStr != null && token != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userStr);
        _user = User.fromJson(userMap);
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    _user = User.fromJson(userMap);
    await prefs.setString('user', jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> setUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveAuthData(prefs.getString('accessToken') ?? '', userData);
  }

  Future<void> updateUser(Map<String, dynamic> updates) async {
    if (_user == null) return;
    User updatedUser = _user!.copyWith(
      fullName: updates['fullName'],
      email: updates['email'],
      phone: updates['phone'],
      avatarUrl: updates['avatarUrl'],
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    await _saveAuthData(token, updatedUser.toJson());
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- 9. LOGIN WITH QR CODE (MỚI) ---
  Future<bool> loginWithQrCode(String qrToken) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // Backend của bạn: POST /api/auth/qr-login?token=...
      final response = await _apiService.post(
        '/api/auth/qr-login',
        queryParameters: {'token': qrToken},
        data: {}, // Body rỗng vì token gửi qua query param
      );

      // Response trả về có dạng { message: "...", result: { accessToken... } }
      // Kiểm tra cấu trúc ApiResponse của backend bạn
      final resultData = response.data['result'] ?? response.data;

      await _handleLoginSuccess(resultData);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
