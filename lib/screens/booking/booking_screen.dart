// lib/screens/booking/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking/booking_provider.dart';
import 'steps/step_type.dart';
import 'steps/step_service_clinic.dart';
import 'steps/step_doctor.dart';
import 'steps/step_date_standard.dart';
import 'steps/step_date_vip.dart';
import 'steps/step_summary.dart';

// ⚠️ Đã chuyển thành StatefulWidget để nhận tham số từ AI
class BookingScreen extends StatefulWidget {
  final int? prefillServiceId;
  final int? prefillDoctorId;

  const BookingScreen({super.key, this.prefillServiceId, this.prefillDoctorId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        // Khởi tạo Provider
        final provider = BookingProvider();

        // 🟢 KÍCH HOẠT LOGIC AI NGAY KHI TẠO PROVIDER
        if (widget.prefillServiceId != null || widget.prefillDoctorId != null) {
          provider.initializeFromAi(
            serviceId: widget.prefillServiceId,
            doctorId: widget.prefillDoctorId,
          );
        }
        return provider;
      },
      child: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          // Logic xác định tổng số bước
          int totalSteps = (provider.appointmentType == 'STANDARD') ? 4 : 5;

          return Scaffold(
            appBar: AppBar(
              title: const Text("Đặt Lịch Hẹn"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (provider.currentStep > 0) {
                    provider.prevStep();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            // Hiển thị Loading khi AI đang xử lý dữ liệu
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // STEPPER INDICATOR
                      _buildStepper(provider.currentStep, totalSteps),

                      // STEP CONTENT
                      Expanded(
                        child: _buildStepContent(
                          provider.currentStep,
                          provider.appointmentType,
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // --- CÁC WIDGET UI BÊN DƯỚI GIỮ NGUYÊN HOÀN TOÀN TỪ CODE CŨ ---

  Widget _buildStepper(int currentStep, int totalSteps) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          bool isActive = index <= currentStep;
          return Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.blue : Colors.white,
                  border: Border.all(color: Colors.blue),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (index < totalSteps - 1)
                Container(
                  width: 30,
                  height: 2,
                  color: isActive ? Colors.blue : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(int step, String type) {
    switch (step) {
      case 0:
        return const StepType();
      case 1:
        return const StepServiceClinic();
      case 2:
        if (type == 'STANDARD') {
          return const StepDateStandard();
        } else {
          return const StepDoctor();
        }
      case 3:
        if (type == 'STANDARD') {
          return const StepSummary();
        } else {
          return const StepDateVip();
        }
      case 4:
        return const StepSummary();
      default:
        return const SizedBox.shrink();
    }
  }
}
