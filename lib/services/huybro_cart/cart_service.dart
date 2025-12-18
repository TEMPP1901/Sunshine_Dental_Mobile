import 'package:dio/dio.dart';
import '../../models/huybro_cart/cart_model.dart';
import '../api_service.dart';

class CartService {
  final ApiService _apiService = ApiService();

  // 1. Lấy giỏ hàng mặc định
  Future<CartModel> getCartDetail() async {
    try {
      final response = await _apiService.get('/api/cart');
      return CartModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tải giỏ hàng: $e');
    }
  }

  // 2. Thêm vào giỏ
  Future<CartModel> addToCart(int productId, int quantity) async {
    try {
      final response = await _apiService.post(
        '/api/cart/items',
        data: {'productId': productId, 'quantity': quantity},
      );
      return CartModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Lỗi thêm giỏ hàng');
      }
      throw Exception('Lỗi: $e');
    }
  }

  // 3. Cập nhật số lượng
  Future<CartModel> updateQuantity(int productId, int quantity) async {
    try {
      final response = await _apiService.put(
        '/api/cart/items',
        data: {'productId': productId, 'quantity': quantity},
      );
      return CartModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi cập nhật: $e');
    }
  }

  // 4. Xóa item
  Future<CartModel> removeCartItem(int productId) async {
    try {
      final response = await _apiService.delete('/api/cart/items/$productId');
      return CartModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi xóa sản phẩm: $e');
    }
  }

  // 5. Xóa toàn bộ giỏ (Clear cart)
  Future<void> clearCart() async {
    try {
      await _apiService.delete('/api/cart');
    } catch (e) {
      throw Exception('Lỗi xóa giỏ hàng: $e');
    }
  }

  // 6. Preview theo tiền tệ (USD/VND)
  // [QUAN TRỌNG]: Chỉ giữ lại 1 hàm này thôi
  Future<CartModel> getCheckoutPreview(String currency) async {
    try {
      final response = await _apiService.get(
        '/api/cart/checkout-preview',
        queryParameters: {'currency': currency},
      );
      return CartModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi đổi tiền tệ: $e');
    }
  }
}