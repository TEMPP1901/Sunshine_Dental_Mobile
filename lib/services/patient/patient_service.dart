// lib/services/patient/patient_service.dart

import 'package:dio/dio.dart';
import '../api_service.dart'; // Import ApiService gốc của bạn
import '../../models/patient/patient_models.dart';
import '../../models/patient/patient_profile_model.dart';

class PatientService {
  final ApiService _api = ApiService();

  Future<PatientDashboardDTO?> getDashboardSummary() async {
    try {
      final response = await _api.get('/api/patient/dashboard/summary');
      return PatientDashboardDTO.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<PatientAppointment>> getAppointments() async {
    try {
      final response = await _api.get('/api/patient/appointments');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => PatientAppointment.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> cancelAppointment(int id, String reason) async {
    try {
      await _api.put(
        '/api/patient/appointments/$id/cancel',
        data: {'reason': reason},
      );
      return true;
    } on DioException catch (e) {
      throw e.response?.data ?? "Lỗi hủy lịch";
    }
  }

  // 1. Lấy thông tin hồ sơ chi tiết
  Future<PatientProfileDTO?> getPatientProfile() async {
    try {
      final response = await _api.get('/api/patient/profile');
      return PatientProfileDTO.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  // 2. Cập nhật hồ sơ
  Future<bool> updatePatientProfile(PatientProfileDTO data) async {
    try {
      await _api.put('/api/patient/profile', data: data.toJson());
      return true;
    } catch (e) {
      rethrow; // Ném lỗi để UI xử lý
    }
  }
}
