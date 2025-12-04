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
        setState(() {
          _notifications = data['content'];
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

    switch (relatedEntityType.toUpperCase()) {
      case 'LEAVE_REQUEST':
        if (relatedEntityId != null) {
          context.go('/leave-request');
        }
        break;
      case 'ATTENDANCE':
        context.go('/attendance');
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
