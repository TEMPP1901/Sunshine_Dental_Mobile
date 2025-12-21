// lib/screens/booking/steps/step_summary.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/booking/booking_provider.dart';
import '../booking_success_page.dart';
import '../payment_webview_screen.dart';
class StepSummary extends StatelessWidget {
  const StepSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    // Không cần patientId - backend sẽ tự lấy từ JWT token (currentUser)

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Xác nhận thông tin", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          _buildInfoRow("Loại lịch", provider.appointmentType),
          _buildInfoRow("Cơ sở", provider.selectedClinic?.clinicName),
          
          // Hiển thị danh sách dịch vụ đã chọn
          if (provider.selectedServices.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text("Dịch vụ đã chọn:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...provider.selectedServices.map((service) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 20, child: Text("•", style: TextStyle(color: Colors.blue, fontSize: 18))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.variantName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          "${NumberFormat("#,###").format(service.price)} VND - ${service.duration} phút",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ] else
            _buildInfoRow("Dịch vụ", "Chưa chọn"),

          if (provider.appointmentType == 'VIP')
            _buildInfoRow("Bác sĩ", provider.selectedDoctor?.fullName),

          _buildInfoRow("Thời gian",
              provider.appointmentType == 'STANDARD'
                  ? "${DateFormat('dd/MM/yyyy').format(provider.selectedDate!)} (${provider.sessionLabel})"
                  : "${DateFormat('dd/MM/yyyy').format(provider.selectedDate!)} - ${provider.selectedTime}"
          ),

          const Divider(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng thanh toán", style: TextStyle(fontSize: 16)),
              Text(
                "${NumberFormat("#,###").format(provider.bookingFee)} VND",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),

          const Spacer(),

          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.appointmentType == 'STANDARD')
          // --- STANDARD: NÚT XÁC NHẬN THƯỜNG ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.blue),
              onPressed: () => _handleStandardBooking(context, provider),
              child: const Text("Xác nhận đặt lịch"),
            )
          else
          // --- VIP: 2 NÚT THANH TOÁN ---
            Column(
              children: [
                const Text("Chọn phương thức thanh toán:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Nút VNPAY
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.red.shade700 // Màu đặc trưng VNPAY
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text("Thanh toán qua VNPAY"),
                  onPressed: () => _handleVipPayment(context, provider, 'VNPAY'),
                ),

                const SizedBox(height: 10),

                // Nút PAYPAL
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.blue.shade900 // Màu đặc trưng PayPal
                  ),
                  icon: const Icon(Icons.paypal),
                  label: const Text("Thanh toán qua PayPal"),
                  onPressed: () => _handleVipPayment(context, provider, 'PAYPAL'),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value ?? "---", style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // Xử lý luồng STANDARD
  Future<void> _handleStandardBooking(BuildContext context, BookingProvider provider) async {
    try {
      await provider.confirmBooking();
      // Thành công -> Chuyển trang Success
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BookingSuccessPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // Xử lý luồng VIP
  Future<void> _handleVipPayment(BuildContext context, BookingProvider provider, String method) async {
    try {
      // 1. Tạo lịch hẹn trước (Trạng thái AWAITING_PAYMENT)
      int? appointmentId = await provider.confirmBooking();

      if (appointmentId != null && context.mounted) {
        // 2. Chuyển sang màn hình WebView để thanh toán
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              appointmentId: appointmentId,
              paymentMethod: method, // 'VNPAY' hoặc 'PAYPAL'
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tạo đơn: $e")));
    }
  }
}