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

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingProvider(),
      child: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          // Logic xác định tổng số bước
          // Standard: Type(0) -> Service(1) -> Date(2) -> Summary(3) => Total 4
          // VIP: Type(0) -> Service(1) -> Doctor(2) -> DateVIP(3) -> Summary(4) => Total 5
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
            body: Column(
              children: [
                // STEPPER INDICATOR
                _buildStepper(provider.currentStep, totalSteps),

                // STEP CONTENT
                Expanded(
                  child: _buildStepContent(provider.currentStep, provider.appointmentType),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget hiển thị thanh tiến trình (1 - 2 - 3 - 4...)
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

  // 👇 LOGIC QUAN TRỌNG: Điều phối màn hình dựa trên Step và Type
  Widget _buildStepContent(int step, String type) {
    switch (step) {
      case 0:
        return const StepType(); // Luôn là chọn loại đầu tiên

      case 1:
        return const StepServiceClinic(); // Luôn là chọn cơ sở/dịch vụ thứ hai

      case 2:
      // RẼ NHÁNH TẠI ĐÂY
        if (type == 'STANDARD') {
          return const StepDateStandard(); // Standard -> Chọn ngày thường
        } else {
          return const StepDoctor(); // VIP -> Chọn bác sĩ
        }

      case 3:
        if (type == 'STANDARD') {
          return const StepSummary(); // Standard -> Tổng kết luôn
        } else {
          return const StepDateVip(); // VIP -> Chọn ngày giờ chính xác
        }

      case 4:
      // Chỉ VIP mới tới bước 4 này
        return const StepSummary();

      default:
        return const SizedBox.shrink();
    }
  }
}