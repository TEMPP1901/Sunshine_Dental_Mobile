import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF0A0A0A), const Color(0xFF1A1A2E)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE8F4F8), Color(0xFFD4E8F0)],
                ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.local_hospital, size: 36),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 320,
                      height: 360,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Hình người trên cùng - căn giữa
                          Positioned(
                            top: 5,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 135,
                                height: 135,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(
                                      'assets/images/patient1.png',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      spreadRadius: -3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Hình người dưới bên phải
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              width: 125,
                              height: 125,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(
                                    'assets/images/patient2.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    spreadRadius: -3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Hình người dưới bên trái
                          Positioned(
                            bottom: 5,
                            left: 5,
                            child: Container(
                              width: 125,
                              height: 125,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage('assets/images/doctor.png'),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    spreadRadius: -3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Hình cây răng ở giữa
                          Center(
                            child: Transform.translate(
                              offset: const Offset(0, 15),
                              child: Image.asset(
                                'assets/images/hero-tooth.png',
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Nếu hero-tooth không có, fallback về tooth-logo
                                  return Image.asset(
                                    'assets/images/tooth-logo.png',
                                    width: 220,
                                    height: 220,
                                    fit: BoxFit.contain,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Perfect Health Center',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Find the best care for you and your loved ones.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    // Khi nhấn, chuyển tới màn hình đăng ký
                    onPressed: () {
                      context.go('/register');
                    },
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      // Khi nhấn, chuyển tới trang đăng nhập
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Color(0xFF0D6EFD),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
