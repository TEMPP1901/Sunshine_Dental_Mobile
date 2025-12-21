import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Bật/tắt log để tránh spam trong profile/release.
  static bool enableLogging = kDebugMode;

  // === CẤU HÌNH IP CHO MÁY THỰC ===
  // Thay đổi IP này theo IP Wi-Fi của máy chạy backend (kiểm tra bằng ipconfig trên Windows)
  // Ví dụ: Nếu IP Wi-Fi là 192.168.1.122 thì set: '192.168.1.122'
  static const String _realDeviceIp = '192.168.100.232';
  static const int _serverPort = 8080;

  // Chọn chế độ: 'emulator' hoặc 'real_device'
  // - 'emulator': Dùng cho Android Emulator (10.0.2.2)
  // - 'real_device': Dùng cho điện thoại thật (IP LAN)
  static const String _androidMode =
      'real_device'; // Đổi thành 'emulator' nếu chạy trên emulator

  // Xác định baseUrl phù hợp với từng môi trường/chạy trên web, android, ios
  static String _resolveBaseUrl() {
    // 1. Ưu tiên lấy từ biến môi trường (nếu chạy lệnh flutter run --dart-define=API_URL=...)
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      if (enableLogging) {
        debugPrint(' [ApiService] Using API_URL from environment: $envUrl');
      }
      return envUrl;
    }

    // 2. Cấu hình cho Web
    if (kIsWeb) {
      if (enableLogging) {
        debugPrint(' [ApiService] Platform: Web, using localhost:$_serverPort');
      }
      return 'http://localhost:$_serverPort';
    }

    // 3. Cấu hình cho Android
    if (!kIsWeb && Platform.isAndroid) {
      String baseUrl;
      if (_androidMode == 'real_device') {
        // Chạy trên điện thoại thật - dùng IP LAN của máy chạy backend
        baseUrl = 'http://$_realDeviceIp:$_serverPort';
        if (enableLogging) {
          debugPrint(' [ApiService] Platform: Android (Real Device)');
          debugPrint(' [ApiService] Using LAN IP: $baseUrl');
          debugPrint(' [ApiService] Make sure backend is running on: $baseUrl');
        }
      } else {
        // Chạy trên Android Emulator - dùng 10.0.2.2 (localhost của host machine)
        baseUrl = 'http://10.0.2.2:$_serverPort';
        if (enableLogging) {
          debugPrint(' [ApiService] Platform: Android (Emulator)');
          debugPrint(' [ApiService] Using: $baseUrl');
        }
      }
      return baseUrl;
    }

    // 4. Mặc định cho iOS/Khác
    // iOS thường chạy trên simulator (localhost) hoặc real device (cần IP LAN)
    if (!kIsWeb && Platform.isIOS) {
      // Nếu chạy trên iOS real device, cần dùng IP LAN
      // Tạm thời dùng IP LAN cho iOS real device
      final baseUrl = 'http://$_realDeviceIp:$_serverPort';
      if (enableLogging) {
        debugPrint(' [ApiService] Platform: iOS, using: $baseUrl');
        debugPrint(
          ' [ApiService] For iOS Simulator, you may need to use localhost',
        );
      }
      return baseUrl;
    }

    if (enableLogging) {
      debugPrint(' [ApiService] Platform: Other, using localhost:$_serverPort');
    }
    return 'http://localhost:$_serverPort';
  }

  static final String baseUrl = _resolveBaseUrl();
  static final Uri _baseUri = Uri.parse(baseUrl);
  static String? cachedToken;

  late Dio _dio;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  // Khởi tạo Dio, thêm interceptor để gắn token và xử lý lỗi 401 (token hết hạn, bị sai)
  ApiService._internal() {
    if (enableLogging) {
      debugPrint(' [ApiService] Initializing with baseUrl: $baseUrl');
    }
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
            debugPrint(
              ' [ApiService] ← ${response.statusCode} ${response.requestOptions.uri}',
            );
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
            // Kiểm tra xem 401 có phải do face verification failed không
            // Nếu là face verification failed thì KHÔNG xóa token (chỉ báo lỗi)
            final errorData = error.response?.data;
            final errorType = errorData is Map
                ? errorData['error']?.toString().toLowerCase()
                : null;
            final errorMessage = errorData is Map
                ? errorData['message']?.toString().toLowerCase()
                : null;

            final isFaceVerificationError =
                (errorType != null &&
                    errorType.contains('face verification')) ||
                (errorMessage != null &&
                    errorMessage.contains('face verification')) ||
                (errorMessage != null && errorMessage.contains('khuôn mặt'));

            if (!isFaceVerificationError) {
              // Chỉ xóa token khi 401 là do token hết hạn/không hợp lệ (KHÔNG phải face verification)
              if (enableLogging) {
                debugPrint(
                  ' [ApiService] 401 Unauthorized - Token expired/invalid. Clearing auth data.',
                );
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('accessToken');
              await prefs.remove('user');
              cachedToken = null;
            } else {
              // Face verification failed - giữ nguyên token, chỉ báo lỗi
              if (enableLogging) {
                debugPrint(
                  ' [ApiService] 401 Face Verification Failed - Keeping token.',
                );
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
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

    // QUAN TRỌNG: Luôn gọi resolveUrl trước để thay thế localhost bằng IP thực tế
    final resolvedUrl = resolveUrl(trimmed);
    if (resolvedUrl.isEmpty) {
      return AssetImage(defaultAsset);
    }

    // Kiểm tra cloudinary sau khi đã resolve
    if (_isCloudinaryUrl(resolvedUrl)) {
      if (enableLogging) {
        debugPrint(
          ' [ApiService] Using Cloudinary URL (no headers): $resolvedUrl',
        );
      }
      return NetworkImage(resolvedUrl);
    }

    // URL từ server nội bộ, cần headers để xác thực
    final headers = authHeaders();
    if (enableLogging) {
      debugPrint(' [ApiService] Resolved avatar URL: $trimmed -> $resolvedUrl');
    }
    return NetworkImage(resolvedUrl, headers: headers);
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
        // Nếu Backend trả về link ảnh là localhost, phải đổi sang IP máy ảo mới load được
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          // Thay host bằng host và scheme baseUrl thật
          final resolvedUri = uri.replace(
            scheme: _baseUri.scheme,
            host: _baseUri.host,
            port: _baseUri.hasPort
                ? _baseUri.port
                : (uri.hasPort ? uri.port : null),
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

  // --- CÁC HÀM WRAPPER ---

  // GET dữ liệu từ API
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

  // POST dữ liệu lên API
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

  // PUT dữ liệu lên API
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

  // PATCH dữ liệu lên API
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

  // DELETE dữ liệu từ API
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
        options: Options(contentType: 'multipart/form-data', headers: headers),
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
        options: Options(contentType: 'multipart/form-data', headers: headers),
      );
    } catch (e) {
      rethrow;
    }
  }
}
