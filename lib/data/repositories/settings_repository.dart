import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/data/api/api_client.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';

/// Represents the canteen's operational status.
enum CanteenStatus { open, paused, closed }

class CanteenOperationalStatus {
  final CanteenStatus status;
  final String message;
  final DateTime? updatedAt;

  const CanteenOperationalStatus({
    required this.status,
    required this.message,
    this.updatedAt,
  });

  factory CanteenOperationalStatus.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status'] as String? ?? 'open';
    CanteenStatus status;
    switch (rawStatus) {
      case 'paused':
        status = CanteenStatus.paused;
        break;
      case 'closed':
        status = CanteenStatus.closed;
        break;
      default:
        status = CanteenStatus.open;
    }
    final updStr = map['updatedAt'] as String?;
    return CanteenOperationalStatus(
      status: status,
      message: map['message'] as String? ?? '',
      updatedAt: updStr != null ? DateTime.tryParse(updStr) : null,
    );
  }

  /// True when new orders can be placed.
  bool get isOpen => status == CanteenStatus.open;

  /// Human-readable label.
  String get statusLabel {
    switch (status) {
      case CanteenStatus.open:
        return 'Open';
      case CanteenStatus.paused:
        return 'Paused';
      case CanteenStatus.closed:
        return 'Closed';
    }
  }

  /// Customer-facing notice when ordering is blocked.
  String get customerNotice {
    if (message.isNotEmpty) return message;
    switch (status) {
      case CanteenStatus.open:
        return '';
      case CanteenStatus.paused:
        return 'The canteen is temporarily paused. Please try again later.';
      case CanteenStatus.closed:
        return 'The canteen is currently closed. Check back soon.';
    }
  }
}

class SettingsRepository {
  final ApiClient _api;

  SettingsRepository(this._api);

  /// Fetch current canteen operational status — no auth required.
  Future<CanteenOperationalStatus> getCanteenStatus() async {
    final result = await _api.get('/settings/status');
    if (!result.isSuccess) {
      // On network failure, assume open so existing clients don't break
      return const CanteenOperationalStatus(
        status: CanteenStatus.open,
        message: '',
      );
    }
    final data = result.data as Map<String, dynamic>;
    return CanteenOperationalStatus.fromMap(data);
  }

  /// Admin only: update canteen operational status.
  Future<CanteenOperationalStatus> setCanteenStatus({
    required CanteenStatus status,
    String message = '',
  }) async {
    final statusStr = status.name; // 'open' | 'paused' | 'closed'
    final result = await _api.patch('/settings/status', body: {
      'status': statusStr,
      'message': message,
    });
    if (!result.isSuccess) {
      throw Exception(result.message);
    }
    final data = result.data as Map<String, dynamic>;
    return CanteenOperationalStatus.fromMap(data);
  }

  /// Admin only: fetch all canteen staff.
  Future<List<Map<String, dynamic>>> getStaff() async {
    final result = await _api.get('/settings/staff');
    if (!result.isSuccess) throw Exception(result.message);
    return (result.data as List).cast<Map<String, dynamic>>();
  }

  /// Admin only: enable or disable a staff account.
  Future<Map<String, dynamic>> setStaffActive(
    String staffId, {
    required bool isActive,
  }) async {
    final result = await _api.patch(
      '/settings/staff/$staffId/active',
      body: {'isActive': isActive},
    );
    if (!result.isSuccess) throw Exception(result.message);
    return result.data as Map<String, dynamic>;
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(apiClientProvider));
});

/// Riverpod async provider for public canteen status — used by menu/cart screens.
final canteenStatusProvider =
    FutureProvider.autoDispose<CanteenOperationalStatus>((ref) async {
  final repo = ref.read(settingsRepositoryProvider);
  return repo.getCanteenStatus();
});
