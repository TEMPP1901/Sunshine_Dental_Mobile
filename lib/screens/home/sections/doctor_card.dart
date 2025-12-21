import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu Hardcode (Gọi key từ file JSON để hỗ trợ đa ngôn ngữ)
    // List này nằm trong build() để được rebuild khi đổi ngôn ngữ
    final List<Map<String, dynamic>> doctors = [
      {
        'name': 'Dr. Sarah West',
        'specialty': 'home.doctor.specialty1'.tr(), // "Chỉnh nha (Niềng răng)"
        'image': 'assets/images/doctor1.png',
        'exp': 'home.doctor.exp1'.tr(), // "10 năm KN"
      },
      {
        'name': 'Dr. John Doe',
        'specialty': 'home.doctor.specialty2'.tr(), // "Cấy ghép Implant"
        'image': 'assets/images/doctor2.png',
        'exp': 'home.doctor.exp2'.tr(), // "8 năm KN"
      },
      {
        'name': 'Dr. Emily Chen',
        'specialty': 'home.doctor.specialty3'.tr(), // "Nha khoa thẩm mỹ"
        'image': 'assets/images/doctor3.png',
        'exp': 'home.doctor.exp3'.tr(), // "5 năm KN"
      },
    ];

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: doctors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final doc = doctors[index];
          return Container(
            width: 300,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE2E8EB),
                  Color(0xFFE9EDF4),
                  Color(0xFFAFD9F6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Ảnh Avatar
                Container(
                  width: 110,
                  height: double.infinity,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage(doc['image']),
                      fit: BoxFit.cover,
                      // Fallback nếu chưa có ảnh
                      onError: (_, __) =>
                          const NetworkImage('https://i.pravatar.cc/300'),
                    ),
                  ),
                ),
                // Thông tin
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          doc['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1B3E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc['specialty'], // Đã dịch từ trên list
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doc['exp'], // Đã dịch từ trên list
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3366FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Nút Đặt lịch
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => context.push('/booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3366FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'home.doctor.bookBtn'.tr(), // "Đặt lịch"
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
