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
    final clinicName =
        attendance['clinicName']?.toString() ??
        attendance['clinic']?['clinicName']?.toString() ??
        'Unknown Clinic';
    // Lấy trạng thái chấm công ưu tiên attendanceStatus. Nếu không có thì lấy trường status
    final status =
        attendance['attendanceStatus']?.toString() ??
        attendance['status']?.toString() ??
        'UNKNOWN';
    // Lấy shiftType để hiển thị ca sáng/chiều
    final shiftType = attendance['shiftType']?.toString();
    final shiftTypeLabel = _getShiftTypeLabel(shiftType);
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(isSelected ? 0.35 : 0.15),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(workDate),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  clinicName.isEmpty ? 'Clinic' : clinicName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                ),
                              ),
                              if (shiftTypeLabel.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    shiftTypeLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              _buildStatusChip(context, status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$formattedStartTime — $formattedEndTime',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (attendance['checkInTime'] != null ||
                              attendance['checkOutTime'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (attendance['checkInTime'] != null) ...[
                                  const Icon(
                                    Icons.login_rounded,
                                    size: 12,
                                    color: Color(0xFF047857),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(attendance['checkInTime']),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF047857),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                if (attendance['checkInTime'] != null &&
                                    attendance['checkOutTime'] != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                if (attendance['checkOutTime'] != null) ...[
                                  const Icon(
                                    Icons.logout_rounded,
                                    size: 12,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(attendance['checkOutTime']),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFD97706),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (attendance['actualWorkHours'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 12,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatHours(attendance['actualWorkHours'])}h',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (attendance['expectedWorkHours'] != null)
                                  Text(
                                    ' / ${_formatHours(attendance['expectedWorkHours'])}h',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                if (attendance['lateMinutes'] != null &&
                                    (attendance['lateMinutes'] as int) > 0) ...[
                                  const SizedBox(width: 8),
                                  _buildBadge(
                                    'Late ${attendance['lateMinutes']}m',
                                    const Color(0xFFD97706),
                                  ),
                                ],
                                if (attendance['earlyMinutes'] != null &&
                                    (attendance['earlyMinutes'] as int) >
                                        0) ...[
                                  const SizedBox(width: 6),
                                  _buildBadge(
                                    'Early ${attendance['earlyMinutes']}m',
                                    const Color(0xFF047857),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
    // === FIX: Kiểm tra thời gian trước khi hiển thị ABSENT ===
    // Nếu chưa tới giờ làm việc thì không hiển thị ABSENT
    final startTime = attendance['startTime']?.toString();
    final checkInTime = attendance['checkInTime'];
    final now = DateTime.now();

    if ((status.toUpperCase() == 'ABSENT' ||
            status.toUpperCase() == 'APPROVED_ABSENCE') &&
        checkInTime == null &&
        startTime != null &&
        startTime.isNotEmpty) {
      try {
        // Parse startTime (format: HH:mm:ss hoặc HH:mm)
        final timeParts = startTime.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final shiftStart = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );

          // Nếu chưa tới giờ bắt đầu ca → hiển thị "Đi trễ" thay vì "Vắng mặt"
          if (now.isBefore(shiftStart)) {
            return _buildPendingChip(context);
          }
        }
      } catch (e) {
        // Nếu parse lỗi thì vẫn hiển thị status như cũ
      }
    }

    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'ON_TIME':
      case 'APPROVED_PRESENT':
      case 'PRESENT':
        color = const Color(0xFF047857);
        label = 'attendance.status.present'.tr();
        break;
      case 'ABSENT':
      case 'APPROVED_ABSENCE':
        color = const Color(0xFFB91C1C);
        label = 'attendance.status.absent'.tr();
        break;
      case 'LATE':
      case 'APPROVED_LATE':
        color = const Color(0xFFD97706);
        label = 'attendance.status.late'.tr();
        break;
      case 'LEAVE_EARLY':
        color = const Color(0xFFB45309);
        label = 'attendance.status.leaveEarly'.tr();
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
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

  // Widget cho trạng thái "Chờ check-in" (chưa tới giờ)
  Widget _buildPendingChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        'Chờ check-in',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // Lấy label cho shiftType (ca sáng/chiều)
  String _getShiftTypeLabel(String? shiftType) {
    if (shiftType == null ||
        shiftType.isEmpty ||
        shiftType.toUpperCase() == 'FULL_DAY') {
      return '';
    }
    switch (shiftType.toUpperCase()) {
      case 'MORNING':
        return 'attendance.shiftType.morning'.tr();
      case 'AFTERNOON':
        return 'attendance.shiftType.afternoon'.tr();
      default:
        return '';
    }
  }
}
