import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/data/api/api_client.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/models/menu_category.dart';
import 'package:campus_eats_ag/models/menu_item.dart';

/// Menu repository fetching categories and items from backend API.
class MenuRepository {
  final ApiClient _api;

  MenuRepository(this._api);

  Future<List<MenuCategory>> getCategories() async {
    final result = await _api.get('/menu/categories');
    if (!result.isSuccess || result.data is! List) return [];

    final categories = <MenuCategory>[
      const MenuCategory(id: 'all', name: 'All', emoji: 'all'),
    ];

    for (final c in result.data as List) {
      final m = c as Map<String, dynamic>;
      categories.add(MenuCategory(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: m['emoji'] as String? ?? '',
      ));
    }

    return categories;
  }

  Future<List<MenuItem>> getItems({String? categoryId, String? search}) async {
    String path = '/menu/items';
    final params = <String>[];
    if (categoryId != null && categoryId != 'all') {
      params.add('category=$categoryId');
    }
    if (search != null && search.isNotEmpty) {
      params.add('search=$search');
    }
    if (params.isNotEmpty) {
      path += '?${params.join('&')}';
    }

    final result = await _api.get(path);
    if (!result.isSuccess || result.data is! List) return [];

    return (result.data as List).map((e) => _parseItem(e as Map<String, dynamic>)).toList();
  }

  Future<MenuItem?> getItemById(String id) async {
    final result = await _api.get('/menu/items/$id');
    if (!result.isSuccess) return null;
    return _parseItem(result.data as Map<String, dynamic>);
  }

  /// Phase 6: Fetch full item list for canteen management (includes unavailable today).
  /// Requires canteen auth — call only from canteen-authenticated context.
  Future<List<MenuItem>> getManagementItems() async {
    final result = await _api.get('/menu/manage');
    if (!result.isSuccess || result.data is! List) return [];
    return (result.data as List).map((e) => _parseItem(e as Map<String, dynamic>)).toList();
  }

  /// Phase 6: Mark an item unavailable/available for today.
  Future<MenuItem?> setUnavailableToday(String itemId, {required bool isUnavailableToday}) async {
    final result = await _api.patch(
      '/menu/items/$itemId/availability',
      body: {'isUnavailableToday': isUnavailableToday},
    );
    if (!result.isSuccess || result.data == null) return null;
    return _parseItem(result.data as Map<String, dynamic>);
  }

  /// Phase 6: Mark/unmark an item as special/event food.
  Future<MenuItem?> setSpecial(String itemId, {required bool isSpecial, String? specialLabel}) async {
    final body = <String, dynamic>{'isSpecial': isSpecial};
    if (specialLabel != null) body['specialLabel'] = specialLabel;
    final result = await _api.patch('/menu/items/$itemId/special', body: body);
    if (!result.isSuccess || result.data == null) return null;
    return _parseItem(result.data as Map<String, dynamic>);
  }

  // ── Helper ─────────────────────────────────────────────────────

  MenuItem _parseItem(Map<String, dynamic> m) {
    final cat = m['category'] as Map<String, dynamic>?;
    return MenuItem(
      id: m['id'] as String,
      categoryId: m['categoryId'] as String? ?? cat?['id'] as String? ?? '',
      name: m['name'] as String,
      description: m['description'] as String? ?? '',
      price: (m['price'] as num).toDouble(),
      isVeg: m['isVeg'] as bool? ?? true,
      isPopular: m['isPopular'] as bool? ?? false,
      isAvailable: m['isAvailable'] as bool? ?? true,
      isUnavailableToday: m['isUnavailableToday'] as bool? ?? false,
      isSpecial: m['isSpecial'] as bool? ?? false,
      specialLabel: m['specialLabel'] as String? ?? '',
      imageUrl: m['imageUrl'] as String? ?? '',
      emoji: m['emoji'] as String? ?? '',
    );
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.read(apiClientProvider));
});
