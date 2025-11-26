import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/sign_up_page.dart';
import '../screens/home/home_page.dart';
import '../screens/service/service_page.dart';
import '../screens/account/my_account_page.dart';
import '../screens/account/change_password_page.dart';
import '../screens/splash/splash_page.dart';
import '../screens/onboarding/onboarding_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/attendance/attendance_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const SplashPage(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const HomePage(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const LoginPage(),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const SignUpPage(),
      ),
    ),
    GoRoute(
      path: '/service',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ServicePage(),
      ),
    ),
    GoRoute(
      path: '/my-account',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const MyAccountPage(),
      ),
    ),
    GoRoute(
      path: '/change-password',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ChangePasswordPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/attendance',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AttendancePage(),
      ),
    ),
  ],
);

/// Builds a page with swipe back gesture support
/// Uses MaterialPage with proper configuration for swipe back gesture
Page _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  // Use MaterialPage which supports native swipe back gesture
  // fullscreenDialog: false allows swipe back gesture
  return MaterialPage<void>(
    key: state.pageKey,
    child: child,
    fullscreenDialog: false,
    maintainState: true,
  );
}

