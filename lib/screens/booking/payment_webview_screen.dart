import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'booking_success_page.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final int appointmentId;
  final String paymentMethod; // 'VNPAY' hoặc 'PAYPAL'

  const PaymentWebViewScreen({
    super.key,
    required this.appointmentId,
    required this.paymentMethod,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;
  String? errorMessage;

  // ⚠️ CẤU HÌNH IP BACKEND (Quan trọng)
  // Nếu chạy máy ảo Android: dùng 10.0.2.2
  // Nếu chạy máy thật: dùng IP LAN (ví dụ 192.168.1.x)
  final String baseUrl = 'http://10.0.2.2:8080/api/booking/payment';

  @override
  void initState() {
    super.initState();
    _initWebView(); // Khởi tạo controller trước
    _fetchPaymentUrl(); // Sau đó mới gọi API lấy link
  }

  // 1. Khởi tạo WebView Controller
  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          // 🔥 QUAN TRỌNG: Bắt sự kiện khi cổng thanh toán redirect về
          onNavigationRequest: (NavigationRequest request) {
            // Check link Return URL mà Backend đã config (http://localhost:5173...)
            if (request.url.contains('payment-result')) {
              _handleReturnUrl(request.url);
              return NavigationDecision.prevent; // Chặn không cho load trang localhost lỗi
            }

            // Check link Cancel/Error
            if (request.url.contains('cancel') || request.url.contains('error')) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Thanh toán bị hủy hoặc gặp lỗi")),
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
  }

  // 2. Lấy Token xác thực
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  // 3. Gọi API lấy link thanh toán ban đầu
  Future<void> _fetchPaymentUrl() async {
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      String? startUrl;

      if (widget.paymentMethod == 'VNPAY') {
        // Gọi GET /vnpay/url
        final uri = Uri.parse('$baseUrl/vnpay/url?appointmentId=${widget.appointmentId}');
        final res = await http.get(uri, headers: headers);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          startUrl = data['paymentUrl'];
        } else {
          throw Exception("Lỗi VNPAY: ${res.body}");
        }
      } else {
        // Gọi POST /paypal/create
        final uri = Uri.parse('$baseUrl/paypal/create?appointmentId=${widget.appointmentId}');
        final res = await http.post(uri, headers: headers); // Create Order dùng POST

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          // Backend trả về: { "orderId": "...", "approveUrl": "..." }
          startUrl = data['approveUrl'];
        } else {
          throw Exception("Lỗi PayPal: ${res.body}");
        }
      }

      if (startUrl != null) {
        _controller.loadRequest(Uri.parse(startUrl));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // 4. Xử lý khi thanh toán xong (Redirect về)
  Future<void> _handleReturnUrl(String url) async {
    setState(() => isLoading = true); // Hiện loading khi đang verify

    try {
      final uri = Uri.parse(url);
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      if (widget.paymentMethod == 'VNPAY') {
        // --- LOGIC VNPAY ---
        final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];

        if (vnpResponseCode == '00') {
          // Thành công -> Gọi API Verify Backend
          // Backend yêu cầu body là Map<String, String> vnpParams
          final body = jsonEncode(uri.queryParameters);

          final verifyRes = await http.post(
            Uri.parse('$baseUrl/vnpay/verify'),
            headers: headers,
            body: body,
          );

          if (verifyRes.statusCode == 200) {
            _goToSuccessPage();
          } else {
            throw Exception("Xác thực VNPAY thất bại: ${verifyRes.body}");
          }
        } else {
          throw Exception("Giao dịch VNPAY thất bại (Code: $vnpResponseCode)");
        }

      } else {
        // --- LOGIC PAYPAL ---
        // Backend set returnUrl: ...?appointmentId=...&token={ORDER_ID}&PayerID=...
        final orderId = uri.queryParameters['token']; // Trong PayPal return, token chính là Order ID

        if (orderId != null) {
          // Gọi API Capture
          // Backend: POST /paypal/capture?orderId=...&appointmentId=...
          final captureUri = Uri.parse('$baseUrl/paypal/capture').replace(queryParameters: {
            'orderId': orderId,
            'appointmentId': widget.appointmentId.toString(),
          });

          final captureRes = await http.post(captureUri, headers: headers);

          if (captureRes.statusCode == 200) {
            _goToSuccessPage();
          } else {
            throw Exception("Capture PayPal thất bại: ${captureRes.body}");
          }
        } else {
          throw Exception("Không tìm thấy PayPal Order ID");
        }
      }

    } catch (e) {
      // Xử lý lỗi
      if (mounted) {
        Navigator.pop(context); // Đóng WebView
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi thanh toán: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _goToSuccessPage() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BookingSuccessPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paymentMethod == 'VNPAY' ? "Cổng thanh toán VNPAY" : "Thanh toán PayPal"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (errorMessage != null)
            Center(child: Text("Lỗi: $errorMessage", style: const TextStyle(color: Colors.red)))
          else
            WebViewWidget(controller: _controller),

          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Đang xử lý thanh toán...", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}