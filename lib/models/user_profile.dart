class UserProfile {
  final String id;
  final String name;
  final String email;
  final String department;
  final String year;
  final String role; // student | faculty | canteen
  final String phone;
  final String roomNumber; // faculty cabin/office number; empty for students
  /// Phase 7: sub-role for canteen users ('canteen_admin' | 'canteen').
  /// Always '' for students and faculty.
  final String canteenRole;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.year,
    required this.role,
    this.phone = '',
    this.roomNumber = '',
    this.canteenRole = '',
  });

  /// Phase 7: true if this user is a canteen admin / management user.
  bool get isAdmin => canteenRole == 'canteen_admin';

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? year,
    String? role,
    String? phone,
    String? roomNumber,
    String? canteenRole,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      year: year ?? this.year,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      roomNumber: roomNumber ?? this.roomNumber,
      canteenRole: canteenRole ?? this.canteenRole,
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
      'roomNumber': roomNumber,
      'canteenRole': canteenRole,
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
      roomNumber: map['roomNumber'] as String? ?? '',
      canteenRole: map['canteenRole'] as String? ?? '',
    );
  }
}
