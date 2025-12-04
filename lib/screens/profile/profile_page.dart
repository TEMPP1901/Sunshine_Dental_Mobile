import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

// Trang Profile người dùng
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _attendanceRoles = {
    'HR',
    'DOCTOR',
    'RECEPTION',
    'ACCOUNTANT',
  };

  static const _attendanceForbiddenRoles = {
    'ADMIN',
    'USER',
  };

  static const _leaveRequestRoles = {
    'HR',
    'DOCTOR',
    'RECEPTION',
    'ACCOUNTANT',
    'ADMIN',
  };

  static const _leaveRequestForbiddenRoles = {
    'USER',
  };

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String _clockText = '';
  Timer? _clockTimer;
  String? _cachedTodayLabel;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startClock();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // Lấy thông tin người dùng từ SharedPreferences
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');

    if (!mounted) return;

    if (raw == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        // Lưu label ngày hôm nay để hiện ra phù hợp với ngôn ngữ đang chọn
        _cachedTodayLabel = DateFormat.yMMMMEEEEd(context.locale.toString())
            .format(DateTime.now());
        
        if (mounted) {
          setState(() {
            _user = decoded;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'profile.toast.loadFailed'.tr());
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Khởi tạo đồng hồ thời gian thực
  void _startClock() {
    _clockText = DateFormat('HH:mm:ss').format(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final newText = DateFormat('HH:mm:ss').format(now);
      if (_clockText != newText) {
        setState(() {
          _clockText = newText;
        });
      }
    });
  }

  // Xử lý đăng xuất tài khoản và xóa toàn bộ local storage
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
            child: Text('profile.actions.logout'.tr()),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Fluttertoast.showToast(msg: 'profile.toast.logoutSuccess'.tr());
      context.go('/login');
    }
  }

  // Chuẩn hóa tên role sang viết hoa, bỏ "ROLE_"
  String _normalizeRole(dynamic role) {
    final roleStr = role?.toString().toUpperCase() ?? '';
    if (roleStr.startsWith('ROLE_')) {
      return roleStr.substring(5);
    }
    return roleStr;
  }

  // Tách và chuẩn hóa danh sách các role ra thành List<String>
  List<String> _extractNormalizedRoles(dynamic roles) {
    if (roles == null) return [];

    if (roles is List) {
      return roles
          .map((role) {
            if (role is Map) {
              final roleName = (role['name'] ?? role['role'] ?? role['roleName'] ?? role).toString();
              return _normalizeRole(roleName);
            }
            return _normalizeRole(role);
          })
          .where((role) => role.isNotEmpty)
          .toList();
    }

    if (roles is String) {
      return roles
          .split(',')
          .map((role) => _normalizeRole(role.replaceAll(RegExp(r'[\[\]\s]'), '')))
          .where((role) => role.isNotEmpty)
          .toList();
    }

    if (roles is Map) {
      return roles.values
          .map((role) => _normalizeRole(role))
          .where((role) => role.isNotEmpty)
          .toList();
    }

    return [];
  }

  // Kiểm tra quyền chấm công theo role
  bool get _canCheckAttendance {
    try {
      final roles = _extractNormalizedRoles(_user?['roles']);
      if (roles.isEmpty) return false;

      final hasForbiddenRole = roles.any(_attendanceForbiddenRoles.contains);
      if (hasForbiddenRole) return false;

      return roles.any(_attendanceRoles.contains);
    } catch (_) {
      return false;
    }
  }

  // Kiểm tra quyền xem và gửi đơn nghỉ phép theo role
  bool get _canViewLeaveRequest {
    try {
      final roles = _extractNormalizedRoles(_user?['roles']);
      if (roles.isEmpty) return false;

      final hasForbiddenRole = roles.any(_leaveRequestForbiddenRoles.contains);
      if (hasForbiddenRole) return false;

      return roles.any(_leaveRequestRoles.contains);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return PopScope(
      canPop: context.canPop(),
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          backgroundColor: colorScheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text('profile.title'.tr()),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context),
        ),
      ),
    );
  }

  // Xây dựng giao diện content chính của profile
  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_user == null) {
      // Giao diện khi chưa đăng nhập
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 72,
                color: colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 32),
              Text(
                'profile.signInPrompt'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('profile.actions.signIn'.tr()),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fullName = _user?['fullName']?.toString() ?? 'profile.guest'.tr();
    final email = _user?['email']?.toString() ?? '—';
    
    String? phone;
    try {
      final phoneValue = _user?['phone'];
      if (phoneValue is String) {
        phone = phoneValue;
      } else if (phoneValue != null) {
        phone = phoneValue.toString();
      }
    } catch (e) {
      phone = null;
    }
    
    // Lấy username để hiển thị menu tài khoản
    String? username;
    try {
      final usernameValue = _user?['username'];
      if (usernameValue is String) {
        username = usernameValue;
      } else if (usernameValue != null) {
        username = usernameValue.toString();
      }
    } catch (e) {
      username = null;
    }
    
    final roles = _user?['roles'];
    final avatarUrl = _user?['avatarUrl']?.toString();
    final todayLabel = _cachedTodayLabel ?? 
        DateFormat.yMMMMEEEEd(context.locale.toString())
            .format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Header Profile
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12, bottom: 24, left: 24, right: 24),
            child: Column(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: ApiService.resolveAvatarImage(avatarUrl),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onBackground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                // Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Display role badges
                if (roles != null) _buildRolesBadges(roles),
              ],
            ),
          ),
          // Main Menu content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card chấm công (Attendance)
                if (_canCheckAttendance) ...[
                  RepaintBoundary(
                    child: _buildAttendanceCard(context, todayLabel),
                  ),
                  const SizedBox(height: 24),
                ],
                // Account Settings section
                _buildSectionHeader(context, 'profile.accountSettings'.tr()),
                const SizedBox(height: 8),
                _buildMenuListItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'account.myAccount.title'.tr(),
                  subtitle: 'account.myAccount.subtitle'.tr(),
                  onTap: () => context.go('/my-account'),
                  isFirst: true,
                  customIcon: Stack(
                    children: [
                      Icon(Icons.person_outline, color: colorScheme.primary, size: 24),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            color: colorScheme.primary,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canViewLeaveRequest)
                  _buildMenuListItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'leaveRequest.title'.tr(),
                    subtitle: 'leaveRequest.subtitle'.tr(),
                    onTap: () => context.go('/leave-request'),
                  ),
                _buildMenuListItem(
                  context,
                  icon: Icons.key_outlined,
                  title: 'profile.changePassword.title'.tr(),
                  subtitle: 'profile.changePassword.subtitle'.tr(),
                  onTap: () => context.go('/change-password'),
                  isLast: true,
                ),
                const SizedBox(height: 24),
                // General Settings section
                _buildSectionHeader(context, 'profile.settings'.tr()),
                const SizedBox(height: 8),
                RepaintBoundary(
                  child: _buildThemeListItem(context),
                ),
                RepaintBoundary(
                  child: _buildLanguageListItem(context),
                ),
                const SizedBox(height: 24),
                // Logout button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text('profile.actions.logout'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withOpacity(0.5), width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 56),
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

  // Hiển thị section header cho từng nhóm menu
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  // Hiển thị từng dòng menu trong section
  Widget _buildMenuListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle, 
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
    Widget? trailingWidget,
    Widget? customIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: customIcon ?? Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailingWidget ?? Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hiển thị option chuyển chủ đề sáng/tối
  Widget _buildThemeListItem(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final colorScheme = Theme.of(context).colorScheme;
        
        return _buildMenuListItem(
          context,
          icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          title: 'profile.theme.title'.tr(),
          subtitle: isDark ? 'profile.theme.dark'.tr() : 'profile.theme.light'.tr(),
          onTap: () => themeProvider.toggleTheme(),
          isFirst: true,
          trailingWidget: Switch(
            value: isDark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: colorScheme.primary,
          ),
        );
      },
    );
  }

  // Hiển thị option chuyển đổi ngôn ngữ
  Widget _buildLanguageListItem(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final currentLang = languageProvider.currentLanguageName;
        final colorScheme = Theme.of(context).colorScheme;
        
        return _buildMenuListItem(
          context,
          icon: Icons.language_outlined,
          title: 'profile.language.title'.tr(),
          onTap: () async {
            await languageProvider.toggleLanguage();
            if (context.mounted) {
              context.setLocale(languageProvider.locale);
              _loadUser(); 
            }
          },
          isLast: true,
          trailingWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLang,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        );
      },
    );
  }

  // Hiện thẻ chấm công (attendance) real-time
  Widget _buildAttendanceCard(BuildContext context, String todayLabel) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.9),
              colorScheme.secondary.withOpacity(0.8), 
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (icon + title)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.watch_later_outlined,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.attendanceCard.title'.tr(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todayLabel,
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hiện đồng hồ thời gian thực
            RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.onPrimary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.attendanceCard.currentTime'.tr(),
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _clockText,
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.face_retouching_natural_rounded,
                      color: colorScheme.onPrimary.withOpacity(0.8),
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Button chuyển đến trang chấm công
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.onPrimary,
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.go('/attendance'),
                label: Text(
                  'profile.actions.openAttendance'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị danh sách các badge role của user
  Widget _buildRolesBadges(dynamic roles) {
    List<String> roleList = [];
    final colorScheme = Theme.of(context).colorScheme;
    
    try {
      if (roles is List) {
        roleList = roles
            .map((r) {
              if (r is Map) {
                return (r['name'] ?? r['role'] ?? r.toString()).toString();
              }
              return r.toString();
            })
            .where((r) => r.isNotEmpty)
            .toList();
      } else if (roles is String) {
        roleList = roles
            .split(',')
            .map((r) => r.replaceAll(RegExp(r'[\[\]\s]'), ''))
            .where((r) => r.isNotEmpty)
            .toList();
      } else if (roles is Map) {
        roleList = roles.values
            .map((r) => r.toString())
            .where((r) => r.isNotEmpty)
            .toList();
      }
    } catch (e) {
      return const SizedBox.shrink();
    }

    if (roleList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: roleList.map((role) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'common.roles.${_normalizeRole(role)}'.tr(),
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}