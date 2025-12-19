import 'package:flutter/material.dart';
import '../../models/huybro_checkout/checkout_models.dart';
import '../../services/huybro_checkout/checkout_service.dart';

class CheckoutProvider extends ChangeNotifier {
  final CheckoutService _service = CheckoutService();

  bool _isLoading = false;

  // Form Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  // Payment State
  String _selectedMethod = 'COD';
  String _selectedChannel = 'CASH_ON_DELIVERY';
  String? _paypalOrderId;

  bool get isLoading => _isLoading;
  String get selectedMethod => _selectedMethod;
  String get selectedChannel => _selectedChannel;

  // ... (Code loadContactInfo, setPaymentMethod cũ giữ nguyên) ...
  Future<void> loadContactInfo() async {
    _isLoading = true; notifyListeners();
    try {
      final info = await _service.getContactInfo();
      nameCtrl.text = info.fullName; emailCtrl.text = info.email; phoneCtrl.text = info.phone;
    } catch (e) { debugPrint("$e"); } finally { _isLoading = false; notifyListeners(); }
  }

  void setPaymentMethod(String method) {
    _selectedMethod = method;
    if (method == 'COD') {
      _selectedChannel = 'CASH_ON_DELIVERY';
    } else {
      _selectedChannel = 'PAYPAL'; // Mặc định
    }
    notifyListeners();
  }

  void setPaymentChannel(String channel) {
    _selectedChannel = channel;
    notifyListeners();
  }

  // --- LOGIC GOM REQUEST ---
  CheckoutRequestModel _buildRequest({required String currency}) {
    return CheckoutRequestModel(
      paymentType: _selectedMethod == 'COD' ? 'COD' : 'BANK_TRANSFER',
      paymentChannel: _selectedChannel,
      currency: currency,
      customerFullName: nameCtrl.text,
      customerEmail: emailCtrl.text,
      customerPhone: phoneCtrl.text,
      shippingAddress: addressCtrl.text,
      note: noteCtrl.text,
    );
  }

  // --- 1. COD ---
  Future<CheckoutInvoiceModel> placeOrderCOD({required String currency}) async {
    _isLoading = true; notifyListeners();
    try {
      final request = _buildRequest(currency: currency);
      return await _service.createInvoice(request);
    } catch (e) { rethrow; } finally { _isLoading = false; notifyListeners(); }
  }

  // --- 2. PAYPAL ---
  Future<String?> createPaypalOrder() async {
    _isLoading = true; notifyListeners();
    try {
      final result = await _service.createPaypalOrder();
      _paypalOrderId = result['orderId'];
      return result['approveUrl'];
    } catch (e) { rethrow; } finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> capturePaypalOrder() async {
    if (_paypalOrderId == null) throw Exception("Mất kết nối phiên PayPal");
    _isLoading = true; notifyListeners();
    try {
      final request = _buildRequest(currency: 'USD'); // PayPal luôn là USD
      await _service.capturePaypalOrder(_paypalOrderId!, request);
      _paypalOrderId = null;
    } catch (e) { rethrow; } finally { _isLoading = false; notifyListeners(); }
  }

  // --- 3. VNPAY (NEW) ---

  // Bước 1: Lấy URL
  Future<String> createVnpayUrl() async {
    _isLoading = true; notifyListeners();
    try {
      // Backend sẽ lấy IP, Amount từ Session Cart
      return await _service.createVnpayUrl();
    } catch (e) { rethrow; } finally { _isLoading = false; notifyListeners(); }
  }

  // Bước 2: Verify (Sau khi user quay lại)
  // NOTE: Do hạn chế Localhost, ta khó lấy được params chính xác.
  // Hàm này thiết kế để nhận params nếu sau này bạn làm Deep Link.
  Future<void> verifyVnpayManually() async {
    _isLoading = true; notifyListeners();
    try {
      // Vì đang chạy localhost và manual check, App không có params thực tế từ URL.
      // -> Gửi request với params rỗng hoặc giả lập để Backend check trạng thái (nếu backend hỗ trợ check ngược IPN).
      // Tuy nhiên, với Controller bạn đưa, nó bắt buộc cần vnpParams để hash check.
      // Dưới đây là giả lập gửi request, khả năng cao sẽ Fail hash nếu không có params thực.

      final request = _buildRequest(currency: 'VND'); // VNPay luôn là VND
      Map<String, String> emptyParams = {};

      await _service.verifyVnpay(emptyParams, request);

    } catch (e) {
      // Do cơ chế localhost khó lấy params, ta có thể chấp nhận rủi ro ném lỗi ở đây
      // hoặc handle riêng.
      rethrow;
    } finally { _isLoading = false; notifyListeners(); }
  }
}