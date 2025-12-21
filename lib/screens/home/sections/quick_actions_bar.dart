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
    // Sử dụng Theme mặc định của App (Hiệu ứng có sẵn)
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>().user;
    final roles = user?.roles ?? [];
    final isDoctor = roles.contains('DOCTOR');

    // [CỦA CHÚNG TA] Lấy đường dẫn hiện tại để biết đang ở tab nào
    final String location = GoRouterState.of(context).uri.toString();

    final icons = [
      Icons.storefront_rounded, // Store ở đầu
      Icons.home_rounded, // Home ở giữa
      if (isDoctor) Icons.calendar_today_rounded, // Schedule (nếu có)
      Icons.person_rounded, // Profile ở cuối
    ];

    final labels = [
      'Store', // Store ở đầu
      'home.nav.home', // Home ở giữa
      if (isDoctor) 'home.nav.schedule', // Schedule (nếu có)
      'home.nav.profile', // Profile ở cuối
    ];

    final routes = [
      '/products', // Store ở đầu
      '/home', // Home ở giữa
      if (isDoctor) '/schedule', // Schedule (nếu có)
      '/profile', // Profile ở cuối
    ];

    // [CỦA CHÚNG TA] Logic xác định currentIndex dựa trên đường dẫn
    int currentIndex = 1; // Mặc định là Home (index 1)

    // Nếu đường dẫn chứa /products (Ví dụ: /products hoặc /products/123) thì active tab Store
    if (location.startsWith('/products')) {
      currentIndex = 0;
    }
    else if (location.startsWith('/home')) {
      currentIndex = 1;
    }
    else if (location.startsWith('/schedule') && isDoctor) {
      currentIndex = 2;
    }
    else if (location.startsWith('/profile') || location.startsWith('/my-account')) {
      currentIndex = isDoctor ? 3 : 2;
    }

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isActive = index == currentIndex;

            // Không có primary action nữa
            final isPrimaryAction = false;

            return GestureDetector(
              onTap: () {
                // [CỦA CHÚNG TA] Dùng push cho Products để giữ nút Back, còn lại dùng go
                if (routes[index] == '/products') {
                  context.push('/products');
                }
                else if (routes[index] == '/home') {
                  context.go('/home');
                }
                else if (routes[index] == '/profile') {
                  context.push('/profile');
                }
                else {
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
                      // Dùng màu mặc định của Theme (Hiệu ứng có sẵn)
                      color: isActive
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      icons[index],
                      // Dùng màu mặc định của Theme
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: isPrimaryAction ? 28 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index].tr(), // Dịch đa ngôn ngữ
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      // Dùng màu mặc định của Theme
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