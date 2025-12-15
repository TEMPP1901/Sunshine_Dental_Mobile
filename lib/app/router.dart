import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Auth & Onboarding ---
import '../screens/auth/login_page.dart';
import '../screens/auth/sign_up_page.dart';
import '../screens/splash/splash_page.dart';
import '../screens/onboarding/onboarding_page.dart';

// --- Main App ---
import '../screens/home/home_page.dart';
import '../screens/service/service_page.dart';
import '../screens/notification/notification_screen.dart';

// --- Account ---
import '../screens/account/my_account_page.dart';
import '../screens/account/change_password_page.dart';

// --- [FIXED] Profile chính (Đã chuyển vào thư mục patient) ---
import '../screens/patient/profile/profile_page.dart';
import '../screens/patient/profile/patient_profile_page.dart';
import '../screens/patient/records/medical_records_screen.dart';

// --- Staff Features ---
import '../screens/attendance/attendance_page.dart';
import '../screens/leave_request/leave_request_list_page.dart';
import '../screens/leave_request/create_leave_request_page.dart';
import '../screens/home/sections/my_schedule_page.dart';

// --- Patient Features ---
import '../screens/patient/dashboard/patient_dashboard_screen.dart';
import '../screens/patient/appointments/my_appointments_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 1. Splash & Onboarding
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const SplashPage()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const OnboardingPage()),
    ),

    // 2. Auth
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const LoginPage()),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const SignUpPage()),
    ),

    // 3. Main Navigation
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const HomePage()),
    ),
    GoRoute(
      path: '/service',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const ServicePage()),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const NotificationScreen()),
    ),

    // 4. Account & Profile
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const ProfilePage()),
    ),
    GoRoute(
      path: '/patient-profile', // Trùng với link bạn gọi ở Dashboard
      builder: (context, state) => const PatientProfilePage(),
    ),
    GoRoute(
      path: '/medical-records',
      builder: (context, state) => const MedicalRecordsScreen(),
    ),
    GoRoute(
      path: '/my-account',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const MyAccountPage()),
    ),
    GoRoute(
      path: '/change-password',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const ChangePasswordPage()),
    ),

    // 5. Staff Features
    GoRoute(
      path: '/attendance',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const AttendancePage()),
    ),
    GoRoute(
      path: '/leave-request',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const LeaveRequestListPage(),
      ),
    ),
    GoRoute(
      path: '/leave-request/create',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const CreateLeaveRequestPage(),
      ),
    ),
    GoRoute(
      path: '/schedule',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(context, state, const MySchedulePage()),
    ),

    // 6. Patient Routes
    GoRoute(
      path: '/patient-dashboard',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const PatientDashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/my-appointments',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const MyAppointmentsScreen(),
      ),
    ),
  ],
);

Page _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return MaterialPage<void>(
    key: state.pageKey,
    child: child,
    fullscreenDialog: false,
    maintainState: true,
  );
}
