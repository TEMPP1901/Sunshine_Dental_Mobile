import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;

  // Khởi tạo widget CustomTabBar với controller và danh sách tab
  const CustomTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Xây dựng giao diện thanh TabBar tuỳ chỉnh
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}
