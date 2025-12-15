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
  final String status; // PENDING, CONFIRMED, COMPLETED, CANCELLED, NOSHOW
  final bool canCancel;

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
  });

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    String? avatar;
    if (json['doctor'] != null && json['doctor']['avatarUrl'] != null) {
      avatar = json['doctor']['avatarUrl'];
    } else if (json['doctorAvatar'] != null) {
      avatar = json['doctorAvatar'];
    }

    return PatientAppointment(
      id: json['appointmentId'] ?? 0,
      serviceName: json['serviceName'] ?? 'General Checkup',
      variantName: json['variantName'],
      doctorName: json['doctorName'] ?? 'Doctor',
      doctorAvatar: avatar,
      clinicName: json['clinicName'] ?? '',
      clinicAddress: json['clinicAddress'] ?? '',
      startDateTime:
          DateTime.tryParse(json['startDateTime'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'PENDING',
      canCancel: json['canCancel'] ?? false,
    );
  }
}

class MedicalRecord {
  final int id;
  final String doctorName;
  final String diagnosis;
  final String treatment;
  final String visitDate;
  // [MỚI] Thêm các trường này
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
      doctorName: json['doctorName'] ?? '',
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
  final String memberTier; // SILVER, GOLD, DIAMOND
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
      memberTier: json['memberTier'] ?? 'SILVER',
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      nextTierGoal: (json['nextTierGoal'] ?? 0).toDouble(),
      healthStatus: json['healthStatus'] ?? 'Unknown',
      healthMessage: json['healthMessage'] ?? '',
      daysSinceLastVisit: json['daysSinceLastVisit'] ?? 0,
      latestAiTip: json['latestAiTip'] ?? 'Luôn giữ nụ cười tươi!',
      nextAppointment: json['nextAppointment'] != null
          ? PatientAppointment.fromJson(json['nextAppointment'])
          : null,
      medicalHistory: (json['medicalHistory'] as List? ?? [])
          .map((e) => MedicalRecord.fromJson(e))
          .toList(),
    );
  }
}
