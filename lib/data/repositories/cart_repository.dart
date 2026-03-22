import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_ag/models/cart_item.dart';

class CartRepository {
  static const String _key = 'cart_data';
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        _items.clear();
        _items.addAll(
          list.map((e) => CartItem.fromMap(Map<String, dynamic>.from(e as Map))),
        );
      } catch (_) {
        _items.clear();
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toMap()).toList()));
  }

  Future<void> addItem(CartItem item) async {
    final index = _items.indexWhere((i) => i.menuItemId == item.menuItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
    } else {
      _items.add(item);
    }
    await _save();
  }

  Future<void> removeItem(String menuItemId) async {
    _items.removeWhere((i) => i.menuItemId == menuItemId);
    await _save();
  }

  Future<void> updateQuantity(String menuItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(menuItemId);
      return;
    }
    final index = _items.indexWhere((i) => i.menuItemId == menuItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      await _save();
    }
  }

  Future<void> clear() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  int getQuantity(String menuItemId) {
    final index = _items.indexWhere((i) => i.menuItemId == menuItemId);
    return index >= 0 ? _items[index].quantity : 0;
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) => CartRepository());

class CartNotifier extends Notifier<List<CartItem>> {
  late CartRepository _repo;

  @override
  List<CartItem> build() {
    _repo = ref.read(cartRepositoryProvider);
    return List.from(_repo.items);
  }

  Future<void> load() async {
    await _repo.load();
    state = List.from(_repo.items);
  }

  Future<void> addItem(CartItem item) async {
    await _repo.addItem(item);
    state = List.from(_repo.items);
  }

  Future<void> removeItem(String menuItemId) async {
    await _repo.removeItem(menuItemId);
    state = List.from(_repo.items);
  }

  Future<void> updateQuantity(String menuItemId, int qty) async {
    await _repo.updateQuantity(menuItemId, qty);
    state = List.from(_repo.items);
  }

  Future<void> clear() async {
    await _repo.clear();
    state = [];
  }

  double get subtotal => _repo.subtotal;
  int get totalItems => _repo.itemCount;
  int getQuantity(String menuItemId) => _repo.getQuantity(menuItemId);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});
