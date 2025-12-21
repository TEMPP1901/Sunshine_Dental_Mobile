// lib/screens/booking/steps/step_doctor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/booking/booking_models.dart';
import '../../../providers/booking/booking_provider.dart';
import '../../../services/api_service.dart';

class StepDoctor extends StatefulWidget {
  const StepDoctor({super.key});

  @override
  State<StepDoctor> createState() => _StepDoctorState();
}

class _StepDoctorState extends State<StepDoctor> {
  List<BookingDoctor> doctors = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy danh sách bác sĩ ngay khi vào màn hình
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await provider.fetchDoctors();
      if (mounted) {
        setState(() {
          doctors = result;
          isLoading = false;
        });
        // Debug: Kiểm tra avatarUrl của các bác sĩ
        for (var doctor in result) {
          debugPrint('Doctor: ${doctor.fullName}, avatarUrl: ${doctor.avatarUrl}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Không thể tải danh sách bác sĩ. Vui lòng thử lại.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    
    // Lấy danh sách categories từ parent services (sẽ được tính trong fetchDoctors)
    // Tạm thời hiển thị từ selectedServiceParent nếu có
    final uniqueCategories = provider.selectedServiceParent != null
        ? [provider.selectedServiceParent!.category]
        : [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header giống web
          Center(
            child: Column(
              children: [
                const Text(
                  "Chọn Bác sĩ (VIP)",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "${uniqueCategories.join(', ')} @ ${provider.selectedClinic?.clinicName ?? ''}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- CONTENT AREA ---
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 10),
                    Text(errorMessage!),
                    TextButton(onPressed: _loadDoctors, child: const Text("Thử lại"))
                  ],
                ),
              ),
            )
          else if (doctors.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        "Không tìm thấy bác sĩ phù hợp",
                        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Vui lòng quay lại và chọn dịch vụ hoặc cơ sở khác",
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    final isSelected = provider.selectedDoctor?.id == doctor.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDoctorCard(doctor, isSelected, () {
                        provider.setDoctor(doctor);
                      }),
                    );
                  },
                ),
              ),

          const SizedBox(height: 16),

          // --- NAVIGATION BUTTON ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.purple, // Màu tím cho VIP
            ),
            onPressed: provider.selectedDoctor != null ? provider.nextStep : null,
            child: const Text("Tiếp tục"),
          )
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BookingDoctor doctor, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Avatar - sử dụng ApiService để resolve URL đúng cách
            ClipOval(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty
                    ? Image(
                        image: ApiService.resolveAvatarImage(
                          doctor.avatarUrl,
                          defaultAsset: 'assets/images/doctor.png',
                        ),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading doctor avatar for ${doctor.fullName}: $error, URL: ${doctor.avatarUrl}');
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Name và Specialties
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    doctor.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Specialties Tags (hiển thị tất cả)
                  if (doctor.specialties.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: doctor.specialties.map((spec) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade100, width: 1),
                          ),
                          child: Text(
                            spec,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            
            // Checkmark icon khi được chọn
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}