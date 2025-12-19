// lib/screens/huybro_products/widgets/draggable_cart_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../providers/huybro_cart/cart_provider.dart';
import '../../../utils/huybro_utils/glass_theme.dart';

class DraggableCartButton extends StatefulWidget {
  const DraggableCartButton({super.key});

  @override
  State<DraggableCartButton> createState() => _DraggableCartButtonState();
}

class _DraggableCartButtonState extends State<DraggableCartButton> {
  Offset position = const Offset(-1, -1);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cartProvider = context.watch<CartProvider>();
    final int cartCount = cartProvider.totalItemCount;

    // Khởi tạo vị trí sát lề phải
    if (position.dx == -1) {
      position = Offset(size.width - 64, size.height / 2);
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        // Feedback là cái bóng khi đang kéo
        feedback: _buildIcon(cartCount, cartProvider.badgeKey, isDragging: true),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            double newX = details.offset.dx;
            double newY = details.offset.dy;

            // Giới hạn biên màn hình
            if (newX < 16) newX = 16;
            if (newX > size.width - 64) newX = size.width - 64;
            if (newY < 100) newY = 100;
            if (newY > size.height - 150) newY = size.height - 150;

            position = Offset(newX, newY);
          });
        },
        child: _buildIcon(cartCount, cartProvider.badgeKey),
      ),
    );
  }

  Widget _buildIcon(int count, int badgeKey, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: isDragging ? null : () => context.push('/cart'),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                // Đổi sang màu tím đậm làm nền để Icon trắng nổi bật
                color: GlassTheme.primaryPurple.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: GlassTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(
                Ionicons.bag_handle, // Dùng icon bag_handle giống ở list của bạn
                color: Colors.white, // Icon màu trắng theo ý bạn
                size: 24,
              ),
            ),
          ),

          // Badge số lượng (Sử dụng màu đỏ hoặc màu store nhưng viền đậm hơn)
          if (count > 0)
            Positioned(
              right: -5,
              top: -5,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Container(
                  key: ValueKey<int>(badgeKey),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.redAccent, // Đỏ đậm cho nổi bật trên nền tím
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                      ]
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}