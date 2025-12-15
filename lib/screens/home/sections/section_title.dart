import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.onSeeAll,
    this.showSeeAll = true,
  });

  final String title;
  final VoidCallback onSeeAll;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'common.seeAll'.tr(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
