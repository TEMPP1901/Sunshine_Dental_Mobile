// lib/screens/huybro_cart/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../providers/huybro_cart/cart_provider.dart';
import '../../utils/huybro_utils/currency_helper.dart';
import '../../utils/huybro_utils/glass_theme.dart';
import '../../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mặc định fetch USD
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Giỏ hàng", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Ionicons.chevron_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: cartProvider.isLoading && cart == null
          ? const Center(child: CircularProgressIndicator(color: GlassTheme.primaryPurple))
          : cart == null || cart.items.isEmpty
          ? _buildEmptyCart()
          : Column(
        children: [
          // --- 1. DANH SÁCH SẢN PHẨM ---
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return _buildCartItem(item, cart.currency, cartProvider);
              },
            ),
          ),

          // --- 2. BOTTOM SUMMARY (PHẲNG - ĐỒNG BỘ CHECKOUT) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              // Đã bỏ borderRadius và boxShadow để đồng bộ Checkout
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSummaryRow("Tạm tính", cart.totals.subTotalBeforeTax, cart.currency),
                  const SizedBox(height: 8),
                  _buildSummaryRow("Tổng thuế", cart.totals.totalAfterTax - cart.totals.subTotalBeforeTax, cart.currency, isHighlight: true),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng thanh toán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        CurrencyHelper.format(cart.totals.totalAfterTax, cart.currency),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.push('/checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassTheme.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0, // Phẳng hoàn toàn
                      ),
                      child: const Text("Tiến hành thanh toán", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Ionicons.cart_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Giỏ hàng đang trống", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item, String currency, CartProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: ApiService.resolveAvatarImage(item.mainImageUrl),
                  width: 60, height: 60, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(item.brand, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildRowDetail("Đơn giá", CurrencyHelper.format(item.unitPriceBeforeTax, currency)),
          _buildRowDetail("Thuế (${item.taxRatePercent}%)", "+ ${CurrencyHelper.format(item.taxAmount, currency)}", isOrange: true),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Picker
              Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Ionicons.remove, size: 16),
                      onPressed: () => item.quantity > 1 ? provider.updateQuantity(item.productId, item.quantity - 1) : provider.removeItem(item.productId),
                    ),
                    Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Ionicons.add, size: 16),
                      onPressed: () => provider.updateQuantity(item.productId, item.quantity + 1),
                    ),
                  ],
                ),
              ),
              Text(CurrencyHelper.format(item.lineTotalAmount, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GlassTheme.primaryPurple)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isOrange = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isOrange ? Colors.orange[800] : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, String currency, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isHighlight ? Colors.orange[800] : Colors.grey[600])),
        Text(
          CurrencyHelper.format(amount, currency),
          style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500, color: isHighlight ? Colors.orange[800] : Colors.black),
        ),
      ],
    );
  }
}