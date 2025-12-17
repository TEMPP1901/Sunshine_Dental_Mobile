import 'package:dio/dio.dart';
import 'api_service.dart';

/// Service cho các tác vụ Admin/HR: duyệt giải trình, duyệt đơn nghỉ.
class AdminService {
  final ApiService _api = ApiService();

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
}

