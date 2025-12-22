import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RankBenefitsSheet extends StatelessWidget {
  const RankBenefitsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Danh sách quyền lợi sử dụng key mới từ benefits.json
    final tiers = [
      {
        'label': 'benefits.ranks.member'.tr(), // Key mới
        'discount': 0,
        'color': Colors.blue,
        'bg': Colors.blue.shade50,
      },
      {
        'label': 'benefits.ranks.silver'.tr(), // Key mới
        'discount': 5,
        'color': Colors.grey.shade700,
        'bg': Colors.grey.shade100,
      },
      {
        'label': 'benefits.ranks.gold'.tr(), // Key mới
        'discount': 10,
        'color': Colors.orange.shade800,
        'bg': Colors.orange.shade50,
      },
      {
        'label': 'benefits.ranks.diamond'.tr(), // Key mới
        'discount': 15,
        'color': Colors.purple,
        'bg': Colors.purple.shade50,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh nắm kéo
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            "benefits.title".tr(), // "QUYỀN LỢI THÀNH VIÊN"
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),

          // Danh sách các mức hạng
          ...tiers.map((tier) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tier['bg'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tier['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tier['color'] as Color,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      "-${tier['discount']}%",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          Text(
            "benefits.note".tr(), // "* Áp dụng trên tổng hóa đơn..."
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

