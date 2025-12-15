import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MedicalRecordPreview extends StatelessWidget {
  const MedicalRecordPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home.section.medicalRecord'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Teeth Chart Placeholder',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LegendDot(
                    color: colorScheme.tertiary,
                    label: 'home.record.hasTreatment'.tr(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LegendDot(
                    color: colorScheme.primary,
                    label: 'home.record.recommended'.tr(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'home.record.summary'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: () =>
                    Fluttertoast.showToast(msg: 'View Medical Record'),
                icon: const Icon(Icons.file_copy_outlined, size: 20),
                label: Text('home.record.viewDetails'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
