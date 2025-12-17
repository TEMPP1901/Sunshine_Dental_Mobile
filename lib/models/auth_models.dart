class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final List<String> roles;
  final bool hasPassword; // Dùng để hiện/ẩn nút đổi mật khẩu

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    required this.roles,
    this.hasPassword = false,
  });

  // --- KỸ THUẬT QUAN TRỌNG: OPERATOR [] ---
  // Giúp HomePage gọi user['fullName'] không bị lỗi
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
      case 'userId':
        return id;
      case 'username':
        return username;
      case 'email':
        return email;
      case 'fullName':
        return fullName;
      case 'avatarUrl':
        return avatarUrl;
      case 'phone':
        return phone;
      case 'roles':
        return roles;
      case 'hasPassword':
        return hasPassword;
      default:
        return null;
    }
  }

  // Hàm copyWith để cập nhật từng trường lẻ
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    List<String>? roles,
    bool? hasPassword,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      roles: roles ?? this.roles,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] ?? json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? 'User',
      avatarUrl: json['avatarUrl'] ?? json['avatar'],
      phone: json['phone'],
      roles: (json['roles'] is List)
          ? (json['roles'] as List).map((e) => e.toString()).toList()
          : [],
      hasPassword: json['hasPassword'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'roles': roles,
      'hasPassword': hasPassword,
    };
  }
}
