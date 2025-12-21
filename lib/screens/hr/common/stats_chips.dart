import 'package:flutter/material.dart';

class StatsChips extends StatelessWidget {
  final Map<String, dynamic> stats;
  const StatsChips({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: stats.entries
              .map(
                (e) => Chip(
                  label: Text('${e.key}: ${e.value}'),
                  backgroundColor: scheme.surfaceContainerHighest.withOpacity(
                    0.6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
