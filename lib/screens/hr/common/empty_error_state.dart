import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class EmptyErrorState extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;
  final String? emptyText;
  final IconData? icon;

  const EmptyErrorState({
    super.key,
    this.error,
    this.onRetry,
    this.emptyText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = icon ?? Icons.info_outline;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 32, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (onRetry != null) FilledButton(onPressed: onRetry, child: Text('hr.common.retry'.tr())),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(emptyText ?? 'hr.common.noData'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}


