import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Lấy baseUrl phù hợp với môi trường và nền tảng
  static String _resolveBaseUrl() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      debugPrint(' [ApiService] Using API_URL from environment: $envUrl');
      return envUrl;
    }

    if (kIsWeb) {
      debugPrint(' [ApiService] Platform: Web, using localhost:8080');
      return 'http://localhost:8080';
    }

    if (!kIsWeb && Platform.isAndroid) {
      // Nếu đang chạy trên Android emulator: 10.0.2.2
      // Nếu test trên thiết bị thật: dùng IP của máy tính trong mạng nội bộ
      // Để thay đổi IP, chạy: flutter run --dart-define=API_URL=http://192.168.1.122:8080
      final baseUrl = 'http://172.16.1.228:8080';
      debugPrint(' [ApiService] Platform: Android, using: $baseUrl');
      debugPrint(' [ApiService] For emulator, use: flutter run --dart-define=API_URL=http://10.0.2.2:8080');
      return baseUrl;
    }

    // Mặc định cho iOS/Khác: dùng localhost
    debugPrint(' [ApiService] Platform: iOS/Other, using localhost:8080');
    return 'http://localhost:8080';
  }

  static final String baseUrl = _resolveBaseUrl();
  static final Uri _baseUri = Uri.parse(baseUrl);
  static String? cachedToken;

  late Dio _dio;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  // Khởi tạo Dio instance + interceptor để tự động gắn token
  ApiService._internal() {
    debugPrint(' [ApiService] Initializing with baseUrl: $baseUrl');
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null && token.isNotEmpty) {
          cachedToken = token;
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token hết hạn hoặc không hợp lệ - xóa token khỏi storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('accessToken');
          await prefs.remove('user');
          cachedToken = null;
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // Header Authorization từ token cache (dành cho xuống NetworkImage...)
  static Map<String, String>? authHeaders() {
    final token = cachedToken;
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  // Xử lý path ảnh đại diện: nếu là asset trả về AssetImage, nếu link thì trả về NetworkImage với header đã gắn token
  static ImageProvider resolveAvatarImage(String? avatarUrl, {String defaultAsset = 'assets/images/doctor.png'}) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return AssetImage(defaultAsset);
    }

    final trimmed = avatarUrl.trim();

    if (trimmed.startsWith('assets/') || trimmed.startsWith('/assets/')) {
      final assetPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
      return AssetImage(assetPath);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(
        trimmed,
        headers: authHeaders(),
      );
    }

    final resolvedUrl = resolveUrl(trimmed);
    if (resolvedUrl.isEmpty) {
      return AssetImage(defaultAsset);
    }

    return NetworkImage(
      resolvedUrl,
      headers: authHeaders(),
    );
  }

  // Chuẩn hóa URL để lấy ảnh hoặc file từ server (tự động thay localhost phù hợp)
  static String resolveUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final value = raw.trim();

    if (value.startsWith('assets/') || value.startsWith('/assets/')) {
      return '';
    }

    if (value.startsWith('http')) {
      try {
        final uri = Uri.parse(value);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          return uri.replace(
            scheme: _baseUri.scheme,
            host: _baseUri.host,
            port: _baseUri.hasPort ? _baseUri.port : uri.port,
          ).toString();
        }
        return value;
      } catch (_) {
        return value;
      }
    }

    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return _baseUri.replace(path: normalizedPath).toString();
  }

  // Hàm GET dữ liệu
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Hàm POST dữ liệu
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Hàm PUT dữ liệu
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Hàm PATCH dữ liệu
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Hàm DELETE dữ liệu
  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Gửi dữ liệu kiểu multipart/form-data qua POST
  Future<Response> postFormData(String path, FormData formData) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Gửi dữ liệu kiểu multipart/form-data qua PATCH
  Future<Response> patchFormData(String path, FormData formData) async {
    try {
      return await _dio.patch(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
