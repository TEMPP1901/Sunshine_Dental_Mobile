import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  // Xây dựng giao diện phần hero trên trang chủ (Hero section UI)
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.only(
        top: isMobile ? 48 : 96,
        bottom: isMobile ? 32 : 64,
        left: 0,
        right: 0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1280),
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 24 : 40,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F7F7), Color(0xFFE6EAF2), Color(0xFFAFD9F6)],
          ),
          borderRadius: BorderRadius.circular(80),
          border: Border.all(color: const Color(0xFFD1E3FF), width: 1),
        ),
        child: Column(
          children: [
            // Đoạn tiêu đề chính với hiệu ứng gradient
            Container(
              constraints: const BoxConstraints(maxWidth: 896),
              margin: const EdgeInsets.only(bottom: 48),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF60FFD2), Color(0xFF3366FF), Color(0xFF60FFD2)],
                  stops: [0.0, 0.56, 1.0],
                ).createShader(bounds),
                child: Text(
                  'Dental Care, Smile Everywhere!',
                  style: TextStyle(
                    fontSize: isMobile ? 48 : 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.02,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Lưới gồm hai avatar và nút CTA ở giữa
            Container(
              constraints: const BoxConstraints(maxWidth: 1152),
              margin: const EdgeInsets.only(bottom: 48),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 768) {
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/avatar-left.png',
                                  width: 140,
                                  height: 112,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 140,
                                      height: 112,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.person, size: 60),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    color: Colors.black87,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Your trusted\n'),
                                    TextSpan(
                                      text: 'Sunshine Dental',
                                      style: const TextStyle(
                                        color: Color(0xFF3366FF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Nút hành động chuyển đến trang giới thiệu phòng khám
                        Container(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFAACCFF), Color(0xFF6699FF), Color(0xFF3366FF)],
                                stops: [0.0, 0.5, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => context.go('/about'),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  child: const Text(
                                    "Learn more about us",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/avatar-right.png',
                                  width: 140,
                                  height: 112,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 140,
                                      height: 112,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.person, size: 60),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Modern facilities\nFriendly staff',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFAACCFF), Color(0xFF6699FF), Color(0xFF3366FF)],
                              stops: [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.go('/about'),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                child: const Text(
                                  "Learn more about us",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 32),

            // Ảnh chiếc răng trung tâm kèm các tag nổi bật (Tooth image with floating tags)
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/hero-tooth.png',
                  width: isMobile ? 300 : 500,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: isMobile ? 300 : 500,
                      height: isMobile ? 300 : 500,
                      color: Colors.grey[200],
                      child: const Icon(Icons.local_hospital, size: 100),
                    );
                  },
                ),

                // Tag nổi bật: Phòng ngừa
                Positioned(
                  top: 80,
                  left: isMobile ? 0 : -40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Color(0xFF3366FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Preventive Care',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: const Color(0xFF3366FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tag nổi bật: Hiện đại
                Positioned(
                  bottom: 80,
                  right: isMobile ? 0 : -40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Color(0xFF3366FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Modern Treatments',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: const Color(0xFF3366FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tag nổi bật: Trang thiết bị
                Positioned(
                  top: 80,
                  right: isMobile ? 0 : -40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.settings,
                          size: 16,
                          color: Color(0xFF3366FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Top Equipment',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: const Color(0xFF3366FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
