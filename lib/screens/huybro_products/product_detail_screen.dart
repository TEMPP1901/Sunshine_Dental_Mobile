import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../providers/huybro_cart/cart_provider.dart';
import '../../providers/huybro_products/product_provider.dart';
import '../../services/api_service.dart';
import '../../utils/huybro_utils/glass_theme.dart';
import '../../utils/huybro_utils/currency_helper.dart';
import '../../models/huybro_products/product_model.dart';
import 'widgets/draggable_cart_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.fetchProductDetail(widget.productId);
      provider.fetchNewArrivals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: false,
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = provider.selectedProduct;
          if (product == null) {
            return const Center(child: Text("Sản phẩm không tồn tại."));
          }

          // [FIX 1] Khai báo biến isOutOfStock ở đây để dùng được bên dưới
          final bool isOutOfStock = product.unit <= 0;

          final images = product.images;
          final bool hasMultipleImages = images.length > 1;
          final bool hasDiscount =
              (product.originalPrice != null) &&
              (product.originalPrice! > product.defaultRetailPrice);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // --- 1. APP BAR & SLIDER ---
                  SliverAppBar(
                    expandedHeight: 420,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: IconButton(
                          icon: const Icon(
                            Ionicons.chevron_back,
                            color: Colors.black87,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    actions: [
                      // [FIX 2] Sửa lại nút giỏ hàng cho đúng cú pháp và màu sắc
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            // Nền tím nhạt giống ProductItemCard
                            color: isOutOfStock
                                ? Colors.grey[200]
                                : GlassTheme.primaryPurple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: isOutOfStock
                                ? null
                                : () async {
                                    try {
                                      // [BƯỚC CHÍNH]: Gọi logic thêm vào giỏ hàng thật
                                      await Provider.of<CartProvider>(
                                        context,
                                        listen: false,
                                      ).addToCart(product.productId);

                                      // Thông báo thành công
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Đã thêm ${product.productName} vào giỏ",
                                            ),
                                            backgroundColor:
                                                GlassTheme.primaryPurple,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Thông báo lỗi nếu Backend trả về lỗi (hết hàng, v.v.)
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Lỗi thêm vào giỏ hàng",
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: Icon(
                              Ionicons.bag_handle_outline,
                              // Icon màu tím giống ProductItemCard
                              color: isOutOfStock
                                  ? Colors.grey
                                  : GlassTheme.primaryPurple,
                              size: 22, // Size to hơn 1 chút vì ở AppBar
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: images.isNotEmpty ? images.length : 1,
                            onPageChanged: (index) =>
                                setState(() => _currentImageIndex = index),
                            itemBuilder: (context, index) {
                              if (images.isEmpty) {
                                return Container(color: Colors.grey[100]);
                              }
                              return Image(
                                image: ApiService.resolveAvatarImage(
                                  images[index].imageUrl,
                                ),
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          if (hasMultipleImages)
                            Positioned(
                              bottom: 60,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: images.asMap().entries.map((entry) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: _currentImageIndex == entry.key
                                        ? 24
                                        : 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _currentImageIndex == entry.key
                                          ? GlassTheme.primaryPurple
                                          : Colors.grey.withOpacity(0.5),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // --- 2. NỘI DUNG CHI TIẾT ---
                  SliverToBoxAdapter(
                    child: Container(
                      transform: Matrix4.translationValues(0, -40, 0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      // [QUAN TRỌNG]: Bỏ padding bottom (set về 0) để nội dung chạy sát xuống dưới
                      padding: const EdgeInsets.only(
                        top: 24,
                        left: 24,
                        right: 24,
                        bottom: 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Header: Brand + Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (product.brand != null)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GlassTheme.primaryPurple
                                              .withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          product.brand!.toUpperCase(),
                                          style: const TextStyle(
                                            color: GlassTheme.primaryPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      product.productName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: GlassTheme.textDark,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Price Column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyHelper.format(
                                      product.defaultRetailPrice,
                                      product.currency,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: GlassTheme.primaryPurple,
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Text(
                                      CurrencyHelper.format(
                                        product.originalPrice!,
                                        product.currency,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Sold count & Tags
                          Row(
                            children: [
                              Text(
                                "(${product.soldCount} đã bán)",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Wrap(
                                spacing: 6,
                                children: product.typeNames
                                    .take(2)
                                    .map(
                                      (t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          t,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),

                          // Social Proof
                          if (product.recentPurchases.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    GlassTheme.primaryPurple.withOpacity(0.05),
                                    Colors.white,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: GlassTheme.primaryPurple.withOpacity(
                                    0.1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Ionicons.flame,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Mới được mua gần đây",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          "${product.recentPurchases.first.customerName} vừa mua ${product.recentPurchases.first.quantity} sản phẩm",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Mô tả
                          const SizedBox(height: 30),
                          const Text(
                            "Mô tả chi tiết",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product.productDescription ?? "Đang cập nhật...",
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Color(0xFF546E7A),
                            ),
                          ),

                          const Divider(height: 50),

                          // --- 1. SẢN PHẨM CÙNG LOẠI ---
                          if (product.relatedProducts.isNotEmpty) ...[
                            _buildSectionHeader(
                              "Sản phẩm tương tự",
                              icon: Ionicons.layers_outline,
                            ),
                            _buildProductHorizontalList(
                              product.relatedProducts.take(5).toList(),
                            ),
                            const SizedBox(height: 30),
                          ],

                          // --- 2. SẢN PHẨM MỚI ---
                          if (provider.newArrivals.isNotEmpty) ...[
                            _buildSectionHeader(
                              "Hàng mới về",
                              icon: Ionicons.sparkles_outline,
                            ),
                            _buildProductHorizontalList(provider.newArrivals),
                          ],

                          // [QUAN TRỌNG]: Đã xóa hoàn toàn khoảng trống cuối cùng
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // --- ĐẶT GIỎ HÀNG DI ĐỘNG Ở ĐÂY ---
              const DraggableCartButton(),
            ],
          );
        },
      ),
    );
  }

  // Widget helper
  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: GlassTheme.primaryPurple, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GlassTheme.textDark,
                ),
              ),
            ],
          ),
          const Icon(Ionicons.arrow_forward, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildProductHorizontalList(List<ProductModel> products) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final p = products[index];
          return GestureDetector(
            onTap: () => context.push('/products/${p.productId}'),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        // Chỉ giữ lại ảnh, đã xóa Positioned (nút +) ở đây
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image(
                            image: ApiService.resolveAvatarImage(p.thumbnail),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            CurrencyHelper.format(
                              p.defaultRetailPrice,
                              p.currency,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: GlassTheme.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
