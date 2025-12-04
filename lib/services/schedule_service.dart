import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class ScheduleService {
  final ApiService _apiService = ApiService();

  // Lấy lịch cá nhân của tuần tương ứng
  Future<List<dynamic>> fetchMySchedule(DateTime weekStart) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(weekStart);
      debugPrint('[ScheduleService] Fetching schedule for week starting: $formattedDate');
      
      final response = await _apiService.get('/api/hr/schedules/my-schedule/$formattedDate');

      debugPrint('[ScheduleService] Response status: ${response.statusCode}');
      debugPrint('[ScheduleService] Response data type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        if (response.data == null) {
          debugPrint('[ScheduleService] Response data is null');
          return [];
        }
        
        if (response.data is List) {
          final schedules = response.data as List<dynamic>;
          debugPrint('[ScheduleService] Found ${schedules.length} schedules');
          return schedules;
        } else {
          debugPrint('[ScheduleService] Response data is not a List: ${response.data}');
          return [];
        }
      } else {
        debugPrint('[ScheduleService] Unexpected status code: ${response.statusCode}');
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[ScheduleService] DioException: ${e.message}');
      debugPrint('[ScheduleService] Response: ${e.response?.data}');
      debugPrint('[ScheduleService] Status code: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. You may not have permission to view schedules.');
      } else if (e.response?.statusCode == 404) {
        debugPrint('[ScheduleService] No schedules found for this week');
        return [];
      }
      
      final errorMessage = e.response?.data?['message'] ?? 
                          e.response?.data?['error'] ?? 
                          e.message ?? 
                          'Failed to load schedule';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('[ScheduleService] Unexpected error: $e');
      rethrow;
    }
  }

  
  Future<List<dynamic>> getMySchedule(DateTime weekStart) async {
    return fetchMySchedule(weekStart);
  }
}
