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
  };
  static const _attendanceForbidden = {'PATIENT', 'USER'};
  static const _staffRoles = {
    'ADMIN',
    'HR',
    'DOCTOR',
    'RECEPTION',
    'ACCOUNTANT',
  };
  static const _leaveRequestRoles = {'HR', 'DOCTOR', 'RECEPTION', 'ACCOUNTANT'};

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSwitchingLanguage = false; // State riêng cho việc đổi ngôn ngữ

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

  // Helper Roles
  List<String> _extractRoles(dynamic roles) {
    if (roles == null) return [];
    try {
      List<dynamic> rawList;
      if (roles is List) {
        rawList = roles;
      } else if (roles is String) {
        rawList = roles.replaceAll('[', '').replaceAll(']', '').split(',');
      } else {
        return [];
      }
      return rawList.map((r) {
        String str = r.toString().toUpperCase().trim();
        if (r is Map && r.containsKey('name')) {
          str = r['name'].toString().toUpperCase().trim();
        }
        if (str.startsWith('ROLE_')) return str.substring(5);
        return str;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  bool get _showPatientLinks {
    final roles = _extractRoles(_user?['roles']);
    if (roles.isEmpty) return false;
    bool isStaff = roles.any((r) => _staffRoles.contains(r));
    return !isStaff;
  }

  bool get _showDoctorLinks {
    final roles = _extractRoles(_user?['roles']);
    return roles.contains('DOCTOR');
  }

  bool get _canCheckAttendance {
    final roles = _extractRoles(_user?['roles']);
    if (roles.isEmpty) return false;
    // Ẩn card attendance nếu user là ADMIN
    if (roles.contains('ADMIN')) return false;
    if (roles.any((r) => _attendanceForbidden.contains(r))) {
      if (roles.any((r) => _attendanceRoles.contains(r))) return true;
      return false;
    }
    return roles.any((r) => _attendanceRoles.contains(r));
  }

  bool get _canViewLeaveRequest {
    final roles = _extractRoles(_user?['roles']);
    if (roles.isEmpty || roles.contains('ADMIN')) return false;
    return roles.any((r) => _leaveRequestRoles.contains(r));
  }

  bool get _isHR => _extractRoles(_user?['roles']).contains('HR');
  bool get _isAdmin => _extractRoles(_user?['roles']).contains('ADMIN');

  bool get _canUpdateFaceProfile {
    final roles = _extractRoles(_user?['roles']);
    if (roles.isEmpty || roles.contains('ADMIN')) return false;
    final faceProfileRoles = {'HR', 'DOCTOR', 'RECEPTION', 'ACCOUNTANT'};
    return roles.any((r) => faceProfileRoles.contains(r));
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
          ProfileHeader(user: _user!),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION BỆNH NHÂN
                if (_showPatientLinks) ...[
                  _buildSectionTitle('profile.section.patient'.tr()),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    icon: Icons.dashboard_customize_outlined,
                    title: 'profile.patient.overview'.tr(),
                    subtitle: 'profile.patient.overviewSub'.tr(),
                    onTap: () => context.push('/patient-dashboard'),
                    isFirst: true,
                    customIconColor: Colors.blue,
                  ),
                  ProfileMenuItem(
                    icon: Icons.calendar_month_outlined,
                    title: 'profile.patient.appointments'.tr(),
                    subtitle: 'profile.patient.appointmentsSub'.tr(),
                    onTap: () => context.push('/my-appointments'),
                    customIconColor: Colors.orange,
                  ),
                  ProfileMenuItem(
                    icon: Icons.history_edu_outlined,
                    title: 'profile.patient.records'.tr(),
                    subtitle: 'profile.patient.recordsSub'.tr(),
                    onTap: () => context.push('/medical-records'),
                    isLast: true,
                    customIconColor: Colors.teal,
                  ),
                  const SizedBox(height: 24),
                ],

                // SECTION BÁC SĨ
                if (_showDoctorLinks) ...[
                  _buildSectionTitle('profile.section.doctor'.tr()),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    icon: Icons.calendar_month,
                    title: 'profile.doctor.schedule'.tr(),
                    subtitle: 'profile.doctor.scheduleSub'.tr(),
                    onTap: () => context.push('/schedule'),
                    isFirst: true,
                    isLast: true,
                    customIconColor: Colors.purple,
                  ),
                  const SizedBox(height: 24),
                ],

                // SECTION NHÂN VIÊN
                if (_canCheckAttendance) ...[
                  const AttendanceCard(),
                  const SizedBox(height: 24),
                ],

                // SECTION ADMIN
                if (_isAdmin) ...[
                  _buildSectionTitle("Admin Management"),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'profile.adminHub.title'.tr(),
                    subtitle: 'profile.adminHub.subtitle'.tr(),
                    onTap: () => context.go('/admin'),
                    isFirst: true,
                    isLast: true,
                    customIconColor: const Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 24),
                ],

                // SECTION HR
                if (_isHR) ...[
                  _buildSectionTitle("HR Management"),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    icon: Icons.business_center_outlined,
                    title: 'profile.hrHub.title'.tr(),
                    subtitle: 'profile.hrHub.subtitle'.tr(),
                    onTap: () => context.go('/hr'),
                    isFirst: true,
                    isLast: true,
                    customIconColor: const Color(0xFF6D28D9),
                  ),
                  const SizedBox(height: 24),
                ],

                // SECTION TÀI KHOẢN
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
                if (_canUpdateFaceProfile)
                  ProfileMenuItem(
                    icon: Icons.face_retouching_natural_rounded,
                    title: 'profile.updateFaceProfile.title'.tr(),
                    subtitle: 'profile.updateFaceProfile.subtitle'.tr(),
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

                // SECTION CÀI ĐẶT
                _buildSectionTitle('profile.settings'.tr()),
                const SizedBox(height: 8),
                _buildThemeItem(context),
                _buildLanguageItem(context), // Widget chuyển ngữ đã fix

                const SizedBox(height: 24),

                // Nút Đăng xuất
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

  // [TỐI ƯU UI] Widget chuyển ngữ mượt mà
  Widget _buildLanguageItem(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (_, langProvider, __) {
        final isEnglish = context.locale.languageCode == 'en';
        final displayLang = isEnglish ? 'English' : 'Tiếng Việt';

        return ProfileMenuItem(
          icon: Icons.language_outlined,
          title: 'profile.language.title'.tr(),
          trailingWidget: _isSwitchingLanguage
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  displayLang,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
          onTap: () async {
            setState(() => _isSwitchingLanguage = true);
            await langProvider.toggleLanguage();

            if (context.mounted) {
              await context.setLocale(langProvider.locale);
              setState(() {
                _isSwitchingLanguage = false;
                _loadUser(); // Load lại thông tin user để đảm bảo
              });
            }
          },
          isLast: true,
        );
      },
    );
  }
}
