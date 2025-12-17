class PatientProfileDTO {
  final int patientId;
  final String fullName;
  final String phone;
  final String email;
  final String? gender; // Nam, Nữ, Khác
  final DateTime? dateOfBirth;
  final String? address;
  final String? note; // Tiền sử bệnh
  final String patientCode;
  final String? avatarUrl; // Để hiển thị ảnh

  PatientProfileDTO({
    required this.patientId,
    required this.fullName,
    required this.phone,
    required this.email,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.note,
    required this.patientCode,
    this.avatarUrl,
  });

  factory PatientProfileDTO.fromJson(Map<String, dynamic> json) {
    return PatientProfileDTO(
      patientId: json['patientId'] ?? 0,
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      address: json['address'],
      note: json['note'],
      patientCode: json['patientCode'] ?? 'UNKNOWN',
      // API profile Java của bạn chưa trả avatarUrl,
      // nhưng ta có thể lấy tạm từ UserProvider hoặc thêm vào DTO Java sau.
      // Ở đây mình để null an toàn.
      avatarUrl: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String().split('T')[0], // yyyy-MM-dd
      'address': address,
      'phone': phone,
      'note': note,
    };
  }
}
