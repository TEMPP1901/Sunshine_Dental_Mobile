import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'shared_widgets.dart';

class FilterBar extends StatelessWidget {
  final TextEditingController dateController;
  final int? selectedClinicId;
  final List<Map<String, dynamic>> clinics;
  final ValueChanged<int?> onClinicChanged;
  final VoidCallback onFilter;

  const FilterBar({
    super.key,
    required this.dateController,
    required this.selectedClinicId,
    required this.clinics,
    required this.onClinicChanged,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: dateController,
            decoration: InputDecoration(
              labelText: 'hr.attendance.date'.tr(),
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 170,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'hr.common.clinic'.tr(),
              prefixIcon: const Icon(Icons.business_outlined, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: selectedClinicId,
                icon: const Icon(Icons.arrow_drop_down),
                onChanged: onClinicChanged,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('hr.common.all'.tr()),
                  ),
                  ...clinics.map((c) {
                    final id = int.tryParse((c['id'] ?? c['clinicId'] ?? '').toString());
                    final name = c['clinicName']?.toString() ?? c['clinicCode']?.toString() ?? 'Clinic';
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(name),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onFilter,
          icon: const Icon(Icons.search, size: 18),
          label: Text('hr.common.filter'.tr()),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class StatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 6,
          children: stats.entries
              .map((e) => Chip(
                    label: Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.4),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class AttendanceCard extends StatelessWidget {
  final String employee;
  final String status;
  final String checkIn;
  final String checkOut;
  final String clinic;

  const AttendanceCard({
    super.key,
    required this.employee,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.clinic,
  });

  Color _statusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'APPROVED':
        return scheme.primary;
      case 'REJECTED':
        return scheme.error;
      case 'PENDING':
      default:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _statusColor(status, scheme);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    employee,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                  ),
                ),
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withOpacity(0.35)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.login_rounded,
              label: 'hr.attendance.checkIn'.tr(),
              value: checkIn,
            ),
            InfoRow(
              icon: Icons.logout_rounded,
              label: 'hr.attendance.checkOut'.tr(),
              value: checkOut,
            ),
            if (clinic.toString().isNotEmpty)
              InfoRow(
                icon: Icons.business_outlined,
                label: 'hr.common.clinic'.tr(),
                value: clinic.toString(),
              ),
          ],
        ),
      ),
    );
  }
}

