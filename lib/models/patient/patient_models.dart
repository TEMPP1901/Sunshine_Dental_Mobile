// lib/models/patient/patient_models.dart

class PatientAppointment {
  final int id;
  final String serviceName;
  final String? variantName;
  final String doctorName;
  final String? doctorAvatar;
  final String clinicName;
  final String clinicAddress;
  final DateTime startDateTime;
  final String
  status; // PENDING, CONFIRMED, IN_PROGRESS, PROCESSING, COMPLETED, CANCELLED, NOSHOW...
  final bool canCancel;
  final String? note; // Ghi chú thêm nếu có

  PatientAppointment({
    required this.id,
    required this.serviceName,
    this.variantName,
    required this.doctorName,
    this.doctorAvatar,
    required this.clinicName,
    required this.clinicAddress,
    required this.startDateTime,
    required this.status,
    required this.canCancel,
    this.note,
  });

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    // Xử lý avatar bác sĩ tùy theo cấu trúc trả về
    String? avatar;
    if (json['doctor'] != null && json['doctor']['avatarUrl'] != null) {
      avatar = json['doctor']['avatarUrl'];
    } else if (json['doctorAvatar'] != null) {
      avatar = json['doctorAvatar'];
    }

    return PatientAppointment(
      id: json['appointmentId'] ?? 0,
      serviceName: json['serviceName'] ?? 'Dịch vụ nha khoa',
      variantName: json['variantName'],
      doctorName: json['doctorName'] ?? 'Đang sắp xếp',
      doctorAvatar: avatar,
      clinicName: json['clinicName'] ?? '',
      clinicAddress: json['clinicAddress'] ?? '',
      startDateTime:
          DateTime.tryParse(json['startDateTime'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'PENDING',
      canCancel: json['canCancel'] ?? false,
      note: json['note'],
    );
  }
}

class MedicalRecord {
  final int id;
  final String doctorName;
  final String diagnosis;
  final String treatment;
  final String visitDate;
  final String? note;
  final String? prescriptionNote;
  final String? imageUrl;

  MedicalRecord({
    required this.id,
    required this.doctorName,
    required this.diagnosis,
    required this.treatment,
    required this.visitDate,
    this.note,
    this.prescriptionNote,
    this.imageUrl,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['recordId'] ?? 0,
      doctorName: json['doctorName'] ?? 'Nha sĩ',
      diagnosis: json['diagnosis'] ?? '',
      treatment: json['treatment'] ?? '',
      visitDate: json['visitDate'] ?? '',
      note: json['note'],
      prescriptionNote: json['prescriptionNote'],
      imageUrl: json['imageUrl'],
    );
  }
}

class PatientDashboardDTO {
  final String fullName;
  final String patientCode;
  final String? avatarUrl;
  final String memberTier;
  final double totalSpent;
  final double nextTierGoal;
  final String healthStatus;
  final String healthMessage;
  final int daysSinceLastVisit;
  final String latestAiTip;
  final PatientAppointment? nextAppointment;
  final List<MedicalRecord> medicalHistory;

  PatientDashboardDTO({
    required this.fullName,
    required this.patientCode,
    this.avatarUrl,
    required this.memberTier,
    required this.totalSpent,
    required this.nextTierGoal,
    required this.healthStatus,
    required this.healthMessage,
    required this.daysSinceLastVisit,
    required this.latestAiTip,
    this.nextAppointment,
    required this.medicalHistory,
  });

  factory PatientDashboardDTO.fromJson(Map<String, dynamic> json) {
    return PatientDashboardDTO(
      fullName: json['fullName'] ?? '',
      patientCode: json['patientCode'] ?? '',
      avatarUrl: json['avatarUrl'],
      memberTier: json['memberTier'] ?? 'MEMBER',
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      nextTierGoal: (json['nextTierGoal'] ?? 0).toDouble(),
      healthStatus: json['healthStatus'] ?? 'New',
      healthMessage: json['healthMessage'] ?? '',
      daysSinceLastVisit: json['daysSinceLastVisit'] ?? -1,
      latestAiTip: json['latestAiTip'] ?? 'Chăm sóc răng miệng thật tốt nhé!',
      nextAppointment: json['nextAppointment'] != null
          ? PatientAppointment.fromJson(json['nextAppointment'])
          : null,
      medicalHistory: (json['medicalHistory'] as List? ?? [])
          .map((e) => MedicalRecord.fromJson(e))
          .toList(),
    );
  }
}
