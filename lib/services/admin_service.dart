import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service cho các tác vụ Admin/HR: duyệt giải trình, duyệt đơn nghỉ.
class AdminService {
  final ApiService _api = ApiService();

  // ===== Clinics Management =====
  /// Danh sách phòng khám (dùng cho admin - endpoint riêng)
  Future<List<Map<String, dynamic>>> fetchClinics() async {
    try {
      final response = await _api.get('/api/admin/clinics');
      final data = response.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      if (data is Map<String, dynamic> && data['content'] is List) {
        return (data['content'] as List).whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();
      throw Exception(msg?.isNotEmpty == true ? msg : 'Không tải được danh sách phòng khám');
    }
  }

  /// Giải trình đang chờ HR
  Future<List<Map<String, dynamic>>> fetchPendingExplanations({int? clinicId}) async {
    final response = await _api.get(
      '/api/hr/attendance/explanations/pending',
      queryParameters: clinicId != null ? {'clinicId': clinicId} : null,
    );
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// HR xử lý giải trình (APPROVE / REJECT)
  Future<void> processExplanation({
    required int attendanceId,
    required String action, // APPROVE hoặc REJECT
    String? adminNote,
    String? customTime,
  }) async {
    try {
      await _api.post('/api/hr/attendance/explanations/process', data: {
        'attendanceId': attendanceId,
        'action': action,
        if (adminNote != null && adminNote.trim().isNotEmpty) 'adminNote': adminNote.trim(),
        if (customTime != null && customTime.trim().isNotEmpty) 'customTime': customTime.trim(),
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();
      throw Exception(msg?.isNotEmpty == true ? msg : 'Failed to process explanation');
    }
  }

  /// Đơn nghỉ pending (HR/Admin)
  Future<List<Map<String, dynamic>>> fetchPendingLeaveRequests() async {
    final response = await _api.get('/api/hr/leave-requests/pending');
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Đơn nghỉ pending cho Admin (trạng thái PENDING_ADMIN)
  Future<List<Map<String, dynamic>>> fetchPendingAdminLeaveRequests() async {
    final response = await _api.get('/api/hr/leave-requests/pending-admin');
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Leave counts by status
  Future<Map<String, dynamic>> fetchLeaveCounts() async {
    final response = await _api.get('/api/hr/leave-requests/counts');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// Leave list with optional status + paging
  Future<Map<String, dynamic>> fetchLeavePaged({
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _api.get(
      '/api/hr/leave-requests',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'size': size,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final content = (data['content'] is List)
          ? (data['content'] as List).whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      return {
        'content': content,
        'totalPages': data['totalPages'] ?? 0,
        'page': data['number'] ?? page,
      };
    }
    if (data is List) {
      return {
        'content': data.whereType<Map<String, dynamic>>().toList(),
        'totalPages': 1,
        'page': 0,
      };
    }
    return {'content': <Map<String, dynamic>>[], 'totalPages': 0, 'page': 0};
  }

  /// Daily attendance list (HR)
  Future<Map<String, dynamic>> fetchDailyAttendance({
    String? workDate, // yyyy-MM-dd
    int? clinicId,
    int? departmentId,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _api.get(
      '/api/hr/attendance/daily-list',
      queryParameters: {
        if (workDate != null && workDate.isNotEmpty) 'workDate': workDate,
        if (clinicId != null) 'clinicId': clinicId,
        if (departmentId != null) 'departmentId': departmentId,
        'page': page,
        'size': size,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final content = (data['content'] is List)
          ? (data['content'] as List).whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      return {
        'content': content,
        'totalPages': data['totalPages'] ?? 0,
        'page': data['number'] ?? page,
      };
    }
    if (data is List) {
      return {
        'content': data.whereType<Map<String, dynamic>>().toList(),
        'totalPages': 1,
        'page': 0,
      };
    }
    return {'content': <Map<String, dynamic>>[], 'totalPages': 0, 'page': 0};
  }

  /// Attendance statistics (HR)
  Future<Map<String, dynamic>> fetchAttendanceStatistics({
    String? startDate,
    String? endDate,
    int? userId,
    int? clinicId,
  }) async {
    final response = await _api.get(
      '/api/hr/attendance/statistics',
      queryParameters: {
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        if (userId != null) 'userId': userId,
        if (clinicId != null) 'clinicId': clinicId,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// Duyệt / từ chối đơn nghỉ
  Future<Map<String, dynamic>> processLeaveRequest({
    required int leaveRequestId,
    required String action, // APPROVE hoặc REJECT
    String? comment,
  }) async {
    try {
      final response = await _api.put('/api/hr/leave-requests/process', data: {
        'leaveRequestId': leaveRequestId,
        'action': action,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      });
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();
      throw Exception(msg?.isNotEmpty == true ? msg : 'Failed to process leave request');
    }
  }

  /// Dashboard statistics
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final response = await _api.get('/api/admin/dashboard/stats');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// Inventory statistics
  Future<Map<String, dynamic>> fetchInventoryStatistics() async {
    final response = await _api.get('/api/admin/inventory/statistics');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// Staff list with pagination
  Future<Map<String, dynamic>> fetchStaff({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _api.get(
        '/api/admin/staff',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'size': size,
        },
      );
      final data = response.data;
      
      // Debug log - in toàn bộ response để debug
      debugPrint('AdminService.fetchStaff - Raw response type: ${data.runtimeType}');
      debugPrint('AdminService.fetchStaff - Raw response: $data');
      
      // Spring Page object khi serialize sẽ có structure:
      // {
      //   "content": [...],
      //   "totalElements": Long,
      //   "totalPages": int,
      //   "number": int (page number),
      //   "size": int,
      //   "first": boolean,
      //   "last": boolean,
      //   ...
      // }
      
      // Xử lý nếu response là List trực tiếp (không phải Page) - fallback
      if (data is List) {
        debugPrint('AdminService.fetchStaff - Response is List (unexpected), length: ${data.length}');
        final content = data.whereType<Map<String, dynamic>>().toList();
        return {
          'content': content,
          'totalPages': 1,
          'page': page,
          'totalElements': content.length,
        };
      }
      
      // Xử lý nếu response là Map (PageResponseDto hoặc Spring Page object)
      if (data is Map<String, dynamic>) {
        debugPrint('AdminService.fetchStaff - Response is Map, keys: ${data.keys.toList()}');
        
        final content = (data['content'] is List)
            ? (data['content'] as List).whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];
        
        debugPrint('AdminService.fetchStaff - Content length: ${content.length}');
        
        // Parse totalElements - có thể ở root level hoặc trong object 'page'
        int totalElements = 0;
        dynamic totalElementsValue = data['totalElements'];
        
        // Nếu không có ở root, thử lấy từ object 'page'
        if (totalElementsValue == null && data['page'] is Map) {
          final pageObj = data['page'] as Map<String, dynamic>;
          totalElementsValue = pageObj['totalElements'];
          debugPrint('AdminService.fetchStaff - Found totalElements in page object: $totalElementsValue');
        }
        
        debugPrint('AdminService.fetchStaff - totalElementsValue: $totalElementsValue (type: ${totalElementsValue?.runtimeType})');
        
        if (totalElementsValue != null) {
          if (totalElementsValue is int) {
            totalElements = totalElementsValue;
          } else if (totalElementsValue is num) {
            // Xử lý cả int và double
            totalElements = totalElementsValue.toInt();
          } else if (totalElementsValue is String) {
            totalElements = int.tryParse(totalElementsValue) ?? 0;
          }
          debugPrint('AdminService.fetchStaff - Parsed totalElements: $totalElements');
        } else {
          debugPrint('AdminService.fetchStaff - WARNING: totalElements is null in response!');
          debugPrint('AdminService.fetchStaff - Response structure: ${data.keys.map((k) => '$k: ${data[k]?.runtimeType}').join(', ')}');
          totalElements = 0;
        }
        
        // Parse totalPages - có thể ở root level hoặc trong object 'page'
        int totalPages = 0;
        dynamic totalPagesValue = data['totalPages'];
        
        // Nếu không có ở root, thử lấy từ object 'page'
        if (totalPagesValue == null && data['page'] is Map) {
          final pageObj = data['page'] as Map<String, dynamic>;
          totalPagesValue = pageObj['totalPages'];
          debugPrint('AdminService.fetchStaff - Found totalPages in page object: $totalPagesValue');
        }
        
        if (totalPagesValue != null) {
          if (totalPagesValue is int) {
            totalPages = totalPagesValue;
          } else if (totalPagesValue is num) {
            totalPages = totalPagesValue.toInt();
          } else if (totalPagesValue is String) {
            totalPages = int.tryParse(totalPagesValue) ?? 0;
          }
        } else if (totalElements > 0) {
          // Tính totalPages từ totalElements nếu không có trong response
          totalPages = ((totalElements - 1) ~/ size) + 1;
        }
        
        // Parse page number - có thể ở root level hoặc trong object 'page'
        int pageNumber = page;
        if (data['page'] is Map) {
          final pageObj = data['page'] as Map<String, dynamic>;
          if (pageObj['number'] != null) {
            pageNumber = pageObj['number'] is int ? pageObj['number'] : int.tryParse(pageObj['number'].toString()) ?? page;
          }
        } else if (data['number'] != null) {
          pageNumber = data['number'] is int ? data['number'] : int.tryParse(data['number'].toString()) ?? page;
        }
        
        debugPrint('AdminService.fetchStaff - Final: totalElements=$totalElements, totalPages=$totalPages, content.length=${content.length}, page=$pageNumber, size=$size');
        
        return {
          'content': content,
          'totalPages': totalPages,
          'page': pageNumber,
          'totalElements': totalElements,
        };
      }
      
      debugPrint('AdminService.fetchStaff - Response is neither List nor Map, returning empty');
      return {'content': <Map<String, dynamic>>[], 'totalPages': 0, 'page': 0, 'totalElements': 0};
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();
      debugPrint('AdminService.fetchStaff - Error: $msg');
      debugPrint('AdminService.fetchStaff - Error response: ${e.response?.data}');
      throw Exception(msg?.isNotEmpty == true ? msg : 'Không thể tải danh sách nhân viên');
    }
  }

  /// Admin attendance list
  Future<List<Map<String, dynamic>>> fetchAdminAttendance({
    String? date, // yyyy-MM-dd
    int? clinicId,
    String? status,
  }) async {
    final response = await _api.get(
      '/api/admin/attendance',
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (clinicId != null) 'clinicId': clinicId,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Update attendance status (Admin)
  Future<Map<String, dynamic>> updateAttendanceStatus({
    required int attendanceId,
    required String newStatus,
    String? adminNote,
  }) async {
    try {
      final response = await _api.patch(
        '/api/admin/attendance/$attendanceId',
        data: {
          'newStatus': newStatus,
          if (adminNote != null && adminNote.trim().isNotEmpty) 'adminNote': adminNote.trim(),
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();
      throw Exception(msg?.isNotEmpty == true ? msg : 'Failed to update attendance status');
    }
  }

  /// Audit logs
  Future<Map<String, dynamic>> fetchAuditLogs({
    int? userId,
    String? action,
    String? tableName,
    String? fromDate,
    String? toDate,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.get(
      '/api/admin/system/audit-logs',
      queryParameters: {
        if (userId != null) 'userId': userId,
        if (action != null && action.isNotEmpty) 'action': action,
        if (tableName != null && tableName.isNotEmpty) 'tableName': tableName,
        if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
        'page': page,
        'size': size,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final content = (data['content'] is List)
          ? (data['content'] as List).whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      return {
        'content': content,
        'totalPages': data['totalPages'] ?? 0,
        'page': data['number'] ?? page,
        'totalElements': data['totalElements'] ?? 0,
      };
    }
    return {'content': <Map<String, dynamic>>[], 'totalPages': 0, 'page': 0, 'totalElements': 0};
  }
}

