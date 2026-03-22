import 'package:campus_eats_ag/models/menu_category.dart';
import 'package:campus_eats_ag/models/menu_item.dart';

class MockMenuData {
  MockMenuData._();

  static const List<MenuCategory> categories = [
    MenuCategory(id: 'all', name: 'All', emoji: 'all'),
    MenuCategory(id: 'breakfast', name: 'Breakfast', emoji: 'sunrise'),
    MenuCategory(id: 'meals', name: 'Meals', emoji: 'meal'),
    MenuCategory(id: 'snacks', name: 'Snacks', emoji: 'snack'),
    MenuCategory(id: 'beverages', name: 'Beverages', emoji: 'beverage'),
    MenuCategory(id: 'thali', name: 'Thali', emoji: 'thali'),
    MenuCategory(id: 'chinese', name: 'Chinese', emoji: 'chinese'),
  ];

  static const List<MenuItem> items = [
    // ---- BREAKFAST ----
    MenuItem(
      id: 'b001',
      categoryId: 'breakfast',
      name: 'Poha',
      description: 'Flattened rice with peas, mustard, and fresh coriander',
      price: 30,
      isVeg: true,
      isPopular: true,
      emoji: '🍚',
    ),
    MenuItem(
      id: 'b002',
      categoryId: 'breakfast',
      name: 'Upma',
      description: 'Semolina cooked with vegetables and spices',
      price: 30,
      isVeg: true,
      isPopular: true,
      emoji: '🍲',
    ),
    MenuItem(
      id: 'b003',
      categoryId: 'breakfast',
      name: 'Sheera',
      description: 'Sweet semolina pudding with saffron and dry fruits',
      price: 25,
      isVeg: true,
      emoji: '🍮',
    ),
    MenuItem(
      id: 'b004',
      categoryId: 'breakfast',
      name: 'Idli Sambar',
      description: 'Steamed soft idlis served with hot sambar and chutney',
      price: 40,
      isVeg: true,
      isPopular: true,
      emoji: '🥙',
    ),
    MenuItem(
      id: 'b005',
      categoryId: 'breakfast',
      name: 'Sada Dosa',
      description: 'Thin crispy rice crepe served with sambar and chutney',
      price: 50,
      isVeg: true,
      emoji: '🫓',
    ),
    MenuItem(
      id: 'b006',
      categoryId: 'breakfast',
      name: 'Masala Dosa',
      description: 'Crispy dosa filled with spiced potato filling',
      price: 65,
      isVeg: true,
      isPopular: true,
      emoji: '🫓',
    ),
    MenuItem(
      id: 'b007',
      categoryId: 'breakfast',
      name: 'Butter Masala Dosa',
      description: 'Masala dosa prepared with generous butter',
      price: 75,
      isVeg: true,
      emoji: '🫓',
    ),
    MenuItem(
      id: 'b008',
      categoryId: 'breakfast',
      name: 'Onion Uttapa',
      description: 'Thick rice pancake topped with caramelized onions',
      price: 60,
      isVeg: true,
      emoji: '🥞',
    ),
    MenuItem(
      id: 'b009',
      categoryId: 'breakfast',
      name: 'Tomato Uttapa',
      description: 'Thick rice pancake topped with fresh tomatoes and herbs',
      price: 60,
      isVeg: true,
      emoji: '🥞',
    ),
    MenuItem(
      id: 'b010',
      categoryId: 'breakfast',
      name: 'Chapati',
      description: 'Soft whole-wheat flatbread, served plain or with sabji',
      price: 10,
      isVeg: true,
      emoji: '🫓',
    ),

    // ---- SNACKS ----
    MenuItem(
      id: 's001',
      categoryId: 'snacks',
      name: 'Batata Vada',
      description: 'Spiced potato dumpling in crispy gram-flour batter',
      price: 20,
      isVeg: true,
      isPopular: true,
      emoji: '🟡',
    ),
    MenuItem(
      id: 's002',
      categoryId: 'snacks',
      name: 'Medu Vada',
      description: 'Crispy lentil donuts served with sambar and chutney',
      price: 35,
      isVeg: true,
      emoji: '🍩',
    ),
    MenuItem(
      id: 's003',
      categoryId: 'snacks',
      name: 'Vada Pav',
      description: 'Mumbai street food - spicy vada in a soft pav bun',
      price: 25,
      isVeg: true,
      isPopular: true,
      emoji: '🍔',
    ),
    MenuItem(
      id: 's004',
      categoryId: 'snacks',
      name: 'Samosa Pav',
      description: 'Crispy samosa served with pav and green chutney',
      price: 30,
      isVeg: true,
      isPopular: true,
      emoji: '🥐',
    ),

    // ---- MEALS ----
    MenuItem(
      id: 'm001',
      categoryId: 'meals',
      name: 'Veg Thali',
      description: 'Dal, 2 sabji, rice, chapati, papad, and salad',
      price: 100,
      isVeg: true,
      isPopular: true,
      emoji: '🍽️',
    ),
    MenuItem(
      id: 'm004',
      categoryId: 'meals',
      name: 'Dal Tadka',
      description: 'Yellow dal tempered with ghee, cumin, and dry red chilli',
      price: 70,
      isVeg: true,
      emoji: '🫕',
    ),
    MenuItem(
      id: 'm005',
      categoryId: 'meals',
      name: 'Aloo Mutter',
      description: 'Potato and green peas in a tomato-onion gravy',
      price: 75,
      isVeg: true,
      emoji: '🥘',
    ),
    MenuItem(
      id: 'm006',
      categoryId: 'meals',
      name: 'Paneer Mutter',
      description: 'Paneer and green peas in a creamy onion-tomato gravy',
      price: 110,
      isVeg: true,
      isPopular: true,
      emoji: '🥘',
    ),
    MenuItem(
      id: 'm009',
      categoryId: 'meals',
      name: 'Paneer Tikka Masala',
      description: 'Grilled paneer in a smoky, creamy tikka sauce',
      price: 130,
      isVeg: true,
      isPopular: true,
      emoji: '🥘',
    ),
    MenuItem(
      id: 'm011',
      categoryId: 'meals',
      name: 'Paneer Biryani',
      description: 'Basmati rice layered with spiced paneer and saffron',
      price: 140,
      isVeg: true,
      isPopular: true,
      emoji: '🍛',
    ),
    MenuItem(
      id: 'm015',
      categoryId: 'meals',
      name: 'Jeera Rice',
      description: 'Steamed basmati rice tempered with cumin seeds and ghee',
      price: 70,
      isVeg: true,
      emoji: '🍚',
    ),
    MenuItem(
      id: 'm016',
      categoryId: 'meals',
      name: 'Puri Bhaji',
      description: 'Deep-fried puris served with spiced potato bhaji',
      price: 60,
      isVeg: true,
      isPopular: true,
      emoji: '🥙',
    ),
    MenuItem(
      id: 'm017',
      categoryId: 'meals',
      name: 'Pav Bhaji',
      description: 'Spiced mashed vegetables with buttery pav buns',
      price: 70,
      isVeg: true,
      isPopular: true,
      emoji: '🍲',
    ),

    // ---- THALI ----
    MenuItem(
      id: 't001',
      categoryId: 'thali',
      name: 'Veg Thali',
      description: 'Dal, 2 sabji, rice, chapati, papad, and salad — a complete meal',
      price: 100,
      isVeg: true,
      isPopular: true,
      emoji: '🍽️',
    ),
    MenuItem(
      id: 't002',
      categoryId: 'thali',
      name: 'Special Thali',
      description: 'Paneer curry, dal, rice, 3 chapati, salad, and sweet',
      price: 130,
      isVeg: true,
      isPopular: true,
      emoji: '🍽️',
    ),
    MenuItem(
      id: 't003',
      categoryId: 'thali',
      name: 'Punjabi Thali',
      description: 'Dal makhani, paneer, raita, rice, and 3 rotis',
      price: 140,
      isVeg: true,
      emoji: '🍽️',
    ),
    MenuItem(
      id: 't004',
      categoryId: 'thali',
      name: 'South Indian Thali',
      description: 'Rice, sambar, rasam, 2 sabji, papad, dessert',
      price: 120,
      isVeg: true,
      emoji: '🍽️',
    ),

    // ---- CHINESE ----
    MenuItem(
      id: 'c001',
      categoryId: 'chinese',
      name: 'Veg Fried Rice',
      description: 'Chinese-style stir-fried rice with mixed vegetables',
      price: 90,
      isVeg: true,
      isPopular: true,
      emoji: '🍚',
    ),
    MenuItem(
      id: 'c002',
      categoryId: 'chinese',
      name: 'Hakka Noodles',
      description: 'Stir-fried noodles tossed with vegetables and sauces',
      price: 90,
      isVeg: true,
      isPopular: true,
      emoji: '🍜',
    ),
    MenuItem(
      id: 'c003',
      categoryId: 'chinese',
      name: 'Chilli Paneer',
      description: 'Crispy paneer tossed in spicy Indo-Chinese chilli sauce',
      price: 130,
      isVeg: true,
      isPopular: true,
      emoji: '🥘',
    ),
    MenuItem(
      id: 'c004',
      categoryId: 'chinese',
      name: 'Manchurian',
      description: 'Crispy veggie balls in a tangy Manchurian sauce',
      price: 100,
      isVeg: true,
      emoji: '🍲',
    ),
    MenuItem(
      id: 'c005',
      categoryId: 'chinese',
      name: 'Spring Rolls',
      description: 'Crispy golden rolls stuffed with veggies, served with dip',
      price: 80,
      isVeg: true,
      emoji: '🥟',
    ),
    MenuItem(
      id: 'c006',
      categoryId: 'chinese',
      name: 'Schezwan Fried Rice',
      description: 'Spicy Schezwan-style fried rice with veggies',
      price: 100,
      isVeg: true,
      emoji: '🍚',
    ),

    // ---- BEVERAGES ----
    MenuItem(
      id: 'v001',
      categoryId: 'beverages',
      name: 'Tea',
      description: 'Freshly brewed milk tea with ginger and cardamom',
      price: 12,
      isVeg: true,
      isPopular: true,
      emoji: '☕',
    ),
    MenuItem(
      id: 'v002',
      categoryId: 'beverages',
      name: 'Coffee',
      description: 'Hot instant coffee with milk and sugar',
      price: 15,
      isVeg: true,
      emoji: '☕',
    ),
    MenuItem(
      id: 'v003',
      categoryId: 'beverages',
      name: 'Cold Drink',
      description: 'Chilled cold drink (Pepsi / Sprite / Mirinda)',
      price: 25,
      isVeg: true,
      emoji: '🥤',
    ),
  ];

  static List<MenuItem> getByCategory(String categoryId) {
    if (categoryId == 'all') return items;
    if (categoryId == 'popular') {
      return items.where((i) => i.isPopular).toList();
    }
    return items.where((i) => i.categoryId == categoryId).toList();
  }

  static List<MenuItem> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return items;
    return items
        .where((i) =>
            i.name.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q))
        .toList();
  }

  static MenuItem? findById(String id) {
    try {
      return items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<MenuItem> get popular =>
      items.where((i) => i.isPopular).take(8).toList();
}
