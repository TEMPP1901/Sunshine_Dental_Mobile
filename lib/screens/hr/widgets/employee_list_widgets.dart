import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Helper functions cho employee widgets
class EmployeeHelpers {
  static List<Color> getAvatarColor(String letter) {
    final colors = [
      [const Color(0xFF5B21B6), const Color(0xFF6D28D9)], // Darker Indigo
      [const Color(0xFF0E7490), const Color(0xFF0891B2)], // Darker Cyan
      [const Color(0xFF047857), const Color(0xFF059669)], // Darker Emerald
      [const Color(0xFFB45309), const Color(0xFFD97706)], // Darker Amber
      [const Color(0xFF0F766E), const Color(0xFF0D9488)], // Darker Teal
      [const Color(0xFF6D28D9), const Color(0xFF7C3AED)], // Darker Purple
      [const Color(0xFFBE185D), const Color(0xFFDB2777)], // Darker Pink
    ];
    return colors[letter.codeUnitAt(0) % colors.length];
  }
}

/// Widget hiển thị empty state cho employee list
class EmployeeEmptyState extends StatelessWidget {
  const EmployeeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
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
                colors: isDark
                    ? [Colors.grey[800]!, Colors.grey[700]!]
                    : [Colors.grey[200]!, Colors.grey[100]!],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'hr.common.noData'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'hr.employees.emptyState'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị status chip
class EmployeeStatusChip extends StatelessWidget {
  final bool active;

  const EmployeeStatusChip({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF059669) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? [
                  const Color(0xFF059669).withOpacity(0.12),
                  const Color(0xFF047857).withOpacity(0.12),
                ]
              : [
                  const Color(0xFFDC2626).withOpacity(0.12),
                  const Color(0xFFB91C1C).withOpacity(0.12),
                ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            active ? 'hr.common.active'.tr() : 'hr.common.inactive'.tr(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị employee card
class EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onToggleStatus;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = employee['active'] ?? employee['isActive'] ?? true;
    final name = employee['fullName'] ?? 'hr.common.employee'.tr();
    final code = employee['code'] ?? employee['employeeCode'] ?? '';
    final role = employee['roleName'] ?? '';
    final email = employee['email'] ?? '';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarColor = EmployeeHelpers.getAvatarColor(firstLetter);

    // Nền card trung tính, ít “phát sáng” hơn trong dark mode
    final surfaceColor = isDark
        ? const Color(0xFF020617)
        : Colors.white; // slate-950
    final surfaceLightColor = isDark
        ? const Color(0xFF020617)
        : const Color(0xFFFAFBFC);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [surfaceColor, surfaceLightColor],
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: avatarColor,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor[0].withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Code
                      if (code.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Email
                      if (email.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  email.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      // Status and Actions
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          EmployeeStatusChip(active: active),
                          if (role.toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF5B21B6,
                                    ).withOpacity(isDark ? 0.18 : 0.12),
                                    const Color(
                                      0xFF6D28D9,
                                    ).withOpacity(isDark ? 0.18 : 0.12),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6D28D9,
                                  ).withOpacity(isDark ? 0.25 : 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF6D28D9),
                                ),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (active == true
                                    ? const Color(0xFFDC2626).withOpacity(0.3)
                                    : const Color(0xFF059669).withOpacity(0.3)),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: onToggleStatus,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        active == true
                                            ? Icons.lock_outline_rounded
                                            : Icons.lock_open_outlined,
                                        size: 14,
                                        color: active == true
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF059669),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        active == true
                                            ? 'hr.common.inactive'.tr()
                                            : 'hr.common.active'.tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: active == true
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }
}

/// Widget hiển thị filter dropdown
class EmployeeFilterDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final List<Map<String, dynamic>> data;
  final ValueChanged<int?> onChanged;

  const EmployeeFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<int?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            'hr.common.all'.tr(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
        ...data.map((e) {
          final id = int.tryParse(
            (e['id'] ?? e['clinicId'] ?? e['departmentId'] ?? e['roleId'] ?? '')
                .toString(),
          );
          final name =
              e['name']?.toString() ??
              e['clinicName']?.toString() ??
              e['departmentName']?.toString() ??
              e['roleName']?.toString() ??
              'N/A';
          return DropdownMenuItem(
            value: id,
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          );
        }),
      ],
      selectedItemBuilder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return [
          Text(
            'hr.common.all'.tr(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          ...data.map((e) {
            final name =
                e['name']?.toString() ??
                e['clinicName']?.toString() ??
                e['departmentName']?.toString() ??
                e['roleName']?.toString() ??
                'N/A';
            return Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            );
          }),
        ];
      },
      onChanged: onChanged,
    );
  }
}

/// Widget hiển thị pager
class EmployeePager extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const EmployeePager({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canGoPrev = currentPage > 0;
    final canGoNext = currentPage + 1 < totalPages;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final surfaceLightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFFAFBFC);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surfaceColor, surfaceLightColor],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.15),
                width: 1,
              ),
            ),
            child: Text(
              'Trang ${currentPage + 1}/${totalPages == 0 ? 1 : totalPages}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF6D28D9),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: canGoPrev
                      ? const LinearGradient(
                          colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                        )
                      : null,
                  color: canGoPrev
                      ? null
                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: canGoPrev
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6D28D9).withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: canGoPrev ? onPrevious : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: canGoPrev
                            ? Colors.white
                            : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: canGoNext
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: canGoNext ? null : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: canGoNext
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: canGoNext ? onNext : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: canGoNext
                            ? Colors.white
                            : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
