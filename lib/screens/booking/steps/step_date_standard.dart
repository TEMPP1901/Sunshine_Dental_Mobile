import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking/booking_provider.dart';

class StepDateStandard extends StatefulWidget {
  const StepDateStandard({super.key});

  @override
  State<StepDateStandard> createState() => _StepDateStandardState();
}

class _StepDateStandardState extends State<StepDateStandard> {
  bool? morningAvail;
  bool? afternoonAvail;
  bool isLoading = false;

  Future<void> _checkAvailability(BuildContext context) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    if (provider.selectedDate == null) return;

    setState(() => isLoading = true);
    try {
      final res = await provider.checkAvailability();
      setState(() {
        morningAvail = res.morningAvailable;
        afternoonAvail = res.afternoonAvailable;
      });
    } catch (e) {
      // Error
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Chọn ngày khám", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                provider.setDate(picked);
                _checkAvailability(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(provider.selectedDate == null
                      ? "Chạm để chọn ngày"
                      : DateFormat('dd/MM/yyyy').format(provider.selectedDate!)
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          if (isLoading) const CircularProgressIndicator(),
          if (!isLoading && provider.selectedDate != null) ...[
            _buildSessionBtn(
                "Buổi Sáng (08:00 - 12:00)",
                morningAvail == true,
                "08:00",
                provider
            ),
            const SizedBox(height: 16),
            _buildSessionBtn(
                "Buổi Chiều (13:00 - 17:00)",
                afternoonAvail == true,
                "13:00",
                provider
            ),
          ],

          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: provider.selectedTime != null ? provider.nextStep : null,
            child: const Text("Tiếp tục"),
          )
        ],
      ),
    );
  }

  Widget _buildSessionBtn(String label, bool isAvailable, String timeValue, BookingProvider provider) {
    bool isSelected = provider.selectedTime == timeValue;
    return InkWell(
      onTap: isAvailable ? () => provider.setTime(timeValue, label: label) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: !isAvailable ? Colors.grey.shade200 : (isSelected ? Colors.blue.shade50 : Colors.white),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.wb_sunny, color: !isAvailable ? Colors.grey : Colors.orange),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(
                color: !isAvailable ? Colors.grey : Colors.black,
                fontWeight: FontWeight.bold
            )),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
            if (!isAvailable) const Text("FULL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}