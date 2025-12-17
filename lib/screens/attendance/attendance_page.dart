import 'dart:convert';
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/attendance_provider.dart';
import '../../services/notification_service.dart';
import 'widgets/shift_card.dart';
import 'widgets/summary_card.dart';
import 'widgets/custom_tab_bar.dart';
import 'widgets/explanation_dialog.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  bool _isDoctor = false;
  late TabController _tabController;
  StreamSubscription? _notificationSubscription;

  Map<String, dynamic>? _selectedAttendanceForCheckOut;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final userId = _user?['userId'] ?? _user?['id'];
        if (_tabController.index == 1 && userId != null) {
          context.read<AttendanceProvider>().loadMonthlyAttendance(userId);
        }
      }
    });

    // Lắng nghe notification realtime để load lại dữ liệu chấm công nếu có cập nhật liên quan
    _notificationSubscription = NotificationService().onNotificationReceived.listen((data) {
      if (!mounted || _user == null) return;

      final relatedEntityType = data['relatedEntityType']?.toString().toUpperCase();
      if (relatedEntityType == 'ATTENDANCE' || relatedEntityType == 'LEAVE_REQUEST') {
        final userId = _user!['userId'] ?? _user!['id'];
        final provider = context.read<AttendanceProvider>();

        // Refresh dữ liệu hôm nay và các yêu cầu giải trình
        provider.loadTodayAttendance(userId, _isDoctor);
        provider.loadExplanationsNeeding(userId);

        // Nếu đang ở tab lịch sử thì refresh dữ liệu lịch sử chấm công
        if (_tabController.index == 1) {
          provider.loadMonthlyAttendance(userId, reset: true);
        }
      }
    });

    Future.microtask(_initialize);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Hàm khởi tạo dữ liệu người dùng cũng như trạng thái chấm công ban đầu
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
      if (mounted) {
        final roles = decoded['roles'];
        List<String> normalizedRoles = [];
        if (roles is List) {
          normalizedRoles = roles.map((role) => role.toString().toUpperCase()).toList();
        } else if (roles is String) {
          normalizedRoles = roles.split(',').map((role) => role.trim().toUpperCase()).toList();
        }
        final isDoctorRole = normalizedRoles.any((role) => role == 'DOCTOR');

        setState(() {
          _user = decoded;
          _isDoctor = isDoctorRole;
        });

        final userId = decoded['userId'] ?? decoded['id'];
        if (mounted) {
          final provider = context.read<AttendanceProvider>();
          await provider.loadTodayAttendance(userId, isDoctorRole);
          await provider.loadExplanationsNeeding(userId);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'attendance.toast.profileLoadFailed'.tr());
    }
  }

  // Hàm xử lý check-in/out dành cho nhân viên và bác sĩ, ưu tiên chọn ca đối với bác sĩ
  Future<void> _handleCheckInOut(bool isClockIn) async {
    if (_user == null) {
      Fluttertoast.showToast(msg: 'User information not found. Please login again.');
      return;
    }
    
    // Validate và lấy userId từ user object
    final userIdRaw = _user!['userId'] ?? _user!['id'];
    if (userIdRaw == null) {
      Fluttertoast.showToast(msg: 'User ID not found. Please login again.');
      return;
    }
    
    // Đảm bảo userId là số nguyên hợp lệ
    int? userId;
    if (userIdRaw is int) {
      userId = userIdRaw;
    } else if (userIdRaw is String) {
      userId = int.tryParse(userIdRaw);
    } else {
      userId = int.tryParse(userIdRaw.toString());
    }
    
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Invalid user ID. Please login again.');
      return;
    }
    
    final provider = context.read<AttendanceProvider>();

    if (!isClockIn && _isDoctor) {
      if (provider.todayAttendanceList.length > 1) {
        final selected = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('attendance.selectShift.title'.tr()),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.todayAttendanceList.length,
                itemBuilder: (context, index) {
                  final item = provider.todayAttendanceList[index];
                  return ShiftCard(
                    attendance: item,
                    isSelected: false,
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
          ),
        );

        if (selected != null && mounted) {
          setState(() {
            _selectedAttendanceForCheckOut = selected;
          });
          await provider.handleAttendanceAction(
            context: context,
            isClockIn: false,
            userId: userId,
            isDoctor: _isDoctor,
            selectedAttendanceForCheckOut: selected,
          );
        }
        return;
      } else if (provider.todayAttendanceList.length == 1) {
        setState(() {
          _selectedAttendanceForCheckOut = provider.todayAttendanceList[0];
        });
        await provider.handleAttendanceAction(
          context: context,
          isClockIn: false,
          userId: userId,
          isDoctor: _isDoctor,
          selectedAttendanceForCheckOut: provider.todayAttendanceList[0],
        );
        return;
      }
    }

    Map<String, dynamic>? selectedAttendance;
    if (!isClockIn) {
      // Ưu tiên: 1. Đã chọn tay, 2. Dùng attendance của hôm nay
      if (_selectedAttendanceForCheckOut != null) {
        selectedAttendance = _selectedAttendanceForCheckOut;
      } else if (_isDoctor) {
        if (provider.todayAttendanceList.isNotEmpty) {
          selectedAttendance = provider.todayAttendanceList[0];
        }
      } else {
        if (provider.todayAttendance != null) {
          selectedAttendance = provider.todayAttendance;
        }
      }

      // Kiểm tra có attendance hợp lệ chưa (có id)
      if (selectedAttendance == null) {
        Fluttertoast.showToast(
          msg: 'attendance.toast.noCheckInRecord'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      final attendanceId = selectedAttendance['id'];
      if (attendanceId == null) {
        Fluttertoast.showToast(
          msg: 'attendance.toast.noAttendanceId'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Kiểm tra trạng thái đã check-out chưa
      if (selectedAttendance['checkOutTime'] != null) {
        Fluttertoast.showToast(
          msg: 'attendance.toast.alreadyCheckedOut'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }
      await provider.handleAttendanceAction(
        context: context,
        isClockIn: false,
        userId: userId,
        isDoctor: _isDoctor,
        selectedAttendanceForCheckOut: selectedAttendance,
      );
      return;
    }

    await provider.handleAttendanceAction(
      context: context,
      isClockIn: true,
      userId: userId,
      isDoctor: _isDoctor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                          ),
                          child: Icon(Icons.arrow_back_rounded, size: 20, color: colorScheme.onSurface),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
                        onPressed: _user == null
                            ? null
                            : () {
                                final userId = _user!['userId'] ?? _user!['id'];
                                if (_tabController.index == 0) {
                                  final provider = context.read<AttendanceProvider>();
                                  provider.loadTodayAttendance(userId, _isDoctor);
                                  provider.loadExplanationsNeeding(userId);
                                } else {
                                  context.read<AttendanceProvider>().loadMonthlyAttendance(userId, reset: true);
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Attendance'.tr(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, dd MMMM').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tab Bar
            CustomTabBar(
              controller: _tabController,
              tabs: [
                'Today'.tr(),
                'Monthly'.tr(),
              ],
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: Consumer<AttendanceProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && _user != null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTodayBody(provider),
                      _buildMonthlyBody(provider),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayBody(AttendanceProvider provider) {
    if (_user == null) {
      return Center(
        child: FilledButton(
          onPressed: () => context.go('/login'),
          child: Text('Sign in'.tr()),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = _user!['userId'] ?? _user!['id'];
        await provider.loadTodayAttendance(userId, _isDoctor);
        await provider.loadExplanationsNeeding(userId);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          if (!_isDoctor)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildAnimatedItem(
                index: 0,
                child: SummaryCard(attendance: provider.todayAttendance),
              ),
            ),

          if (_isDoctor && provider.todayAttendanceList.isNotEmpty)
            ...provider.todayAttendanceList.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAnimatedItem(
                index: entry.key + 1,
                child: ShiftCard(
                  attendance: entry.value,
                  isSelected: false,
                  onTap: () {},
                ),
              ),
            )),

          // Trạng thái không có ca cho bác sĩ hôm nay
          if (_isDoctor && !provider.isLoading && provider.todayAttendanceList.isEmpty && provider.error == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildAnimatedItem(
                index: 0,
                child: _buildEmptyStateForDoctors(),
              ),
            ),

          if (provider.error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  if (provider.error!.toLowerCase().contains('unauthorized') ||
                      provider.error!.toLowerCase().contains('authentication'))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login, size: 18),
                        label: Text('Sign in again'.tr()),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          _buildActionButtons(provider),

          const SizedBox(height: 32),

          if (provider.isLoadingExplanations)
            const Center(child: CircularProgressIndicator())
          else if (provider.explanationsNeeding.isNotEmpty)
            _buildExplanationsSection(provider),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AttendanceProvider provider) {
    // Kiểm tra trạng thái check-in/check-out để disable button tương ứng
    bool hasCheckedIn = false;
    bool hasCheckedOut = false;
    bool canCheckIn = true;
    bool canCheckOut = false;

    if (_isDoctor) {
      // Bác sĩ: kiểm tra tất cả các ca hôm nay
      if (provider.todayAttendanceList.isNotEmpty) {
        // Kiểm tra xem có ca nào đã check-in chưa
        hasCheckedIn = provider.todayAttendanceList.any((att) => 
          att['checkInTime'] != null
        );
        // Kiểm tra xem có ca nào đã check-out chưa
        hasCheckedOut = provider.todayAttendanceList.any((att) => 
          att['checkOutTime'] != null
        );
        // Kiểm tra xem có ca nào đã check-in nhưng chưa check-out
        final hasIncompleteShift = provider.todayAttendanceList.any((att) => 
          att['checkInTime'] != null && att['checkOutTime'] == null
        );
        
        // Có thể check-in nếu chưa có ca nào check-in, hoặc tất cả ca đã check-out
        canCheckIn = !hasCheckedIn || (hasCheckedOut && !hasIncompleteShift);
        // Có thể check-out nếu có ít nhất 1 ca đã check-in nhưng chưa check-out
        canCheckOut = hasIncompleteShift;
      }
    } else {
      // Nhân viên: kiểm tra attendance hôm nay
      final todayAtt = provider.todayAttendance;
      if (todayAtt != null) {
        hasCheckedIn = todayAtt['checkInTime'] != null;
        hasCheckedOut = todayAtt['checkOutTime'] != null;
        
        // Có thể check-in nếu chưa check-in, hoặc đã check-out (ca mới)
        canCheckIn = !hasCheckedIn || hasCheckedOut;
        // Có thể check-out nếu đã check-in nhưng chưa check-out
        canCheckOut = hasCheckedIn && !hasCheckedOut;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Check In'.tr(),
              icon: Icons.login_rounded,
              color: const Color(0xFF047857),
              onPressed: (provider.isSubmitting || !canCheckIn) 
                  ? null 
                  : () => _handleCheckInOut(true),
              isLoading: provider.isSubmitting,
              isOutlined: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              label: 'Check Out'.tr(),
              icon: Icons.logout_rounded,
              color: const Color(0xFFD97706),
              onPressed: (provider.isSubmitting || !canCheckOut) 
                  ? null 
                  : () => _handleCheckInOut(false),
              isLoading: provider.isSubmitting,
              isOutlined: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required bool isLoading,
    required bool isOutlined,
  }) {
    final isDisabled = onPressed == null;
    final effectiveColor = isDisabled ? color.withOpacity(0.4) : color;
    
    if (isOutlined) {
      return Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: effectiveColor.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: isDisabled ? [] : [
              BoxShadow(
                color: effectiveColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: effectiveColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: effectiveColor, size: 18),
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: effectiveColor,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              effectiveColor,
              effectiveColor.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isDisabled ? [] : [
            BoxShadow(
              color: effectiveColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: effectiveColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Section giải trình cho các trường hợp chấm công bất thường
  Widget _buildExplanationsSection(AttendanceProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explanations required'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...provider.explanationsNeeding.map((item) => _buildExplanationItem(item, provider)),
      ],
    );
  }

  // Lấy tiêu đề giải trình theo loại
  String _getExplanationTitle(String type) {
    switch (type.toUpperCase()) {
      case 'LATE':
        return 'Late'.tr();
      case 'MISSING_CHECK_OUT':
        return 'Missing check-out'.tr();
      case 'MISSING_CHECK_IN':
        return 'Missing check-in'.tr();
      case 'ABSENT':
        return 'Absent'.tr();
      default:
        return 'Early leave'.tr();
    }
  }

  // Lấy nhãn loại ca làm việc
  String _getShiftTypeLabel(String? shiftType) {
    if (shiftType == null || shiftType == 'FULL_DAY') return '';
    return shiftType == 'MORNING' ? 'Morning shift' : 'Afternoon shift';
  }

  // Hiển thị 1 item giải trình
  Widget _buildExplanationItem(Map<String, dynamic> item, AttendanceProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final type = item['explanationType']?.toString() ?? 'UNKNOWN';
    final date = item['workDate']?.toString() ?? '';
    final shiftType = item['shiftType']?.toString();
    final shiftLabel = _getShiftTypeLabel(shiftType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getExplanationTitle(type),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    if (shiftLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shiftLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final reason = await showDialog<String>(
                context: context,
                builder: (context) => const ExplanationDialog(),
              );

              if (reason != null && mounted) {
                final userId = _user!['userId'] ?? _user!['id'];
                final attendanceId = item['attendanceId'];
                
                // Lấy thông tin cần thiết cho trường hợp attendanceId = 0
                int? clinicId;
                String? workDate;
                String? shiftType;
                
                if (attendanceId == null || attendanceId == 0) {
                  clinicId = item['clinicId'] as int?;
                  final dateRaw = item['workDate'];
                  if (dateRaw != null) {
                    if (dateRaw is List && dateRaw.length >= 3) {
                      // Chuyển đổi từ List [year, month, day] sang String yyyy-MM-dd
                      final y = dateRaw[0].toString();
                      final m = dateRaw[1].toString().padLeft(2, '0');
                      final d = dateRaw[2].toString().padLeft(2, '0');
                      workDate = '$y-$m-$d';
                    } else if (dateRaw is String) {
                      // Nếu là string, kiểm tra format và chuẩn hóa về yyyy-MM-dd
                      try {
                        final parsed = DateTime.parse(dateRaw);
                        workDate = DateFormat('yyyy-MM-dd').format(parsed);
                      } catch (_) {
                        workDate = dateRaw;
                      }
                    } else {
                      workDate = dateRaw.toString();
                    }
                  }
                  shiftType = item['shiftType']?.toString();
                }
                
                await provider.submitExplanation(
                  attendanceId ?? 0,
                  type,
                  reason,
                  userId,
                  clinicId: clinicId,
                  workDate: workDate,
                  shiftType: shiftType,
                );
              }
            },
            child: Text('Submit'.tr()),
          ),
        ],
      ),
    );
  }

  // Hiển thị danh sách chấm công tháng
  Widget _buildMonthlyBody(AttendanceProvider provider) {
    if (provider.monthlyAttendanceList.isEmpty && provider.isLoadingMonthly) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.monthlyAttendanceList.isEmpty) {
      return Center(child: Text('No attendance data for this month'.tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: provider.monthlyAttendanceList.length + (provider.hasMoreMonthlyData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.monthlyAttendanceList.length) {
          if (!provider.isLoadingMonthly) {
            final userId = _user!['userId'] ?? _user!['id'];
            provider.loadMonthlyAttendance(userId);
          }
          return const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
        }

        final item = provider.monthlyAttendanceList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShiftCard(
            attendance: item,
            isSelected: false,
            onTap: () {},
          ),
        );
      },
    );
  }

  // Hiển thị hiệu ứng xuất hiện danh sách từng mục
  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        final delay = index * 0.1;
        final effectiveValue = (value - delay).clamp(0.0, 1.0);

        return Opacity(
          opacity: effectiveValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - effectiveValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Hiển thị trạng thái rỗng cho bác sĩ khi hôm nay không có ca làm
  Widget _buildEmptyStateForDoctors() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 32,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No shifts today'.tr(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}