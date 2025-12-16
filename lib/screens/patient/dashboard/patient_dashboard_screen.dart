import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/patient/patient_models.dart';
import '../../../../services/patient/patient_service.dart';
import '../appointments/widgets/appointment_card.dart';
import 'widgets/rank_card.dart';
import 'widgets/wellness_card.dart'; // [MỚI] Import WellnessCard

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

  // Helper để lấy thông tin giảm giá
  Map<String, dynamic>? _getDiscountInfo(String tier) {
    switch (tier) {
      case 'DIAMOND':
        return {
          'pct': 15,
          'color': const Color(0xFF9333EA), // Purple
          'bgColor': const Color(0xFFF3E8FF),
          'borderColor': const Color(0xFFD8B4FE),
        };
      case 'GOLD':
        return {
          'pct': 10,
          'color': const Color(0xFFA16207), // Yellow/Brown
          'bgColor': const Color(0xFFFEF9C3),
          'borderColor': const Color(0xFFFEF08A),
        };
      case 'SILVER':
        return {
          'pct': 5,
          'color': const Color(0xFF374151), // Gray
          'bgColor': const Color(0xFFF3F4F6),
          'borderColor': const Color(0xFFE5E7EB),
        };
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Tổng Quan Sức Khỏe",
          style: TextStyle(fontWeight: FontWeight.bold),
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
                  const Text("Không tải được dữ liệu"),
                  TextButton(
                    onPressed: _fetchData,
                    child: const Text("Thử lại"),
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
                        RankCard(data: _data!),

                        // [MỚI] Hiển thị ưu đãi giảm giá
                        Builder(
                          builder: (context) {
                            final discount = _getDiscountInfo(
                              _data!.memberTier,
                            );
                            if (discount == null) {
                              return const SizedBox.shrink();
                            }
                            return Container(
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
                                    "Ưu đãi thành viên: Giảm ${discount['pct']}%",
                                    style: TextStyle(
                                      color: discount['color'],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. Menu Nhanh
                    const Text(
                      "Truy cập nhanh",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildQuickLink(
                          context,
                          "Lịch hẹn",
                          Icons.calendar_month,
                          Colors.blue,
                          () => context.push('/my-appointments'),
                        ),
                        const SizedBox(width: 12),
                        _buildQuickLink(
                          context,
                          "Hồ sơ",
                          Icons.medical_information,
                          Colors.teal,
                          () => context.push('/patient-profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Wellness Card (Thay thế AI Tip cũ)
                    // [MỚI] Sử dụng WellnessCard
                    SizedBox(
                      height: 220, // Chiều cao cố định cho đẹp
                      child: WellnessCard(
                        status: _data!.healthStatus,
                        message: _data!.healthMessage,
                        daysSince: _data!.daysSinceLastVisit,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Lịch hẹn sắp tới
                    if (_data!.nextAppointment != null) ...[
                      const Text(
                        "Lịch hẹn sắp tới",
                        style: TextStyle(
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
