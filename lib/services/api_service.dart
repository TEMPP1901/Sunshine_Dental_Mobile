import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Bật/tắt log để tránh spam trong profile/release.
  static bool enableLogging = kDebugMode;

  // Xác định baseUrl phù hợp với từng môi trường/chạy trên web, android, ios
  static String _resolveBaseUrl() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      if (enableLogging) debugPrint(' [ApiService] Using API_URL from environment: $envUrl');
      return envUrl;
    }

    if (kIsWeb) {
      if (enableLogging) debugPrint(' [ApiService] Platform: Web, using localhost:8080');
      return 'http://localhost:8080';
    }

    if (!kIsWeb && Platform.isAndroid) {
      // Nếu chạy trên Android: có thể cần dùng địa chỉ IP mạng LAN để kết nối server backend
      // IP này phải khớp với IP của máy chạy backend (kiểm tra bằng ipconfig trên Windows)
      final baseUrl = 'http://192.168.1.5:8080';
      if (enableLogging) {
        debugPrint(' [ApiService] Platform: Android, using: $baseUrl');
        debugPrint(' [ApiService] For emulator, use: flutter run --dart-define=API_URL=http://10.0.2.2:8080');
      }
      return baseUrl;
    }

    if (enableLogging) debugPrint(' [ApiService] Platform: iOS/Other, using localhost:8080');
    return 'http://localhost:8080';
  }

  static final String baseUrl = _resolveBaseUrl();
  static final Uri _baseUri = Uri.parse(baseUrl);
  static String? cachedToken;

  late Dio _dio;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  // Khởi tạo Dio, thêm interceptor để gắn token và xử lý lỗi 401 (token hết hạn, bị sai)
  ApiService._internal() {
    if (enableLogging) debugPrint(' [ApiService] Initializing with baseUrl: $baseUrl');
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
        if (enableLogging) {
          debugPrint(' [ApiService] → ${options.method} ${options.uri}');
          if (options.data != null) {
            debugPrint(' [ApiService] Request data: ${options.data}');
          }
        }
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null && token.isNotEmpty) {
          cachedToken = token;
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (enableLogging) {
          debugPrint(' [ApiService] ← ${response.statusCode} ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (enableLogging) {
          debugPrint(' [ApiService] ✗ Error: ${error.type}');
          debugPrint(' [ApiService] URL: ${error.requestOptions.uri}');
          if (error.response != null) {
            debugPrint(' [ApiService] Status: ${error.response?.statusCode}');
            debugPrint(' [ApiService] Response: ${error.response?.data}');
          } else {
            debugPrint(' [ApiService] Message: ${error.message}');
          }
        }
        if (error.response?.statusCode == 401) {
          // Khi token hết hạn/xảy ra lỗi xác thực thì xóa token ở local storage
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

  // Trả về header Authorization hiện tại từ cache (áp dụng cho tải ảnh/NetworkImage khi cần xác thực)
  static Map<String, String>? authHeaders() {
    final token = cachedToken;
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  // Kiểm tra xem url có phải là link cloudinary (public, không cần đính kèm token)
  static bool _isCloudinaryUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('cloudinary.com') ||
          uri.host.contains('res.cloudinary.com');
    } catch (e) {
      return false;
    }
  }

  // Xử lý ảnh đại diện; ưu tiên asset local, cloudinary hoặc trả về NetworkImage đính kèm token nếu là ảnh từ server nội bộ
  static ImageProvider resolveAvatarImage(String? avatarUrl, {String defaultAsset = 'assets/images/doctor.png'}) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return AssetImage(defaultAsset);
    }

    final trimmed = avatarUrl.trim();

    if (trimmed.startsWith('assets/') || trimmed.startsWith('/assets/')) {
      final assetPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
      return AssetImage(assetPath);
    }

    if (trimmed.startsWith('http') && _isCloudinaryUrl(trimmed)) {
      if (enableLogging) {
        debugPrint(' [ApiService] Using Cloudinary URL (no headers): $trimmed');
      }
      return NetworkImage(trimmed);
    }

    // Luôn gọi resolveUrl để tránh lỗi khi dùng localhost trên mobile
    final resolvedUrl = resolveUrl(trimmed);
    if (resolvedUrl.isEmpty) {
      return AssetImage(defaultAsset);
    }

    final headers = _isCloudinaryUrl(resolvedUrl) ? null : authHeaders();
    return NetworkImage(
      resolvedUrl,
      headers: headers,
    );
  }

  // Chuẩn hóa, thay thế localhost/127.0.0.1 bằng baseUrl nếu cần, trả về url dùng để tải file từ server
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
          // Thay host bằng host và scheme baseUrl thật
          final resolvedUri = uri.replace(
            scheme: _baseUri.scheme,
            host: _baseUri.host,
            port: _baseUri.hasPort ? _baseUri.port : (uri.hasPort ? uri.port : null),
          );
          final resolved = resolvedUri.toString();
          if (enableLogging) {
            debugPrint(' [ApiService] Resolved URL: $value -> $resolved');
          }
          return resolved;
        }
        return value;
      } catch (e) {
        if (enableLogging) {
          debugPrint(' [ApiService] Error parsing URL $value: $e');
        }
        return value;
      }
    }

    // Nếu là path tương đối thì ghép vào baseUrl
    final normalizedPath = value.startsWith('/') ? value : '/$value';
    final resolved = _baseUri.replace(path: normalizedPath).toString();
    if (enableLogging) {
      debugPrint(' [ApiService] Resolved relative path: $value -> $resolved');
    }
    return resolved;
  }

  // GET dữ liệu từ API
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // POST dữ liệu lên API
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // PUT dữ liệu lên API
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // PATCH dữ liệu lên API
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE dữ liệu từ API
  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Gửi dữ liệu kiểu multipart/form-data qua POST (thường dùng upload file/ảnh)
  Future<Response> postFormData(String path, FormData formData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      return await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: headers,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Gửi dữ liệu kiểu multipart/form-data qua PATCH (thường dùng upload file/ảnh)
  Future<Response> patchFormData(String path, FormData formData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      return await _dio.patch(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: headers,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
