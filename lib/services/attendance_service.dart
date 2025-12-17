import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';
import 'face_embedding_service.dart';

class AttendanceService {
  final ApiService _apiService = ApiService();
  final FaceEmbeddingService _faceEmbeddingService = FaceEmbeddingService();
  final NetworkInfo _networkInfo = NetworkInfo();

  // Lấy danh sách điểm danh hôm nay (trả lại nhiều bản ghi với bác sĩ, 1 bản ghi với nhân viên)
  Future<Map<String, dynamic>> fetchTodayAttendance(
    dynamic userId,
    bool isDoctor,
  ) async {
    if (userId == null) {
      throw Exception('User ID is required');
    }

    try {
      if (isDoctor) {
        // Lấy danh sách điểm danh hôm nay cho bác sĩ (có thể nhiều ca)
        final response = await _apiService.get(
          '/api/hr/attendance/today-list',
          queryParameters: {'userId': userId},
        );
        if (response.data is List) {
          final list = (response.data as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          return {
            'success': true,
            'data': list,
            'single': list.isNotEmpty ? list[0] : null,
          };
        } else if (response.data is String) {
          try {
            final parsed = jsonDecode(response.data as String);
            if (parsed is List) {
              final list = parsed
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
              return {
                'success': true,
                'data': list,
                'single': list.isNotEmpty ? list[0] : null,
              };
            }
          } catch (_) {}
        }
        return {'success': true, 'data': [], 'single': null};
      } else {
        // Lấy điểm danh hôm nay cho nhân viên (chỉ một bản ghi)
        final response = await _apiService.get(
          '/api/hr/attendance/today',
          queryParameters: {'userId': userId},
        );
        if (response.data != null) {
          if (response.data is Map) {
            final single = Map<String, dynamic>.from(response.data as Map);
            return {
              'success': true,
              'data': [single],
              'single': single,
            };
          } else if (response.data is String) {
            try {
              final parsed = jsonDecode(response.data as String);
              if (parsed is Map) {
                final single = Map<String, dynamic>.from(parsed);
                return {
                  'success': true,
                  'data': [single],
                  'single': single,
                };
              }
            } catch (_) {}
          }
        }
        return {'success': true, 'data': [], 'single': null};
      }
    } on DioException catch (dioError) {
      final status = dioError.response?.statusCode;
      if (status == 404) {
        return {'success': true, 'data': [], 'single': null};
      } else if (status == 401) {
        final serverMessage = dioError.response?.data?['message']?.toString();
        throw Exception(
          serverMessage?.isNotEmpty == true
              ? serverMessage
              : 'Unauthorized. Please login again.',
        );
      } else {
        final serverMessage =
            dioError.response?.data?['message']?.toString() ??
            dioError.response?.data?['error']?.toString();
        throw Exception(
          serverMessage?.isNotEmpty == true
              ? serverMessage
              : 'attendance.toast.loadFailed'.tr(),
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Lấy dữ liệu điểm danh theo tháng và phân trang
  Future<Map<String, dynamic>> fetchMonthlyAttendance(
    dynamic userId,
    int year,
    int month,
    int page,
    int size,
  ) async {
    if (userId == null) {
      throw Exception('User ID is required');
    }

    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      final response = await _apiService.get(
        '/api/hr/attendance/history',
        queryParameters: {
          'userId': userId,
          'startDate': startDateStr,
          'endDate': endDateStr,
          'page': page,
          'size': size,
        },
      );

      if (response.data != null) {
        final data = response.data;
        List<Map<String, dynamic>> items = [];

        if (data is Map<String, dynamic>) {
          if (data['content'] is List) {
            items = (data['content'] as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }

          final totalPages = data['totalPages'] as int? ?? 0;
          final currentPage = data['number'] as int? ?? 0;

          return {
            'success': true,
            'data': items,
            'currentPage': currentPage,
            'totalPages': totalPages,
            'hasMore': currentPage + 1 < totalPages,
          };
        } else if (data is List) {
          items = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          return {
            'success': true,
            'data': items,
            'currentPage': 0,
            'totalPages': 0,
            'hasMore': false,
          };
        } else if (data is String) {
          try {
            final parsed = jsonDecode(data);
            if (parsed is Map<String, dynamic>) {
              if (parsed['content'] is List) {
                items = (parsed['content'] as List)
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();
              }
              final totalPages = parsed['totalPages'] as int? ?? 0;
              final currentPage = parsed['number'] as int? ?? 0;

              return {
                'success': true,
                'data': items,
                'currentPage': currentPage,
                'totalPages': totalPages,
                'hasMore': currentPage + 1 < totalPages,
              };
            } else if (parsed is List) {
              items = parsed
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();

              return {
                'success': true,
                'data': items,
                'currentPage': 0,
                'totalPages': 0,
                'hasMore': false,
              };
            }
          } catch (_) {
            throw Exception('Invalid response format: $data');
          }
        }

        final totalPages = 0;
        final currentPage = 0;

        return {
          'success': true,
          'data': items,
          'currentPage': currentPage,
          'totalPages': totalPages,
          'hasMore': currentPage + 1 < totalPages,
        };
      }

      return {
        'success': true,
        'data': [],
        'currentPage': 0,
        'totalPages': 0,
        'hasMore': false,
      };
    } on DioException catch (dioError) {
      final status = dioError.response?.statusCode;
      if (status != 404) {
        final serverMessage = dioError.response?.data?['message'];
        throw Exception(
          serverMessage?.toString() ?? 'attendance.toast.loadFailed'.tr(),
        );
      }
      return {
        'success': true,
        'data': [],
        'currentPage': 0,
        'totalPages': 0,
        'hasMore': false,
      };
    } catch (e) {
      throw Exception('attendance.toast.loadFailed'.tr());
    }
  }

  // Lấy danh sách giải trình chưa xử lý (giải trình cần xử lý)
  Future<List<Map<String, dynamic>>> fetchExplanationsNeeding(
    dynamic userId,
  ) async {
    if (userId == null) {
      return [];
    }

    try {
      final response = await _apiService.get(
        '/api/hr/attendance/explanations/needing',
        queryParameters: {'userId': userId},
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response.data is String) {
        try {
          final parsed = jsonDecode(response.data as String);
          if (parsed is List) {
            return parsed
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Gửi giải trình cho một điểm danh
  Future<void> submitExplanation(
    int attendanceId,
    String explanationType,
    String reason, {
    int? clinicId,
    String? workDate,
    String? shiftType,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'attendanceId': attendanceId,
        'explanationType': explanationType,
        'reason': reason,
      };
      
      // Nếu attendanceId = 0 (chưa có attendance record), cần gửi thêm clinicId, workDate, shiftType
      if (attendanceId == 0) {
        if (clinicId != null) {
          requestData['clinicId'] = clinicId;
        }
        if (workDate != null && workDate.isNotEmpty) {
          requestData['workDate'] = workDate;
        }
        if (shiftType != null && shiftType.isNotEmpty) {
          requestData['shiftType'] = shiftType;
        }
      }
      
      await _apiService.post(
        '/api/hr/attendance/explanations/submit',
        data: requestData,
      );
    } on DioException catch (dioError) {
      final serverMessage = dioError.response?.data?['message']?.toString();
      throw Exception(
        (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : 'attendance.explanation.submitFailed'.tr(),
      );
    } catch (e) {
      throw Exception('attendance.explanation.submitFailed'.tr());
    }
  }

  // Check-in (điểm danh vào)
  Future<Map<String, dynamic>> checkIn({
    required dynamic userId,
    required String faceEmbedding,
    required String? ssid,
    required String? bssid,
    int? clinicId,
  }) async {
    // Validate userId
    if (userId == null) {
      throw Exception('User ID is required for check-in');
    }
    
    // Validate embedding trước khi gửi
    if (faceEmbedding.isEmpty || faceEmbedding.trim().isEmpty) {
      throw Exception('Face embedding is required for check-in');
    }
    
    final trimmedEmbedding = faceEmbedding.trim();
    if (!trimmedEmbedding.startsWith('[') || !trimmedEmbedding.endsWith(']')) {
      throw Exception('Invalid face embedding format');
    }
    
    try {
      final payload = <String, dynamic>{
        'userId': userId,
        'faceEmbedding': trimmedEmbedding,
        'ssid': ssid,
        'bssid': bssid,
      };
      if (clinicId != null) {
        payload['clinicId'] = clinicId;
      }

      final response = await _apiService.post(
        '/api/hr/attendance/check-in',
        data: payload,
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (dioError) {
      // Lấy message từ server response
      final serverMessage = dioError.response?.data?['message']?.toString();
      
      // Kiểm tra nếu là lỗi face verification (401 Unauthorized)
      if (dioError.response?.statusCode == 401) {
        final errorType = dioError.response?.data?['error']?.toString();
        if (errorType != null && errorType.contains('Face Verification')) {
          // Đây là lỗi face verification - trả về message từ server
          throw Exception(
            serverMessage != null && serverMessage.isNotEmpty
                ? serverMessage
                : 'Khuôn mặt không khớp. Vui lòng sử dụng khuôn mặt đã đăng ký.',
          );
        }
      }
      
      // Các lỗi khác
      throw Exception(
        (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : 'attendance.toast.loadFailed'.tr(),
      );
    } catch (e) {
      throw Exception('attendance.toast.loadFailed'.tr());
    }
  }

  // Check-out (điểm danh ra)
  Future<Map<String, dynamic>> checkOut({
    required int attendanceId,
    required String faceEmbedding,
    required String? ssid,
    required String? bssid,
  }) async {
    // Validate embedding trước khi gửi
    if (faceEmbedding.isEmpty || faceEmbedding.trim().isEmpty) {
      throw Exception('Face embedding is required for check-out');
    }
    
    final trimmedEmbedding = faceEmbedding.trim();
    if (!trimmedEmbedding.startsWith('[') || !trimmedEmbedding.endsWith(']')) {
      throw Exception('Invalid face embedding format');
    }
    
    try {
      final payload = <String, dynamic>{
        'attendanceId': attendanceId,
        'faceEmbedding': trimmedEmbedding,
        'ssid': ssid,
        'bssid': bssid,
      };

      final response = await _apiService.post(
        '/api/hr/attendance/check-out',
        data: payload,
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (dioError) {
      // Lấy message từ server response
      final serverMessage = dioError.response?.data?['message']?.toString();
      
      // Kiểm tra nếu là lỗi face verification (401 Unauthorized)
      if (dioError.response?.statusCode == 401) {
        final errorType = dioError.response?.data?['error']?.toString();
        if (errorType != null && errorType.contains('Face Verification')) {
          // Đây là lỗi face verification - trả về message từ server
          throw Exception(
            serverMessage != null && serverMessage.isNotEmpty
                ? serverMessage
                : 'Khuôn mặt không khớp. Vui lòng sử dụng khuôn mặt đã đăng ký.',
          );
        }
      }
      
      // Các lỗi khác
      throw Exception(
        (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : 'attendance.toast.loadFailed'.tr(),
      );
    } catch (e) {
      throw Exception('attendance.toast.loadFailed'.tr());
    }
  }

  // Xác định clinicId của bác sĩ dựa vào lịch làm việc hôm nay (ưu tiên ca hiện tại, nếu chưa có thì lấy ca sớm nhất sắp tới)
  Future<int?> resolveDoctorClinicId(dynamic userId) async {
    if (userId == null) {
      return null;
    }

    try {
      final today = DateTime.now();
      final isoDate = DateFormat('yyyy-MM-dd').format(today);
      final response = await _apiService.get('/api/hr/schedules/date/$isoDate');

      final data = response.data;
      if (data is! List) {
        return null;
      }

      Map<String, dynamic>? selected;
      DateTime? selectedStart;
      Map<String, dynamic>? upcoming;
      DateTime? upcomingStart;
      final now = DateTime.now();

      for (final entry in data) {
        if (entry is! Map) continue;
        final doctor = entry['doctor'];
        final doctorId = doctor is Map ? doctor['id'] : null;
        if (doctorId == null || doctorId != userId) continue;

        final startStr = entry['startTime']?.toString();
        final endStr = entry['endTime']?.toString();
        final start = _combineDateAndTime(now, startStr);
        final end = _combineDateAndTime(now, endStr);
        if (start == null || end == null) continue;

        if (!now.isBefore(start) && !now.isAfter(end)) {
          // Nếu đang trong ca làm, lấy ca hiện tại
          if (selected == null ||
              (selectedStart != null && start.isAfter(selectedStart))) {
            selected = entry.cast<String, dynamic>();
            selectedStart = start;
          }
        } else if (now.isBefore(start)) {
          // Nếu chưa đến ca, lấy ca sớm nhất tiếp theo
          if (upcomingStart == null || start.isBefore(upcomingStart)) {
            upcoming = entry.cast<String, dynamic>();
            upcomingStart = start;
          }
        }
      }

      final chosen = selected ?? upcoming;
      final clinic = chosen?['clinic'];
      final clinicId = clinic is Map ? clinic['id'] : null;
      if (clinicId is int) {
        return clinicId;
      }
    } catch (_) {}

    return null;
  }

  // Đảm bảo ứng dụng có quyền truy cập wifi trên Android
  Future<bool> ensureWifiPermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final locationStatus = await Permission.locationWhenInUse.request();
    if (!locationStatus.isGranted) {
      return false;
    }

    try {
      final nearbyStatus = await Permission.nearbyWifiDevices.request();
      if (nearbyStatus.isDenied && nearbyStatus != PermissionStatus.granted) {
        return false;
      }
    } catch (_) {}

    return true;
  }

  // Thu thập thông tin wifi hiện tại
  Future<Map<String, String?>> collectWifiInfo() async {
    final ssid = await _networkInfo.getWifiName();
    final bssid = await _networkInfo.getWifiBSSID();
    return {'ssid': ssid, 'bssid': bssid};
  }

  // Chụp ảnh và trích xuất embedding khuôn mặt từ ảnh
  Future<String?> captureEmbedding(BuildContext context) async {
    try {
      final imageFile = await _faceEmbeddingService.captureFaceImage(context);
      if (imageFile == null) {
        return null;
      }

      // Extract embedding với error handling tốt hơn
      try {
        return await _faceEmbeddingService.extractEmbedding(imageFile);
      } catch (e) {
        // Log error để debug
        debugPrint('Error extracting embedding: $e');
        
        // Throw lại với message rõ ràng hơn
        if (e is FormatException) {
          throw Exception('Không thể nhận diện khuôn mặt từ ảnh. Vui lòng đảm bảo:\n- Khuôn mặt rõ ràng, nhìn thẳng vào camera\n- Ánh sáng đủ\n- Không có vật che mặt');
        }
        throw Exception('Lỗi khi xử lý ảnh khuôn mặt: ${e.toString()}');
      }
    } catch (e) {
      debugPrint('Error in captureEmbedding: $e');
      rethrow;
    }
  }

  // Kết hợp một ngày với một chuỗi giờ phút giây (trả về đối tượng DateTime, null nếu lỗi)
  DateTime? _combineDateAndTime(DateTime date, String? time) {
    if (time == null || time.isEmpty) return null;
    try {
      if (time.contains('T')) {
        return DateTime.parse(time);
      }
      final parsed = DateFormat.Hms().parse(time);
      return DateTime(
        date.year,
        date.month,
        date.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      );
    } catch (_) {
      return null;
    }
  }
}
