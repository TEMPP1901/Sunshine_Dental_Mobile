import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HrHubPage extends StatefulWidget {
  const HrHubPage({super.key});

  @override
  State<HrHubPage> createState() => _HrHubPageState();
}

class _HrHubPageState extends State<HrHubPage> with TickerProviderStateMixin {
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

    final shortcuts = [
      _Shortcut(
        'hr.shortcuts.employees.title'.tr(),
        'hr.shortcuts.employees.subtitle'.tr(),
        Icons.people_alt_rounded,
        '/hr/employees',
        const Color(0xFF6D28D9), // Darker Purple
        const Color(0xFF7C3AED), // Darker Purple Light
      ),
      _Shortcut(
        'hr.shortcuts.attendance.title'.tr(),
        'hr.shortcuts.attendance.subtitle'.tr(),
        Icons.history_rounded,
        '/hr/attendance-history',
        const Color(0xFF0E7490), // Darker Cyan
        const Color(0xFF06B6D4), // Darker Cyan Light
      ),
      _Shortcut(
        'hr.shortcuts.schedules.title'.tr(),
        'hr.shortcuts.schedules.subtitle'.tr(),
        Icons.calendar_today_rounded,
        '/hr/schedules',
        const Color(0xFF047857), // Darker Green
        const Color(0xFF10B981), // Darker Green Light
      ),
      _Shortcut(
        'hr.shortcuts.faceApprovals.title'.tr(),
        'hr.shortcuts.faceApprovals.subtitle'.tr(),
        Icons.face_retouching_natural_rounded,
        '/hr/face-approvals',
        const Color(0xFFB45309), // Darker Orange
        const Color(0xFFF59E0B), // Darker Orange Light
      ),
      _Shortcut(
        'hr.shortcuts.approvedLeaves.title'.tr(),
        'hr.shortcuts.approvedLeaves.subtitle'.tr(),
        Icons.check_circle_rounded,
        '/hr/approved-leaves',
        const Color(0xFF0F766E), // Darker Teal
        const Color(0xFF14B8A6), // Darker Teal Light
      ),
      _Shortcut(
        'hr.shortcuts.pendingExplanations.title'.tr(),
        'hr.shortcuts.pendingExplanations.subtitle'.tr(),
        Icons.description_rounded,
        '/hr/pending-explanations',
        const Color(0xFFBE185D), // Darker Pink
        const Color(0xFFEC4899), // Darker Pink Light
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
                        'hr.title'.tr(),
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
                            'hr.features'.tr(),
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
  const _Shortcut(this.title, this.subtitle, this.icon, this.route, this.primaryColor, this.lightColor);
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
          if (mounted) context.go(widget.item.route);
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
                        offset: Offset(0, isDark ? 10 : 6 + 2 * _elevationAnimation.value),
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
                          onTap: () => context.go(widget.item.route),
                          splashColor: widget.item.primaryColor.withOpacity(0.1),
                          highlightColor: widget.item.primaryColor.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
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
                                        color: widget.item.primaryColor.withOpacity(
                                          0.25 + (_glowAnimation.value * 0.1),
                                        ),
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
                                const SizedBox(height: 6),
                                Flexible(
                                  child: Text(
                                    widget.item.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFFB4B9C4)
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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


