import 'package:flutter/material.dart';

/// Widget hiển thị filter chip cho approved leave page
class LeaveFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color color;

  const LeaveFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(isDark ? 0.2 : 0.15)
                : (isDark ? Colors.grey[900]!.withOpacity(0.3) : Colors.grey[50]!.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.4)
                  : (isDark ? Colors.grey[700]!.withOpacity(0.3) : Colors.grey[300]!.withOpacity(0.5)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? color
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? color
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị empty state cho approved leave page
class LeaveEmptyState extends StatelessWidget {
  const LeaveEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!.withOpacity(0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 56,
                color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Không có đơn xin nghỉ cần xử lý',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE8EAED) : const Color(0xFF0F172A),
                letterSpacing: -0.3,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tất cả đơn đã được xử lý',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị divider cho leave card
class LeaveDivider extends StatelessWidget {
  final bool isDark;

  const LeaveDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 1,
        color: isDark 
            ? Colors.grey[800]!.withOpacity(0.3)
            : Colors.grey[200]!.withOpacity(0.5),
      ),
    );
  }
}

/// Widget hiển thị info row cho leave card
class LeaveInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isDark;

  const LeaveInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withOpacity(0.2),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE8EAED) : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị leave request card
class LeaveRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const LeaveRequestCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFE8EAED) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? Colors.grey[300] : Colors.grey[700];

    // Extract data
    final user = item['user'] as Map<String, dynamic>?;
    final employeeName = user?['fullName']?.toString() ?? 'Nhân viên';
    final employeeId = user?['id']?.toString() ?? user?['userId']?.toString() ?? '';
    final clinic = item['clinic'] as Map<String, dynamic>?;
    final clinicName = clinic?['clinicName']?.toString() ?? clinic?['clinicCode']?.toString() ?? '--';
    final startDate = item['startDate']?.toString() ?? '--';
    final endDate = item['endDate']?.toString() ?? '--';
    final type = item['type']?.toString() ?? '';
    final reason = item['reason']?.toString() ?? '';
    final status = item['status']?.toString() ?? 'PENDING';
    final createdAt = item['createdAt']?.toString() ?? '';

    // Tính số ngày nghỉ
    int? daysCount;
    try {
      if (startDate != '--' && endDate != '--') {
        final start = DateTime.tryParse(startDate);
        final end = DateTime.tryParse(endDate);
        if (start != null && end != null) {
          daysCount = end.difference(start).inDays + 1;
        }
      }
    } catch (e) {
      // Ignore
    }

    // Status color
    Color statusColor;
    Color statusLightColor;
    if (status == 'PENDING') {
      statusColor = Colors.amber;
      statusLightColor = Colors.amber.shade100;
    } else if (status == 'PENDING_ADMIN') {
      statusColor = Colors.purple;
      statusLightColor = Colors.purple.shade100;
    } else if (status == 'APPROVED') {
      statusColor = Colors.green;
      statusLightColor = Colors.green.shade100;
    } else if (status == 'REJECTED') {
      statusColor = Colors.red;
      statusLightColor = Colors.red.shade100;
    } else {
      statusColor = Colors.grey;
      statusLightColor = Colors.grey.shade100;
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
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
            // Header: Employee info + Status
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      if (employeeId.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_rounded,
                              size: 14,
                              color: textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ID: $employeeId',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[900]!.withOpacity(0.3)
                    : Colors.grey[50]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Colors.grey[800]!.withOpacity(0.3)
                      : Colors.grey[200]!.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  LeaveInfoRow(
                    icon: Icons.business_rounded,
                    label: 'Phòng khám',
                    value: clinicName,
                    iconColor: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                  LeaveDivider(isDark: isDark),
                  LeaveInfoRow(
                    icon: Icons.date_range_rounded,
                    label: 'Từ ngày',
                    value: startDate,
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  LeaveDivider(isDark: isDark),
                  LeaveInfoRow(
                    icon: Icons.event_rounded,
                    label: 'Đến ngày',
                    value: endDate,
                    iconColor: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                  if (daysCount != null) ...[
                    LeaveDivider(isDark: isDark),
                    LeaveInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Số ngày',
                      value: '$daysCount ${daysCount == 1 ? 'ngày' : 'ngày'}',
                      iconColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ],
                  if (type.isNotEmpty) ...[
                    LeaveDivider(isDark: isDark),
                    LeaveInfoRow(
                      icon: Icons.category_rounded,
                      label: 'Loại',
                      value: type,
                      iconColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ],
                  if (reason.isNotEmpty) ...[
                    LeaveDivider(isDark: isDark),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withOpacity(isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEC4899).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.note_rounded,
                            size: 18,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lý do',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (createdAt.isNotEmpty) ...[
                    LeaveDivider(isDark: isDark),
                    LeaveInfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Ngày tạo',
                      value: createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt,
                      iconColor: const Color(0xFF6366F1),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            // Actions - chỉ hiển thị nếu status là PENDING hoặc PENDING_ADMIN
            if (status == 'PENDING' || status == 'PENDING_ADMIN') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onReject,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Từ chối',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onApprove,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Duyệt',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

