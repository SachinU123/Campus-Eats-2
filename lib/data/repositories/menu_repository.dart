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

    return (result.data as List).map((e) {
      final m = e as Map<String, dynamic>;
      final cat = m['category'] as Map<String, dynamic>?;
      return MenuItem(
        id: m['id'] as String,
        categoryId: m['categoryId'] as String? ?? cat?['slug'] as String? ?? '',
        name: m['name'] as String,
        description: m['description'] as String? ?? '',
        price: (m['price'] as num).toDouble(),
        isVeg: m['isVeg'] as bool? ?? true,
        isPopular: m['isPopular'] as bool? ?? false,
        isAvailable: m['isAvailable'] as bool? ?? true,
        imageUrl: m['imageUrl'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '',
      );
    }).toList();
  }

  Future<MenuItem?> getItemById(String id) async {
    final result = await _api.get('/menu/items/$id');
    if (!result.isSuccess) return null;
    final m = result.data as Map<String, dynamic>;
    return MenuItem(
      id: m['id'] as String,
      categoryId: m['categoryId'] as String? ?? '',
      name: m['name'] as String,
      description: m['description'] as String? ?? '',
      price: (m['price'] as num).toDouble(),
      isVeg: m['isVeg'] as bool? ?? true,
      isPopular: m['isPopular'] as bool? ?? false,
      isAvailable: m['isAvailable'] as bool? ?? true,
      imageUrl: m['imageUrl'] as String? ?? '',
      emoji: m['emoji'] as String? ?? '',
    );
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.read(apiClientProvider));
});
