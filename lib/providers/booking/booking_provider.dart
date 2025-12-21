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
  BookingServiceVariant? selectedServiceVariant; // Giữ lại để tương thích với code cũ
  BookingService? selectedServiceParent; // Giữ lại để tương thích với code cũ
  
  // Danh sách dịch vụ đã chọn (hỗ trợ chọn nhiều dịch vụ)
  List<BookingServiceVariant> selectedServices = [];

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
    // Thêm vào danh sách nếu chưa có
    if (!selectedServices.any((s) => s.variantId == variant.variantId)) {
      selectedServices.add(variant);
    }
    notifyListeners();
  }
  
  // Toggle dịch vụ (thêm/xóa khỏi danh sách)
  void toggleService(BookingService parent, BookingServiceVariant variant) {
    final existingIndex = selectedServices.indexWhere((s) => s.variantId == variant.variantId);
    
    if (existingIndex >= 0) {
      // Xóa nếu đã có
      selectedServices.removeAt(existingIndex);
      // Nếu xóa dịch vụ cuối cùng, cập nhật selectedServiceVariant
      if (selectedServices.isEmpty) {
        selectedServiceVariant = null;
        selectedServiceParent = null;
      } else {
        // Giữ selectedServiceVariant là dịch vụ đầu tiên
        selectedServiceVariant = selectedServices.first;
        selectedServiceParent = parent;
      }
    } else {
      // Thêm mới
      selectedServices.add(variant);
      // Cập nhật selectedServiceVariant và selectedServiceParent
      selectedServiceVariant = variant;
      selectedServiceParent = parent;
    }
    notifyListeners();
  }
  
  // Kiểm tra dịch vụ có được chọn không
  bool isServiceSelected(BookingServiceVariant variant) {
    return selectedServices.any((s) => s.variantId == variant.variantId);
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

  // Lấy danh sách bác sĩ (VIP) - hỗ trợ nhiều dịch vụ
  Future<List<BookingDoctor>> fetchDoctors() async {
    if (selectedClinic == null || selectedServices.isEmpty) return [];
    
    // Lấy danh sách categories từ parent service của các dịch vụ đã chọn
    // Cần tìm parent service cho mỗi variant
    final categories = <String>{};
    
    // Load lại services để tìm parent
    final allServices = await _apiService.getServices();
    for (var variant in selectedServices) {
      for (var service in allServices) {
        if (service.variants.any((v) => v.variantId == variant.variantId)) {
          if (service.category.isNotEmpty) {
            categories.add(service.category);
          }
          break;
        }
      }
    }
    
    if (categories.isEmpty) return [];
    
    // Gửi categories dưới dạng chuỗi phân cách bằng dấu phẩy
    final specialtyParam = categories.join(',');
    
    return await _apiService.getDoctors(
      selectedClinic!.id,
      specialtyParam,
    );
  }

  // Lấy Slot (VIP)
  Future<List<TimeSlot>> fetchSlots() async {
    if (selectedClinic == null ||
        selectedDoctor == null ||
        selectedDate == null ||
        selectedServiceVariant == null) {
      print('[BookingProvider] Cannot fetch slots: missing required data');
      return [];
    }
    String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    return await _apiService.getSlots(
      selectedClinic!.id,
      selectedDoctor!.id,
      selectedServiceVariant!.variantId,
      dateStr,
    );
  }

  // Check Availability (Standard)
  Future<SessionAvailability> checkAvailability() async {
    if (selectedClinic == null || selectedDate == null) {
      return SessionAvailability(
        morningAvailable: false,
        afternoonAvailable: false,
      );
    }
    String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    return await _apiService.checkSessionAvailability(
      selectedClinic!.id,
      dateStr,
    );
  }

  // CONFIRM BOOKING
  Future<int?> confirmBooking() async {
    isLoading = true;
    notifyListeners();

    try {
      // Format date and time
      String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
      // Format time: "08:00" -> "08:00:00"
      String timeStr = (selectedTime!.length == 5)
          ? "$selectedTime:00"
          : selectedTime!;

      // Format to ISO-8601 with Vietnam timezone offset (+07:00)
      String startDateTime = "${dateStr}T$timeStr+07:00";

      final payload = {
        "clinicId": selectedClinic!.id,
        "appointmentType": appointmentType,
        "bookingFee": bookingFee,
        "doctorId": (appointmentType == 'VIP') ? selectedDoctor?.id : null,
        "startDateTime": startDateTime, // Backend sẽ tự tính EndDateTime
        "status": (appointmentType == 'VIP') ? "AWAITING_PAYMENT" : "PENDING",
        "channel": "Mobile App", // Set channel để phân biệt booking từ mobile
        "note": "Booking via Mobile App ($appointmentType)",
        "services": selectedServices.map((s) => {
          "serviceId": s.variantId,
          "quantity": 1,
        }).toList(),
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
    selectedServiceParent = null;
    selectedServices.clear();
    selectedDoctor = null;
    selectedDate = null;
    selectedTime = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 🟢 AI SUPPORT LOGIC (Đã tối ưu Skip Step giống Website)
  // ---------------------------------------------------------------------------

  Future<void> initializeFromAi({int? serviceId, int? doctorId}) async {
    if (serviceId == null && doctorId == null) return;

    isLoading = true;
    notifyListeners();

    try {
      print("🤖 AI Auto-fill: Processing...");

      // 1. Load Clinics & Select Default
      List<BookingClinic> clinics = await _apiService.getClinics();
      if (clinics.isNotEmpty) {
        selectedClinic = clinics.first;
        print("🤖 AI: Auto-selected Clinic ID: ${selectedClinic!.id}");
      }

      // 2. Load Services & Find Target
      if (serviceId != null && selectedClinic != null) {
        List<BookingService> services = await _apiService.getServices();

        bool found = false;
        for (var service in services) {
          for (var variant in service.variants) {
            if (variant.variantId == serviceId) {
              selectedServiceParent = service;
              selectedServiceVariant = variant;
              // Thêm vào danh sách dịch vụ
              if (!selectedServices.any((s) => s.variantId == variant.variantId)) {
                selectedServices.add(variant);
              }

              // 🚀 NHẢY CÓC: Đến thẳng bước chọn ngày (Step 2)
              currentStep = 2;
              found = true;
              print("🤖 AI: Selected Service ${variant.variantName} -> Step 2");
              break;
            }
          }
          if (found) break;
        }
      }

      // 3. Load Doctors & Find Target (VIP)
      if (doctorId != null &&
          selectedClinic != null &&
          selectedServiceParent != null) {
        print("🤖 AI: Detected Doctor ID, switching to VIP...");
        setType('VIP');

        List<BookingDoctor> doctors = await _apiService.getDoctors(
          selectedClinic!.id,
          selectedServiceParent!.category,
        );

        try {
          BookingDoctor targetDoc = doctors.firstWhere((d) => d.id == doctorId);
          selectedDoctor = targetDoc;

          // 🚀 NHẢY CÓC: Đến thẳng bước chọn ngày VIP (Step 3)
          currentStep = 3;
          print("🤖 AI: Selected Doctor ${targetDoc.fullName} -> Step 3");
        } catch (e) {
          print("🤖 AI Error: Doctor ID $doctorId not found");
        }
      }
    } catch (e) {
      print("🤖 AI Auto-fill Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
