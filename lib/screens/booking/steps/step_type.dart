import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking/booking_provider.dart';

class StepType extends StatelessWidget {
  const StepType({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Chọn gói dịch vụ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildCard(
            context,
            title: "STANDARD",
            price: "500,000 VND",
            icon: Icons.flash_on,
            color: Colors.blue,
            isSelected: provider.appointmentType == 'STANDARD',
            onTap: () => provider.setType('STANDARD'),
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: "VIP",
            price: "1,000,000 VND",
            icon: Icons.diamond,
            color: Colors.purple,
            isSelected: provider.appointmentType == 'VIP',
            onTap: () => provider.setType('VIP'),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: provider.nextStep,
            child: const Text("Tiếp tục"),
          )
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required String price, required IconData icon, required Color color, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}