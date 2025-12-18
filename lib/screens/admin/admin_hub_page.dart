import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminHubPage extends StatefulWidget {
  const AdminHubPage({super.key});

  @override
  State<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends State<AdminHubPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Các tính năng xử lý thường xuyên và quan trọng
    final shortcuts = [
      _Shortcut(
        'Leave Requests',
        'Duyệt đơn nghỉ',
        Icons.description_rounded,
        '/admin/leave-requests',
        const Color(0xFFDC2626), // Red - Urgent
        const Color(0xFFEF4444), // Red Light
      ),
      _Shortcut(
        'Reports',
        'Báo cáo & Thống kê',
        Icons.bar_chart_rounded,
        '/admin/reports',
        const Color(0xFFB45309), // Orange - Important
        const Color(0xFFF59E0B), // Orange Light
      ),
      _Shortcut(
        'Attendance',
        'Chấm công',
        Icons.access_time_rounded,
        '/admin/attendance',
        const Color(0xFF0F766E), // Teal - Daily check
        const Color(0xFF14B8A6), // Teal Light
      ),
      _Shortcut(
        'Staff',
        'Quản lý nhân viên',
        Icons.people_alt_rounded,
        '/admin/staff',
        const Color(0xFF6D28D9), // Purple
        const Color(0xFF7C3AED), // Purple Light
      ),
      _Shortcut(
        'System Logs',
        'Nhật ký hệ thống',
        Icons.history_rounded,
        '/admin/system-logs',
        const Color(0xFF475569), // Slate
        const Color(0xFF64748B), // Slate Light
      ),
    ];

    return Scaffold(
      // Gradient background hiện đại
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0D14),
                    Color(0xFF0F1419),
                    Color(0xFF141923),
                  ],
                  stops: [0.0, 0.5, 1.0],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surface,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern AppBar với blur effect
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF151B24).withOpacity(0.8)
                          : Colors.white.withOpacity(0.8),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A3441).withOpacity(0.3)
                              : const Color(0xFFE0E0E0).withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: AppBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F2835).withOpacity(0.6)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFE8EAED)
                                : colorScheme.onSurface,
                          ),
                        ),
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go('/home'),
                      ),
                      title: Text(
                        'Admin Hub',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          fontSize: 24,
                          color: isDark
                              ? const Color(0xFFE8EAED)
                              : colorScheme.onSurface,
                        ),
                      ),
                      centerTitle: false,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Modern title với gradient effect
                        ShaderMask(
                          shaderCallback: (bounds) => isDark
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFE8EAED),
                                    Color(0xFFB4B9C4),
                                  ],
                                ).createShader(bounds)
                              : LinearGradient(
                                  colors: [
                                    colorScheme.onSurface,
                                    colorScheme.onSurfaceVariant,
                                  ],
                                ).createShader(bounds),
                          child: Text(
                            'Tính năng',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                              height: 1.1,
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Expanded(
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 18,
                              childAspectRatio: 0.88,
                            ),
                            itemCount: shortcuts.length,
                            itemBuilder: (context, index) {
                              final item = shortcuts[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 300 + (index * 100),
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: _ShortcutCard(
                                        item: item,
                                        delay: index * 50,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shortcut {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color primaryColor;
  final Color lightColor;
  const _Shortcut(
    this.title,
    this.subtitle,
    this.icon,
    this.route,
    this.primaryColor,
    this.lightColor,
  );
}

class _ShortcutCard extends StatefulWidget {
  final _Shortcut item;
  final int delay;
  const _ShortcutCard({required this.item, this.delay = 0});

  @override
  State<_ShortcutCard> createState() => _ShortcutCardState();
}

class _ShortcutCardState extends State<_ShortcutCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.1, end: 0.25).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            // Navigate to route, fallback to admin dashboard if route doesn't exist
            try {
              context.go(widget.item.route);
            } catch (e) {
              // If route doesn't exist yet, show coming soon or navigate to main admin page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.item.title} - Coming soon'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        });
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;

          return AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    // Glassmorphism effect với gradient đẹp hơn
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1A2332).withOpacity(0.95),
                              const Color(0xFF1F2835).withOpacity(0.9),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.cardColor,
                              theme.cardColor.withOpacity(0.95),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? widget.item.primaryColor
                              .withOpacity(0.08 + (_glowAnimation.value * 0.05))
                          : widget.item.primaryColor.withOpacity(0.06),
                      width: 0.8,
                    ),
                    boxShadow: [
                      // Rất tinh tế glow effect
                      BoxShadow(
                        color: widget.item.primaryColor.withOpacity(
                          isDark
                              ? (0.08 + (_glowAnimation.value * 0.05)) *
                                  (1 - _elevationAnimation.value)
                              : 0.05 * (1 - _elevationAnimation.value),
                        ),
                        blurRadius: isDark ? 16 : 14,
                        offset: Offset(0, 4 + 2 * _elevationAnimation.value),
                        spreadRadius: -4,
                      ),
                      // Main shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDark
                              ? 0.4 * (1 + _elevationAnimation.value)
                              : 0.06 * (1 - _elevationAnimation.value),
                        ),
                        blurRadius: isDark ? 20 : 18,
                        offset: Offset(
                            0, isDark ? 10 : 6 + 2 * _elevationAnimation.value),
                        spreadRadius: isDark ? -6 : -5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            try {
                              context.go(widget.item.route);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${widget.item.title} - Coming soon'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          splashColor:
                              widget.item.primaryColor.withOpacity(0.1),
                          highlightColor:
                              widget.item.primaryColor.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon container với glow rất tinh tế
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        widget.item.primaryColor,
                                        widget.item.lightColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      // Rất tinh tế glow
                                      BoxShadow(
                                        color: widget.item.primaryColor
                                            .withOpacity(
                                                0.25 +
                                                    (_glowAnimation.value *
                                                        0.1)),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                        spreadRadius: -3,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    widget.item.icon,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  widget.item.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.6,
                                    height: 1.2,
                                    color: isDark
                                        ? const Color(0xFFE8EAED)
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.item.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13.5,
                                    color: isDark
                                        ? const Color(0xFFB4B9C4)
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

