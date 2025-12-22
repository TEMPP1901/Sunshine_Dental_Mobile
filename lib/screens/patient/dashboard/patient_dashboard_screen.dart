import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../models/patient/patient_models.dart';
import '../../../../services/patient/patient_service.dart';
import '../appointments/widgets/appointment_card.dart';
import 'widgets/rank_card.dart';
import 'widgets/wellness_card.dart';
import 'widgets/rank_benefits_sheet.dart'; // <--- IMPORT WIDGET MỚI

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final PatientService _service = PatientService();
  PatientDashboardDTO? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _service.getDashboardSummary();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  // Helper giảm giá (Giữ lại để tô màu Badge bên ngoài)
  Map<String, dynamic>? _getDiscountInfo(String tier) {
    switch (tier) {
      case 'DIAMOND':
        return {
          'pct': 15,
          'color': const Color(0xFF9333EA),
          'bgColor': const Color(0xFFF3E8FF),
          'borderColor': const Color(0xFFD8B4FE),
        };
      case 'GOLD':
        return {
          'pct': 10,
          'color': const Color(0xFFA16207),
          'bgColor': const Color(0xFFFEF9C3),
          'borderColor': const Color(0xFFFEF08A),
        };
      case 'SILVER':
        return {
          'pct': 5,
          'color': const Color(0xFF374151),
          'bgColor': const Color(0xFFF3F4F6),
          'borderColor': const Color(0xFFE5E7EB),
        };
      default:
        return null;
    }
  }

  // Hàm gọi Modal đã được rút gọn
  void _showRankBenefits(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => const RankBenefitsSheet(), // <--- GỌI WIDGET Ở ĐÂY
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'dashboard.title'.tr(), // "Tổng Quan Sức Khỏe"
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('dashboard.error'.tr()), // "Không tải được dữ liệu"
                  TextButton(
                    onPressed: _fetchData,
                    child: Text('dashboard.retry'.tr()), // "Thử lại"
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Rank Card & Discount Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            RankCard(data: _data!),
                            // Icon Info
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white70,
                                ),
                                onPressed: () => _showRankBenefits(context),
                                tooltip: "Xem quyền lợi",
                              ),
                            ),
                          ],
                        ),

                        // Discount Badge
                        Builder(
                          builder: (context) {
                            final discount = _getDiscountInfo(
                              _data!.memberTier,
                            );
                            if (discount == null) {
                              return const SizedBox.shrink();
                            }
                            return GestureDetector(
                              onTap: () => _showRankBenefits(context),
                              child: Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: discount['bgColor'],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: discount['borderColor'],
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "🎁 ",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'dashboard.discount'.tr(
                                        namedArgs: {
                                          'percent': discount['pct'].toString(),
                                        },
                                      ),
                                      style: TextStyle(
                                        color: discount['color'],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.help_outline,
                                      size: 14,
                                      color: discount['color'].withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. Menu Nhanh
                    Text(
                      'dashboard.quickAccess'.tr(), // "Truy cập nhanh"
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildQuickLink(
                          context,
                          'dashboard.appointments'.tr(), // "Lịch hẹn"
                          Icons.calendar_month,
                          Colors.blue,
                          () => context.push('/my-appointments'),
                        ),
                        const SizedBox(width: 12),
                        _buildQuickLink(
                          context,
                          'dashboard.records'.tr(), // "Hồ sơ"
                          Icons.medical_information,
                          Colors.teal,
                          () => context.push('/patient-profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Wellness Card
                    // ĐÃ SỬA: Xóa SizedBox cố định chiều cao để tránh overflow
                    WellnessCard(
                      status: _data!.healthStatus,
                      message: _data!.healthMessage,
                      daysSince: _data!.daysSinceLastVisit,
                    ),
                    const SizedBox(height: 24),

                    // 4. Lịch hẹn sắp tới
                    if (_data!.nextAppointment != null) ...[
                      Text(
                        'dashboard.upcoming'.tr(), // "Lịch hẹn sắp tới"
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppointmentCard(appointment: _data!.nextAppointment!),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickLink(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
