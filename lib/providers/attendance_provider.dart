import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  Map<String, dynamic>? _todayAttendance;
  List<Map<String, dynamic>> _todayAttendanceList = [];
  bool _isLoading = false;
  String? _error;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _explanationsNeeding = [];
  bool _isLoadingExplanations = false;

  List<Map<String, dynamic>> _monthlyAttendanceList = [];
  bool _isLoadingMonthly = false;
  int _currentPage = 0;
  bool _hasMoreMonthlyData = true;

  Map<String, dynamic>? get todayAttendance => _todayAttendance;
  List<Map<String, dynamic>> get todayAttendanceList => _todayAttendanceList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;
  List<Map<String, dynamic>> get explanationsNeeding => _explanationsNeeding;
  bool get isLoadingExplanations => _isLoadingExplanations;
  List<Map<String, dynamic>> get monthlyAttendanceList => _monthlyAttendanceList;
  bool get isLoadingMonthly => _isLoadingMonthly;
  bool get hasMoreMonthlyData => _hasMoreMonthlyData;

  // Hàm lấy dữ liệu điểm danh hôm nay
  Future<void> loadTodayAttendance(dynamic userId, bool isDoctor) async {
    if (userId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _attendanceService.fetchTodayAttendance(userId, isDoctor);
      final data = result['data'];
      _todayAttendanceList = (data is List)
          ? data.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      final single = result['single'];
      _todayAttendance = (single is Map<String, dynamic>) ? single : null;
      _error = null;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _error = errorMessage;

      // Hiển thị thông báo lỗi xác thực
      if (errorMessage.toLowerCase().contains('unauthorized') ||
          errorMessage.toLowerCase().contains('authentication')) {
        Fluttertoast.showToast(
          msg: 'attendance.toast.unauthorized'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm lấy danh sách explanation cần xử lý
  Future<void> loadExplanationsNeeding(dynamic userId) async {
    if (userId == null) return;
    _isLoadingExplanations = true;
    notifyListeners();

    try {
      final explanations = await _attendanceService.fetchExplanationsNeeding(userId);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      _explanationsNeeding = explanations.where((ex) {
        final status = ex['explanationStatus']?.toString().toUpperCase();
        if (status != 'PENDING') return false;
        final reason = ex['employeeReason']?.toString();
        if (reason != null && reason.trim().isNotEmpty) return false;
        final dateRaw = ex['workDate'];
        String? dateStr;
        if (dateRaw is List) {
          // Xử lý trường hợp [yyyy, MM, dd]
          if (dateRaw.length >= 3) {
            final y = dateRaw[0];
            final m = dateRaw[1].toString().padLeft(2, '0');
            final d = dateRaw[2].toString().padLeft(2, '0');
            dateStr = '$y-$m-$d';
          }
        } else {
          dateStr = dateRaw?.toString();
        }

        if (dateStr == null) return false;
        try {
          final parsed = DateTime.parse(dateStr);
          final workDate = DateFormat('yyyy-MM-dd').format(parsed);
          final explanationType = ex['explanationType']?.toString().toUpperCase();

          // Loại trừ giải trình MISSING_CHECK_OUT cho ngày hôm nay
          if (workDate == today && explanationType == 'MISSING_CHECK_OUT') {
            return false;
          }

          return true;
        } catch (_) {
          return false;
        }
      }).toList();
    } catch (e) {
      _explanationsNeeding = [];
    } finally {
      _isLoadingExplanations = false;
      notifyListeners();
    }
  }

  // Hàm gửi giải trình vắng mặt, đi muộn
  Future<bool> submitExplanation(int attendanceId, String explanationType, String reason, dynamic userId) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _attendanceService.submitExplanation(
        attendanceId,
        explanationType,
        reason,
      );
      Fluttertoast.showToast(msg: 'attendance.explanation.submitSuccess'.tr());

      await loadExplanationsNeeding(userId);
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      Fluttertoast.showToast(msg: errorMessage);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Hàm điểm danh: check-in/check-out bằng wifi & nhận diện khuôn mặt
  Future<bool> handleAttendanceAction({
    required bool isClockIn,
    required dynamic userId,
    required bool isDoctor,
    Map<String, dynamic>? selectedAttendanceForCheckOut,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      int? clinicId;
      if (isDoctor) {
        clinicId = await _attendanceService.resolveDoctorClinicId(userId);
        if (clinicId == null) {
          Fluttertoast.showToast(msg: 'attendance.toast.clinicNotFound'.tr());
          return false;
        }
      }

      final permissionGranted = await _attendanceService.ensureWifiPermissions();
      if (!permissionGranted) {
        Fluttertoast.showToast(msg: 'attendance.toast.permissionDenied'.tr());
        return false;
      }

      final wifiInfo = await _attendanceService.collectWifiInfo();
      final embedding = await _attendanceService.captureEmbedding();
      if (embedding == null) {
        Fluttertoast.showToast(msg: 'attendance.toast.captureCancelled'.tr());
        return false;
      }

      Map<String, dynamic> result;
      if (isClockIn) {
        result = await _attendanceService.checkIn(
          userId: userId,
          faceEmbedding: embedding,
          ssid: wifiInfo['ssid'],
          bssid: wifiInfo['bssid'],
          clinicId: clinicId,
        );
        Fluttertoast.showToast(msg: 'attendance.toast.checkInSuccess'.tr());
      } else {
        final attendanceIdRaw = selectedAttendanceForCheckOut?['id'];
        if (attendanceIdRaw == null) {
          Fluttertoast.showToast(msg: 'attendance.toast.noAttendance'.tr());
          return false;
        }
        // Kiểm tra attendanceId đảm bảo là kiểu int
        int? attendanceId;
        if (attendanceIdRaw is int) {
          attendanceId = attendanceIdRaw;
        } else if (attendanceIdRaw is String) {
          attendanceId = int.tryParse(attendanceIdRaw);
        } else {
          attendanceId = int.tryParse(attendanceIdRaw.toString());
        }

        if (attendanceId == null) {
          Fluttertoast.showToast(msg: 'attendance.toast.invalidAttendanceId'.tr());
          return false;
        }

        result = await _attendanceService.checkOut(
          attendanceId: attendanceId,
          faceEmbedding: embedding,
          ssid: wifiInfo['ssid'],
          bssid: wifiInfo['bssid'],
        );
        Fluttertoast.showToast(msg: 'attendance.toast.checkOutSuccess'.tr());
      }

      // Kiểm tra các cảnh báo xác thực wifi/face
      final data = result['data'];
      final responseData = (data is Map<String, dynamic>) ? data : null;
      if (responseData != null) {
        final verificationStatus = responseData['verificationStatus']?.toString();
        final wifiValid = responseData['wifiValid'] as bool?;

        if (verificationStatus == 'FAILED') {
          Fluttertoast.showToast(
            msg: 'attendance.toast.faceVerificationFailed'.tr(),
            toastLength: Toast.LENGTH_LONG,
          );
        }
        if (wifiValid == false) {
          Fluttertoast.showToast(
            msg: responseData['wifiValidationMessage']?.toString() ??
                'attendance.toast.wifiInvalid'.tr(),
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }

      await loadTodayAttendance(userId, isDoctor);
      await loadExplanationsNeeding(userId);
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      Fluttertoast.showToast(
        msg: errorMessage.isNotEmpty ? errorMessage : 'attendance.toast.loadFailed'.tr(),
        toastLength: Toast.LENGTH_LONG,
      );
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Hàm lấy dữ liệu điểm danh theo tháng
  Future<void> loadMonthlyAttendance(dynamic userId, {bool reset = false}) async {
    if (userId == null || _isLoadingMonthly) return;

    if (reset) {
      _monthlyAttendanceList = [];
      _currentPage = 0;
      _hasMoreMonthlyData = true;
      notifyListeners();
    }

    if (!_hasMoreMonthlyData && !reset) return;

    _isLoadingMonthly = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final result = await _attendanceService.fetchMonthlyAttendance(
        userId,
        now.year,
        now.month,
        _currentPage,
        20,
      );

      final data = result['data'];
      final newItems = (data is List)
          ? data.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      if (reset) {
        _monthlyAttendanceList = newItems;
      } else {
        _monthlyAttendanceList.addAll(newItems);
      }
      _currentPage = ((result['currentPage'] as int?) ?? 0) + 1;
      _hasMoreMonthlyData = (result['hasMore'] as bool?) ?? false;
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      _isLoadingMonthly = false;
      notifyListeners();
    }
  }
  // Helper để lấy explanation cho ngày cụ thể (dùng cho UI tự động popup)
  Map<String, dynamic>? getExplanationForDate(DateTime date) {
    final targetDateStr = DateFormat('yyyy-MM-dd').format(date);
    
    try {
      return _explanationsNeeding.firstWhere((ex) {
        final dateRaw = ex['workDate'];
        String? dateStr;
        if (dateRaw is List) {
          if (dateRaw.length >= 3) {
            final y = dateRaw[0];
            final m = dateRaw[1].toString().padLeft(2, '0');
            final d = dateRaw[2].toString().padLeft(2, '0');
            dateStr = '$y-$m-$d';
          }
        } else {
          dateStr = dateRaw?.toString();
        }
        
        if (dateStr == null) return false;
        
        // So sánh ngày (chỉ lấy phần yyyy-MM-dd)
        return dateStr.startsWith(targetDateStr);
      });
    } catch (_) {
      return null;
    }
  }
}
