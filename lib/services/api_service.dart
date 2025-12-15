import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Lấy baseUrl phù hợp với môi trường và nền tảng
  static String _resolveBaseUrl() {
    // 1. Ưu tiên lấy từ biến môi trường (nếu chạy lệnh flutter run --dart-define=API_URL=...)
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      debugPrint(' [ApiService] Using API_URL from environment: $envUrl');
      return envUrl;
    }

    // 2. Cấu hình cho Web
    if (kIsWeb) {
      debugPrint(' [ApiService] Platform: Web, using localhost:8080');
      return 'http://localhost:8080';
    }

    // 3. Cấu hình cho Android
    if (!kIsWeb && Platform.isAndroid) {
      // QUAN TRỌNG:
      // - 10.0.2.2: Là địa chỉ localhost của máy tính (Host) khi nhìn từ Máy ảo (Emulator).
      // - Nếu bạn chạy trên ĐIỆN THOẠI THẬT: Bạn phải đổi lại thành IP LAN (ví dụ: 192.168.1.x)

      const baseUrl = 'http://10.0.2.2:8080';

      debugPrint(' [ApiService] Platform: Android Emulator, using: $baseUrl');
      debugPrint(
        ' [ApiService] Note: If using real device, use --dart-define=API_URL=http://YOUR_LAN_IP:8080',
      );

      return baseUrl;
    }

    // 4. Mặc định cho iOS/Khác
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
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          seconds: 15,
        ), // Tăng timeout lên 15s cho chắc
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('accessToken');
          if (token != null && token.isNotEmpty) {
            cachedToken = token;
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint(
            '--> ${options.method} ${options.path}',
          ); // Log request để dễ debug
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '<-- ${response.statusCode} ${response.requestOptions.path}',
          ); // Log response
          return handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint(
            ' [ApiService] Error: ${error.message} (${error.response?.statusCode})',
          );
          if (error.response?.statusCode == 401) {
            // Token hết hạn hoặc không hợp lệ - xóa token khỏi storage
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('accessToken');
            await prefs.remove('user');
            cachedToken = null;
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Header Authorization từ token cache (dành cho xuống NetworkImage...)
  static Map<String, String>? authHeaders() {
    final token = cachedToken;
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  // Xử lý path ảnh đại diện
  static ImageProvider resolveAvatarImage(
    String? avatarUrl, {
    String defaultAsset = 'assets/images/doctor.png',
  }) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return AssetImage(defaultAsset);
    }

    final trimmed = avatarUrl.trim();

    if (trimmed.startsWith('assets/') || trimmed.startsWith('/assets/')) {
      final assetPath = trimmed.startsWith('/')
          ? trimmed.substring(1)
          : trimmed;
      return AssetImage(assetPath);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed, headers: authHeaders());
    }

    final resolvedUrl = resolveUrl(trimmed);
    if (resolvedUrl.isEmpty) {
      return AssetImage(defaultAsset);
    }

    return NetworkImage(resolvedUrl, headers: authHeaders());
  }

  // Chuẩn hóa URL (Tự động thay localhost bằng 10.0.2.2 khi cần)
  static String resolveUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final value = raw.trim();

    if (value.startsWith('assets/') || value.startsWith('/assets/')) {
      return '';
    }

    if (value.startsWith('http')) {
      try {
        final uri = Uri.parse(value);
        // Nếu Backend trả về link ảnh là localhost, phải đổi sang IP máy ảo mới load được
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          return uri
              .replace(
                scheme: _baseUri.scheme,
                host: _baseUri.host,
                port: _baseUri.hasPort ? _baseUri.port : uri.port,
              )
              .toString();
        }
        return value;
      } catch (_) {
        return value;
      }
    }

    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return _baseUri.replace(path: normalizedPath).toString();
  }

  // --- CÁC HÀM WRAPPER ---

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> postFormData(String path, FormData formData) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patchFormData(String path, FormData formData) async {
    try {
      return await _dio.patch(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (e) {
      rethrow;
    }
  }
}
