// lib/models/booking/booking_models.dart

class BookingClinic {
  final int id;
  final String clinicName;
  final String address;

  BookingClinic({required this.id, required this.clinicName, required this.address});

  factory BookingClinic.fromJson(Map<String, dynamic> json) {
    return BookingClinic(
      id: json['id'] ?? 0,
      clinicName: json['clinicName'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class BookingServiceVariant {
  final int variantId;
  final String variantName;
  final int duration;
  final double price;
  final String? description;

  BookingServiceVariant({
    required this.variantId,
    required this.variantName,
    required this.duration,
    required this.price,
    this.description,
  });

  factory BookingServiceVariant.fromJson(Map<String, dynamic> json) {
    return BookingServiceVariant(
      variantId: json['variantId'] ?? 0,
      variantName: json['variantName'] ?? '',
      duration: json['duration'] ?? 60,
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}

class BookingService {
  final int id;
  final String serviceName;
  final String category;
  final List<BookingServiceVariant> variants;

  BookingService({
    required this.id,
    required this.serviceName,
    required this.category,
    required this.variants,
  });

  factory BookingService.fromJson(Map<String, dynamic> json) {
    var list = json['variants'] as List? ?? [];
    List<BookingServiceVariant> variantsList =
    list.map((i) => BookingServiceVariant.fromJson(i)).toList();

    return BookingService(
      id: json['id'] ?? 0,
      serviceName: json['serviceName'] ?? '',
      category: json['category'] ?? '',
      variants: variantsList,
    );
  }
}

class BookingDoctor {
  final int id;
  final String fullName;
  final String? avatarUrl;
  final List<String> specialties;

  BookingDoctor({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.specialties,
  });

  factory BookingDoctor.fromJson(Map<String, dynamic> json) {
    return BookingDoctor(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? 'Doctor',
      avatarUrl: json['avatarUrl'],
      specialties: List<String>.from(json['specialties'] ?? []),
    );
  }
}

class TimeSlot {
  final String time; // "08:00:00"
  final bool available;

  TimeSlot({required this.time, required this.available});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time'] ?? '',
      available: json['available'] ?? false,
    );
  }
}

class SessionAvailability {
  final bool morningAvailable;
  final bool afternoonAvailable;
  final String? message;

  SessionAvailability({
    required this.morningAvailable,
    required this.afternoonAvailable,
    this.message,
  });

  factory SessionAvailability.fromJson(Map<String, dynamic> json) {
    return SessionAvailability(
      morningAvailable: json['morningAvailable'] ?? false,
      afternoonAvailable: json['afternoonAvailable'] ?? false,
      message: json['message'],
    );
  }
}