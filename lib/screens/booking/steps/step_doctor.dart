// lib/screens/booking/steps/step_doctor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/booking/booking_models.dart';
import '../../../providers/booking/booking_provider.dart';

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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chọn Bác sĩ (VIP)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Dịch vụ: ${provider.selectedServiceParent?.serviceName ?? 'Unknown'}",
            style: TextStyle(color: Colors.grey[600]),
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
              const Expanded(
                child: Center(child: Text("Không tìm thấy bác sĩ phù hợp tại cơ sở này.")),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 cột
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8, // Tỷ lệ khung hình thẻ
                  ),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    final isSelected = provider.selectedDoctor?.id == doctor.id;

                    return _buildDoctorCard(doctor, isSelected, () {
                      provider.setDoctor(doctor);
                    });
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 8)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                image: DecorationImage(
                  image: NetworkImage(
                    (doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty)
                        ? doctor.avatarUrl!
                        : "https://i.pravatar.cc/150?u=${doctor.id}"
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Name
            Text(
              doctor.fullName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.purple.shade900 : Colors.black87,
              ),
            ),

            const SizedBox(height: 4),

            // Specialties (Chỉ hiện 1 cái đầu tiên cho gọn)
            if (doctor.specialties.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  doctor.specialties.first,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 8.0), // Sửa dòng này
                child: Icon(Icons.check_circle, color: Colors.purple, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}