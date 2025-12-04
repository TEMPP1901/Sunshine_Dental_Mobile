import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ShiftCard extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCheckIn;

  const ShiftCard({
    super.key,
    required this.attendance,
    required this.isSelected,
    required this.onTap,
    this.isCheckIn = false,
  });

  // Xây dựng giao diện thẻ ca làm việc
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startTime = attendance['startTime']?.toString() ?? '--:--';
    final endTime = attendance['endTime']?.toString() ?? '--:--';
    final clinicName = attendance['clinicName']?.toString() ?? attendance['clinic']?['clinicName']?.toString() ?? 'Unknown Clinic';
    // Lấy trạng thái chấm công ưu tiên attendanceStatus. Nếu không có thì lấy trường status
    final status = attendance['attendanceStatus']?.toString() ??
                   attendance['status']?.toString() ??
                   'UNKNOWN';
    final workDateStr = attendance['workDate']?.toString();
    DateTime? workDate;
    if (workDateStr != null) {
      try {
        workDate = DateTime.parse(workDateStr);
      } catch (_) {}
    }

    // Định dạng lại giờ cho đẹp
    String formattedStartTime = startTime;
    String formattedEndTime = endTime;
    try {
      if (startTime != '--:--' && startTime.length > 5) {
        formattedStartTime = startTime.substring(0, 5);
      }
      if (endTime != '--:--' && endTime.length > 5) {
        formattedEndTime = endTime.substring(0, 5);
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (workDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14,
                            color: colorScheme.primary
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(workDate),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinicName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$formattedStartTime - $formattedEndTime',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(context, status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sinh widget trạng thái chấm công (status chip)
  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'ON_TIME':
      case 'APPROVED_PRESENT':
      case 'PRESENT':
        color = const Color(0xFF2E7D32);
        label = 'attendance.status.present'.tr();
        break;
      case 'ABSENT':
      case 'APPROVED_ABSENCE':
        color = const Color(0xFFC62828);
        label = 'attendance.status.absent'.tr();
        break;
      case 'LATE':
      case 'APPROVED_LATE':
        color = const Color(0xFFEF6C00);
        label = 'attendance.status.late'.tr();
        break;
      case 'LEAVE_EARLY':
        color = const Color(0xFFF9A825);
        label = 'attendance.status.leaveEarly'.tr();
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
