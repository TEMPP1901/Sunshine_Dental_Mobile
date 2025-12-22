import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/booking/booking_provider.dart';

class BookingSuccessPage extends StatefulWidget {
  const BookingSuccessPage({super.key});

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Hiệu ứng checkmark nảy ra
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    // 2. Reset dữ liệu booking trong Provider để lần sau đặt mới hoàn toàn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).reset();
    });

    // 3. Bắt đầu đếm ngược về Home
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        // Tự động đi đến màn hình xem lịch hẹn thay vì về home
        _navigateToMyAppointments();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _navigateToHome() {
    _timer?.cancel();
    // Quay về trang chủ sử dụng GoRouter
    if (mounted) {
      context.go('/home');
    }
  }

  void _navigateToMyAppointments() {
    _timer?.cancel();
    // Đi đến màn hình xem lịch hẹn của tôi
    if (mounted) {
      context.go('/my-appointments');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // --- ICON ANIMATION ---
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade500,
                  size: 80,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- TEXT MESSAGES ---
            const Text(
              "Đặt lịch thành công!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Cảm ơn bạn đã tin tưởng Sunshine Dental Care.\nChúng tôi đã gửi email xác nhận cho bạn.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // --- BUTTONS ---
            // Nút xem lịch hẹn (chính)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToMyAppointments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Xem lịch hẹn của tôi",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nút về trang chủ (phụ)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _navigateToHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                child: const Text(
                  "Về trang chủ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- COUNTDOWN TEXT ---
            Text(
              "Tự động chuyển đến lịch hẹn sau $_countdown giây...",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}