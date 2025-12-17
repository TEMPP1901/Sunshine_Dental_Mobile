import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/patient/patient_models.dart';

class AppointmentCard extends StatelessWidget {
  final PatientAppointment appointment;
  // Đã bỏ final VoidCallback? onCancel;

  const AppointmentCard({super.key, required this.appointment});

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
              // Info Content
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
                        const SizedBox(width: 8),
                        _buildStatusBadge(appointment.status),
                      ],
                    ),
                    if (appointment.variantName != null &&
                        appointment.variantName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          appointment.variantName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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

          // --- [ĐÃ XÓA PHẦN NÚT HỦY TẠI ĐÂY ĐỂ GIỐNG WEB] ---
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
    final s = status.toUpperCase();

    switch (s) {
      case 'PENDING':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        label = "Chờ xác nhận";
        break;
      case 'SCHEDULED':
      case 'CONFIRMED':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        label = "Đã lên lịch";
        break;
      case 'IN_PROGRESS':
      case 'PROCESSING':
        bg = Colors.purple.shade50;
        text = Colors.purple.shade800;
        label = "Đang khám";
        break;
      case 'COMPLETED':
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        label = "Hoàn thành";
        break;
      case 'CANCELLED':
      case 'CANCELED':
        bg = Colors.red.shade50;
        text = Colors.red.shade800;
        label = "Đã hủy";
        break;
      case 'NOSHOW':
      case 'NO_SHOW':
        bg = Colors.grey.shade200;
        text = Colors.grey.shade700;
        label = "Vắng mặt";
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade800;
        label = s;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withOpacity(0.5)),
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
