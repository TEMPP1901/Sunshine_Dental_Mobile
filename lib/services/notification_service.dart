import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../app/router.dart';

// Hàm xử lý thông báo nền của FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Handling a background message: ${message.messageId}');
  debugPrint('[FCM] Background message title: ${message.notification?.title}');
  debugPrint('[FCM] Background message body: ${message.notification?.body}');
  debugPrint('[FCM] Background message data: ${message.data}');
}

// Service quản lý notification firebase, notification local
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  bool _isInitialized = false;

  // Luồng notification để UI nhận dữ liệu realtime
  final _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationReceived =>
      _notificationStreamController.stream;

  // ValueNotifier lưu trữ số lượng notification chưa đọc
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  // Khởi tạo notification service (bao gồm FCM, permission, các listener)
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _requestPermissions();
    await _initLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Message received in foreground');
      debugPrint('[FCM] Message ID: ${message.messageId}');
      debugPrint('[FCM] Message data: ${message.data}');
      debugPrint('[FCM] Notification title: ${message.notification?.title}');
      debugPrint('[FCM] Notification body: ${message.notification?.body}');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
      // Emit sự kiện, cập nhật UI
      _notificationStreamController.add(message.data);
      // Gọi lại để reload số chưa đọc
      fetchUnreadCount();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] App opened from notification');
      debugPrint('[FCM] Message ID: ${message.messageId}');
      debugPrint('[FCM] Message data: ${message.data}');
      debugPrint(
        '[FCM] RelatedEntityType: ${message.data['relatedEntityType']}',
      );
      debugPrint('[FCM] RelatedEntityId: ${message.data['relatedEntityId']}');
      // Cập nhật số lượng thông báo chưa đọc khi mở app từ notification
      fetchUnreadCount();
      _handleNotificationNavigation(message.data);
    });

    // Kiểm tra nếu app được mở từ notification khi app đang terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from terminated state via notification');
      debugPrint('[FCM] Initial message ID: ${initialMessage.messageId}');
      debugPrint('[FCM] Initial message data: ${initialMessage.data}');
      // Cập nhật số lượng thông báo chưa đọc
      fetchUnreadCount();
      // Điều hướng sau khi app đã khởi tạo xong
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(initialMessage.data);
      });
    }

    // Kiểm tra đã login -> đăng ký thiết bị + lấy số lượng notification chưa đọc
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken != null && accessToken.isNotEmpty) {
      debugPrint(
        '[NotificationService] User already logged in, registering device...',
      );
      await _registerDevice();
      fetchUnreadCount();
    }

    _isInitialized = true;
  }

  // Lấy số lượng thông báo chưa đọc từ server (dành cho badge, list v.v)
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiService.get('/api/notifications/unread-count');
      if (response.statusCode == 200) {
        final count = response.data;
        if (count is int) {
          unreadCount.value = count;
        } else {
          unreadCount.value = int.tryParse(count.toString()) ?? 0;
        }
        debugPrint(
          '[NotificationService] Unread count updated: ${unreadCount.value}',
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Failed to fetch unread count: $e');
    }
  }

  void dispose() {
    // Hủy ValueNotifier khi không còn dùng
    unreadCount.dispose();
    debugPrint('Disposed NotificationService');
  }

  // Xin quyền nhận notification từ user
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  // Khởi tạo local notification channel, thiết lập xử lý click notification local
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
            debugPrint('Notification clicked: ${notificationResponse.payload}');
            if (notificationResponse.payload != null) {
              _handleNotificationNavigation({
                'actionUrl': notificationResponse.payload,
              });
            }
          },
    );
  }

  // Hiển thị local notification khi nhận FCM
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      debugPrint(
        '[LocalNotification] Showing notification: ${notification.title}',
      );
      debugPrint('[LocalNotification] Body: ${notification.body}');
      if (android != null) {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
                  'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload:
              message.data['actionUrl'] ?? message.data['relatedEntityType'],
        );
        debugPrint('[LocalNotification] Android notification shown');
      } else {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
                  'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload:
              message.data['actionUrl'] ?? message.data['relatedEntityType'],
        );
        debugPrint('[LocalNotification] iOS notification shown');
      }
    }
  }

  // Đăng ký thiết bị nhận FCM (gửi token lên backend)
  Future<void> registerDevice() async {
    await _registerDevice();
  }

  // Đăng ký thiết bị với FCM token lên backend
  Future<void> _registerDevice({String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('User not logged in, skipping device registration');
        return;
      }

      String? fcmToken = token ?? await _firebaseMessaging.getToken();

      debugPrint('FCM Token: $fcmToken');
      await prefs.setString('fcmToken', fcmToken!);

      String deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';
      if (kIsWeb) deviceType = 'WEB';

      await _apiService.post(
        '/api/notifications/device',
        queryParameters: {'token': fcmToken, 'deviceType': deviceType},
      );
      debugPrint('Device registered successfully');
    } catch (e) {
      debugPrint('Failed to register device: $e');
    }
  }

  // Lấy user roles từ API
  Future<List<String>> _getUserRoles() async {
    try {
      final response = await _apiService.get('/api/users/me');
      if (response.statusCode == 200) {
        final userData = response.data as Map<String, dynamic>;
        final roles = (userData['roles'] as List<dynamic>? ?? [])
            .map((r) => r.toString().toUpperCase())
            .toList();
        return roles;
      }
    } catch (e) {
      debugPrint('[NotificationService] Failed to get user roles: $e');
    }
    return [];
  }

  // Kiểm tra xem user có role ADMIN không (xử lý cả ROLE_ADMIN và ADMIN)
  bool _hasAdminRole(List<String> roles) {
    return roles.any((role) => 
      role == 'ADMIN' || 
      role == 'ROLE_ADMIN' || 
      role.contains('ADMIN')
    );
  }

  // Kiểm tra xem user có role HR không (xử lý cả ROLE_HR và HR)
  bool _hasHrRole(List<String> roles) {
    return roles.any((role) => 
      role == 'HR' || 
      role == 'ROLE_HR' || 
      role.contains('HR')
    );
  }

  // Điều hướng đến trang duyệt đơn nghỉ dựa trên role
  // HR và Admin luôn được điều hướng đến trang duyệt của họ
  Future<void> _navigateToLeaveRequestPage() async {
    try {
      final roles = await _getUserRoles();
      debugPrint('[NotificationService] User roles: $roles');
      
      if (_hasAdminRole(roles)) {
        debugPrint('[NotificationService] Navigating ADMIN to /admin/leave-requests');
        appRouter.go('/admin/leave-requests');
      } else if (_hasHrRole(roles)) {
        debugPrint('[NotificationService] Navigating HR to /hr/approved-leaves');
        appRouter.go('/hr/approved-leaves');
      } else {
        debugPrint('[NotificationService] Navigating user to /leave-request');
        appRouter.go('/leave-request');
      }
    } catch (e) {
      debugPrint('[NotificationService] Error navigating to leave request page: $e');
      // Fallback: điều hướng đến trang chung
      appRouter.go('/leave-request');
    }
  }

  // Điều hướng khi user nhấn vào notification (bao gồm cả logic cho loại liên quan)
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final relatedEntityType = data['relatedEntityType']?.toString();
        final actionUrl = data['actionUrl']?.toString();

        if (relatedEntityType != null) {
          switch (relatedEntityType.toUpperCase()) {
            case 'LEAVE_REQUEST':
              // HR và Admin sẽ được điều hướng đến trang duyệt của họ
              // User thường sẽ được điều hướng đến trang xem đơn nghỉ của mình
              await _navigateToLeaveRequestPage();
              return;
            case 'ATTENDANCE':
              // Trường hợp ATTENDANCE_CHECKIN, ATTENDANCE_CHECKOUT, ATTENDANCE_ABSENT, EXPLANATION_SUBMITTED, EXPLANATION_APPROVED, EXPLANATION_REJECTED
              appRouter.go('/attendance');
              return;
            case 'DOCTOR_SCHEDULE':
              // Trường hợp DOCTOR_MISSING_CHECKIN, DOCTOR_LATE_CHECKIN - điều hướng đến attendance để check
              appRouter.go('/attendance');
              return;
            case 'APPOINTMENT':
              // Thông báo về lịch hẹn (CREATED, CONFIRMED, CANCELLED, COMPLETED, IN_PROGRESS, STATUS_UPDATED, REMINDER)
              // Mobile chưa có màn appointment, điều hướng về home
              appRouter.go('/home');
              return;
            case 'MEDICAL_RECORD':
              // Thông báo về bệnh án (COMPLETED, UPDATED)
              // Mobile chưa có màn medical record, điều hướng về home
              appRouter.go('/home');
              return;
            case 'SCHEDULE':
              // Thông báo về lịch làm việc bị hủy hoặc khôi phục (CANCELLED, RESTORED)
              appRouter.go('/schedule');
              return;
            case 'HOLIDAY':
              // Thông báo về ngày nghỉ lễ (CREATED)
              appRouter.go('/home');
              return;
            case 'FACEPROFILEUPDATEREQUEST':
              // Thông báo về yêu cầu duyệt cập nhật khuôn mặt (REQUEST, APPROVED, REJECTED)
              // HR/Admin: điều hướng đến trang duyệt face profile
              // User: điều hướng đến profile
              appRouter.go('/hr/face-approvals');
              return;
            default:
              break;
          }
        }

        if (actionUrl != null && actionUrl.isNotEmpty) {
          // Parse actionUrl và điều hướng tương ứng
          if (actionUrl.contains('/leave-request')) {
            await _navigateToLeaveRequestPage();
          } else if (actionUrl.contains('/attendance')) {
            appRouter.go('/attendance');
          } else if (actionUrl.contains('/schedule')) {
            appRouter.go('/schedule');
          } else if (actionUrl.contains('/hr/schedules')) {
            appRouter.go('/hr/schedules');
          } else if (actionUrl.contains('/hr/face-approval') || actionUrl.contains('/face-profile-approval')) {
            appRouter.go('/hr/face-approvals');
          } else if (actionUrl.contains('/profile')) {
            appRouter.go('/profile');
          } else {
            // Fallback: điều hướng đến notifications
            appRouter.go('/notifications');
          }
        } else {
          // Nếu không có actionUrl và relatedEntityType, điều hướng đến notifications
          appRouter.go('/notifications');
        }
      } catch (e) {
        debugPrint('Error navigating from notification: $e');
      }
    });
  }
}
