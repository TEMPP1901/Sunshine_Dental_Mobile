import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/attendance_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _todayAttendance; // Giữ lại cho nhân viên (1 record)
  List<Map<String, dynamic>> _todayAttendanceList = []; // Danh sách các ca cho bác sĩ
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;
  bool _isDoctor = false; // Flag để phân biệt bác sĩ và nhân viên
  
  // Explanation related
  List<Map<String, dynamic>> _explanationsNeeding = [];
  bool _isLoadingExplanations = false;

  // Monthly attendance
  late TabController _tabController;
  List<Map<String, dynamic>> _monthlyAttendanceList = [];
  bool _isLoadingMonthly = false;
  int _currentPage = 0;
  bool _hasMoreMonthlyData = true;

  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final userId = _user?['userId'] ?? _user?['id'];
        if (_tabController.index == 1 && userId != null && _monthlyAttendanceList.isEmpty) {
          _loadMonthlyAttendance(userId, reset: true);
        }
      }
    });
    Future.microtask(_initialize);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // ==================== LOGIC VÀ DATA FETCHING ====================

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('user');

    if (rawUser == null) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'common.signInRequired'.tr());
        context.go('/login');
      }
      return;
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is Map<String, dynamic>) {
        final roles = decoded['roles'];
        List<String> normalizedRoles = [];
        if (roles is List) {
          normalizedRoles = roles.map((role) => role.toString().toUpperCase()).toList();
        } else if (roles is String) {
          normalizedRoles = roles.split(',').map((role) => role.trim().toUpperCase()).toList();
        }
        final isDoctorRole = normalizedRoles.any((role) => role == 'DOCTOR');
        final hasForbiddenRole = normalizedRoles.any(
          (role) => role == 'USER' || role == 'ADMIN',
        );
        setState(() {
          _user = decoded;
          _isDoctor = isDoctorRole;
        });
        if (hasForbiddenRole) {
          Fluttertoast.showToast(msg: 'attendance.accessDenied'.tr());
          context.go('/home');
          return;
        }
        final userId = decoded['userId'] ?? decoded['id'];
        await _loadTodayAttendance(userId);
        await _loadExplanationsNeeding(userId);
        // Load monthly attendance nếu đang ở tab tháng
        if (_tabController.index == 1) {
          await _loadMonthlyAttendance(userId, reset: true);
        }
      } else {
        throw const FormatException('Invalid user profile');
      }
    } catch (e) {
      setState(() {
        _error = 'attendance.toast.profileLoadFailed'.tr();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadExplanationsNeeding(dynamic userId) async {
    if (userId == null) return;
    setState(() {
      _isLoadingExplanations = true;
    });
    try {
      final explanations = await _attendanceService.fetchExplanationsNeeding(userId);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final filtered = explanations.where((ex) {
        final status = ex['explanationStatus']?.toString().toUpperCase();
        if (status != 'PENDING') return false;
        final reason = ex['employeeReason']?.toString();
        if (reason != null && reason.trim().isNotEmpty) return false;
        final dateStr = ex['workDate']?.toString();
        if (dateStr == null) return false;
        try {
          final parsed = DateTime.parse(dateStr);
          return DateFormat('yyyy-MM-dd').format(parsed) == today;
        } catch (_) {
          return false;
        }
      }).toList();

      setState(() {
        _explanationsNeeding = filtered;
      });
    } catch (e) {
      // Silently fail - explanations are optional
      setState(() {
        _explanationsNeeding = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExplanations = false;
        });
      }
    }
  }
  
  Future<void> _submitExplanation(Map<String, dynamic> explanation) async {
    final attendanceId = explanation['attendanceId'];
    final explanationType = explanation['explanationType'];
    
    if (attendanceId == null || explanationType == null) {
      Fluttertoast.showToast(msg: 'attendance.explanation.invalidData'.tr());
      return;
    }
    
    // Show dialog to enter reason
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('attendance.explanation.dialogTitle'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: 'attendance.explanation.reasonLabel'.tr(),
            hintText: 'attendance.explanation.reasonHint'.tr(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            child: Text('common.submit'.tr()),
          ),
        ],
      ),
    );
    
    if (result == null || result.isEmpty) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      await _attendanceService.submitExplanation(
        attendanceId,
        explanationType,
        result,
      );
      Fluttertoast.showToast(msg: 'attendance.explanation.submitSuccess'.tr());
      
      // Refresh explanations
      final userId = _user!['userId'] ?? _user!['id'];
      await _loadExplanationsNeeding(userId);
    } on DioException catch (dioError) {
      final serverMessage = dioError.response?.data?['message']?.toString();
      Fluttertoast.showToast(
        msg: (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : 'attendance.explanation.submitFailed'.tr(),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'attendance.explanation.submitFailed'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  List<String> get _normalizedRoles {
    final roles = _user?['roles'];
    if (roles is List) {
      return roles.map((role) => role.toString().toUpperCase()).toList();
    }
    if (roles is String) {
      return roles
          .split(',')
          .map((role) => role.replaceAll(RegExp(r'[\[\]\s]'), '').toUpperCase())
          .where((role) => role.isNotEmpty)
          .toList();
    }
    return const [];
  }


  Future<void> _loadTodayAttendance(dynamic userId) async {
    if (userId == null) return;
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      final result = await _attendanceService.fetchTodayAttendance(userId, _isDoctor);
          setState(() {
        _todayAttendanceList = result['data'] as List<Map<String, dynamic>>;
        _todayAttendance = result['single'] as Map<String, dynamic>?;
        });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _handleAttendanceAction({required bool isClockIn}) async {
    if (_user == null || _isSubmitting) {
      return;
    }

    final userId = _user!['userId'] ?? _user!['id'];
    if (userId == null) {
      Fluttertoast.showToast(msg: 'attendance.toast.profileLoadFailed'.tr());
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      int? clinicId;
      if (_isDoctor) {
        // Reset cache để đảm bảo resolve đúng clinicId cho ca hiện tại
        clinicId = await _attendanceService.resolveDoctorClinicId(userId);
        if (clinicId == null) {
          Fluttertoast.showToast(msg: 'attendance.toast.clinicNotFound'.tr());
          return;
        }
      }

      final permissionGranted = await _attendanceService.ensureWifiPermissions();
      if (!permissionGranted) {
        Fluttertoast.showToast(msg: 'attendance.toast.permissionDenied'.tr());
        return;
      }

      final wifiInfo = await _attendanceService.collectWifiInfo();
      final embedding = await _attendanceService.captureEmbedding();
      if (embedding == null) {
        Fluttertoast.showToast(msg: 'attendance.toast.captureCancelled'.tr());
        return;
      }

      if (isClockIn) {
        final result = await _attendanceService.checkIn(
          userId: userId,
          faceEmbedding: embedding,
          ssid: wifiInfo['ssid'],
          bssid: wifiInfo['bssid'],
          clinicId: clinicId,
        );

        // Xử lý response với các field mới từ backend
        final responseData = result['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          final verificationStatus = responseData['verificationStatus']?.toString();
          final wifiValid = responseData['wifiValid'] as bool?;

          if (verificationStatus == 'FAILED') {
            Fluttertoast.showToast(
              msg: 'attendance.toast.faceVerificationFailed'.tr(),
              toastLength: Toast.LENGTH_LONG,
            );
            return;
          }

          if (wifiValid == false) {
            Fluttertoast.showToast(
              msg: responseData['wifiValidationMessage']?.toString() ??
                  'attendance.toast.wifiInvalid'.tr(),
              toastLength: Toast.LENGTH_LONG,
            );
          }
        }

        Fluttertoast.showToast(msg: 'attendance.toast.checkInSuccess'.tr());
      } else {
        // Check-out: Cần chọn ca cho bác sĩ
        Map<String, dynamic>? selectedAttendance;
        if (_isDoctor && _todayAttendanceList.length > 1) {
          selectedAttendance = await _selectAttendanceForCheckOut();
          if (selectedAttendance == null) {
            return; // User đã hủy
          }
        } else {
          selectedAttendance = _todayAttendance;
        }
        
        final attendanceId = selectedAttendance?['id'];
        if (attendanceId == null) {
          Fluttertoast.showToast(msg: 'attendance.toast.noAttendance'.tr());
          return;
        }

        final result = await _attendanceService.checkOut(
          attendanceId: attendanceId,
          faceEmbedding: embedding,
          ssid: wifiInfo['ssid'],
          bssid: wifiInfo['bssid'],
        );

        // Xử lý response với các field mới từ backend
        final responseData = result['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          final verificationStatus = responseData['verificationStatus']?.toString();
          final wifiValid = responseData['wifiValid'] as bool?;

          if (verificationStatus == 'FAILED') {
            Fluttertoast.showToast(
              msg: 'attendance.toast.faceVerificationFailed'.tr(),
              toastLength: Toast.LENGTH_LONG,
            );
            return;
          }

          if (wifiValid == false) {
            Fluttertoast.showToast(
              msg: responseData['wifiValidationMessage']?.toString() ??
                  'attendance.toast.wifiInvalid'.tr(),
              toastLength: Toast.LENGTH_LONG,
            );
          }
        }

        Fluttertoast.showToast(msg: 'attendance.toast.checkOutSuccess'.tr());
      }

      await _loadTodayAttendance(userId);
      await _loadExplanationsNeeding(userId);
    } on DioException catch (dioError) {
      final serverMessage = dioError.response?.data?['message']?.toString();
      Fluttertoast.showToast(
        msg: (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : 'attendance.toast.loadFailed'.tr(),
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      // Xử lý Exception được throw từ attendance_service
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      Fluttertoast.showToast(
        msg: errorMessage.isNotEmpty ? errorMessage : 'attendance.toast.loadFailed'.tr(),
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--:--';
    try {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed == null) return '--:--';
      return DateFormat('HH:mm:ss').format(parsed.toLocal());
    } catch (_) {
      return '--:--';
    }
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return dateStr;
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _loadMonthlyAttendance(dynamic userId, {bool reset = false}) async {
    if (userId == null || _isLoadingMonthly) return;

    if (reset) {
      setState(() {
        _monthlyAttendanceList = [];
        _currentPage = 0;
        _hasMoreMonthlyData = true;
      });
    }

    if (!_hasMoreMonthlyData && !reset) return;

    setState(() {
      _isLoadingMonthly = true;
    });

    try {
      final now = DateTime.now();
      final result = await _attendanceService.fetchMonthlyAttendance(
        userId,
        now.year,
        now.month,
        _currentPage,
        20,
      );

      setState(() {
        final newItems = result['data'] as List<Map<String, dynamic>>;
        if (reset) {
          _monthlyAttendanceList = newItems;
        } else {
          _monthlyAttendanceList.addAll(newItems);
        }
        _currentPage = (result['currentPage'] as int) + 1;
        _hasMoreMonthlyData = result['hasMore'] as bool;
      });
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMonthly = false;
        });
      }
    }
  }

  // ==================== CÁC HÀM TIỆN ÍCH UI MỚI/CẬP NHẬT ====================

  Widget _buildVerificationStatusChip({
    required String verificationStatus,
    required bool? wifiValid,
    required ColorScheme colorScheme,
  }) {
    List<Widget> chips = [];
    
    // 1. Chip trạng thái Xác thực khuôn mặt
    Color faceColor;
    String faceLabel;
    IconData faceIcon;

    switch (verificationStatus) {
      case 'SUCCESS':
        faceColor = Colors.green.shade600;
        faceLabel = 'attendance.status.verified'.tr();
        faceIcon = Icons.face_retouching_natural_outlined;
        break;
      case 'FAILED':
        faceColor = colorScheme.error;
        faceLabel = 'attendance.status.faceFailed'.tr();
        faceIcon = Icons.error_outline;
        break;
      case 'PENDING':
      default:
        faceColor = colorScheme.outline;
        faceLabel = 'attendance.status.unknown'.tr();
        faceIcon = Icons.help_outline;
        break;
    }

    chips.add(Chip(
      avatar: Icon(faceIcon, size: 16, color: faceColor),
      label: Text(faceLabel, style: TextStyle(fontSize: 12, color: faceColor, fontWeight: FontWeight.w600)),
      backgroundColor: faceColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.zero,
    ));

    // 2. Chip trạng thái Wi-Fi
    if (wifiValid != null) {
      Color wifiColor = wifiValid ? colorScheme.primary : colorScheme.error;
      String wifiLabel = wifiValid ? 'attendance.status.wifiValid'.tr() : 'attendance.status.wifiInvalid'.tr();
      IconData wifiIcon = wifiValid ? Icons.wifi_rounded : Icons.wifi_off_rounded;

      chips.add(const SizedBox(width: 8));
      chips.add(Chip(
        avatar: Icon(wifiIcon, size: 16, color: wifiColor),
        label: Text(wifiLabel, style: TextStyle(fontSize: 12, color: wifiColor, fontWeight: FontWeight.w600)),
        backgroundColor: wifiColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.zero,
      ));
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildTimeTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Màu nền nhẹ từ màu chính
          borderRadius: BorderRadius.circular(16), // Bo góc nhỏ hơn một chút cho gọn
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8), // Giảm khoảng cách
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith( // Dùng labelMedium
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith( // Vẫn giữ kích thước lớn nhưng gọn hơn
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh, // Nền màu nổi bật hơn
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }


  // ==================== CÁC HÀM BUILD CỦA WIDGET ====================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = _isLoading && _user == null;
    return PopScope(
      canPop: context.canPop(),
      child: Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        title: Text('attendance.title'.tr()),
          backgroundColor: colorScheme.surfaceContainerHighest, // Dùng màu nền nhẹ
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _user == null
                ? null
                : () async {
                    final userId = _user!['userId'] ?? _user!['id'];
                      if (_tabController.index == 0) {
                        await _loadTodayAttendance(userId);
                        await _loadExplanationsNeeding(userId);
                      } else {
                        await _loadMonthlyAttendance(userId, reset: true);
                      }
                  },
          ),
        ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              tabs: [
                Tab(text: 'attendance.tab.today'.tr()),
                Tab(text: 'attendance.tab.monthly'.tr()),
              ],
            ),
          ),
      ),
      body: SafeArea(
        child: isBusy
            ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayBody(),
                    _buildMonthlyBody(),
                  ],
                ),
      ),
      ),
    );
  }

  Widget _buildTodayBody() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_user == null) {
      return Center(
        child: FilledButton(
          onPressed: () => context.go('/login'),
          child: Text('attendance.actions.signIn'.tr()),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = _user!['userId'] ?? _user!['id'];
        await _loadTodayAttendance(userId);
        await _loadExplanationsNeeding(userId);
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Hiển thị danh sách các ca cho bác sĩ
          if (_isDoctor && _todayAttendanceList.isNotEmpty) ...[
            _buildShiftsList(),
            const SizedBox(height: 24),
          ] else if (!_isDoctor) ...[
            _buildSummaryCard(),
            const SizedBox(height: 24),
          ],
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _buildActionButtons(),
          const SizedBox(height: 32),
          if (_isLoadingExplanations)
            const Center(child: CircularProgressIndicator())
          else if (_explanationsNeeding.isNotEmpty) ...[
            _buildExplanationsSection(),
            const SizedBox(height: 24),
          ],
          _buildInfoNote(),
        ],
      ),
    );
  }
  
  Widget _buildExplanationsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.3)), // Dùng tertiary cho cảnh báo/giải trình
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                'attendance.explanation.title'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._explanationsNeeding.map((explanation) => _buildExplanationCard(explanation)),
        ],
      ),
    );
  }
  
  Widget _buildExplanationCard(Map<String, dynamic> explanation) {
    final colorScheme = Theme.of(context).colorScheme;
    final workDate = explanation['workDate'];
    final explanationType = explanation['explanationType']?.toString().toUpperCase() ?? '';
    final explanationStatus = explanation['explanationStatus']?.toString().toUpperCase() ?? 'PENDING';
    final attendanceStatus = explanation['attendanceStatus']?.toString().toUpperCase() ?? '';
    final employeeReason = explanation['employeeReason']?.toString();
    
    String typeLabel = '';
    Color statusColor = colorScheme.outline;
    IconData statusIcon = Icons.pending;
    
    switch (explanationType) {
      case 'LATE':
        typeLabel = 'attendance.explanation.typeLate'.tr();
        break;
      case 'ABSENT':
        typeLabel = 'attendance.explanation.typeAbsent'.tr();
        break;
      case 'MISSING_CHECK_IN':
        typeLabel = 'attendance.explanation.typeMissingCheckIn'.tr();
        break;
      case 'MISSING_CHECK_OUT':
        typeLabel = 'attendance.explanation.typeMissingCheckOut'.tr();
        break;
      default:
        typeLabel = explanationType;
    }
    
    switch (explanationStatus) {
      case 'APPROVED':
        statusColor = colorScheme.primary;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'REJECTED':
        statusColor = colorScheme.error;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = colorScheme.tertiary; // Sử dụng màu khác cho Pending
        statusIcon = Icons.pending_actions_outlined;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, // Nền nhẹ hơn
        borderRadius: BorderRadius.circular(16), // Bo góc lớn hơn
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  typeLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  explanationStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (workDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'attendance.explanation.date'.tr(namedArgs: {
                'date': _formatDate(workDate.toString())
              }),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (attendanceStatus.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'attendance.explanation.attendanceStatus'.tr(namedArgs: {
                'status': attendanceStatus
              }),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (employeeReason != null && employeeReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'attendance.explanation.reasonLabel'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employeeReason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (explanationStatus == 'PENDING') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon( // Chuyển sang FilledButton cho hành động quan trọng
                onPressed: _isSubmitting
                    ? null
                    : () => _submitExplanation(explanation),
                icon: const Icon(Icons.edit, size: 18),
                label: Text('attendance.explanation.submitButton'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.tertiary,
                  foregroundColor: colorScheme.onTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'attendance.summary.today'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._todayAttendanceList.map((attendance) => _buildShiftCard(attendance)),
      ],
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> attendance) {
    final colorScheme = Theme.of(context).colorScheme;
    final shiftType = attendance['shiftType']?.toString().toUpperCase() ?? '';
    final checkInTime = _formatTime(attendance['checkInTime']);
    final checkOutTime = _formatTime(attendance['checkOutTime']);
    final clinicName = attendance['clinicName']?.toString() ?? '—';
    final rawStatus = attendance['attendanceStatus']?.toString().toUpperCase() ?? '';
    final statusLabel = rawStatus.isEmpty ? 'attendance.summary.unknown'.tr() : rawStatus;
    
    final verificationStatus = attendance['verificationStatus']?.toString().toUpperCase() ?? 'PENDING';
    final wifiValid = attendance['wifiValid'] as bool?;

    Color shiftBaseColor;
    String shiftLabel;
    IconData shiftIcon;
    
    if (shiftType == 'MORNING') {
      shiftLabel = 'Ca sáng (08:00-11:00)';
      shiftBaseColor = Colors.orange.shade700;
      shiftIcon = Icons.wb_sunny_outlined;
    } else if (shiftType == 'AFTERNOON') {
      shiftLabel = 'Ca chiều (13:00-18:00)';
      shiftBaseColor = Colors.indigo.shade700;
      shiftIcon = Icons.nightlight_outlined;
    } else {
      shiftLabel = shiftType;
      shiftBaseColor = colorScheme.primary;
      shiftIcon = Icons.access_time_rounded;
    }

    Color statusBgColor;
    Color statusFgColor;
    switch (rawStatus) {
      case 'ON_TIME':
        statusBgColor = colorScheme.primaryContainer;
        statusFgColor = colorScheme.onPrimaryContainer;
        break;
      case 'LATE':
        statusBgColor = colorScheme.tertiaryContainer;
        statusFgColor = colorScheme.onTertiaryContainer;
        break;
      case 'ABSENT':
        statusBgColor = colorScheme.errorContainer;
        statusFgColor = colorScheme.onErrorContainer;
        break;
      default:
        statusBgColor = colorScheme.surfaceContainerHighest;
        statusFgColor = colorScheme.onSurfaceVariant;
    }

    return Card( // Sử dụng Card để tận dụng Material 3 elevation
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: shiftBaseColor.withOpacity(0.1), width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: shiftBaseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                  child: Icon(shiftIcon, color: shiftBaseColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shiftLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                              color: shiftBaseColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                          Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            clinicName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
            const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeTile(
                label: 'attendance.summary.checkIn'.tr(),
                value: checkInTime,
                icon: Icons.login_rounded,
                  color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _buildTimeTile(
                label: 'attendance.summary.checkOut'.tr(),
                value: checkOutTime,
                icon: Icons.logout_rounded,
                  color: colorScheme.secondary,
              ),
            ],
          ),
            const SizedBox(height: 20),
            // Thêm chip trạng thái xác thực và Wi-Fi
            _buildVerificationStatusChip(
              verificationStatus: verificationStatus, 
              wifiValid: wifiValid, 
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: statusBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'attendance.summary.status'.tr(namedArgs: {'status': statusLabel}),
                style: TextStyle(
                  color: statusFgColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Dialog để chọn ca khi check-out (cho bác sĩ có nhiều ca)
  Future<Map<String, dynamic>?> _selectAttendanceForCheckOut() async {
    // Lọc các ca đã check-in nhưng chưa check-out
    final availableShifts = _todayAttendanceList.where((att) {
      return att['checkInTime'] != null && att['checkOutTime'] == null;
    }).toList();

    if (availableShifts.isEmpty) {
      Fluttertoast.showToast(msg: 'attendance.toast.noAttendanceToCheckOut'.tr());
      return null;
    }

    if (availableShifts.length == 1) {
      return availableShifts[0];
    }

    // Hiển thị dialog để chọn ca
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('attendance.selectShift.title'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableShifts.length,
            itemBuilder: (context, index) {
              final shift = availableShifts[index];
              final shiftType = shift['shiftType']?.toString().toUpperCase() ?? '';
              final clinicName = shift['clinicName']?.toString() ?? '';
              final checkInTime = _formatTime(shift['checkInTime']);
              
              String shiftLabel = '';
              Color shiftColor = Colors.blue;
              if (shiftType == 'MORNING') {
                shiftLabel = 'Ca sáng';
                shiftColor = Colors.orange;
              } else if (shiftType == 'AFTERNOON') {
                shiftLabel = 'Ca chiều';
                shiftColor = Colors.purple;
              } else {
                shiftLabel = shiftType;
              }

              return ListTile(
                leading: Icon(
                  shiftType == 'MORNING' ? Icons.wb_sunny : Icons.nightlight,
                  color: shiftColor,
                ),
                title: Text(shiftLabel),
                subtitle: Text('$clinicName\nCheck-in: $checkInTime'),
                onTap: () => Navigator.pop(context, shift),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final checkInTime = _formatTime(_todayAttendance?['checkInTime']);
    final checkOutTime = _formatTime(_todayAttendance?['checkOutTime']);
    final clinicName = _todayAttendance?['clinicName']?.toString() ?? '—';
    final rawStatus =
        _todayAttendance?['attendanceStatus']?.toString().toUpperCase();
    final statusLabel = (rawStatus == null || rawStatus.isEmpty)
        ? 'attendance.summary.unknown'.tr()
        : rawStatus;

    final verificationStatus = _todayAttendance?['verificationStatus']?.toString().toUpperCase() ?? 'PENDING';
    final wifiValid = _todayAttendance?['wifiValid'] as bool?;

    Color statusBgColor;
    Color statusFgColor;
    switch (rawStatus) {
      case 'ON_TIME':
        statusBgColor = colorScheme.primaryContainer;
        statusFgColor = colorScheme.onPrimaryContainer;
        break;
      case 'LATE':
        statusBgColor = colorScheme.tertiaryContainer;
        statusFgColor = colorScheme.onTertiaryContainer;
        break;
      case 'ABSENT':
        statusBgColor = colorScheme.errorContainer;
        statusFgColor = colorScheme.onErrorContainer;
        break;
      default:
        statusBgColor = colorScheme.surfaceContainerHighest;
        statusFgColor = colorScheme.onSurfaceVariant;
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28), // Bo góc lớn và đẹp hơn
      ),
      child: Padding(
        padding: const EdgeInsets.all(28), // Padding lớn hơn
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'attendance.summary.today'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                ),
          ),
            const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeTile(
                label: 'attendance.summary.checkIn'.tr(),
                value: checkInTime,
                icon: Icons.login_rounded,
                  color: colorScheme.primary, // Dùng màu chủ đạo
              ),
                const SizedBox(width: 16),
              _buildTimeTile(
                label: 'attendance.summary.checkOut'.tr(),
                value: checkOutTime,
                icon: Icons.logout_rounded,
                  color: colorScheme.secondary, // Dùng màu phụ
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
                Icon(Icons.location_on_outlined, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clinicName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
            _buildVerificationStatusChip(
              verificationStatus: verificationStatus, 
              wifiValid: wifiValid, 
              colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'attendance.summary.status'.tr(namedArgs: {'status': statusLabel}),
              style: TextStyle(
                  color: statusFgColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    bool alreadyCheckedIn = false;
    bool canCheckOut = false;
    
    if (_isDoctor) {
      if (_todayAttendanceList.isEmpty) {
        alreadyCheckedIn = false;
        canCheckOut = false;
      } else {
        final hasUncheckedShift = _todayAttendanceList.any(
            (att) => att['checkInTime'] == null);
        final hasCheckedInButNotOut = _todayAttendanceList.any(
            (att) => att['checkInTime'] != null && att['checkOutTime'] == null);
        
        alreadyCheckedIn = !hasUncheckedShift;
        canCheckOut = hasCheckedInButNotOut;
      }
    } else {
      alreadyCheckedIn = _todayAttendance?['checkInTime'] != null;
      canCheckOut = _todayAttendance?['checkOutTime'] == null && alreadyCheckedIn;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nút Check-In chính
        FilledButton.icon(
          onPressed: (_isSubmitting || alreadyCheckedIn)
              ? null
              : () => _handleAttendanceAction(isClockIn: true),
          icon: const Icon(Icons.sensor_door_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'attendance.actions.clockIn'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
            ),
          ),
        ),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 60), // Nút lớn hơn
          ),
        ),
        const SizedBox(height: 16),
        // Nút Check-Out phụ
        OutlinedButton.icon(
          onPressed: (_isSubmitting || !canCheckOut)
              ? null
              : () => _handleAttendanceAction(isClockIn: false),
          icon: const Icon(Icons.waving_hand_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'attendance.actions.clockOut'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.secondary,
            side: BorderSide(color: colorScheme.secondary.withOpacity(0.5), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 60),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_person_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'attendance.info.note'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBody() {
    if (_user == null) {
      return Center(
        child: FilledButton(
          onPressed: () => context.go('/login'),
          child: Text('attendance.actions.signIn'.tr()),
        ),
      );
    }

    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', context.locale.toString())
        .format(now);

    return RefreshIndicator(
      onRefresh: () async {
        final userId = _user!['userId'] ?? _user!['id'];
        await _loadMonthlyAttendance(userId, reset: true);
      },
      child: CustomScrollView(
        slivers: [
          // Header với tháng/năm hiện tại
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'attendance.monthly.title'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Danh sách attendance
          if (_isLoadingMonthly && _monthlyAttendanceList.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_monthlyAttendanceList.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'attendance.monthly.noData'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _monthlyAttendanceList.length) {
                    return _buildMonthlyAttendanceCard(_monthlyAttendanceList[index]);
                  } else if (_hasMoreMonthlyData && !_isLoadingMonthly) {
                    // Load more
                    final userId = _user?['userId'] ?? _user?['id'];
                    if (userId != null) {
                      _loadMonthlyAttendance(userId);
                    }
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
                childCount: _monthlyAttendanceList.length + (_hasMoreMonthlyData ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyAttendanceCard(Map<String, dynamic> attendance) {
    final colorScheme = Theme.of(context).colorScheme;
    final workDate = attendance['workDate']?.toString();
    final checkInTime = _formatTime(attendance['checkInTime']);
    final checkOutTime = _formatTime(attendance['checkOutTime']);
    final clinicName = attendance['clinicName']?.toString() ?? '—';
    final rawStatus = attendance['attendanceStatus']?.toString().toUpperCase() ?? '';
    final statusLabel = rawStatus.isEmpty ? 'attendance.summary.unknown'.tr() : rawStatus;
    final shiftType = attendance['shiftType']?.toString().toUpperCase() ?? '';

    Color statusColor;
    IconData statusIcon;
    Color statusBgColor;

    switch (rawStatus) {
      case 'ON_TIME':
        statusColor = Colors.green.shade700;
        statusIcon = Icons.check_circle_outline_rounded;
        statusBgColor = Colors.green.shade50;
        break;
      case 'LATE':
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.schedule_outlined;
        statusBgColor = Colors.orange.shade50;
        break;
      case 'ABSENT':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.cancel_outlined;
        statusBgColor = Colors.red.shade50;
        break;
      default:
        statusColor = colorScheme.outline;
        statusIcon = Icons.help_outline_rounded;
        statusBgColor = colorScheme.surfaceContainerHigh;
    }

    String formattedDate = '—';
    if (workDate != null) {
      try {
        final parsed = DateTime.tryParse(workDate);
        if (parsed != null) {
          formattedDate = DateFormat('dd MMM', context.locale.toString()).format(parsed); // Format gọn hơn
        }
      } catch (_) {
        formattedDate = workDate;
      }
    }

    return Card(
      elevation: 0, // Giảm elevation tối đa
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5), // Đường viền mỏng
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: statusBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        title: Text(
          formattedDate,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
        subtitle: Text(
          clinicName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfoTile(
                  label: 'attendance.summary.checkIn'.tr(),
                  value: checkInTime,
                  icon: Icons.login_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfoTile(
                  label: 'attendance.summary.checkOut'.tr(),
                  value: checkOutTime,
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
          if (shiftType.isNotEmpty && _isDoctor) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  shiftType == 'MORNING'
                      ? 'Ca sáng'
                      : shiftType == 'AFTERNOON'
                          ? 'Ca chiều'
                          : shiftType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}