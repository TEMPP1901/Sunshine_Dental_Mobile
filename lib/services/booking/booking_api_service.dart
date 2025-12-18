// lib/services/booking/booking_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Đảm bảo đã thêm vào pubspec.yaml
import '../../models/booking/booking_models.dart';

class BookingApiService {
  // Thay đổi URL này cho đúng với IP máy tính chạy Backend (không dùng localhost nếu chạy máy ảo)
  // Ví dụ: http://10.0.2.2:8080 (Android Emulator) hoặc IP LAN
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken'); // Key token của bạn
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Lấy danh sách Clinic (Public)
  Future<List<BookingClinic>> getClinics() async {
    final response = await http.get(Uri.parse('$baseUrl/public/clinics'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => BookingClinic.fromJson(e)).toList();
    }
    throw Exception('Failed to load clinics');
  }

  // 2. Lấy danh sách Service (Public)
  Future<List<BookingService>> getServices() async {
    final response = await http.get(Uri.parse('$baseUrl/public/services'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => BookingService.fromJson(e)).toList();
    }
    throw Exception('Failed to load services');
  }

  // 3. Lấy danh sách Bác sĩ (Public)
  Future<List<BookingDoctor>> getDoctors(int clinicId, String specialty) async {
    final uri = Uri.parse('$baseUrl/public/doctors')
        .replace(queryParameters: {
      'clinicId': clinicId.toString(),
      'specialty': specialty,
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => BookingDoctor.fromJson(e)).toList();
    }
    throw Exception('Failed to load doctors');
  }

  // 4. Check Availability (Cho Standard)
  Future<SessionAvailability> checkSessionAvailability(int clinicId, String date) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/booking/availability').replace(queryParameters: {
      'clinicId': clinicId.toString(),
      'date': date,
    });

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return SessionAvailability.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to check availability');
  }

  // 5. Check Time Slots (Cho VIP)
  Future<List<TimeSlot>> getSlots(int clinicId, int doctorId, int serviceId, String date) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/booking/slots').replace(queryParameters: {
      'clinicId': clinicId.toString(),
      'doctorId': doctorId.toString(),
      'serviceIds': serviceId.toString(),
      'date': date,
    });

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => TimeSlot.fromJson(e)).toList();
    }
    throw Exception('Failed to load slots');
  }

  // 6. TẠO LỊCH HẸN (POST)
  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/booking/appointments'),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Booking failed');
    }
  }
}