class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final bool isVeg;
  final bool isPopular;
  final bool isAvailable;
  final String imageUrl; // can be empty - use placeholder
  final String emoji; // fallback emoji for card

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.isVeg = true,
    this.isPopular = false,
    this.isAvailable = true,
    this.imageUrl = '',
    this.emoji = '',
  });

  MenuItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    bool? isVeg,
    bool? isPopular,
    bool? isAvailable,
    String? imageUrl,
    String? emoji,
  }) {
    return MenuItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      isPopular: isPopular ?? this.isPopular,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'isVeg': isVeg,
      'isPopular': isPopular,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'emoji': emoji,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      isVeg: map['isVeg'] as bool? ?? true,
      isPopular: map['isPopular'] as bool? ?? false,
      isAvailable: map['isAvailable'] as bool? ?? true,
      imageUrl: map['imageUrl'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '',
    );
  }
}
