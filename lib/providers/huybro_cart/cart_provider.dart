import 'package:flutter/material.dart';
import '../../models/huybro_cart/cart_model.dart';
import '../../services/huybro_cart/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _service = CartService();

  CartModel? _cart;
  bool _isLoading = false;
  String _errorMessage = '';

  // Biến kiểm soát Animation badge (tăng lên mỗi khi add/remove)
  int _badgeKey = 0;

  // Tiền tệ đang chọn (Mặc định USD)
  String _currentCurrency = 'USD';

  CartModel? get cart => _cart;
  bool get isLoading => _isLoading;
  int get badgeKey => _badgeKey;
  String get currentCurrency => _currentCurrency;

  int get totalItemCount {
    if (_cart == null) return 0;
    return _cart!.items.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Luôn gọi preview để đảm bảo đúng tiền tệ đang chọn
      _cart = await _service.getCheckoutPreview(_currentCurrency);
    } catch (e) {
      debugPrint("Lỗi fetchCart: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(int productId, {int quantity = 1}) async {
    try {
      _cart = await _service.addToCart(productId, quantity);

      // Nếu đang ở mode VND, cần gọi lại preview để convert giá item vừa thêm
      if (_currentCurrency == 'VND') {
        _cart = await _service.getCheckoutPreview('VND');
      }

      _badgeKey++; // Kích hoạt animation
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      // Update quantity trả về USD gốc, nên nếu đang VND phải gọi preview lại
      await _service.updateQuantity(productId, quantity);
      await fetchCart(); // Reload đúng currency
    } catch (e) {
      debugPrint("Lỗi updateQuantity: $e");
    }
  }

  Future<void> removeItem(int productId) async {
    try {
      await _service.removeCartItem(productId);
      _badgeKey++; // Kích hoạt animation
      await fetchCart();
    } catch (e) {
      debugPrint("Lỗi removeItem: $e");
    }
  }

  // 2.  Hàm đổi tiền tệ (USD <-> VND)
  Future<void> switchCurrency(String currency) async {
    if (_currentCurrency == currency) return; // Nếu đang chọn rồi thì thôi

    _currentCurrency = currency;
    _isLoading = true;
    notifyListeners(); // Để hiện loading xoay xoay

    try {
      // Gọi API checkout-preview để BE tính toán lại giá tiền
      _cart = await _service.getCheckoutPreview(currency);
    } catch (e) {
      debugPrint("Lỗi switchCurrency: $e");
      // Nếu lỗi thì quay về currency cũ
      _currentCurrency = (currency == 'USD') ? 'VND' : 'USD';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      await _service.clearCart(); // Gọi API xóa giỏ hàng (nếu có)
      _cart = null; // Xóa dữ liệu local
      _badgeKey = 0; // Reset badge
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi clearCart: $e");
    }
  }
}