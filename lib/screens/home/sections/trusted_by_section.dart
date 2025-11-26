import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TrustedBySection extends StatefulWidget {
  const TrustedBySection({super.key});

  @override
  State<TrustedBySection> createState() => _TrustedBySectionState();
}

class _TrustedBySectionState extends State<TrustedBySection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final logos = List.generate(
      10,
      (index) => 'assets/images/slider-logo${index + 1}.png',
    );

    return Container(
      padding: EdgeInsets.only(
        top: isMobile ? 16 : 16,
        bottom: isMobile ? 48 : 64,
      ),
      color: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1280),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Text(
              tr('home.trustedBy.heading'),
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5E83CC),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 80,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final double offset = _animation.value * -1200; // Adjust based on logo width + gap
                    return Stack(
                      children: [
                        Positioned(
                          left: offset,
                          child: Row(
                            children: [
                              ...logos.map((logo) => Container(
                                width: 120,
                                margin: const EdgeInsets.symmetric(horizontal: 48),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    Colors.grey[600]!,
                                    BlendMode.saturation,
                                  ),
                                  child: Image.asset(
                                    logo,
                                    fit: BoxFit.contain,
                                    height: 80,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Text(
                                            'Logo ${logos.indexOf(logo) + 1}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )),
                              // Duplicate for seamless loop
                              ...logos.map((logo) => Container(
                                width: 120,
                                margin: const EdgeInsets.symmetric(horizontal: 48),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    Colors.grey[600]!,
                                    BlendMode.saturation,
                                  ),
                                  child: Image.asset(
                                    logo,
                                    fit: BoxFit.contain,
                                    height: 80,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Text(
                                            'Logo ${logos.indexOf(logo) + 1}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
