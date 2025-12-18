import 'package:flutter/material.dart';

class AttendanceFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const AttendanceFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: disabled
                ? (isDark ? Colors.grey[900]!.withOpacity(0.2) : Colors.grey[100]!.withOpacity(0.3))
                : selected
                    ? color.withOpacity(isDark ? 0.2 : 0.15)
                    : (isDark ? Colors.grey[900]!.withOpacity(0.3) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: disabled
                  ? (isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.grey[300]!.withOpacity(0.3))
                  : selected
                      ? color.withOpacity(0.5)
                      : (isDark ? Colors.grey[700]!.withOpacity(0.3) : Colors.grey[300]!.withOpacity(0.6)),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected && !disabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected && !disabled) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: disabled
                      ? (isDark ? Colors.grey[600] : Colors.grey[400])
                      : selected
                          ? color
                          : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  letterSpacing: selected ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

