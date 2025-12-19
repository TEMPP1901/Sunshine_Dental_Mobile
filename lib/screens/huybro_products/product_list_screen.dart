import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:sunshine_denttal_mobile/screens/huybro_products/widgets/draggable_cart_button.dart';
import 'package:sunshine_denttal_mobile/screens/huybro_products/widgets/product_filter_sheet.dart';

import '../../providers/huybro_cart/cart_provider.dart';
import '../../providers/huybro_products/product_provider.dart';
import '../../utils/huybro_utils/glass_theme.dart';
import '../home/sections/quick_actions_bar.dart';
import 'widgets/product_item_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isFilterMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(isRefresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Column(
            children: [
              // --- 1. HEADER ---
              _buildAnimatedHeader(context),

              // --- 2. GRID VIEW ---
              Expanded(
                child: Consumer<ProductProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.products.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: GlassTheme.primaryPurple));
                    }

                    if (provider.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Ionicons.cube_outline, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            const Text("Không tìm thấy sản phẩm", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: GlassTheme.primaryPurple,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await provider.fetchProducts(isRefresh: true);
                      },
                      child: GridView.builder(
                        controller: _scrollController,
                        // [SỬA 1]: Giảm padding bottom từ 100 xuống 20 để xóa khoảng trắng thừa ở dưới
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: provider.products.length + (provider.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.products.length) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2, color: GlassTheme.primaryPurple),
                            ));
                          }

                          final product = provider.products[index];
                          return ProductItemCard(
                            product: product,
                            onTap: () => context.push('/products/${product.productId}'),
                            onBuyNow: () async {
                              try {
                                // Gọi Provider để thêm vào giỏ
                                await Provider.of<CartProvider>(context, listen: false).addToCart(product.productId);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Đã thêm ${product.productName} vào giỏ"),
                                    backgroundColor: GlassTheme.primaryPurple,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Lỗi thêm vào giỏ hàng")),
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const DraggableCartButton(),
          // --- 3. BOTTOM BAR ---
          const Positioned(
            left: 20, right: 20, bottom: 20,
            child: QuickActionsBar(),
          ),
        ],
      ),
    );
  }

  // --- HEADER ANIMATION ---
  Widget _buildAnimatedHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: _isFilterMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,

        // --- STATE 1: SEARCH BAR ---
        firstChild: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: const BoxDecoration(
                  // [SỬA 2]: Đổi thành Transparent để xóa cái khung xám bao quanh
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8), // Giảm margin trái xíu vì đã bỏ khung
                    const Icon(Ionicons.search_outline, color: Colors.grey, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        decoration: const InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        onSubmitted: (val) {
                          Provider.of<ProductProvider>(context, listen: false).setKeyword(val);
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Ionicons.close_circle, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<ProductProvider>(context, listen: false).setKeyword('');
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nút Filter
            GestureDetector(
              onTap: () => setState(() => _isFilterMode = true),
              child: Container(
                height: 48, width: 48,
                decoration: BoxDecoration(
                  color: GlassTheme.primaryPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Ionicons.options_outline, color: GlassTheme.primaryPurple, size: 24),
              ),
            ),
          ],
        ),

        // --- STATE 2: FILTER BAR ---
        secondChild: SizedBox(
          height: 48,
          child: Row(
            children: [
              // Nút quay lại Search
              GestureDetector(
                onTap: () => setState(() => _isFilterMode = false),
                child: Container(
                  height: 48, width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Ionicons.search_outline, color: Colors.black54, size: 22),
                ),
              ),
              const SizedBox(width: 12),

              // Thanh lọc ngang
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      label: "Brand",
                      icon: Ionicons.pricetag_outline,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const FilterSelectionSheet(title: "Chọn Thương Hiệu", filterType: "brand"),
                      ),
                    ),

                    _buildFilterChip(
                      label: "Type",
                      icon: Ionicons.shapes_outline,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const FilterSelectionSheet(title: "Chọn Loại", filterType: "type"),
                      ),
                    ),

                    _buildFilterChip(
                      label: "Giá",
                      icon: Ionicons.swap_vertical_outline,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SortSelectionSheet(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Chip
  Widget _buildFilterChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
            ]
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: GlassTheme.primaryPurple),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GlassTheme.primaryPurple)),
            const SizedBox(width: 4),
            const Icon(Ionicons.chevron_down, size: 12, color: GlassTheme.primaryPurple),
          ],
        ),
      ),
    );
  }
}