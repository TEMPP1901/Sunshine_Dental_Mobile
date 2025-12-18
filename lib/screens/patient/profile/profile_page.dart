import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';

// Import các Widgets con
import 'widgets/profile_header.dart';
import 'widgets/attendance_card.dart';
import 'widgets/profile_menu_item.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- ROLES CONFIG ---
  static const _attendanceRoles = {
    'HR',
    'DOCTOR',
    'RECEPTION',
    'ACCOUNTANT',
    'ADMIN',
  }; // Admin cũng có thể check
  static const _attendanceForbidden = {
    'PATIENT',
    'USER',
  }; // User thường không chấm công

  static const _staffRoles = {
    'ADMIN',
    'HR',
    'DOCTOR',
    'RECEPTION',
    'ACCOUNTANT',
  };

  static const _leaveRequestRoles = {
    'HR',
    'DOCTOR',
    'RECEPTION',
    'ACCOUNTANT',
    // ADMIN không có quyền xin nghỉ
  };
  static const _leaveRequestForbidden = {'USER', 'PATIENT', 'ADMIN'};

  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');

    if (!mounted) return;
    if (raw == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        setState(() {
          _user = decoded;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.actions.logout'.tr()),
        content: Text('profile.actions.logoutConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('profile.actions.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) context.go('/login');
  }

  // --- ROLE HELPERS (Đã gia cố để không bị crash) ---
  List<String> _extractRoles(dynamic roles) {
    if (roles == null) return [];
    try {
      List<dynamic> rawList;
      if (roles is List) {
        rawList = roles;
      } else if (roles is String) {
        // Trường hợp roles lưu dạng chuỗi "[ROLE_USER]"
        rawList = roles.replaceAll('[', '').replaceAll(']', '').split(',');
      } else {
        return [];
      }

      return rawList.map((r) {
        String str = r.toString().toUpperCase().trim();
        // Xử lý nếu object là Map (ví dụ {id: 1, name: "ROLE_ADMIN"})
        if (r is Map && r.containsKey('name')) {
          str = r['name'].toString().toUpperCase().trim();
        }

        // Chuẩn hóa: Bỏ "ROLE_"
        if (str.startsWith('ROLE_')) {
          return str.substring(5);
        }
        return str;
      }).toList();
    } catch (e) {
      debugPrint("Error extracting roles: $e");
      return [];
    }
  }

  // Logic: Chỉ hiện menu bệnh nhân nếu là USER và KHÔNG PHẢI nhân viên
  bool get _showPatientLinks {
    final roles = _extractRoles(_user?['roles']);
    if (roles.isEmpty) return false;

    // Nếu có role ADMIN hoặc DOCTOR... thì chắc chắn không phải Patient thuần túy
    bool isStaff = roles.any((r) => _staffRoles.contains(r));
    if (isStaff) return false;

    return true; // Mặc định hiển thị cho User thường
  }

  // Logic: Hiện menu bác sĩ
  bool get _showDoctorLinks {
    final roles = _extractRoles(_user?['roles']);
    return roles.contains('DOCTOR');
  }

  bool get _canCheckAttendance {
    final roles = _extractRoles(_user?['roles']);
    if (roles.isEmpty) return false;
    // Nếu có role bị cấm thì chặn luôn
    if (roles.any((r) => _attendanceForbidden.contains(r)) &&
        !roles.contains('ADMIN')) {
      // Tuy nhiên, logic này cần cẩn thận: Một người vừa là USER vừa là DOCTOR thì sao?
      // Ưu tiên role cao hơn. Nếu là DOCTOR thì được check.
      if (roles.any((r) => _attendanceRoles.contains(r))) return true;
      return false;
    }
    return roles.any((r) => _attendanceRoles.contains(r));
  }

  bool get _canViewLeaveRequest {
    final roles = _extractRoles(_user?['roles']);
    if (roles.isEmpty) return false;
    // Loại trừ ADMIN
    if (roles.contains('ADMIN')) return false;
    return roles.any((r) => _leaveRequestRoles.contains(r));
  }

  bool get _isHR {
    final roles = _extractRoles(_user?['roles']);
    return roles.contains('HR');
  }

  bool get _isAdmin {
    final roles = _extractRoles(_user?['roles']);
    return roles.contains('ADMIN');
  }

  // Kiểm tra xem có thể cập nhật face profile không (chỉ cho nhân viên, không bao gồm ADMIN)
  bool get _canUpdateFaceProfile {
    final roles = _extractRoles(_user?['roles']);
    if (roles.isEmpty) return false;
    // Loại trừ ADMIN
    if (roles.contains('ADMIN')) return false;
    // Chỉ cho phép các role nhân viên: HR, DOCTOR, RECEPTION, ACCOUNTANT
    final faceProfileRoles = {'HR', 'DOCTOR', 'RECEPTION', 'ACCOUNTANT'};
    return roles.any((r) => faceProfileRoles.contains(r));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: context.canPop(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: Text('profile.title'.tr()),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _user == null
            ? _buildGuestView(context)
            : _buildUserView(context),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text('profile.signInPrompt'.tr()),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: Text('profile.actions.signIn'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildUserView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // 1. Header (Avatar, Tên, Role)
          // Đảm bảo user không null khi truyền vào
          ProfileHeader(user: _user!),

          // 2. Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === SECTION BỆNH NHÂN (Chỉ hiện cho bệnh nhân) ===
                if (_showPatientLinks) ...[
                  _buildSectionTitle("Bệnh nhân"),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    icon: Icons.dashboard_customize_outlined,
                    title: "Tổng quan sức khỏe",
                    subtitle: "Xem hạng & chỉ số",
                    onTap: () => context.push('/patient-dashboard'),
                    isFirst: true,
                    customIconColor: Colors.blue,
                  ),
                  ProfileMenuItem(
                    icon: Icons.calendar_month_outlined,
                    title: "Lịch hẹn của tôi",
                    subtitle: "Quản lý & Hủy lịch",
                    onTap: () => context.push('/my-appointments'),
                    customIconColor: Colors.orange,
                  ),
                  ProfileMenuItem(
                    icon: Icons.history_edu_outlined,
                    title: "Hồ sơ bệnh án",
                    subtitle: "Lịch sử khám & điều trị",
                    onTap: () => context.push('/medical-records'),
                    isLast: true,
                    customIconColor: Colors.teal,
                  ),
                  const SizedBox(height: 24),
                ],

                // === SECTION BÁC SĨ (MỚI: Để Doctor không bị trống) ===
                if (_showDoctorLinks) ...[
                  _buildSectionTitle("Dành cho Bác sĩ"),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    icon: Icons.calendar_month,
                    title: "Lịch làm việc",
                    subtitle: "Xem ca trực & Lịch hẹn khách",
                    onTap: () =>
                        context.push('/schedule'), // Dùng trang schedule có sẵn
                    isFirst: true,
                    isLast: true,
                    customIconColor: Colors.purple,
                  ),
                  const SizedBox(height: 24),
                ],

                // === SECTION NHÂN VIÊN (CHẤM CÔNG) ===
                if (_canCheckAttendance) ...[
                  const AttendanceCard(),
                  const SizedBox(height: 24),
                ],

                // === SECTION ADMIN (Chỉ hiện cho ADMIN) ===
                if (_isAdmin) ...[
                  _buildSectionTitle("Admin Management"),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: "Admin Hub",
                    subtitle: "Quản lý hệ thống & báo cáo",
                    onTap: () => context.go('/admin'),
                    isFirst: true,
                    isLast: true,
                    customIconColor: const Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 24),
                ],

                // === SECTION HR (Chỉ hiện cho HR) ===
                if (_isHR) ...[
                  _buildSectionTitle("HR Management"),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    icon: Icons.business_center_outlined,
                    title: "HR Hub",
                    subtitle: "Quản lý nhân sự & chấm công",
                    onTap: () => context.go('/hr'),
                    isFirst: true,
                    isLast: true,
                    customIconColor: const Color(0xFF6D28D9),
                  ),
                  const SizedBox(height: 24),
                ],

                // === SECTION TÀI KHOẢN (Chung cho tất cả) ===
                _buildSectionTitle('profile.accountSettings'.tr()),
                const SizedBox(height: 8),

                ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'account.myAccount.title'.tr(),
                  subtitle: 'account.myAccount.subtitle'.tr(),
                  onTap: () => context.go('/my-account'),
                  isFirst: true,
                ),

                if (_canViewLeaveRequest)
                  ProfileMenuItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'leaveRequest.title'.tr(),
                    subtitle: 'leaveRequest.subtitle'.tr(),
                    onTap: () => context.go('/leave-request'),
                  ),

                // Cập nhật khuôn mặt chấm công (chỉ cho nhân viên, không bao gồm ADMIN)
                if (_canUpdateFaceProfile)
                  ProfileMenuItem(
                    icon: Icons.face_retouching_natural_rounded,
                    title: 'Cập nhật khuôn mặt chấm công',
                    subtitle: 'Cập nhật ảnh khuôn mặt để chấm công',
                    onTap: () => context.push('/update-face-profile'),
                    customIconColor: Colors.purple,
                  ),

                ProfileMenuItem(
                  icon: Icons.key_outlined,
                  title: 'profile.changePassword.title'.tr(),
                  subtitle: 'profile.changePassword.subtitle'.tr(),
                  onTap: () => context.go('/change-password'),
                  isLast: true,
                ),
                const SizedBox(height: 24),

                // === SECTION CÀI ĐẶT ===
                _buildSectionTitle('profile.settings'.tr()),
                const SizedBox(height: 8),
                _buildThemeItem(context),
                _buildLanguageItem(context),

                const SizedBox(height: 24),

                // Logout Button
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('profile.actions.logout'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildThemeItem(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) => ProfileMenuItem(
        icon: themeProvider.isDarkMode
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        title: 'profile.theme.title'.tr(),
        onTap: () => themeProvider.toggleTheme(),
        isFirst: true,
        trailingWidget: Switch(
          value: themeProvider.isDarkMode,
          onChanged: (_) => themeProvider.toggleTheme(),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (_, langProvider, __) => ProfileMenuItem(
        icon: Icons.language_outlined,
        title: 'profile.language.title'.tr(),
        onTap: () async {
          await langProvider.toggleLanguage();
          if (context.mounted) {
            context.setLocale(langProvider.locale);
            _loadUser();
          }
        },
        isLast: true,
        trailingWidget: Text(
          langProvider.currentLanguageName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}
