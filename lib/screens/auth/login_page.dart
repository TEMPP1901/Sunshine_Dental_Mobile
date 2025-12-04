import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = false;

  static const _rememberedEmailKey = 'rememberedEmail';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  // Lấy lại email đã lưu nếu user chọn Remember me
  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_rememberedEmailKey);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  // Xử lý đăng nhập
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().post(
        '/api/auth/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      final data = response.data;
      final prefs = await SharedPreferences.getInstance();

      // Chuẩn hóa role
      final roles = (data['roles'] as List<dynamic>? ?? [])
          .map((r) => r.toString().replaceAll(RegExp(r'^ROLE_', caseSensitive: false), '').toUpperCase())
          .toList();

      // Chuẩn bị thông tin user
      final userData = {
        'userId': data['userId'],
        'fullName': data['fullName'],
        'email': data['email'],
        'avatarUrl': data['avatarUrl'],
        'roles': roles,
      };

      await prefs.setString('accessToken', data['accessToken']);
      await prefs.setString('roles', roles.toString());
      await prefs.setString('user', jsonEncode(userData));

      // Cập nhật UserProvider
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.setUser(userData);
      }

      if (_rememberMe) {
        await prefs.setString(_rememberedEmailKey, _emailController.text.trim());
      } else {
        await prefs.remove(_rememberedEmailKey);
      }

      // Đăng ký thiết bị cho notification
      try {
        await NotificationService().registerDevice();
        // Cập nhật số lượng thông báo chưa đọc sau khi đăng nhập
        await NotificationService().fetchUnreadCount();
      } catch (e) {
        debugPrint('Failed to register device after login: $e');
      }

      final successMsg = tr('login.loginSuccess');
      if (mounted && successMsg.isNotEmpty) {
        Fluttertoast.showToast(
          msg: successMsg,
          toastLength: Toast.LENGTH_SHORT,
        );
      }

      // Chuyển sang màn hình home ngay lập tức sau khi đăng nhập
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      String errorMsg = tr('login.loginFailed');
      
      if (e is DioException) {
        // Kiểm tra lỗi kết nối và lỗi server
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          errorMsg = tr('login.connectionTimeout');
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = tr('login.connectionError');
        } else if (e.response != null) {
          final message = e.response?.data?['message'];
          if (message != null && message.toString().isNotEmpty) {
            errorMsg = message is List ? message.join(', ') : message.toString();
          } else if (e.response?.statusCode != null) {
            errorMsg = tr('login.serverError').replaceAll('{code}', e.response!.statusCode.toString());
          }
        } else {
          errorMsg = e.message ?? tr('login.loginFailed');
        }
      } else {
        errorMsg = e.toString();
      }
      
      if (errorMsg.isEmpty) {
        errorMsg = tr('login.loginFailed');
      }
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: errorMsg,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Tạo style cho input
  InputDecoration _inputDecoration(String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF0D6EFD)),
      filled: true,
      fillColor: isDark
          ? theme.inputDecorationTheme.fillColor
          : const Color(0xFFF5F7FB),
      labelStyle: TextStyle(
        color: isDark
            ? theme.colorScheme.onSurface.withAlpha(180)
            : null,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: isDark
              ? Colors.grey.shade700
              : Colors.transparent,
          width: isDark ? 1 : 0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: isDark
              ? Colors.grey.shade700
              : Colors.transparent,
          width: isDark ? 1 : 0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/onboarding');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A0A),
                      const Color(0xFF1A1A2E),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF05152E), Color(0xFF030A1A)],
                  ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: SizedBox(
                        height: constraints.maxHeight - 32,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/onboarding');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? theme.cardColor : const Color(0xFFE8F4F8),
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withAlpha(128)
                                          : Colors.black.withAlpha(38),
                                      blurRadius: 30,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(40),
                                        topRight: Radius.circular(40),
                                      ),
                                      child: SizedBox(
                                        height: 220,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.asset(
                                              'assets/images/doctor.png',
                                              fit: BoxFit.cover,
                                              alignment: Alignment.topCenter,
                                            ),
                                            Positioned.fill(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      const Color(0xFF05152E).withAlpha(140),
                                                      const Color(0xFF05152E).withAlpha(25),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                                        child: Form(
                                          key: _formKey,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  "Welcome Back",
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w700,
                                                    color: theme.colorScheme.onSurface,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Please login to your account",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: theme.colorScheme.onSurface.withAlpha(153),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 20),
                                                TextFormField(
                                                  controller: _emailController,
                                                  keyboardType: TextInputType.emailAddress,
                                                  decoration: _inputDecoration(
                                                    "Email Address",
                                                    Icons.mail_outline_rounded,
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return "Please fill in all fields";
                                                    }
                                                    if (!value.contains('@')) {
                                                      return "Invalid email address";
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                TextFormField(
                                                  controller: _passwordController,
                                                  obscureText: !_showPassword,
                                                  decoration: _inputDecoration(
                                                    "Password",
                                                    Icons.lock_outline_rounded,
                                                  ).copyWith(
                                                    suffixIcon: IconButton(
                                                      icon: Icon(
                                                        _showPassword
                                                            ? Icons.visibility_off
                                                            : Icons.visibility,
                                                      ),
                                                      onPressed: () => setState(
                                                        () => _showPassword = !_showPassword,
                                                      ),
                                                    ),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return "Please fill in all fields";
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Checkbox(
                                                      value: _rememberMe,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _rememberMe = value ?? false;
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                      "Remember me",
                                                      style: TextStyle(
                                                        color: theme.colorScheme.onSurface.withAlpha(204),
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    TextButton(
                                                      onPressed: () =>
                                                          context.go('/change-password'),
                                                      child: Text(
                                                        "Forgot password?",
                                                        style: const TextStyle(
                                                          color: Color(0xFF0D6EFD),
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                SizedBox(
                                                  height: 56,
                                                  child: ElevatedButton(
                                                    onPressed:
                                                        _isLoading ? null : _handleLogin,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(0xFF0D6EFD),
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(28),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: _isLoading
                                                        ? const SizedBox(
                                                            height: 24,
                                                            width: 24,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 3,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                      Color>(Colors.white),
                                                            ),
                                                          )
                                                        : const Text(
                                                            "Login now",
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Divider(
                                                        color: isDark
                                                            ? Colors.grey.shade700
                                                            : Colors.grey.shade300,
                                                        thickness: 1,
                                                      ),
                                                    ),
                                                    const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                                      child: Text(
                                                        "or login with",
                                                        style: TextStyle(
                                                          color: Color(0x99000000),
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Divider(
                                                        color: isDark
                                                            ? Colors.grey.shade700
                                                            : Colors.grey.shade300,
                                                        thickness: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  height: 56,
                                                  child: OutlinedButton.icon(
                                                    onPressed: () {
                                                      // TODO: Google OAuth
                                                    },
                                                    style: OutlinedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(28),
                                                      ),
                                                      side: BorderSide(
                                                        color: isDark
                                                            ? Colors.grey.shade700
                                                            : Colors.grey.shade300,
                                                        width: 1.5,
                                                      ),
                                                      backgroundColor: Colors.white,
                                                    ),
                                                    icon: Image.asset(
                                                      'assets/images/google_logo.png',
                                                      height: 24,
                                                      width: 24,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return const Icon(
                                                          Icons.g_mobiledata,
                                                          color: Color(0xFFDB4437),
                                                          size: 28,
                                                        );
                                                      },
                                                    ),
                                                    label: Text(
                                                      "Google",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Don't have an account? ",
                                                      style: TextStyle(
                                                        color: theme.colorScheme.onSurface.withAlpha(179),
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => context.go('/register'),
                                                      child: const Text(
                                                        "Sign Up",
                                                        style: TextStyle(
                                                          color: Color(0xFF0D6EFD),
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

