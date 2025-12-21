import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart'; // Import Ionicons
import '../../../models/huybro_products/product_model.dart';
import '../../../services/api_service.dart';
import '../../../utils/huybro_utils/glass_theme.dart';
import '../../../utils/huybro_utils/currency_helper.dart';

class ProductItemCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onBuyNow;

  const ProductItemCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = product.unit <= 0;

    // Lấy thông tin Brand và Type
    final String brandText = product.brand?.toUpperCase() ?? '';
    final String typeText = product.typeNames.isNotEmpty
        ? product.typeNames.first
        : '';
    // Ghép chuỗi hiển thị: "BRAND • Type"
    final String metaText = [
      brandText,
      typeText,
    ].where((e) => e.isNotEmpty).join(' • ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Bo góc vừa phải cho Card
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ẢNH SẢN PHẨM (Phần trên) ---
            Expanded(
              flex: 6, // Ảnh chiếm 6 phần
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      image: DecorationImage(
                        image: ApiService.resolveAvatarImage(product.thumbnail),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Badge % Giảm giá (Góc phải trên)
                  if (product.discountPercentage != null &&
                      product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GlassTheme.priceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discountPercentage!.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Badge Hết hàng (Góc trái trên)
                  if (isOutOfStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'HẾT HÀNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- 2. THÔNG TIN & HÀNH ĐỘNG (Phần dưới) ---
            Expanded(
              flex: 5, // Tăng không gian cho text một chút (4 -> 5)
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // A. Meta Data: Brand & Type
                    if (metaText.isNotEmpty)
                      Text(
                        metaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors
                              .grey[500], // Màu nhạt để làm nền cho tên SP
                          letterSpacing: 0.3,
                        ),
                      ),

                    // B. Tên sản phẩm
                    Text(
                      product.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: GlassTheme.textDark,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4), // Khoảng cách nhỏ
                    // C. Giá tiền & Nút Giỏ hàng (Row dưới cùng)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cột Giá
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Giá gốc (Gạch ngang)
                              if (product.originalPrice != null &&
                                  product.originalPrice! >
                                      product.defaultRetailPrice)
                                Text(
                                  CurrencyHelper.format(
                                    product.originalPrice!,
                                    product.currency,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 10,
                                  ),
                                ),
                              // Giá bán (Màu Tím)
                              Text(
                                CurrencyHelper.format(
                                  product.defaultRetailPrice,
                                  product.currency,
                                ),
                                style: const TextStyle(
                                  color: GlassTheme.primaryPurple,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Nút Giỏ Hàng (Góc phải dưới - Thuận tay phải)
                        InkWell(
                          onTap: isOutOfStock ? null : onBuyNow,
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              // Nền tím nhạt để nổi bật nhưng không quá gắt trên nền trắng
                              color: isOutOfStock
                                  ? Colors.grey[200]
                                  : GlassTheme.primaryPurple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Ionicons
                                  .bag_handle_outline, // Đã đổi sang icon túi xách
                              size: 18,
                              color: isOutOfStock
                                  ? Colors.grey
                                  : GlassTheme.primaryPurple, // Màu icon tím
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
