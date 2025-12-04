import 'package:dio/dio.dart';
import 'api_service.dart';

class LeaveRequestService {
  final ApiService _apiService = ApiService();

  // Lấy danh sách đơn nghỉ của user
  Future<List<Map<String, dynamic>>> fetchMyLeaveRequests() async {
    try {
      final response = await _apiService.get('/api/hr/leave-requests/my');
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message']?.toString() ?? 'Failed to load leave requests',
      );
    }
  }

 
  Future<List<Map<String, dynamic>>> getMyLeaveRequests() async {
    return fetchMyLeaveRequests();
  }

  // Lấy chi tiết đơn nghỉ bằng id
  Future<Map<String, dynamic>> fetchLeaveRequestById(int leaveRequestId) async {
    try {
      final response = await _apiService.get('/api/hr/leave-requests/$leaveRequestId');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message']?.toString() ?? 'Failed to load leave request',
      );
    }
  }

  // Tạo đơn nghỉ mới
  Future<Map<String, dynamic>> createLeaveRequest({
    int? clinicId,
    required String startDate,
    required String endDate,
    required String type,
    required String reason,
    String? shiftType, // MORNING, AFTERNOON, FULL_DAY (dành cho bác sĩ)
  }) async {
    try {
      final data = <String, dynamic>{
        'startDate': startDate,
        'endDate': endDate,
        'type': type,
        'reason': reason,
        if (clinicId != null) 'clinicId': clinicId,
        if (shiftType != null && shiftType.isNotEmpty) 'shiftType': shiftType,
      };

      final response = await _apiService.post(
        '/api/hr/leave-requests',
        data: data,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message']?.toString() ?? 'Failed to create leave request',
      );
    }
  }

  // Hủy đơn nghỉ
  Future<void> cancelLeaveRequest(int leaveRequestId) async {
    try {
      await _apiService.delete('/api/hr/leave-requests/$leaveRequestId');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message']?.toString() ?? 'Failed to cancel leave request',
      );
    }
  }

  // Lấy danh sách clinics (dùng khi tạo đơn nghỉ)
  Future<List<Map<String, dynamic>>> fetchClinics() async {
    try {
      final response = await _apiService.get('/api/hr/management/clinics');
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      // Nếu không có quyền, trả về danh sách rỗng
      return [];
    }
  }
}
