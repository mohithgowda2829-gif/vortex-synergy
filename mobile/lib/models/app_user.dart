class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.accountVerified,
    required this.emailVerified,
    required this.phoneVerified,
    required this.adminApproved,
    required this.active,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool accountVerified;
  final bool emailVerified;
  final bool phoneVerified;
  final bool adminApproved;
  final bool active;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      accountVerified: json['accountVerified'] as bool? ?? false,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      adminApproved: json['adminApproved'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'accountVerified': accountVerified,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'adminApproved': adminApproved,
      'active': active,
    };
  }
}
