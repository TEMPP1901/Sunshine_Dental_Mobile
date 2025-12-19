// lib/screens/booking/steps/step_date_vip.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/booking/booking_models.dart';
import '../../../providers/booking/booking_provider.dart';

class StepDateVip extends StatefulWidget {
  const StepDateVip({super.key});

  @override
  State<StepDateVip> createState() => _StepDateVipState();
}

class _StepDateVipState extends State<StepDateVip> {
  List<TimeSlot> slots = [];
  bool isLoading = false;
  String? errorMsg;

  // Khi chọn ngày xong -> Gọi API lấy Slot
  Future<void> _fetchSlots(BuildContext context) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    if (provider.selectedDate == null) {
      print('[StepDateVip] Cannot fetch slots: selectedDate is null');
      return;
    }

    // Kiểm tra các điều kiện cần thiết
    if (provider.selectedClinic == null) {
      print('[StepDateVip] Cannot fetch slots: selectedClinic is null');
      return;
    }
    if (provider.selectedDoctor == null) {
      print('[StepDateVip] Cannot fetch slots: selectedDoctor is null');
      return;
    }
    if (provider.selectedServiceVariant == null) {
      print('[StepDateVip] Cannot fetch slots: selectedServiceVariant is null');
      return;
    }

    print('[StepDateVip] Fetching slots for date: ${provider.selectedDate}');
    print('[StepDateVip] Clinic: ${provider.selectedClinic?.id}, Doctor: ${provider.selectedDoctor?.id}, Service: ${provider.selectedServiceVariant?.variantId}');

    setState(() {
      isLoading = true;
      errorMsg = null;
      slots = [];
    });

    try {
      // provider.fetchSlots đã được cài đặt ở bước trước
      final result = await provider.fetchSlots();
      print('[StepDateVip] Fetched ${result.length} slots');
      setState(() {
        slots = result;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('[StepDateVip] Error fetching slots: $e');
      print('[StepDateVip] Stack trace: $stackTrace');
      setState(() {
        isLoading = false;
        errorMsg = "Lỗi tải khung giờ. Vui lòng chọn ngày khác.";
      });
    }
  }

  Future<void> _pickDate(BuildContext context, BookingProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)), // Cho đặt trước 30 ngày
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.purple), // Style màu tím VIP
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDate(picked);
      // Sau khi set ngày, gọi API lấy giờ
      if (mounted) _fetchSlots(context);
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
          const Text("Chọn ngày & giờ khám", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Lịch trống của BS. ${provider.selectedDoctor?.fullName ?? ''}", style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 16),

          // --- 1. DATE PICKER INPUT ---
          InkWell(
            onTap: () => _pickDate(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.selectedDate == null
                        ? "Bấm để chọn ngày"
                        : DateFormat('dd/MM/yyyy - EEEE', 'vi').format(provider.selectedDate!), // Format tiếng Việt nếu có locale
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.calendar_month, color: Colors.purple),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- 2. TIME SLOTS GRID ---
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMsg != null)
            Center(child: Text(errorMsg!, style: const TextStyle(color: Colors.red)))
          else if (provider.selectedDate != null && slots.isEmpty)
              const Center(child: Text("Không có lịch trống cho ngày này."))
            else if (provider.selectedDate != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Giờ còn trống:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, // 4 cột
                            childAspectRatio: 1.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: slots.length,
                          itemBuilder: (context, index) {
                            final slot = slots[index];
                            // Lấy giờ hiển thị (xử lý nhiều format: "08:00:00" -> "08:00", "08:00" -> "08:00")
                            String displayTime = slot.time;
                            if (displayTime.length >= 5) {
                              displayTime = displayTime.substring(0, 5);
                            }
                            // Đảm bảo format "HH:mm" (thêm số 0 nếu cần: "8:00" -> "08:00")
                            if (displayTime.length == 4 && displayTime[1] == ':') {
                              displayTime = '0$displayTime';
                            }
                            final isSelected = provider.selectedTime == displayTime;
                            final isAvailable = slot.available;

                            return _buildTimeSlot(
                              time: displayTime,
                              isAvailable: isAvailable,
                              isSelected: isSelected,
                              onTap: () {
                                if (isAvailable) {
                                  print("Tapping time slot: $displayTime");
                                  provider.setTime(displayTime);
                                  print("After setTime, selectedTime: ${provider.selectedTime}");
                                } else {
                                  print("Time slot $displayTime is not available");
                                }
                              },
                            );
                          },
                        ),
                      ),

                      // Chú thích
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegend(Colors.white, "Trống", borderColor: Colors.grey),
                          const SizedBox(width: 16),
                          _buildLegend(Colors.grey.shade300, "Bận"),
                          const SizedBox(width: 16),
                          _buildLegend(Colors.purple, "Đang chọn"),
                        ],
                      )
                    ],
                  ),
                ),

          if (provider.selectedDate == null)
            const Expanded(child: Center(child: Text("Vui lòng chọn ngày trước.", style: TextStyle(color: Colors.grey)))),

          const SizedBox(height: 16),

          // --- NEXT BUTTON ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: provider.selectedTime != null ? Colors.purple : Colors.grey,
              disabledBackgroundColor: Colors.grey,
            ),
            onPressed: provider.selectedTime != null ? () {
              // Debug: Kiểm tra selectedTime
              print("Selected time: ${provider.selectedTime}");
              provider.nextStep();
            } : null,
            child: Text(
              "Tiếp tục",
              style: TextStyle(
                color: provider.selectedTime != null ? Colors.white : Colors.grey.shade400,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeSlot({
    required String time,
    required bool isAvailable,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isAvailable ? () {
        print("GestureDetector tapped: $time, available: $isAvailable");
        onTap();
      } : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !isAvailable
              ? Colors.grey.shade200 // Bận
              : isSelected
              ? Colors.purple // Đang chọn
              : Colors.white, // Trống
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.purple 
                : (isAvailable ? Colors.grey.shade300 : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: !isAvailable
                ? Colors.grey
                : isSelected
                ? Colors.white
                : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            decoration: !isAvailable ? TextDecoration.lineThrough : null,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label, {Color? borderColor}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}