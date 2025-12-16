import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileHeader({super.key, required this.user});

  String _normalizeRole(dynamic role) {
    final roleStr = role?.toString().toUpperCase() ?? '';
    if (roleStr.startsWith('ROLE_')) return roleStr.substring(5);
    return roleStr;
  }

  List<String> _extractNormalizedRoles(dynamic roles) {
    if (roles == null) return [];
    List<dynamic> rawList = [];
    if (roles is List) {
      rawList = roles;
    } else if (roles is String)
      rawList = roles.split(',');

    return rawList
        .map((r) {
          if (r is Map) return _normalizeRole(r['name'] ?? r['role']);
          return _normalizeRole(
            r.toString().replaceAll(RegExp(r'[\[\]\s]'), ''),
          );
        })
        .where((r) => r.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fullName = user['fullName']?.toString() ?? 'profile.guest'.tr();
    final email = user['email']?.toString() ?? '—';
    final avatarUrl = user['avatarUrl']?.toString();
    final roles = user['roles'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundImage: ApiService.resolveAvatarImage(avatarUrl),
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (roles != null) _buildRolesBadges(context, roles),
        ],
      ),
    );
  }

  Widget _buildRolesBadges(BuildContext context, dynamic roles) {
    final roleList = _extractNormalizedRoles(roles);
    if (roleList.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: roleList.map((role) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            role,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}
