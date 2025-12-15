import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/patient/patient_models.dart';
import '../../../../services/api_service.dart'; // Để resolve ảnh

class RankCard extends StatelessWidget {
  final PatientDashboardDTO data;

  const RankCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    double progress = data.nextTierGoal > 0
        ? (data.totalSpent / data.nextTierGoal).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366FF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: ApiService.resolveAvatarImage(
                    data.avatarUrl,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRankLabel(data.memberTier),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chi tiêu tích lũy",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${currencyFormat.format(data.totalSpent)} / ${NumberFormat.compact().format(data.nextTierGoal)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              if (data.nextTierGoal > data.totalSpent)
                Text(
                  "Cần thêm ${currencyFormat.format(data.nextTierGoal - data.totalSpent)} để thăng hạng",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRankLabel(String tier) {
    switch (tier) {
      case 'DIAMOND':
        return '💎 Kim Cương';
      case 'GOLD':
        return '🥇 Vàng';
      case 'SILVER':
        return '🥈 Bạc';
      default:
        return '👋 Thành viên';
    }
  }
}
