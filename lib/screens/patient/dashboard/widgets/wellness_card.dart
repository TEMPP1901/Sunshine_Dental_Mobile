import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Import i18n

class WellnessCard extends StatelessWidget {
  final String status; // 'Excellent', 'Warning', 'Overdue', 'New'
  final String message;
  final int daysSince;

  const WellnessCard({
    super.key,
    required this.status,
    required this.message,
    required this.daysSince,
  });

  // Helper để lấy màu sắc và icon
  Map<String, dynamic> _getConfig() {
    switch (status) {
      case 'Excellent': // < 6 tháng
        return {
          'color': Colors.green,
          'bgColor': const Color(0xFF10B981),
          'lightColor': const Color(0xFFECFDF5),
          'textColor': const Color(0xFF047857),
          'icon': '🛡️',
          'title': 'dashboard.wellness.safe'.tr(), // "An toàn"
        };
      case 'Warning': // 6-12 tháng
        return {
          'color': Colors.amber,
          'bgColor': const Color(0xFFF59E0B),
          'lightColor': const Color(0xFFFFFBEB),
          'textColor': const Color(0xFFB45309),
          'icon': '⚠️',
          'title': 'dashboard.wellness.warning'.tr(), // "Cần kiểm tra"
        };
      case 'Overdue': // > 1 năm
        return {
          'color': Colors.red,
          'bgColor': const Color(0xFFEF4444),
          'lightColor': const Color(0xFFFEF2F2),
          'textColor': const Color(0xFFB91C1C),
          'icon': '❗',
          'title': 'dashboard.wellness.overdue'.tr(), // "Quá hạn"
        };
      default: // New User
        return {
          'color': Colors.blue,
          'bgColor': const Color(0xFF3B82F6),
          'lightColor': const Color(0xFFEFF6FF),
          'textColor': const Color(0xFF1D4ED8),
          'icon': '👋',
          'title': 'dashboard.wellness.new'.tr(), // "Thành viên mới"
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    final Color bgColor = config['bgColor'];
    final Color lightColor = config['lightColor'];
    final Color textColor = config['textColor'];

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Thanh màu trạng thái bên trái
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 8,
              child: Container(color: bgColor),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: lightColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                config['icon'],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            config['title'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      // Số ngày (Nếu không phải New)
                      if (daysSince >= 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              daysSince.toString(),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              'dashboard.wellness.daysUnchecked'
                                  .tr(), // "ngày chưa khám"
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Message Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '"$message"',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Nút Đặt Lịch (Nếu cần cảnh báo)
                        if (status == 'Warning' ||
                            status == 'Overdue' ||
                            status == 'New') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Cập nhật route booking nếu dùng GoRouter
                                // context.push('/booking');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'dashboard.wellness.bookingRedirect'.tr(),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bgColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'dashboard.wellness.bookNow'
                                    .tr(), // "Đặt lịch ngay"
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
