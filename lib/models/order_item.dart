import 'cart_item.dart';

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final bool isVeg;
  final String emoji;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.isVeg = true,
    this.emoji = '',
  });

  double get lineTotal => price * quantity;

  factory OrderItem.fromCartItem(CartItem item) {
    return OrderItem(
      menuItemId: item.menuItemId,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      isVeg: item.isVeg,
      emoji: item.emoji,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'isVeg': isVeg,
      'emoji': emoji,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      isVeg: map['isVeg'] as bool? ?? true,
      emoji: map['emoji'] as String? ?? '',
    );
  }
}
