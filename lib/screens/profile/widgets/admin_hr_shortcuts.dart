import 'package:flutter/material.dart';

class AdminHrShortcuts extends StatelessWidget {
  final bool isHr;
  final bool isAdmin;
  final VoidCallback onGoHr;
  final VoidCallback onGoAdmin;

  const AdminHrShortcuts({
    super.key,
    required this.isHr,
    required this.isAdmin,
    required this.onGoHr,
    required this.onGoAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quản trị',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (isHr)
              Expanded(
                child: _ShortcutCard(
                  title: 'HR Dashboard',
                  subtitle: 'Chấm công, giải trình',
                  icon: Icons.badge_outlined,
                  color: colorScheme.primary,
                  onTap: onGoHr,
                ),
              ),
            if (isHr && isAdmin) const SizedBox(width: 12),
            if (isAdmin)
              Expanded(
                child: _ShortcutCard(
                  title: 'Admin Dashboard',
                  subtitle: 'Duyệt đơn nghỉ',
                  icon: Icons.verified_user_outlined,
                  color: colorScheme.tertiary,
                  onTap: onGoAdmin,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

