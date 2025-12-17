import 'package:flutter/material.dart';

/// Widget hiển thị empty state cho attendance history
class AttendanceEmptyState extends StatelessWidget {
  const AttendanceEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    
    return Container(
      padding: const EdgeInsets.all(48),
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6D28D9).withOpacity(isDark ? 0.15 : 0.08),
                  const Color(0xFF7C3AED).withOpacity(isDark ? 0.15 : 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: Color(0xFF6D28D9),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Không có dữ liệu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Không tìm thấy lịch sử attendance cho ngày đã chọn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị no search results
class AttendanceNoSearchResults extends StatelessWidget {
  const AttendanceNoSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    
    return Container(
      padding: const EdgeInsets.all(48),
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6D28D9).withOpacity(isDark ? 0.15 : 0.08),
                  const Color(0xFF7C3AED).withOpacity(isDark ? 0.15 : 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Color(0xFF6D28D9),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị detail row cho attendance card (deprecated - using inline widget now)
class AttendanceDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const AttendanceDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: iconColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị pager button
class AttendancePagerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const AttendancePagerButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                  )
                : null,
            color: isEnabled ? null : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: isEnabled 
                  ? Colors.white 
                  : (isDark ? Colors.grey[600] : Colors.grey[400]),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị action button cho filters
class AttendanceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const AttendanceActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
              )
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPrimary
            ? null
            : Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? const Color(0xFF6D28D9).withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: isPrimary ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị attendance item card
class AttendanceItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const AttendanceItemCard({
    super.key,
    required this.item,
  });

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr == '--' || timeStr.isEmpty) return '--';
    try {
      final date = DateTime.parse(timeStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr;
    }
  }

  Widget _buildTimeDetail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
    final employee = item['fullName'] ?? item['employeeName'] ?? 'Nhân viên';
    final status = item['attendanceStatus'] ?? item['status']?.toString() ?? '';
    final checkIn = item['checkInTime'] ?? item['checkIn'] ?? '--';
    final checkOut = item['checkOutTime'] ?? item['checkOut'] ?? '--';
    final workDate = item['workDate'] ?? '';
    final jobTitle = item['jobTitle']?.toString() ?? '';
    
    // Determine status color - darker colors
    Color statusColor = const Color(0xFF6D28D9);
    Color statusLightColor = const Color(0xFF7C3AED);
    Color statusBgColor = const Color(0xFF6D28D9).withOpacity(isDark ? 0.15 : 0.08);
    IconData statusIcon = Icons.info_outline_rounded;
    
    if (status.toLowerCase().contains('absent') || status.toLowerCase().contains('vắng')) {
      statusColor = const Color(0xFFDC2626);
      statusLightColor = const Color(0xFFEF4444);
      statusBgColor = const Color(0xFFDC2626).withOpacity(isDark ? 0.15 : 0.08);
      statusIcon = Icons.cancel_outlined;
    } else if (status.toLowerCase().contains('late') || status.toLowerCase().contains('muộn')) {
      statusColor = const Color(0xFFD97706);
      statusLightColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFD97706).withOpacity(isDark ? 0.15 : 0.08);
      statusIcon = Icons.schedule_outlined;
    } else if (status.toLowerCase().contains('present') || status.toLowerCase().contains('có mặt')) {
      statusColor = const Color(0xFF059669);
      statusLightColor = const Color(0xFF10B981);
      statusBgColor = const Color(0xFF059669).withOpacity(isDark ? 0.15 : 0.08);
      statusIcon = Icons.check_circle_outline;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!.withOpacity(0.5)
              : Colors.grey[200]!.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
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
            // Header with employee name and status
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor,
                        statusLightColor,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      employee.isNotEmpty ? employee[0].toUpperCase() : 'N',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (jobTitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          jobTitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (status.toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Details - simplified layout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[900]!.withOpacity(0.3)
                    : Colors.grey[50]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark 
                      ? Colors.grey[800]!.withOpacity(0.3)
                      : Colors.grey[200]!.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeDetail(
                          context,
                          Icons.login_rounded,
                          'Check-in',
                          _formatTime(checkIn.toString()),
                          const Color(0xFF059669),
                          isDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDark 
                            ? Colors.grey[700]!.withOpacity(0.3)
                            : Colors.grey[300]!.withOpacity(0.5),
                      ),
                      Expanded(
                        child: _buildTimeDetail(
                          context,
                          Icons.logout_rounded,
                          'Check-out',
                          _formatTime(checkOut.toString()),
                          const Color(0xFF6D28D9),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  if (item['clinicName'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: isDark 
                          ? Colors.grey[700]!.withOpacity(0.3)
                          : Colors.grey[300]!.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinic',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['clinicName'].toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

