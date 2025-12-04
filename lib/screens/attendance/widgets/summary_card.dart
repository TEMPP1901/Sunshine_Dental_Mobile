import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SummaryCard extends StatelessWidget {
  final Map<String, dynamic>? attendance;

  const SummaryCard({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (attendance == null) {
      // Kiểm tra cuối tuần để báo user là hôm nay không có ca
      final now = DateTime.now();
      final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                isWeekend ? Icons.weekend_rounded : Icons.calendar_today_rounded,
                size: 32,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                isWeekend
                  ? 'No attendance data today (weekend)'
                  : 'No attendance data today',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final checkIn = _formatTime(attendance!['checkInTime']);
    final checkOut = _formatTime(attendance!['checkOutTime']);

    // Validate và định dạng số giờ đã làm (rất quan trọng cho tính lương)
    final workedHoursRaw = attendance!['workedHours'];
    String workedHours = '0';
    if (workedHoursRaw != null) {
      try {
        final hours = workedHoursRaw is num
            ? workedHoursRaw.toDouble()
            : double.tryParse(workedHoursRaw.toString());
        if (hours != null && hours >= 0) {
          workedHours = hours % 1 == 0
              ? hours.toInt().toString()
              : hours.toStringAsFixed(2);
        }
      } catch (_) {
        workedHours = '0';
      }
    }
    // Lấy trạng thái ca làm từ backend, fallback cho các API cũ
    final status = attendance!['attendanceStatus']?.toString() ??
        attendance!['status']?.toString() ??
        'UNKNOWN';
    final verificationStatus = attendance!['verificationStatus']?.toString();
    final wifiValid = attendance!['wifiValid'] as bool?;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, dd MMMM').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),
              _buildStatusBadge(context, status),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  context,
                  'Check-in',
                  checkIn,
                  Icons.login_rounded,
                  const Color(0xFF2E7D32),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outline.withOpacity(0.2),
              ),
              Expanded(
                child: _buildTimeInfo(
                  context,
                  'Check-out',
                  checkOut,
                  Icons.logout_rounded,
                  const Color(0xFFEF6C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total worked hours',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$workedHours hrs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (verificationStatus != null || wifiValid != null) ...[
            const SizedBox(height: 20),
            Divider(color: colorScheme.outline.withOpacity(0.1)),
            const SizedBox(height: 12),
            _buildVerificationStatus(
              context,
              verificationStatus: verificationStatus ?? 'UNKNOWN',
              wifiValid: wifiValid,
            ),
          ],
        ],
      ),
    );
  }

  // Tạo badge hiển thị trạng thái ca làm
  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'ON_TIME':
      case 'APPROVED_PRESENT':
      case 'PRESENT':
        color = const Color(0xFF2E7D32);
        label = 'Present';
        break;
      case 'ABSENT':
      case 'APPROVED_ABSENCE':
        color = const Color(0xFFC62828);
        label = 'Absent';
        break;
      case 'LATE':
      case 'APPROVED_LATE':
        color = const Color(0xFFEF6C00);
        label = 'Late';
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

  // Hiển thị thông tin check-in và check-out (giờ vào, ra)
  Widget _buildTimeInfo(
    BuildContext context,
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Xử lý hiển thị trạng thái xác thực khuôn mặt và wifi
  Widget _buildVerificationStatus(
    BuildContext context, {
    required String verificationStatus,
    required bool? wifiValid,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    List<Widget> items = [];

    Color faceColor = verificationStatus == 'SUCCESS' ? const Color(0xFF00C853) : colorScheme.error;
    IconData faceIcon = verificationStatus == 'SUCCESS' ? Icons.face_retouching_natural_rounded : Icons.error_outline_rounded;

    items.add(Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(faceIcon, size: 16, color: faceColor),
        const SizedBox(width: 6),
        Text(
          verificationStatus == 'SUCCESS' ? 'Face ID Verified' : 'Face ID Failed',
          style: TextStyle(fontSize: 12, color: faceColor, fontWeight: FontWeight.w600),
        ),
      ],
    ));

    if (wifiValid != null) {
      Color wifiColor = wifiValid ? const Color(0xFF00C853) : colorScheme.error;
      IconData wifiIcon = wifiValid ? Icons.wifi_rounded : Icons.wifi_off_rounded;
      items.add(const SizedBox(width: 16));
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(wifiIcon, size: 16, color: wifiColor),
          const SizedBox(width: 6),
          Text(
            wifiValid ? 'WiFi Valid' : 'WiFi Invalid',
            style: TextStyle(fontSize: 12, color: wifiColor, fontWeight: FontWeight.w600),
          ),
        ],
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items,
    );
  }

  // Định dạng giờ phút dạng HH:mm từ mốc datetime hoặc string
  String _formatTime(dynamic value) {
    if (value == null) return '--:--';
    try {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed == null) return '--:--';
      return DateFormat('HH:mm').format(parsed.toLocal());
    } catch (_) {
      return '--:--';
    }
  }
}
