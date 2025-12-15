import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TrustedByBanner extends StatefulWidget {
  const TrustedByBanner({super.key});

  @override
  State<TrustedByBanner> createState() => _TrustedByBannerState();
}

class _TrustedByBannerState extends State<TrustedByBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  static const double _itemSize = 56;
  static const double _spacing = 20;
  final _logos = List.generate(
    10,
    (index) => 'assets/images/slider-logo${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _badge(BuildContext context, String asset) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _itemSize,
      height: _itemSize,
      margin: const EdgeInsets.only(right: _spacing),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.insert_emoticon, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home.trustedBy.heading'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _itemSize,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final offset = _animation.value * -1200;
                  return Stack(
                    children: [
                      Positioned(
                        left: offset,
                        child: Row(
                          children: [
                            ..._logos.map((logo) => _badge(context, logo)),
                            ..._logos.map((logo) => _badge(context, logo)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
