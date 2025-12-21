import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Auth & Onboarding ---
import '../screens/auth/login_page.dart';
import '../screens/auth/sign_up_page.dart';
import '../screens/huybro_cart/cart_screen.dart';
import '../screens/huybro_checkout/checkout_screen.dart';
import '../screens/huybro_products/product_detail_screen.dart';
import '../screens/huybro_products/product_list_screen.dart';
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
import '../screens/camera/face_camera_screen.dart';
import '../screens/face_registration/face_registration_page.dart';
import '../screens/face_registration/update_face_profile_page.dart';
import '../screens/admin/admin_dashboard_page.dart';
import '../screens/admin/admin_hub_page.dart';
import '../screens/admin/reports/admin_reports_page.dart';
import '../screens/admin/attendance/admin_attendance_page.dart';
import '../screens/admin/staff/admin_staff_page.dart';
import '../screens/admin/system_logs/admin_system_logs_page.dart';
import '../screens/hr/face_profile_approval_page.dart';
import '../screens/hr/employee_list_page.dart';
import '../screens/hr/attendance_history_page.dart';
import '../screens/hr/schedule_page.dart';
import '../screens/hr/approved_leave_page.dart';
import '../screens/hr/hr_hub_page.dart';
import '../screens/hr/pending_explanations_page.dart';

// --- Patient Features ---
import '../screens/patient/dashboard/patient_dashboard_screen.dart';
import '../screens/patient/appointments/my_appointments_screen.dart';

// --- Booking ---
import '../screens/booking/booking_screen.dart';

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
    // --- 7. Product Routes (THÊM MỚI VÀO ĐÂY) ---
    GoRoute(
      path: '/products',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ProductListScreen(),
      ),
    ),
    GoRoute(
      path: '/products/:id', // Dùng tham số động :id
      pageBuilder: (context, state) {
        // Lấy id từ URL (VD: /products/123 -> id = 123)
        final id = int.parse(state.pathParameters['id']!);
        return _buildPageWithTransition(
          context,
          state,
          ProductDetailScreen(productId: id),
        );
      },
    ),
    GoRoute(
      path: '/cart',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const CartScreen(),
      ),
    ),
    GoRoute(
      path: '/checkout',
      pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CheckoutScreen()
      ),
    ),
    GoRoute(
      path: '/order-success',
      builder: (context, state) => const Scaffold(body: Center(child: Text("Đặt hàng thành công!"))), // Làm đẹp sau
    ),
    GoRoute(
      path: '/my-appointments',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const MyAppointmentsScreen(),
      ),
    ),
    GoRoute(
      path: '/booking',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const BookingScreen(),
      ),
    ),
    GoRoute(
      path: '/face-camera',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const FaceCameraScreen(),
      ),
    ),
    GoRoute(
      path: '/face-registration',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const FaceRegistrationPage(),
      ),
    ),
    GoRoute(
      path: '/update-face-profile',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const UpdateFaceProfilePage(),
      ),
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AdminHubPage(),
      ),
    ),
    GoRoute(
      path: '/admin/leave-requests',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AdminDashboardPage(),
      ),
    ),
    GoRoute(
      path: '/admin/reports',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AdminReportsPage(),
      ),
    ),
    GoRoute(
      path: '/admin/attendance',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AdminAttendancePage(),
      ),
    ),
    GoRoute(
      path: '/admin/staff',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AdminStaffPage(),
      ),
    ),
    GoRoute(
      path: '/admin/system-logs',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AdminSystemLogsPage(),
      ),
    ),
    GoRoute(
      path: '/hr/hub',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const HrHubPage(),
      ),
    ),
    GoRoute(
      path: '/hr',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const HrHubPage(),
      ),
    ),
    GoRoute(
      path: '/hr/face-approvals',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const FaceProfileApprovalPage(),
      ),
    ),
    GoRoute(
      path: '/hr/employees',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const EmployeeListPage(),
      ),
    ),
    GoRoute(
      path: '/hr/attendance-history',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const AttendanceHistoryPage(),
      ),
    ),
    GoRoute(
      path: '/hr/schedules',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const HrSchedulePage(),
      ),
    ),
    GoRoute(
      path: '/hr/approved-leaves',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const ApprovedLeavePage(),
      ),
    ),
    GoRoute(
      path: '/hr/pending-explanations',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        const PendingExplanationsPage(),
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
