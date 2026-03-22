class CartItem {
  final String menuItemId;
  final String name;
  final double price;
  final bool isVeg;
  final String emoji;
  int quantity;

  CartItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.isVeg,
    this.emoji = '',
    this.quantity = 1,
  });

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      menuItemId: menuItemId,
      name: name,
      price: price,
      isVeg: isVeg,
      emoji: emoji,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'isVeg': isVeg,
      'emoji': emoji,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      menuItemId: map['menuItemId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      isVeg: map['isVeg'] as bool? ?? true,
      emoji: map['emoji'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
    );
  }
}
