// lib/providers/booking/booking_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking/booking_models.dart';
import '../../services/booking/booking_api_service.dart';

class BookingProvider with ChangeNotifier {
  final BookingApiService _apiService = BookingApiService();

  // --- STATE ---
  int currentStep = 0;
  bool isLoading = false;

  // Dữ liệu đã chọn
  String appointmentType = 'STANDARD'; // 'STANDARD' | 'VIP'
  double bookingFee = 500000;

  BookingClinic? selectedClinic;
  BookingServiceVariant? selectedServiceVariant;
  BookingService? selectedServiceParent;

  BookingDoctor? selectedDoctor; // Chỉ VIP

  DateTime? selectedDate;
  String? selectedTime; // "08:00"
  String? sessionLabel; // "Sáng" / "Chiều" (Cho Standard)

  // --- ACTIONS ---

  // Bước 0: Chọn loại
  void setType(String type) {
    appointmentType = type;
    // Cập nhật giá (Giả định hardcode, có thể gọi API config nếu cần)
    bookingFee = (type == 'VIP') ? 1000000 : 500000;
    notifyListeners();
  }

  // Bước 1: Chọn Clinic & Service
  void setClinic(BookingClinic clinic) {
    selectedClinic = clinic;
    notifyListeners();
  }

  void setService(BookingService parent, BookingServiceVariant variant) {
    selectedServiceParent = parent;
    selectedServiceVariant = variant;
    notifyListeners();
  }

  // Bước 2 (VIP): Chọn Doctor
  void setDoctor(BookingDoctor doctor) {
    selectedDoctor = doctor;
    notifyListeners();
  }

  // Bước Chọn Ngày/Giờ
  void setDate(DateTime date) {
    selectedDate = date;
    selectedTime = null; // Reset giờ khi đổi ngày
    sessionLabel = null;
    notifyListeners();
  }

  void setTime(String time, {String? label}) {
    selectedTime = time;
    sessionLabel = label;
    notifyListeners();
  }

  // --- NAVIGATION LOGIC ---
  void nextStep() {
    currentStep++;
    notifyListeners();
  }

  void prevStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  // --- API CALLS ---

  // Lấy danh sách bác sĩ (VIP)
  Future<List<BookingDoctor>> fetchDoctors() async {
    if (selectedClinic == null || selectedServiceParent == null) return [];
    return await _apiService.getDoctors(
        selectedClinic!.id, selectedServiceParent!.category);
  }

  // Lấy Slot (VIP)
  Future<List<TimeSlot>> fetchSlots() async {
    if (selectedClinic == null || selectedDoctor == null || selectedDate == null) return [];
    String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    return await _apiService.getSlots(
        selectedClinic!.id,
        selectedDoctor!.id,
        selectedServiceVariant!.variantId,
        dateStr
    );
  }

  // Check Availability (Standard)
  Future<SessionAvailability> checkAvailability() async {
    if (selectedClinic == null || selectedDate == null) {
      return SessionAvailability(morningAvailable: false, afternoonAvailable: false);
    }
    String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    return await _apiService.checkSessionAvailability(selectedClinic!.id, dateStr);
  }

  // CONFIRM BOOKING
  Future<int?> confirmBooking(int patientId) async {
    isLoading = true;
    notifyListeners();

    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
      // Format time: "08:00" -> "08:00:00"
      String timeStr = (selectedTime!.length == 5) ? "$selectedTime:00" : selectedTime!;
      String startDateTime = "${dateStr}T$timeStr"; // ISO 8601 simple

      final payload = {
        "clinicId": selectedClinic!.id,
        "patientId": patientId,
        "appointmentType": appointmentType,
        "bookingFee": bookingFee,
        "doctorId": (appointmentType == 'VIP') ? selectedDoctor?.id : null,
        "startDateTime": startDateTime, // Backend sẽ tự tính EndDateTime
        "note": "Booking via Mobile App ($appointmentType)",
        "services": [
          {
            "serviceId": selectedServiceVariant!.variantId,
            "quantity": 1
          }
        ]
      };

      final response = await _apiService.createAppointment(payload);
      return response['id']; // Trả về appointmentId
    } catch (e) {
      print("Booking Error: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Reset khi hoàn thành
  void reset() {
    currentStep = 0;
    selectedClinic = null;
    selectedServiceVariant = null;
    selectedDoctor = null;
    selectedDate = null;
    selectedTime = null;
    notifyListeners();
  }
}