import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../providers/user_provider.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>().user;
    final roles = user?.roles ?? [];
    final isDoctor = roles.contains('DOCTOR');

    final icons = [
      Icons.home_rounded,
      if (isDoctor) Icons.calendar_today_rounded,
      Icons.message_outlined,
      Icons.history_rounded,
      Icons.person_rounded,
    ];
    final labels = [
      'home.nav.home',
      if (isDoctor) 'home.nav.schedule',
      'home.nav.chat',
      'home.nav.history',
      'home.nav.profile',
    ];
    final routes = [
      '/home',
      if (isDoctor) '/schedule',
      '/chat',
      '/history',
      '/profile',
    ];

    const currentIndex = 0;

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isActive = index == currentIndex;
            final chatIndex = isDoctor ? 2 : 1;
            final isPrimaryAction = index == chatIndex;

            return GestureDetector(
              onTap: () {
                if (routes[index] != '/home' &&
                    routes[index] != '/profile' &&
                    routes[index] != '/schedule') {
                  Fluttertoast.showToast(
                    msg: '${labels[index].tr()} is coming soon',
                  );
                } else {
                  context.go(routes[index]);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      icons[index],
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: isPrimaryAction ? 28 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index].tr(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
