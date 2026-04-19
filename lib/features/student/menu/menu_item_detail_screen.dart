import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/cart_repository.dart';
import 'package:campus_eats_ag/models/cart_item.dart';
import 'package:campus_eats_ag/models/menu_item.dart';

class MenuItemDetailScreen extends ConsumerWidget {
  final MenuItem? item;
  final String itemId;

  const MenuItemDetailScreen({
    super.key,
    this.item,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedItem = item;

    if (resolvedItem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: Text('Item not found')),
      );
    }

    return _ItemDetailView(item: resolvedItem);
  }
}

class _ItemDetailView extends ConsumerWidget {
  final MenuItem item;
  const _ItemDetailView({required this.item});

  String get _categoryLabel {
    switch (item.categoryId) {
      case 'breakfast': return 'Breakfast';
      case 'meals': return 'Meals';
      case 'snacks': return 'Snacks';
      case 'beverages': return 'Beverages';
      case 'thali': return 'Thali';
      case 'chinese': return 'Chinese';
      default: return 'Food';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartQty = cartNotifier.getQuantity(item.id);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero image area as SliverAppBar
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: theme.colorScheme.surface,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                      tag: 'item_${item.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF1B3A2D),
                                    const Color(0xFF162E24)
                                  ]
                                : [
                                    const Color(0xFFE8F5E9),
                                    const Color(0xFFC8E6C9)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 100),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags row
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            VegBadge(isVeg: item.isVeg, size: 20),
                            _Badge(
                              label: _categoryLabel,
                              color: theme.colorScheme.primary,
                            ),
                            // Phase 6: Special badge
                            if (item.isSpecial)
                              _Badge(
                                label: item.specialLabel.isNotEmpty
                                    ? item.specialLabel
                                    : "Today's Special",
                                color: const Color(0xFFFF6B2B),
                                icon: Icons.star_rounded,
                              ),
                            if (item.isPopular && !item.isSpecial)
                              _Badge(
                                label: 'Popular',
                                color: AppColors.warning,
                                icon: Icons.local_fire_department_rounded,
                              ),
                            // Phase 6: Unavailable today
                            if (!item.isOrderable)
                              _Badge(
                                label: 'Unavailable Today',
                                color: theme.colorScheme.error,
                                icon: Icons.block_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Item name
                        Text(
                          item.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Info cards row
                        Row(
                          children: [
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.straighten_rounded,
                                label: 'Serving Size',
                                value: 'Standard',
                                sublabel: 'To be updated',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.star_rounded,
                                label: 'Rating',
                                value: '4.2',
                                sublabel: 'Avg. student rating',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Nutritional / extra info placeholder
                        AppCard(
                          child: Row(
                            children: [
                              Icon(
                                item.isVeg
                                    ? Icons.eco_rounded
                                    : Icons.restaurant_rounded,
                                color: item.isVeg
                                    ? AppColors.vegGreen
                                    : AppColors.nonVegRed,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.isVeg
                                          ? 'Vegetarian'
                                          : 'Non-Vegetarian',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: item.isVeg
                                            ? AppColors.vegGreen
                                            : AppColors.nonVegRed,
                                      ),
                                    ),
                                    Text(
                                       '$_categoryLabel • Freshly Prepared',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom sticky: price + add to cart
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Rs. ${item.price.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: !item.isOrderable
                        // Phase 6: Unavailable today — disabled button
                        ? AppButton(
                            label: 'Unavailable Today',
                            icon: Icons.block_rounded,
                            onTap: null,
                          )
                        : cartQty > 0
                            ? _QuantityStepper(item: item, qty: cartQty)
                            : AppButton(
                                label: 'Add to Cart',
                                icon: Icons.add_shopping_cart_rounded,
                                onTap: () async {
                                  await ref
                                      .read(cartProvider.notifier)
                                      .addItem(CartItem(
                                        menuItemId: item.id,
                                        name: item.name,
                                        price: item.price,
                                        isVeg: item.isVeg,
                                        emoji: item.emoji,
                                      ));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('${item.name} added to cart'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          Text(
            sublabel,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  final MenuItem item;
  final int qty;
  const _QuantityStepper({required this.item, required this.qty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: () => notifier.updateQuantity(item.id, qty - 1),
          ),
          Text(
            '$qty in cart',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => notifier.updateQuantity(item.id, qty + 1),
          ),
        ],
      ),
    );
  }
}
