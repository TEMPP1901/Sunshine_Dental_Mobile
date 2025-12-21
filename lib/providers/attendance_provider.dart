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

  // Lấy dữ liệu điểm danh hôm nay
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

  // Lấy danh sách giải trình cần xử lý cho user
  Future<void> loadExplanationsNeeding(dynamic userId) async {
    if (userId == null) return;
    _isLoadingExplanations = true;
    notifyListeners();

    try {
      final explanations = await _attendanceService.fetchExplanationsNeeding(userId);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      _explanationsNeeding = explanations.where((ex) {
        // Đảm bảo chỉ lấy explanations của user hiện tại 
        final exUserId = ex['userId'];
        if (exUserId == null || exUserId != userId) {
          return false;
        }
        
        final status = ex['explanationStatus']?.toString().toUpperCase();
        if (status != 'PENDING') return false;
        final reason = ex['employeeReason']?.toString();
        if (reason != null && reason.trim().isNotEmpty) return false;
        final dateRaw = ex['workDate'];
        String? dateStr;
        if (dateRaw is List) {
          // Chuyển đổi dữ liệu ngày từ dạng List về String yyyy-MM-dd
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

          // CHỈ CÒN LOẠI GIẢI TRÌNH: MISSING_CHECK_OUT (quên check out)
          // Loại bỏ MISSING_CHECK_OUT cho ngày hôm nay nếu ĐANG TRONG GIỜ LÀM VIỆC (8:00 - 18:00)
          final isToday = workDate == today;
          final currentHour = DateTime.now().hour;
          
          if (isToday && explanationType == 'MISSING_CHECK_OUT') {
            // Nếu đang trong giờ làm việc (8:00 - 18:00) thì filter out
            if (currentHour >= 8 && currentHour < 18) {
              return false;
            }
          }

          // CHỈ CHẤP NHẬN MISSING_CHECK_OUT
          if (explanationType != 'MISSING_CHECK_OUT') {
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

  // Gửi giải trình: CHỈ HỖ TRỢ MISSING_CHECK_OUT (quên check out)
  Future<bool> submitExplanation(
    int attendanceId,
    String explanationType,
    String reason,
    dynamic userId, {
    int? clinicId,
    String? workDate,
    String? shiftType,
  }) async {
    // Validation: CHỈ CHẤP NHẬN MISSING_CHECK_OUT
    if (explanationType.toUpperCase() != 'MISSING_CHECK_OUT') {
      Fluttertoast.showToast(
        msg: 'Invalid explanation type. Only MISSING_CHECK_OUT is supported.',
      );
      return false;
    }
    _isSubmitting = true;
    notifyListeners();

    try {
      await _attendanceService.submitExplanation(
        attendanceId,
        explanationType,
        reason,
        clinicId: clinicId,
        workDate: workDate,
        shiftType: shiftType,
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

  // Xử lý logic điểm danh (check-in, check-out)
  Future<bool> handleAttendanceAction({
    required BuildContext context,
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
        // Thử lấy clinicId từ schedule (không bắt buộc, backend tự xử lý)
        clinicId = await _attendanceService.resolveDoctorClinicId(userId);
      }

      final permissionGranted = await _attendanceService.ensureWifiPermissions();
      if (!permissionGranted) {
        Fluttertoast.showToast(msg: 'attendance.toast.permissionDenied'.tr());
        return false;
      }

      // Kiểm tra userId hợp lệ
      if (userId == null) {
        Fluttertoast.showToast(msg: 'User ID is required');
        return false;
      }

      // Ép kiểu userId về int
      int? validUserId;
      if (userId is int) {
        validUserId = userId;
      } else if (userId is String) {
        validUserId = int.tryParse(userId);
      } else {
        validUserId = int.tryParse(userId.toString());
      }

      if (validUserId == null) {
        Fluttertoast.showToast(msg: 'Invalid user ID');
        return false;
      }

      final wifiInfo = await _attendanceService.collectWifiInfo();

      // Chụp khuôn mặt và lấy embedding
      String? embedding;
      try {
        embedding = await _attendanceService.captureEmbedding(context);
        if (embedding == null || embedding.trim().isEmpty) {
          Fluttertoast.showToast(
            msg: 'Bạn đã hủy chụp ảnh khuôn mặt. Vui lòng chụp lại để chấm công.',
            toastLength: Toast.LENGTH_LONG,
          );
          return false;
        }
      } catch (e) {
        // Bắn ra lỗi khi chụp ảnh khuôn mặt thất bại
        String errorMsg = e.toString().replaceFirst('Exception: ', '');
        Fluttertoast.showToast(
          msg: errorMsg.isNotEmpty ? errorMsg : 'Lỗi khi chụp ảnh khuôn mặt. Vui lòng thử lại.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return false;
      }

      Map<String, dynamic> result;
      if (isClockIn) {
        // Check-in
        result = await _attendanceService.checkIn(
          userId: validUserId,
          faceEmbedding: embedding,
          ssid: wifiInfo['ssid'],
          bssid: wifiInfo['bssid'],
          clinicId: clinicId,
        );
        Fluttertoast.showToast(msg: 'attendance.toast.checkInSuccess'.tr());
      } else {
        // Check-out
        final attendanceIdRaw = selectedAttendanceForCheckOut?['id'];
        if (attendanceIdRaw == null) {
          Fluttertoast.showToast(msg: 'attendance.toast.noAttendance'.tr());
          return false;
        }
        // Đảm bảo attendanceId là số nguyên
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

      // Kiểm tra cảnh báo xác thực wifi/face (báo đỏ cho người dùng các lỗi khi xác thực)
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
      // Bắt lỗi và cảnh báo chi tiết (gồm cảnh báo đối chiếu khuôn mặt)
      String errorMessage = e.toString().replaceFirst('Exception: ', '');

      if (errorMessage.contains('Khuôn mặt không khớp') ||
          errorMessage.contains('Face verification failed') ||
          errorMessage.contains('face does not match') ||
          errorMessage.contains('khuôn mặt')) {
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: errorMessage.isNotEmpty ? errorMessage : 'attendance.toast.loadFailed'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
      }
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Lấy dữ liệu điểm danh theo tháng
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

  // Lấy giải trình cho ngày cụ thể từ explanationsNeeding
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

        // So sánh ngày (bỏ giờ nếu có)
        return dateStr.startsWith(targetDateStr);
      });
    } catch (_) {
      return null;
    }
  }
}
