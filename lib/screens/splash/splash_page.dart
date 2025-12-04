import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _splashDuration = Duration(seconds: 2);
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Chờ frame đầu tiên để đảm bảo context đã sẵn sàng trước khi điều hướng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  // Kiểm tra trạng thái đăng nhập và chuyển trang phù hợp
  Future<void> _checkAndNavigate() async {
    if (_hasNavigated || !mounted) return;

    await Future.delayed(_splashDuration);

    if (!mounted || _hasNavigated) return;

    try {
      // Kiểm tra thông tin đăng nhập của người dùng trong local storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final user = prefs.getString('user');

      if (mounted && !_hasNavigated) {
        final isLoggedIn = token != null &&
            token.isNotEmpty &&
            token.trim().isNotEmpty &&
            user != null &&
            user.isNotEmpty;

        if (isLoggedIn) {
          // Nếu đã đăng nhập -> chuyển sang trang Home
          _hasNavigated = true;
          context.go('/home');
        } else {
          // Nếu chưa đăng nhập -> chuyển thẳng sang Login
          _hasNavigated = true;
          context.go('/login');
        }
      }
    } catch (e) {
      // Nếu lỗi -> fallback sang Login/onboarding
      if (mounted && !_hasNavigated) {
        try {
          _hasNavigated = true;
          context.go('/login');
        } catch (e2) {
          if (mounted) {
            try {
              context.go('/onboarding');
            } catch (e3) {}
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                  colors: [
                    Color(0xFFF7FBFF),
                    Color(0xFFE6F1FF),
                  ],
                ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Nếu lỗi load logo -> hiển thị icon mặc định
              return const Icon(
                Icons.local_hospital,
                size: 120,
                color: Color(0xFF3366FF),
              );
            },
          ),
        ),
      ),
    );
  }
}
