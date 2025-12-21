import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/booking/booking_api_service.dart';
import '../../../models/booking/booking_models.dart';
import '../../../services/api_service.dart';

class DoctorCard extends StatefulWidget {
  const DoctorCard({super.key});

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  final BookingApiService _apiService = BookingApiService();
  List<BookingDoctor> doctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      debugPrint('[DoctorCard] Loading doctors...');
      // Lấy clinic đầu tiên
      final clinics = await _apiService.getClinics();
      debugPrint('[DoctorCard] Found ${clinics.length} clinics');
      
      if (clinics.isEmpty) {
        debugPrint('[DoctorCard] No clinics found');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // Lấy danh sách bác sĩ từ clinic đầu tiên
      final firstClinic = clinics.first;
      debugPrint('[DoctorCard] Using clinic: ${firstClinic.id} - ${firstClinic.clinicName}');
      
      // Thử với các specialties phổ biến để lấy bác sĩ
      final specialties = ['Preventive Care', 'Orthodontics', 'Cosmetic Dentistry', 'Dental Implants', 'Oral Surgery', 'Pediatric Dentistry'];
      final allDoctors = <BookingDoctor>[];
      
      for (var specialty in specialties) {
        try {
          debugPrint('[DoctorCard] Trying specialty: $specialty');
          final result = await _apiService.getDoctors(firstClinic.id, specialty);
          debugPrint('[DoctorCard] Found ${result.length} doctors for $specialty');
          for (var doctor in result) {
            if (!allDoctors.any((d) => d.id == doctor.id)) {
              allDoctors.add(doctor);
              debugPrint('[DoctorCard] Added doctor: ${doctor.fullName}');
            }
          }
        } catch (e) {
          debugPrint('[DoctorCard] Error loading doctors for $specialty: $e');
          // Bỏ qua nếu specialty không có bác sĩ
        }
      }
      
      debugPrint('[DoctorCard] Total doctors loaded: ${allDoctors.length}');
      if (mounted) {
        setState(() {
          doctors = allDoctors;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[DoctorCard] Error loading doctors: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (doctors.isEmpty) {
      debugPrint('[DoctorCard] No doctors to display');
      // Hiển thị placeholder thay vì ẩn hoàn toàn
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Đang tải danh sách bác sĩ...',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: doctors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final doctor = doctors[index];
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
                // Ảnh Avatar - sử dụng ApiService để resolve URL đúng cách
                Container(
                  width: 110,
                  height: double.infinity,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty
                        ? Image(
                            image: ApiService.resolveAvatarImage(
                              doctor.avatarUrl,
                              defaultAsset: 'assets/images/doctor.png',
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                // Thông tin
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tên và chuyên khoa
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                doctor.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D1B3E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Hiển thị tất cả specialties
                              if (doctor.specialties.isNotEmpty)
                                Wrap(
                                  spacing: 3,
                                  runSpacing: 3,
                                  children: doctor.specialties.map((spec) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        spec,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3366FF),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Nút Đặt lịch
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            onPressed: () => context.push('/booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3366FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'home.doctor.bookBtn'.tr(), // "Đặt lịch"
                              style: const TextStyle(
                                fontSize: 10,
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
