import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/huybro_cart/cart_provider.dart';
import '../../providers/huybro_checkout/checkout_provider.dart';
import '../../utils/huybro_utils/currency_helper.dart';
import '../../utils/huybro_utils/glass_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CheckoutProvider>(context, listen: false).loadContactInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final checkoutProvider = context.watch<CheckoutProvider>();
    final cart = cartProvider.cart;

    if (cart == null || cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Thanh toán")),
        body: Center(child: ElevatedButton(onPressed: () => context.go('/products'), child: const Text("Về cửa hàng"))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Thanh Toán", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Ionicons.chevron_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. INFO FORM ---
            const Text("Thông tin giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField("Họ tên", checkoutProvider.nameCtrl, Ionicons.person_outline),
            const SizedBox(height: 12),
            _buildTextField("Email", checkoutProvider.emailCtrl, Ionicons.mail_outline),
            const SizedBox(height: 12),
            _buildTextField("SĐT *", checkoutProvider.phoneCtrl, Ionicons.phone_portrait_outline, isNumber: true),
            const SizedBox(height: 12),
            _buildTextField("Địa chỉ *", checkoutProvider.addressCtrl, Ionicons.location_outline, hint: "Địa chỉ chi tiết"),
            const SizedBox(height: 12),
            _buildTextField("Ghi chú", checkoutProvider.noteCtrl, Icons.note_add_outlined, maxLines: 3),

            const SizedBox(height: 30),

            // --- 2. PAYMENT METHOD ---
            const Text("Phương thức thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMethodCard(
                    title: "COD",
                    icon: Ionicons.cash_outline,
                    value: "COD",
                    groupValue: checkoutProvider.selectedMethod,
                    onTap: () => checkoutProvider.setPaymentMethod("COD"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMethodCard(
                    title: "Online",
                    icon: Ionicons.card_outline,
                    value: "BANK",
                    groupValue: checkoutProvider.selectedMethod,
                    onTap: () => checkoutProvider.setPaymentMethod("BANK"),
                  ),
                ),
              ],
            ),

            // KHI CHỌN ONLINE -> HIỆN PAYPAL & VNPAY
            if (checkoutProvider.selectedMethod == 'BANK') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Chọn cổng thanh toán", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Nút PayPal
                        Expanded(
                          child: _buildChannelButton(
                            label: "PayPal",
                            // Dùng hình ảnh hoặc Icon
                            icon: Ionicons.logo_paypal,
                            color: const Color(0xFF0070BA),
                            value: "PAYPAL",
                            groupValue: checkoutProvider.selectedChannel,
                            onTap: () => checkoutProvider.setPaymentChannel("PAYPAL"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nút VNPay
                        Expanded(
                          child: _buildChannelButton(
                            label: "VNPay",
                            icon: Ionicons.qr_code_outline, // Hoặc icon VNPAY nếu có asset
                            color: Colors.red, // Màu đặc trưng VNPay
                            value: "VNPAY",
                            groupValue: checkoutProvider.selectedChannel,
                            onTap: () => checkoutProvider.setPaymentChannel("VNPAY"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),

      // --- 3. BOTTOM BUTTON ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tổng thanh toán", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(
                    CurrencyHelper.format(cart.totals.totalAfterTax, cart.currency),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: GlassTheme.primaryPurple),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // NÚT BẤM CHÍNH (Đã đồng bộ màu Tím)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: checkoutProvider.isLoading
                      ? null
                      : () => _handlePayment(context, checkoutProvider, cartProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.primaryPurple, // [FIX] LUÔN LUÔN TÍM
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: checkoutProvider.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          checkoutProvider.selectedMethod == 'COD' ? Ionicons.checkmark_circle : Ionicons.card,
                          size: 20, color: Colors.white
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getButtonLabel(checkoutProvider),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Label nút
  String _getButtonLabel(CheckoutProvider provider) {
    if (provider.selectedMethod == 'COD') return "Xác nhận đặt hàng";
    if (provider.selectedChannel == 'PAYPAL') return "Thanh toán PayPal";
    if (provider.selectedChannel == 'VNPAY') return "Thanh toán VNPay";
    return "Thanh toán";
  }

  // --- LOGIC XỬ LÝ (QUAN TRỌNG) ---
  Future<void> _handlePayment(BuildContext ctx, CheckoutProvider checkoutProvider, CartProvider cartProvider) async {
    // Validate
    if (checkoutProvider.addressCtrl.text.trim().isEmpty || checkoutProvider.phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin nhận hàng")));
      return;
    }

    try {
      // CASE 1: COD
      if (checkoutProvider.selectedMethod == 'COD') {
        await checkoutProvider.placeOrderCOD(currency: cartProvider.cart!.currency);
        if (ctx.mounted) _onSuccess(ctx, cartProvider);
        return;
      }

      // CASE 2: ONLINE (PAYPAL / VNPAY)
      String? paymentUrl;

      // A. Lấy URL thanh toán
      if (checkoutProvider.selectedChannel == 'PAYPAL') {
        // Cảnh báo nếu đang là VND
        if (cartProvider.cart!.currency == 'VND') {
          bool ok = await _showWarning(ctx, "PayPal chỉ hỗ trợ USD. Hệ thống sẽ tự quy đổi.");
          if (!ok) return;
        }
        paymentUrl = await checkoutProvider.createPaypalOrder();

      } else if (checkoutProvider.selectedChannel == 'VNPAY') {
        // Cảnh báo nếu đang là USD (VNPay chỉ VND)
        if (cartProvider.cart!.currency == 'USD') {
          bool ok = await _showWarning(ctx, "VNPay chỉ hỗ trợ VND. Hệ thống sẽ tính theo giá trị VND.");
          if (!ok) return;
        }
        paymentUrl = await checkoutProvider.createVnpayUrl();
      }

      // B. Mở trình duyệt
      if (paymentUrl != null) {
        final uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication); // Mở Chrome

          // C. Hiện Dialog xác nhận thủ công
          if (ctx.mounted) {
            _showConfirmDialog(ctx, checkoutProvider, cartProvider);
          }
        } else {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication); // Thử lại fallback
          } catch(e) {
            throw Exception("Không mở được trình duyệt");
          }
        }
      }

    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool> _showWarning(BuildContext context, String msg) async {
    return await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Lưu ý"),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Hủy")),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text("Tiếp tục")),
          ],
        )
    ) ?? false;
  }

  void _showConfirmDialog(BuildContext context, CheckoutProvider checkoutProvider, CartProvider cartProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Đang chờ thanh toán"),
        content: const Text("Vui lòng hoàn tất giao dịch trên trình duyệt, sau đó quay lại đây xác nhận."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GlassTheme.primaryPurple),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              try {
                if (checkoutProvider.selectedChannel == 'PAYPAL') {
                  await checkoutProvider.capturePaypalOrder();
                } else {
                  // VNPAY: Do localhost khó lấy params, hàm này có thể fail verify signature.
                  // Đây là điểm hạn chế của môi trường Dev Mobile + Localhost BE.
                  await checkoutProvider.verifyVnpayManually();
                }

                if (context.mounted) _onSuccess(context, cartProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chưa nhận được thanh toán: ${e.toString().replaceAll('Exception: ', '')}")));
                }
              }
            },
            child: const Text("Đã thanh toán xong", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onSuccess(BuildContext context, CartProvider provider) {
    provider.clearCart();
    context.go('/products');
    showDialog(context: context, builder: (_) => const AlertDialog(title: Text("Thành công"), content: Text("Đơn hàng đã được tạo!"), icon: Icon(Ionicons.checkmark_circle, color: Colors.green, size: 50)));
  }

  // --- WIDGETS ---
  // (Giữ nguyên các hàm _buildTextField, _buildMethodCard như cũ)

  // Widget nút chọn kênh thanh toán (PayPal/VNPay)
  Widget _buildChannelButton({required String label, required IconData icon, required Color color, required String value, required String groupValue, required VoidCallback onTap}) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.black87)),
          ],
        ),
      ),
    );
  }

  // Widget Card chọn COD/Online
  Widget _buildMethodCard({required String title, required IconData icon, required String value, required String groupValue, required VoidCallback onTap}) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? GlassTheme.primaryPurple.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? GlassTheme.primaryPurple : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? GlassTheme.primaryPurple : Colors.grey),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? GlassTheme.primaryPurple : Colors.black87)),
          ],
        ),
      ),
    );
  }
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            maxLines: maxLines,
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.grey, size: 20),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}