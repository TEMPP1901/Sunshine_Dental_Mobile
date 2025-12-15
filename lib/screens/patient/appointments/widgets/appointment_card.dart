import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/patient/patient_models.dart';

class AppointmentCard extends StatelessWidget {
  final PatientAppointment appointment;
  final VoidCallback? onCancel; // Truyền hàm nếu muốn hiện nút hủy

  const AppointmentCard({super.key, required this.appointment, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final date = appointment.startDateTime;
    final dayStr = DateFormat('dd').format(date);
    final monthStr = DateFormat('MM').format(date);
    final timeStr = DateFormat('HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayStr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3366FF),
                      ),
                    ),
                    Text(
                      "Th $monthStr",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3366FF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            appointment.serviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(appointment.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.access_time_rounded, timeStr),
                    const SizedBox(height: 4),
                    _infoRow(
                      Icons.person_rounded,
                      "BS. ${appointment.doctorName}",
                    ),
                    const SizedBox(height: 4),
                    _infoRow(Icons.location_on_rounded, appointment.clinicName),
                  ],
                ),
              ),
            ],
          ),
          if (appointment.canCancel && onCancel != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: Colors.red,
                ),
                label: const Text(
                  "Hủy lịch hẹn",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'CONFIRMED':
        bg = Colors.blue.shade50;
        text = Colors.blue;
        label = "Đã xác nhận";
        break;
      case 'COMPLETED':
        bg = Colors.green.shade50;
        text = Colors.green;
        label = "Hoàn thành";
        break;
      case 'CANCELLED':
        bg = Colors.red.shade50;
        text = Colors.red;
        label = "Đã hủy";
        break;
      case 'NOSHOW':
        bg = Colors.grey.shade200;
        text = Colors.grey;
        label = "Vắng mặt";
        break;
      default:
        bg = Colors.orange.shade50;
        text = Colors.orange;
        label = "Chờ duyệt";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
