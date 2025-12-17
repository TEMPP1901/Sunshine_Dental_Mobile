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
    // Sử dụng actualWorkHours từ backend (đã trừ lunch break, late, early)
    final actualWorkHoursRaw = attendance!['actualWorkHours'];
    String actualWorkHours = '0';
    if (actualWorkHoursRaw != null) {
      try {
        final hours = actualWorkHoursRaw is num
            ? actualWorkHoursRaw.toDouble()
            : double.tryParse(actualWorkHoursRaw.toString());
        if (hours != null && hours >= 0) {
          actualWorkHours = hours % 1 == 0
              ? hours.toInt().toString()
              : hours.toStringAsFixed(2);
        }
      } catch (_) {
        actualWorkHours = '0';
      }
    }
    
    // Lấy thông tin chi tiết
    final expectedWorkHoursRaw = attendance!['expectedWorkHours'];
    final lateMinutes = attendance!['lateMinutes'] as int?;
    final earlyMinutes = attendance!['earlyMinutes'] as int?;
    final lunchBreakMinutes = attendance!['lunchBreakMinutes'] as int?;
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
                  const Color(0xFF047857),
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
                  const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Hiển thị giờ làm việc thực tế
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total worked hours',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                    Row(
                      children: [
                Text(
                          '$actualWorkHours hrs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.primary,
                  ),
                ),
                        if (expectedWorkHoursRaw != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '/ ${_formatHours(expectedWorkHoursRaw)} hrs',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Hiển thị thông tin chi tiết nếu có
                if (lateMinutes != null && lateMinutes > 0 || 
                    earlyMinutes != null && earlyMinutes > 0 ||
                    lunchBreakMinutes != null && lunchBreakMinutes > 0) ...[
                  const SizedBox(height: 12),
                  Divider(color: colorScheme.outline.withOpacity(0.1)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (lateMinutes != null && lateMinutes > 0)
                        _buildDetailChip(
                          context,
                          'Late: ${lateMinutes}m',
                          const Color(0xFFD97706),
                        ),
                      if (earlyMinutes != null && earlyMinutes > 0)
                        _buildDetailChip(
                          context,
                          'Early: ${earlyMinutes}m',
                          const Color(0xFFB45309),
                        ),
                      if (lunchBreakMinutes != null && lunchBreakMinutes > 0)
                        _buildDetailChip(
                          context,
                          'Lunch: ${lunchBreakMinutes}m',
                          colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ],
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
        color = const Color(0xFF047857);
        label = 'Present';
        break;
      case 'ABSENT':
      case 'APPROVED_ABSENCE':
        color = const Color(0xFFB91C1C);
        label = 'Absent';
        break;
      case 'LATE':
      case 'APPROVED_LATE':
        color = const Color(0xFFD97706);
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

    Color faceColor = verificationStatus == 'SUCCESS' ? const Color(0xFF059669) : colorScheme.error;
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
      Color wifiColor = wifiValid ? const Color(0xFF059669) : colorScheme.error;
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

  // Định dạng số giờ từ BigDecimal hoặc số
  String _formatHours(dynamic value) {
    if (value == null) return '0';
    try {
      final hours = value is num
          ? value.toDouble()
          : double.tryParse(value.toString());
      if (hours != null && hours >= 0) {
        return hours % 1 == 0
            ? hours.toInt().toString()
            : hours.toStringAsFixed(2);
      }
    } catch (_) {}
    return '0';
  }

  // Tạo chip hiển thị thông tin chi tiết
  Widget _buildDetailChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
