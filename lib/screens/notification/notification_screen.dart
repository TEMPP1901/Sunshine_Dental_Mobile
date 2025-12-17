import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    // Refresh unread count when opening notification screen
    NotificationService().fetchUnreadCount();
  }

  // Tải danh sách thông báo từ API
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().get('/api/notifications?page=0&size=20');
      final data = response.data;

      if (data != null && data['content'] is List) {
     
        final allNotifications = List<dynamic>.from(data['content']);
        final filteredNotifications = allNotifications.where((n) {
          final type = n['type']?.toString().toUpperCase();
          return type != 'AUDIT'; // Loại bỏ audit logs
        }).toList();
        
        setState(() {
          _notifications = filteredNotifications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
      // Cập nhật số lượng thông báo chưa đọc sau khi fetch
      NotificationService().fetchUnreadCount();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Đánh dấu thông báo là đã đọc
  Future<void> _markAsRead(int id) async {
    try {
      await ApiService().put('/api/notifications/$id/read');
      setState(() {
        final index = _notifications.indexWhere((n) => n['notificationId'] == id);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
        }
      });
      // Cập nhật số lượng thông báo chưa đọc sau khi đánh dấu đã đọc
      NotificationService().fetchUnreadCount();
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    }
  }

  // Đánh dấu tất cả thông báo là đã đọc
  Future<void> _markAllAsRead() async {
    try {
      await ApiService().put('/api/notifications/read-all');
      setState(() {
        for (var n in _notifications) {
          n['isRead'] = true;
        }
      });
      // Cập nhật số lượng thông báo chưa đọc sau khi đánh dấu tất cả đã đọc
      NotificationService().fetchUnreadCount();
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
    }
  }

  // Điều hướng khi click vào thông báo tương ứng đến màn phù hợp
  void _handleNotificationTap(Map<String, dynamic> notification) {
    final relatedEntityType = notification['relatedEntityType']?.toString();
    final relatedEntityId = notification['relatedEntityId'];

    if (relatedEntityType == null) return;

    final actionUrl = notification['actionUrl']?.toString();
    
    // Nếu có actionUrl, ưu tiên dùng actionUrl
    if (actionUrl != null && actionUrl.isNotEmpty) {
      if (actionUrl.contains('/leave-request')) {
        context.go('/leave-request');
        return;
      } else if (actionUrl.contains('/attendance')) {
        context.go('/attendance');
        return;
      } else if (actionUrl.contains('/schedule')) {
        context.go('/schedule');
        return;
      } else if (actionUrl.contains('/hr/schedules')) {
        context.go('/hr/schedules');
        return;
      } else if (actionUrl.contains('/hr/face-approval') || actionUrl.contains('/face-profile-approval')) {
        context.go('/hr/face-approvals');
        return;
      } else if (actionUrl.contains('/profile')) {
        context.go('/profile');
        return;
      }
    }

    switch (relatedEntityType.toUpperCase()) {
      case 'LEAVE_REQUEST':
        context.go('/leave-request');
        break;
      case 'ATTENDANCE':
        // ATTENDANCE_CHECKIN, ATTENDANCE_CHECKOUT, ATTENDANCE_ABSENT, EXPLANATION_SUBMITTED, EXPLANATION_APPROVED, EXPLANATION_REJECTED
        context.go('/attendance');
        break;
      case 'DOCTOR_SCHEDULE':
        // DOCTOR_MISSING_CHECKIN, DOCTOR_LATE_CHECKIN - điều hướng đến attendance
        context.go('/attendance');
        break;
      case 'APPOINTMENT':
        // Thông báo về lịch hẹn (CREATED, CONFIRMED, CANCELLED, COMPLETED, IN_PROGRESS, STATUS_UPDATED, REMINDER)
        // Mobile chưa có màn appointment, điều hướng về home
        context.go('/home');
        break;
      case 'MEDICAL_RECORD':
        // Thông báo về bệnh án - mobile chưa có màn medical record, điều hướng về home
        context.go('/home');
        break;
      case 'SCHEDULE':
        // Thông báo về lịch làm việc bị hủy hoặc khôi phục
        context.go('/schedule');
        break;
      case 'HOLIDAY':
        // Thông báo về ngày nghỉ lễ
        context.go('/home');
        break;
      case 'FACEPROFILEUPDATEREQUEST':
        // Thông báo về yêu cầu duyệt cập nhật khuôn mặt
        context.go('/hr/face-approvals');
        break;
      default:
        break;
    }
  }

  // Lấy icon phù hợp với loại thông báo
  IconData _getNotificationIcon(String? type) {
    if (type == null) return Icons.notifications;

    switch (type.toUpperCase()) {
      case 'LEAVE_REQUEST_CREATED':
      case 'LEAVE_REQUEST_APPROVED':
        return Icons.event_available;
      case 'LEAVE_REQUEST_REJECTED':
        return Icons.event_busy;
      case 'LEAVE_REQUEST_CANCELLED':
        return Icons.cancel;
      case 'ATTENDANCE_CHECKIN':
      case 'ATTENDANCE_CHECKOUT':
        return Icons.access_time;
      case 'ATTENDANCE_ABSENT':
        return Icons.person_off;
      case 'EXPLANATION_SUBMITTED':
      case 'EXPLANATION_APPROVED':
      case 'EXPLANATION_REJECTED':
        return Icons.description;
      case 'DOCTOR_MISSING_CHECKIN':
      case 'DOCTOR_LATE_CHECKIN':
        return Icons.warning_amber_rounded;
      case 'APPOINTMENT_CREATED':
      case 'APPOINTMENT_CONFIRMED':
      case 'APPOINTMENT_COMPLETED':
      case 'APPOINTMENT_IN_PROGRESS':
        return Icons.calendar_today;
      case 'APPOINTMENT_CANCELLED':
      case 'APPOINTMENT_STATUS_UPDATED':
        return Icons.event_busy;
      case 'APPOINTMENT_REMINDER':
        return Icons.notifications_active;
      case 'MEDICAL_RECORD_COMPLETED':
      case 'MEDICAL_RECORD_UPDATED':
        return Icons.medical_services;
      case 'SCHEDULE_CANCELLED':
        return Icons.cancel_schedule_send;
      case 'SCHEDULE_RESTORED':
        return Icons.restore;
      case 'HOLIDAY_CREATED':
        return Icons.celebration;
      case 'FACE_PROFILE_UPDATE_REQUEST':
      case 'FACE_PROFILE_APPROVED':
      case 'FACE_PROFILE_REJECTED':
        return Icons.face;
      default:
        return Icons.notifications;
    }
  }

  // Lấy màu phù hợp với loại thông báo
  Color _getNotificationColor(String? type, ColorScheme colorScheme) {
    if (type == null) return colorScheme.primary;

    switch (type.toUpperCase()) {
      case 'LEAVE_REQUEST_APPROVED':
        return Colors.green;
      case 'LEAVE_REQUEST_REJECTED':
        return Colors.red;
      case 'LEAVE_REQUEST_CREATED':
      case 'LEAVE_REQUEST_CANCELLED':
        return Colors.orange;
      case 'ATTENDANCE_CHECKIN':
      case 'ATTENDANCE_CHECKOUT':
        return Colors.blue;
      case 'ATTENDANCE_ABSENT':
        return Colors.red;
      case 'EXPLANATION_SUBMITTED':
        return Colors.orange;
      case 'EXPLANATION_APPROVED':
        return Colors.green;
      case 'EXPLANATION_REJECTED':
        return Colors.red;
      case 'DOCTOR_MISSING_CHECKIN':
      case 'DOCTOR_LATE_CHECKIN':
        return Colors.redAccent;
      case 'APPOINTMENT_CREATED':
      case 'APPOINTMENT_CONFIRMED':
      case 'APPOINTMENT_COMPLETED':
      case 'APPOINTMENT_IN_PROGRESS':
        return Colors.green;
      case 'APPOINTMENT_CANCELLED':
        return Colors.red;
      case 'APPOINTMENT_STATUS_UPDATED':
      case 'APPOINTMENT_REMINDER':
        return Colors.blue;
      case 'MEDICAL_RECORD_COMPLETED':
      case 'MEDICAL_RECORD_UPDATED':
        return Colors.teal;
      case 'SCHEDULE_CANCELLED':
        return Colors.red;
      case 'SCHEDULE_RESTORED':
        return Colors.green;
      case 'HOLIDAY_CREATED':
        return Colors.purple;
      case 'FACE_PROFILE_UPDATE_REQUEST':
        return Colors.orange;
      case 'FACE_PROFILE_APPROVED':
        return Colors.green;
      case 'FACE_PROFILE_REJECTED':
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _notifications.isNotEmpty ? _markAllAsRead : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 64, color: colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No notification found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final isRead = notification['isRead'] == true;
                          final createdAt = notification['createdAt'] != null
                              ? DateTime.parse(notification['createdAt'])
                              : DateTime.now();

                          final notificationType = notification['type']?.toString();
                          final notificationIcon = _getNotificationIcon(notificationType);
                          final notificationColor = _getNotificationColor(notificationType, colorScheme);

                          return ListTile(
                            tileColor: isRead ? null : colorScheme.primaryContainer.withOpacity(0.1),
                            leading: CircleAvatar(
                              backgroundColor: isRead
                                  ? colorScheme.surfaceContainerHighest
                                  : notificationColor.withOpacity(0.2),
                              child: Icon(
                                notificationIcon,
                                color: isRead ? colorScheme.onSurfaceVariant : notificationColor,
                              ),
                            ),
                            title: Text(
                              notification['title'] ?? 'Notification',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notification['message'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, HH:mm').format(createdAt),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(notification['notificationId']);
                              }
                              _handleNotificationTap(notification);
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
