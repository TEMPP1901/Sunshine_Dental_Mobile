import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
// [FIX] Import đúng model mới
import '../../../models/patient/patient_models.dart';

class UpcomingAppointmentCard extends StatefulWidget {
  const UpcomingAppointmentCard({super.key});

  @override
  State<UpcomingAppointmentCard> createState() =>
      _UpcomingAppointmentCardState();
}

class _UpcomingAppointmentCardState extends State<UpcomingAppointmentCard> {
  // [FIX] Dùng đúng tên class PatientAppointment
  PatientAppointment? _appointment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingAppointment();
  }

  Future<void> _fetchUpcomingAppointment() async {
    try {
      // API này trả về List<PatientAppointmentResponse> (theo Backend của bạn)
      final response = await ApiService().get('/api/patient/appointments');

      if (response.data is List && (response.data as List).isNotEmpty) {
        final list = response.data as List;

        // Tìm lịch hẹn sắp tới (PENDING hoặc CONFIRMED)
        final upcomingData = list.firstWhere((item) {
          final status = item['status']?.toString().toUpperCase();
          return status == 'PENDING' || status == 'CONFIRMED';
        }, orElse: () => null);

        if (upcomingData != null && mounted) {
          setState(() {
            // [FIX] Parse bằng PatientAppointment.fromJson
            _appointment = PatientAppointment.fromJson(upcomingData);
            _isLoading = false;
          });
          return;
        }
      }

      if (mounted) {
        setState(() {
          _appointment = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching upcoming appointment: $e");
      if (mounted) {
        setState(() {
          _appointment = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _appointment == null) {
      return const SizedBox.shrink();
    }

    // --- Format Date/Time ---
    // [FIX] Dùng startDateTime từ model mới
    String dateStr = DateFormat(
      'EEE, dd MMM',
    ).format(_appointment!.startDateTime);
    String timeStr = DateFormat('HH:mm').format(_appointment!.startDateTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upcoming Appointment",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _appointment!.serviceName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Doctor Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF283593),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _appointment!.doctorAvatar != null && 
                         _appointment!.doctorAvatar!.isNotEmpty &&
                         ApiService.resolveUrl(_appointment!.doctorAvatar!).isNotEmpty
                      ? Image.network(
                          ApiService.resolveUrl(_appointment!.doctorAvatar!),
                          height: 48,
                          width: 48,
                          fit: BoxFit.cover,
                          headers: ApiService.authHeaders(),
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 48,
                            width: 48,
                            color: Colors.white24,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                        )
                      : Container(
                          height: 48,
                          width: 48,
                          color: Colors.white24,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appointment!.doctorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _appointment!.clinicName.isNotEmpty
                            ? _appointment!.clinicName
                            : "Dental Specialist",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Time Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF1A237E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: const Color(0xFF1A237E).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF1A237E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: const Color(0xFF1A237E).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
