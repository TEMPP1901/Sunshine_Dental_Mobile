import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Helper functions cho schedule widgets
class ScheduleHelpers {
  static String asString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map) {
      final name = v['name'] ?? v['fullName'] ?? v['clinicName'] ?? v['roomName'] ?? v.values.firstOrNull;
      if (name != null) return name.toString();
    }
    return v.toString();
  }

  static Color getDoctorColor(String doctorName) {
    final colors = [
      const Color(0xFF6D28D9), // Darker Indigo
      const Color(0xFF7C3AED), // Darker Purple
      const Color(0xFFDB2777), // Darker Pink
      const Color(0xFFDC2626), // Darker Red
      const Color(0xFFD97706), // Darker Amber
      const Color(0xFF059669), // Darker Emerald
      const Color(0xFF0891B2), // Darker Cyan
      const Color(0xFF2563EB), // Darker Blue
    ];
    
    int hash = doctorName.hashCode;
    return colors[hash.abs() % colors.length];
  }

  static String getDoctorInitial(String doctorName) {
    if (doctorName.isEmpty) return 'BS';
    final parts = doctorName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return doctorName.substring(0, doctorName.length > 2 ? 2 : doctorName.length).toUpperCase();
  }

  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }
}

/// Widget hiển thị empty schedule state
class ScheduleEmptyState extends StatelessWidget {
  const ScheduleEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'hr.common.noData'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị info chip nhỏ gọn
class ScheduleInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final bool isDark;

  const ScheduleInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: iconColor.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: iconColor,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị info row cho schedule
class ScheduleInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isDark;

  const ScheduleInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                iconColor.withOpacity(0.15),
                iconColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE8EAED) : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị một ca làm việc trong doctor card
class ScheduleItem extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final Color doctorColor;
  final bool isDark;

  const ScheduleItem({
    super.key,
    required this.schedule,
    required this.doctorColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final clinic = ScheduleHelpers.asString(schedule['clinicName'] ?? schedule['clinic']);
    final room = ScheduleHelpers.asString(schedule['roomName'] ?? schedule['room']);
    final day = ScheduleHelpers.asString(schedule['dayOfWeek'] ?? schedule['day']);
    final start = ScheduleHelpers.asString(schedule['startTime']);
    final end = ScheduleHelpers.asString(schedule['endTime']);
    final date = ScheduleHelpers.asString(schedule['workDate'] ?? schedule['date']);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time icon container
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: doctorColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: doctorColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.access_time_rounded,
            size: 14,
            color: doctorColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time
              Text(
                '${ScheduleHelpers.formatTime(start)} - ${ScheduleHelpers.formatTime(end)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
              if (clinic.toString().isNotEmpty || room.toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (clinic.toString().isNotEmpty)
                      ScheduleInfoChip(
                        icon: Icons.business_rounded,
                        label: clinic,
                        color: doctorColor.withOpacity(isDark ? 0.12 : 0.08),
                        iconColor: doctorColor,
                        isDark: isDark,
                      ),
                    if (room.toString().isNotEmpty)
                      ScheduleInfoChip(
                        icon: Icons.room_rounded,
                        label: room,
                        color: doctorColor.withOpacity(isDark ? 0.1 : 0.06),
                        iconColor: doctorColor.withOpacity(0.8),
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị doctor card với danh sách ca làm việc
class DoctorCard extends StatelessWidget {
  final String doctorName;
  final List<Map<String, dynamic>> schedules;

  const DoctorCard({
    super.key,
    required this.doctorName,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final doctorColor = ScheduleHelpers.getDoctorColor(doctorName);
    final doctorInitial = ScheduleHelpers.getDoctorInitial(doctorName);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: doctorColor.withOpacity(isDark ? 0.2 : 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: doctorColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        doctorColor,
                        doctorColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: doctorColor.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      doctorInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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
                        doctorName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: doctorColor,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${schedules.length} ca',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: doctorColor.withOpacity(0.08),
            indent: 14,
            endIndent: 14,
          ),
          // Schedule items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: schedules.asMap().entries.map((entry) {
                final index = entry.key;
                final schedule = entry.value;
                final isLast = index == schedules.length - 1;
                
                return Column(
                  children: [
                    ScheduleItem(
                      schedule: schedule,
                      doctorColor: doctorColor,
                      isDark: isDark,
                    ),
                    if (!isLast) ...[
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark 
                            ? Colors.grey[800]!.withOpacity(0.3)
                            : Colors.grey[200]!.withOpacity(0.5),
                        indent: 0,
                        endIndent: 0,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị schedule section với ExpansionTile
class ScheduleSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final IconData? icon;

  const ScheduleSection({
    super.key,
    required this.title,
    required this.data,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final surfaceLightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    
    // Group by doctor
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var schedule in data) {
      final doctor = ScheduleHelpers.asString(
        schedule['doctorName'] ?? schedule['doctor'] ?? schedule['employee'] ?? schedule['user']
      );
      if (doctor.isEmpty) continue;
      
      if (!grouped.containsKey(doctor)) {
        grouped[doctor] = [];
      }
      grouped[doctor]!.add(schedule);
    }
    
    // Sort schedules within each doctor
    grouped.forEach((doctor, doctorSchedules) {
      doctorSchedules.sort((a, b) {
        final dateA = ScheduleHelpers.asString(a['workDate'] ?? a['date'] ?? '');
        final dateB = ScheduleHelpers.asString(b['workDate'] ?? b['date'] ?? '');
        if (dateA != dateB) {
          return dateA.compareTo(dateB);
        }
        final timeA = ScheduleHelpers.asString(a['startTime'] ?? '');
        final timeB = ScheduleHelpers.asString(b['startTime'] ?? '');
        return timeA.compareTo(timeB);
      });
    });
    
    final sortedDoctors = grouped.keys.toList()..sort();
    
    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon ?? Icons.calendar_today_rounded,
              color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
              size: 18,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE8EAED) : const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          children: [
            if (data.isEmpty)
              const ScheduleEmptyState()
            else
              ...sortedDoctors.map((doctor) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DoctorCard(
                    doctorName: doctor,
                    schedules: grouped[doctor]!,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

