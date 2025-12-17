// import 'api_service.dart';
// import '../models/patient/appointment_model.dart';

// class AppointmentService {
//   final ApiService _api = ApiService();

//   // Lấy danh sách lịch hẹn của tôi
//   Future<List<Appointment>> getMyAppointments() async {
//     try {
//       // Endpoint này cần khớp với PatientAppointmentController trong Backend
//       // Ví dụ: /api/patient/appointments/my-appointments
//       final response = await _api.get('/api/patient/appointments');

//       if (response.data is List) {
//         return (response.data as List)
//             .map((e) => Appointment.fromJson(e))
//             .toList();
//       }
//       return [];
//     } catch (e) {
//       throw Exception('Không thể tải lịch hẹn: $e');
//     }
//   }

//   // Hủy lịch hẹn
//   Future<bool> cancelAppointment(int id, String reason) async {
//     try {
//       await _api.patch(
//         '/api/appointments/$id/cancel',
//         data: {'reason': reason},
//       );
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
// }
