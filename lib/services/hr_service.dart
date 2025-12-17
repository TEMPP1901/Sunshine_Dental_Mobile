import 'package:dio/dio.dart';

import 'api_service.dart';

/// Service dành riêng cho HR (face profile approval, employees...).
/// Giữ file nhỏ, mỗi chức năng một nhóm hàm rõ ràng.
class HrService {
  final ApiService _api = ApiService();

  // ===== Management (clinics/departments/roles) =====
  /// Danh sách phòng khám (dùng cho dropdown lọc)
  Future<List<Map<String, dynamic>>> fetchClinics() async {
    try {
      // HR được phép gọi /api/hr/management/clinics (SecurityConfig hasAnyRole HR, ADMIN)
      final response = await _api.get('/api/hr/management/clinics');
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

  // ===== Face Profile Approval =====

  Future<List<Map<String, dynamic>>> fetchPendingFaceProfiles() async {
    final response = await _api.get('/api/hr/face-profile/pending-requests');
    final data = response.data;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) {
      final firstArrayKey =
          data.keys.firstWhere((k) => data[k] is List, orElse: () => '');
      if (firstArrayKey.isNotEmpty) {
        return (data[firstArrayKey] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }
    return [];
  }

  Future<void> approveFaceProfile(int requestId) async {
    try {
      await _api.post('/api/hr/face-profile/approve/$requestId');
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();
      throw Exception(msg?.isNotEmpty == true ? msg : 'Duyệt thất bại');
    }
  }

  Future<void> rejectFaceProfile({
    required int requestId,
    String? reason,
  }) async {
    try {
      await _api.post(
        '/api/hr/face-profile/reject/$requestId',
        queryParameters: {
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();
      throw Exception(msg?.isNotEmpty == true ? msg : 'Từ chối thất bại');
    }
  }

  // ===== Employees =====
  Future<Map<String, dynamic>> fetchEmployees({
    String? search,
    int? clinicId,
    int? departmentId,
    int? roleId,
    bool? isActive,
    int page = 0,
    int size = 10,
  }) async {
    final resp = await _api.get('/api/hr/employees', queryParameters: {
      if (search?.isNotEmpty == true) 'search': search,
      if (clinicId != null) 'clinicId': clinicId,
      if (departmentId != null) 'departmentId': departmentId,
      if (roleId != null) 'roleId': roleId,
      if (isActive != null) 'isActive': isActive,
      'page': page,
      'size': size,
    });
    return Map<String, dynamic>.from(resp.data ?? {});
  }

  Future<Map<String, dynamic>> toggleEmployeeStatus({
    required int employeeId,
    required bool isActive,
    required String reason,
  }) async {
    final resp = await _api.put('/api/hr/employees/$employeeId/toggle-status',
        queryParameters: {'isActive': isActive, 'reason': reason});
    return Map<String, dynamic>.from(resp.data ?? {});
  }

  Future<Map<String, dynamic>> fetchEmployeeStats({
    int? clinicId,
    int? departmentId,
  }) async {
    final resp = await _api.get('/api/hr/employees/statistics', queryParameters: {
      if (clinicId != null) 'clinicId': clinicId,
      if (departmentId != null) 'departmentId': departmentId,
    });
    return Map<String, dynamic>.from(resp.data ?? {});
  }

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    final resp = await _api.get('/api/hr/management/departments');
    final data = resp.data;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchRoles() async {
    final resp = await _api.get('/api/hr/management/roles');
    final data = resp.data;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  // ===== Attendance History & Stats =====
  Future<Map<String, dynamic>> fetchAttendanceHistory({
    String? startDate,
    String? endDate,
    int? userId,
    int? clinicId,
    int page = 0,
    int size = 10,
  }) async {
    final resp = await _api.get('/api/hr/attendance/history', queryParameters: {
      if (startDate?.isNotEmpty == true) 'startDate': startDate,
      if (endDate?.isNotEmpty == true) 'endDate': endDate,
      if (userId != null) 'userId': userId,
      if (clinicId != null) 'clinicId': clinicId,
      'page': page,
      'size': size,
    });
    return Map<String, dynamic>.from(resp.data ?? {});
  }

  /// Fetch daily attendance list (same API as web)
  Future<Map<String, dynamic>> fetchDailyAttendanceList({
    required String workDate,
    int? departmentId,
    int page = 0,
    int size = 20,
  }) async {
    final resp = await _api.get('/api/hr/attendance/daily-list', queryParameters: {
      'workDate': workDate,
      if (departmentId != null) 'departmentId': departmentId,
      'page': page,
      'size': size,
    });
    return Map<String, dynamic>.from(resp.data ?? {});
  }

  Future<Map<String, dynamic>> fetchAttendanceStats({
    String? startDate,
    String? endDate,
    int? userId,
    int? clinicId,
  }) async {
    final resp = await _api.get('/api/hr/attendance/statistics', queryParameters: {
      if (startDate?.isNotEmpty == true) 'startDate': startDate,
      if (endDate?.isNotEmpty == true) 'endDate': endDate,
      if (userId != null) 'userId': userId,
      if (clinicId != null) 'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(resp.data ?? {});
  }

  // ===== Leave approved in range =====
  Future<List<Map<String, dynamic>>> fetchApprovedLeavesInRange({
    required String startDate,
    required String endDate,
  }) async {
    final resp = await _api.get('/api/hr/leave-requests/approved-in-range', queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
    });
    final data = resp.data;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  // ===== Schedule (view only, concise) =====
  Future<List<Map<String, dynamic>>> fetchCurrentWeekSchedule() async {
    final resp = await _api.get('/api/hr/schedules/current');
    final data = resp.data;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchNextWeekSchedule() async {
    final resp = await _api.get('/api/hr/schedules/next-week');
    final data = resp.data;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchMySchedule(String weekStart) async {
    final resp = await _api.get('/api/hr/schedules/my-schedule/$weekStart');
    final data = resp.data;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Lấy schedule theo ngày cụ thể (format: yyyy-MM-dd)
  Future<List<Map<String, dynamic>>> fetchScheduleByDate(String date) async {
    final resp = await _api.get('/api/hr/schedules/date/$date');
    final data = resp.data;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}

