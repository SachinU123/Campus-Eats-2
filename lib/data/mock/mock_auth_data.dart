import 'package:campus_eats_ag/models/user_profile.dart';

class MockAuthData {
  MockAuthData._();

  static const String studentPassword = 'student123';
  static const String canteenPassword = 'canteen123';

  /// The fixed mock OTP for canteen staff (demo only).
  static const String canteenOtp = '1234';

  static const List<UserProfile> mockStudents = [
    UserProfile(
      id: 'stu001',
      name: 'Priya Sharma',
      email: 'priya@vppcoeva.edu.in',
      department: 'Computer Engineering',
      year: 'Second Year',
      role: 'student',
      phone: '9876543210',
    ),
    UserProfile(
      id: 'stu002',
      name: 'Rahul Patil',
      email: 'rahul@vppcoeva.edu.in',
      department: 'Mechanical Engineering',
      year: 'Third Year',
      role: 'student',
      phone: '9876543211',
    ),
    UserProfile(
      id: 'stu003',
      name: 'Aisha Khan',
      email: 'aisha@vppcoeva.edu.in',
      department: 'Electronics Engineering',
      year: 'First Year',
      role: 'student',
      phone: '9876543212',
    ),
  ];

  static const List<UserProfile> mockCanteenStaff = [
    UserProfile(
      id: 'can001',
      name: 'Canteen Admin',
      email: 'canteen@vppcoeva.edu.in',
      department: 'Canteen',
      year: '',
      role: 'canteen',
      phone: '9876540000',
    ),
  ];

  /// Email + password login (used for student side).
  static UserProfile? login(String email, String password) {
    // Student login
    final student = mockStudents.where((u) => u.email == email).firstOrNull;
    if (student != null && password == studentPassword) return student;

    // Canteen email login (fallback for old demo credentials)
    final canteen =
        mockCanteenStaff.where((u) => u.email == email).firstOrNull;
    if (canteen != null && password == canteenPassword) return canteen;

    return null;
  }

  /// Phone + OTP login (used for canteen side).
  static UserProfile? loginByPhone(String phone) {
    return mockCanteenStaff.where((u) => u.phone == phone).firstOrNull;
  }

  /// Validates the OTP for a given phone number.
  /// For the mock, any registered canteen phone number accepts otp '1234'.
  static bool validateCanteenOtp(String phone, String otp) {
    final isRegistered =
        mockCanteenStaff.any((u) => u.phone == phone);
    return isRegistered && otp == canteenOtp;
  }

  static UserProfile register({
    required String name,
    required String email,
    required String department,
    required String year,
    required String phone,
    required String role,
  }) {
    return UserProfile(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      department: department,
      year: year,
      role: role,
      phone: phone,
    );
  }
}
