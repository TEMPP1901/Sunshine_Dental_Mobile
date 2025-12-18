import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../services/hr_service.dart';
import 'widgets/login_form_email.dart';
import 'widgets/login_form_phone.dart';
import 'qr_scan_page.dart'; // [MỚI] Import trang Scan QR

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Controllers ---
  final _emailCtrl = TextEditingController();
  final _emailPassCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _phonePassCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  // --- State ---
  bool _otpSent = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRememberedEmail();
  }

  // Lấy lại email nếu đã tick "Ghi nhớ đăng nhập"
  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    const rememberedEmailKey = 'remembered_email';
    final savedEmail = prefs.getString(rememberedEmailKey);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailCtrl.text = savedEmail;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _emailPassCtrl.dispose();
    _phoneCtrl.dispose();
    _phonePassCtrl.dispose();
    _otpCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- Timer OTP ---
  void _startTimer() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // --- Logic Xử Lý ---

  // 1. Đăng nhập Email
  Future<void> _handleEmailLogin() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<UserProvider>();
    final success = await provider.login(
      _emailCtrl.text.trim(),
      _emailPassCtrl.text,
    );
    _checkResult(success, provider.errorMessage);
  }

  // 2. Đăng nhập Phone (Pass hoặc OTP)
  Future<void> _handlePhoneLogin(bool isOtpMode) async {
    FocusScope.of(context).unfocus();
    final provider = context.read<UserProvider>();
    bool success;

    if (isOtpMode) {
      success = await provider.loginPhoneOtp(
        _phoneCtrl.text.trim(),
        _otpCtrl.text.trim(),
      );
    } else {
      success = await provider.loginPhonePassword(
        _phoneCtrl.text.trim(),
        _phonePassCtrl.text,
      );
    }
    _checkResult(success, provider.errorMessage);
  }

  // 3. Gửi OTP
  Future<void> _handleSendOtp(String phone) async {
    FocusScope.of(context).unfocus();
    final success = await context.read<UserProvider>().sendOtp(phone);
    if (success) {
      setState(() {
        _otpSent = true;
        _startTimer();
      });
      Fluttertoast.showToast(msg: "OTP Sent successfully!");
    } else {
      Fluttertoast.showToast(
        msg: context.read<UserProvider>().errorMessage ?? "Failed to send OTP",
        backgroundColor: Colors.red,
      );
    }
  }

  // 4. Đăng nhập Google
  Future<void> _handleGoogleLogin() async {
    final provider = context.read<UserProvider>();
    final success = await provider.loginWithGoogle();
    _checkResult(success, provider.errorMessage);
  }

  // Helper kiểm tra kết quả chung
  void _checkResult(bool success, String? error) async {
    if (success) {
      Fluttertoast.showToast(
        msg: tr('login.loginSuccess'),
        backgroundColor: Colors.green,
      );
      
      if (mounted) {
        // Kiểm tra xem có cần đăng ký face profile không
        await _checkAndRedirectToFaceRegistration();
      }
    } else {
      Fluttertoast.showToast(
        msg: error ?? tr('login.loginFailed'),
        backgroundColor: Colors.red,
      );
    }
  }

  // Kiểm tra và redirect đến màn hình đăng ký face profile nếu cần
  Future<void> _checkAndRedirectToFaceRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr == null) {
        context.go('/home');
        return;
      }

      final userData = jsonDecode(userStr) as Map<String, dynamic>;
      final roles = (userData['roles'] as List<dynamic>?)
          ?.map((r) => r.toString().toUpperCase())
          .toList() ?? [];

      // Chỉ check cho nhân viên cần chấm công (không bao gồm ADMIN)
      final attendanceRoles = {'HR', 'DOCTOR', 'RECEPTION', 'ACCOUNTANT'};
      final isStaff = roles.any((r) => attendanceRoles.contains(r));
      
      if (!isStaff) {
        // Không phải nhân viên, vào app bình thường
        context.go('/home');
        return;
      }

      // Kiểm tra face profile
      final hrService = HrService();
      final checkResult = await hrService.checkFaceProfile();
      final hasFaceProfile = checkResult['hasFaceProfile'] as bool? ?? false;
      final requiresRegistration = checkResult['requiresRegistration'] as bool? ?? false;

      if (requiresRegistration || !hasFaceProfile) {
        // Chưa có face profile, redirect đến màn hình đăng ký
        if (mounted) {
          context.go('/face-registration');
        }
      } else {
        // Đã có face profile, vào app bình thường
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      debugPrint('Error checking face profile: $e');
      // Nếu có lỗi, vẫn cho vào app (không block user)
      if (mounted) {
        context.go('/home');
      }
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,

      // [MỚI] AppBar chứa nút QR Code Scanner
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Dùng iconBack nếu cần, hoặc để tự động (nếu push từ trang khác)
        // automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              // Chuyển hướng sang trang Scan QR
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const QrScanPage()),
              );
            },
            icon: const Icon(
              Icons.qr_code_scanner,
              color: Color(0xFF3366FF),
              size: 28,
            ),
            tooltip: "Scan Login QR",
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Đã có AppBar nên giảm khoảng cách top xuống một chút
              const SizedBox(height: 10),

              // 1. Header Logo & Title
              const Icon(
                Icons.lock_person_outlined,
                size: 60,
                color: Color(0xFF3366FF),
              ),
              const SizedBox(height: 16),
              Text(
                tr('login.welcomeBack'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('login.subtitle'),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // 2. Tab Bar (Email / Phone)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      const BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  labelColor: const Color(0xFF3366FF),
                  unselectedLabelColor: Colors.grey,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined, size: 18),
                          SizedBox(width: 8),
                          Text("Email"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_android, size: 18),
                          SizedBox(width: 8),
                          Text("Phone"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Form Content (Email & Phone Forms)
              SizedBox(
                // Chiều cao cố định để tránh layout shift khi chuyển tab
                height: 420,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Email Form
                    LoginFormEmail(
                      emailController: _emailCtrl,
                      passwordController: _emailPassCtrl,
                      isLoading: isLoading,
                      onLogin: _handleEmailLogin,
                      onForgotPassword: () {
                        // TODO: Show Forgot Password Dialog
                        Fluttertoast.showToast(msg: "Feature coming soon");
                      },
                    ),
                    // Tab 2: Phone Form
                    LoginFormPhone(
                      phoneController: _phoneCtrl,
                      passwordController: _phonePassCtrl,
                      otpController: _otpCtrl,
                      isLoading: isLoading,
                      otpSent: _otpSent,
                      countdown: _countdown,
                      onLogin: _handlePhoneLogin,
                      onSendOtp: _handleSendOtp,
                      onResetOtp: () => setState(() {
                        _otpSent = false;
                        _otpCtrl.clear();
                      }),
                    ),
                  ],
                ),
              ),

              // 4. Divider "Or continue with"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      tr('login.orLoginWith'),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Google Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    backgroundColor: Colors.white,
                  ),
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  label: const Text(
                    "Google",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Footer (Sign Up Link)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('login.noAccount'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(
                      tr('login.signUp'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
