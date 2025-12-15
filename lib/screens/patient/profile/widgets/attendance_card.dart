import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AttendanceCard extends StatefulWidget {
  const AttendanceCard({super.key});

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  String _clockText = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // [FIX] KHÔNG lấy DateFormat(context.locale) ở đây vì context chưa sẵn sàng
    _startClock();
  }

  void _startClock() {
    // Format giờ thì không cần locale nên để đây được, hoặc chuyển vào build cũng được
    _clockText = DateFormat('HH:mm:ss').format(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final newText = DateFormat('HH:mm:ss').format(DateTime.now());
      if (_clockText != newText) {
        setState(() => _clockText = newText);
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // [FIX] Lấy ngày tháng và Locale ở trong hàm build() là an toàn nhất
    // Nó sẽ tự cập nhật khi người dùng đổi ngôn ngữ
    final todayLabel = DateFormat.yMMMMEEEEd(
      context.locale.toString(),
    ).format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.attendanceCard.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Hiển thị ngày tháng đã fix
                  Text(
                    todayLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.access_time_filled,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _clockText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'profile.actions.openAttendance'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
