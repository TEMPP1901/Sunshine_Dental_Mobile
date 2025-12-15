import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/notification_service.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>().user;
    final fullName = user?.fullName;
    final avatarUrl = user?.avatarUrl;
    final avatarImage = ApiService.resolveAvatarImage(avatarUrl);

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: avatarImage,
            backgroundColor: colorScheme.primaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.greeting'.tr(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fullName != null && fullName.isNotEmpty
                    ? fullName
                    : 'profile.guest'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          width: 48,
          child: Card(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: colorScheme.surface,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push('/notifications');
                },
                borderRadius: BorderRadius.circular(16),
                child: ValueListenableBuilder<int>(
                  valueListenable: NotificationService().unreadCount,
                  builder: (context, count, child) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
