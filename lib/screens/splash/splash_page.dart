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
    // Wait for the first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  Future<void> _checkAndNavigate() async {
    if (_hasNavigated || !mounted) return;
    
    // Wait for splash duration
    await Future.delayed(_splashDuration);
    
    if (!mounted || _hasNavigated) return;
    
    try {
      // Check if user is already logged in
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final user = prefs.getString('user');
      
      debugPrint('Splash: Token exists: ${token != null && token.isNotEmpty}');
      debugPrint('Splash: User exists: ${user != null && user.isNotEmpty}');
      
      if (mounted && !_hasNavigated) {
        // Validate token exists and is not empty
        final isLoggedIn = token != null && 
                          token.isNotEmpty && 
                          token.trim().isNotEmpty &&
                          user != null && 
                          user.isNotEmpty;
        
        debugPrint('Splash: Is logged in: $isLoggedIn');
        
        if (isLoggedIn) {
          // User is logged in, go to home
          debugPrint('Splash: Navigating to /home');
          _hasNavigated = true;
          context.go('/home');
        } else {
          // User not logged in, go to login directly
          debugPrint('Splash: Navigating to /login');
          _hasNavigated = true;
          context.go('/login');
        }
      }
    } catch (e) {
      debugPrint('Navigation error in splash: $e');
      // Fallback to login if anything fails
      if (mounted && !_hasNavigated) {
        try {
          _hasNavigated = true;
          context.go('/login');
        } catch (e2) {
          debugPrint('Fallback navigation also failed: $e2');
          // Last resort: try onboarding
          if (mounted) {
            try {
              context.go('/onboarding');
            } catch (e3) {
              debugPrint('All navigation attempts failed: $e3');
            }
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
              debugPrint('Error loading logo: $error');
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


