class AppConstants {
  AppConstants._();

  static const String appName = 'CampusEats';
  static const String collegeFullName =
      "Vasantdada Patil Pratishthan's College of Engineering and Visual Arts";
  static const String collegeShort = 'VPPCOEVA';
  static const String canteenName = 'Campus Canteen';
  static const String footerNote = 'Show this token at the counter';

  // Hive box names
  static const String hiveBoxCart = 'cart_box';
  static const String hiveBoxOrders = 'orders_box';
  static const String hiveBoxMenu = 'menu_box';
  static const String hiveBoxUser = 'user_box';
  static const String hiveBoxPendingActions = 'pending_actions_box';
  static const String hiveBoxSettings = 'settings_box';
  static const String hiveBoxReports = 'reports_box';

  // SharedPreferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefCurrentRole = 'current_role';
  static const String prefStudentId = 'student_id';
  static const String prefStudentName = 'student_name';
  static const String prefStudentEmail = 'student_email';
  static const String prefStudentDept = 'student_dept';

  // Schedule order rules
  static const int scheduleMaxMinutes = 150; // 2.5 hours
  static const int scheduleSlotMinutes = 30;

  // Roles
  static const String roleStudent = 'student';
  static const String roleCanteen = 'canteen';

  // Currency symbol
  static const String rupee = 'Rs.';

  // Order states
  static const String stateScheduled = 'Scheduled';
  static const String statePending = 'Pending';
  static const String statePreparing = 'Preparing';
  static const String stateReady = 'Ready';
  static const String stateVerified = 'Verified';
  static const String stateCollected = 'Collected';

  // Payment methods
  static const String paymentUPI = 'UPI';
  static const String paymentCard = 'Card';
  static const String paymentWallet = 'Wallet';

  // Pending action types
  static const String actionMarkReady = 'mark_ready';
  static const String actionMarkVerified = 'mark_verified';
  static const String actionMarkCollected = 'mark_collected';
}
