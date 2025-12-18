import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'attendance_info_row.dart';
import 'attendance_action_button.dart';

class AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  final void Function(String) onUpdateStatus;

  const AttendanceCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onUpdateStatus,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PRESENT':
        return Colors.green;
      case 'LATE':
        return Colors.orange;
      case 'ABSENT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'PRESENT':
        return Icons.check_circle_rounded;
      case 'LATE':
        return Icons.schedule_rounded;
      case 'ABSENT':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr == '--' || dateTimeStr.isEmpty) return '--';
    try {
      // Parse datetime từ backend (thường là UTC format với 'Z' ở cuối)
      DateTime dateTime = DateTime.parse(dateTimeStr);
      
      // Backend trả về UTC, cần convert sang local time
      // toLocal() sẽ tự động convert từ UTC sang timezone của device
      // Nếu device đang ở timezone VN (UTC+7) thì sẽ hiển thị đúng
      if (dateTime.isUtc) {
        dateTime = dateTime.toLocal();
      }
      // Nếu không phải UTC, giả định đã là local time hoặc format khác
      
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy status từ attendanceStatus (backend) hoặc status (fallback)
    final status = (item['attendanceStatus'] ?? item['status'])?.toString().toUpperCase() ?? 'UNKNOWN';
    final statusColor = _getStatusColor(status);
    final surfaceColor = isDark ? const Color(0xFF1A2332) : Colors.white;
    final borderColor = isDark
        ? Colors.grey[800]!.withOpacity(0.5)
        : Colors.grey[200]!.withOpacity(0.8);
    final textColor = isDark ? const Color(0xFFE8EAED) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6D28D9),
                        const Color(0xFF7C3AED),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6D28D9).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['fullName'] ?? item['employeeName'] ?? item['userName'] ?? 'Nhân viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (item['jobTitle'] != null || item['roleName'] != null || item['role'] != null) ...[
                            Icon(
                              Icons.work_rounded,
                              size: 14,
                              color: textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item['jobTitle']?.toString() ?? 
                                item['roleName']?.toString() ?? 
                                (item['role'] is Map ? item['role']['roleName']?.toString() : item['role']?.toString()) ?? 
                                'Nhân viên',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else if (item['userId'] != null || item['employeeId'] != null) ...[
                            Icon(
                              Icons.badge_rounded,
                              size: 12,
                              color: textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ID: ${item['userId'] ?? item['employeeId'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge - luôn hiển thị để biết trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: statusColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[900]!.withOpacity(0.3)
                    : Colors.grey[50]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.grey[800]!.withOpacity(0.3)
                      : Colors.grey[200]!.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  AttendanceInfoRow(
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    label: 'Check-in',
                    value: _formatDateTime(item['checkInTime']?.toString() ?? item['checkIn']?.toString() ?? '--'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  AttendanceInfoRow(
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Check-out',
                    value: _formatDateTime(item['checkOutTime']?.toString() ?? item['checkOut']?.toString() ?? '--'),
                    isDark: isDark,
                  ),
                  if (item['clinicName'] != null || item['clinic'] != null) ...[
                    const SizedBox(height: 12),
                    AttendanceInfoRow(
                      icon: Icons.business_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Phòng khám',
                      value: item['clinicName']?.toString() ?? item['clinic']?.toString() ?? '--',
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            // Action buttons - chỉ hiển thị khi status là UNKNOWN hoặc null
            if (status.toUpperCase() == 'UNKNOWN' || status.isEmpty)
              ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AttendanceActionButton(
                        label: 'PRESENT',
                        color: const Color(0xFF10B981),
                        icon: Icons.check_circle_rounded,
                        isDark: isDark,
                        onTap: () => onUpdateStatus('PRESENT'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AttendanceActionButton(
                        label: 'LATE',
                        color: const Color(0xFFF59E0B),
                        icon: Icons.schedule_rounded,
                        isDark: isDark,
                        onTap: () => onUpdateStatus('LATE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AttendanceActionButton(
                        label: 'ABSENT',
                        color: const Color(0xFFEF4444),
                        icon: Icons.cancel_rounded,
                        isDark: isDark,
                        onTap: () => onUpdateStatus('ABSENT'),
                      ),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }
}

