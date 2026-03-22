class UserProfile {
  final String id;
  final String name;
  final String email;
  final String department;
  final String year;
  final String role; // student or canteen
  final String phone;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.year,
    required this.role,
    this.phone = '',
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? year,
    String? role,
    String? phone,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      year: year ?? this.year,
      role: role ?? this.role,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'year': year,
      'role': role,
      'phone': phone,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      department: map['department'] as String? ?? '',
      year: map['year'] as String? ?? '',
      role: map['role'] as String,
      phone: map['phone'] as String? ?? '',
    );
  }
}
