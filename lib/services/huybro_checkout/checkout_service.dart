import 'package:dio/dio.dart';
import '../api_service.dart';
import '../../models/huybro_checkout/checkout_models.dart';

class CheckoutService {
  final ApiService _apiService = ApiService();

  // ... (Các hàm getContactInfo, createInvoice, createPaypalOrder giữ nguyên) ...

  // --- PART 1: GIỮ NGUYÊN CODE CŨ ---
  Future<ContactInfoModel> getContactInfo() async {
    try {
      final response = await _apiService.get('/api/checkout/contact-info');
      return ContactInfoModel.fromJson(response.data);
    } catch (e) {
      return ContactInfoModel(fullName: '', email: '', phone: '');
    }
  }

  Future<CheckoutInvoiceModel> createInvoice(CheckoutRequestModel request) async {
    try {
      final response = await _apiService.post('/api/checkout/invoices', data: request.toJson());
      return CheckoutInvoiceModel.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPaypalOrder() async {
    try {
      final response = await _apiService.post('/api/checkout/paypal/create-order');
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<CheckoutInvoiceModel> capturePaypalOrder(String orderId, CheckoutRequestModel request) async {
    try {
      final response = await _apiService.post(
        '/api/checkout/paypal/capture',
        queryParameters: {'token': orderId},
        data: request.toJson(),
      );
      return CheckoutInvoiceModel.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // --- PART 2: THÊM VNPAY ---

  // 1. Tạo URL thanh toán VNPay
  // Backend trả về: { "paymentUrl": "https://sandbox.vnpayment.vn/..." }
  Future<String> createVnpayUrl() async {
    try {
      final response = await _apiService.post('/api/checkout/vnpay/create-payment-url');
      return response.data['paymentUrl']; // Lấy trường paymentUrl từ DTO trả về
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // 2. Verify VNPay (Cần truyền toàn bộ Query Params mà VNPay trả về)
  // Backend: @RequestParam Map<String, String> vnpParams
  Future<CheckoutInvoiceModel> verifyVnpay(Map<String, String> vnpParams, CheckoutRequestModel request) async {
    try {
      final response = await _apiService.post(
        '/api/checkout/vnpay/verify-and-capture',
        queryParameters: vnpParams, // Gửi toàn bộ params lên URL
        data: request.toJson(),     // Body chứa info user
      );
      return CheckoutInvoiceModel.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(dynamic e) {
    if (e is DioException && e.response != null) {
      throw Exception(e.response?.data['message'] ?? 'Có lỗi xảy ra từ hệ thống');
    }
    throw Exception('Lỗi kết nối: $e');
  }
}