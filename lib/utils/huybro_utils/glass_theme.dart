import 'package:flutter/material.dart';
import 'dart:ui';

class GlassTheme {
  // --- PALETTE: TÍM ÁNH XANH DƯƠNG ---
  static const Color primaryPurple = Color(0xFF6200EA); // Tím đậm
  static const Color neonPurple   = Color(0xFFD500F9); // Tím sáng (Neon)
  static const Color neonBlue     = Color(0xFF00E5FF); // Xanh dương sáng (Ánh)
  static const Color priceColor   = Color(0xFFFF2E63); // Đỏ hồng nổi bật cho giá
  static const Color textDark     = Color(0xFF2E0063); // Màu chữ tím đen

  // Gradient Tím sang Xanh (Mystic Aurora)
  static const LinearGradient mainGradient = LinearGradient(
    colors: [primaryPurple, Color(0xFF304FFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background nhạt hơn cho toàn màn hình
  static const BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF3E5F5), Color(0xFFE3F2FD)], // Tím nhạt pha xanh nhạt
    ),
  );

  // Hiệu ứng kính với bóng Tím/Xanh
  static BoxDecoration glassDecoration({double radius = 16, Color? color}) {
    return BoxDecoration(
      color: color ?? Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(0.6),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withOpacity(0.15), // Bóng tím
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: neonBlue.withOpacity(0.1), // Ánh xanh nhẹ
          blurRadius: 10,
          offset: const Offset(2, 2),
        ),
      ],
    );
  }

  // Wrapper Widget
  static Widget glassContainer({
    required Widget child,
    double radius = 16,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: padding,
          decoration: glassDecoration(radius: radius),
          child: child,
        ),
      ),
    );
  }
}