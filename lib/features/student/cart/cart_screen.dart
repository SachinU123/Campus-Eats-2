import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/cart_repository.dart';
import 'package:campus_eats_ag/models/cart_item.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  DateTime? _scheduledSlot;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          subtitle: 'Add items from the menu to get started',
          actionLabel: 'Browse Menu',
          onAction: () => context.go('/student/menu'),
        ),
      );
    }

    final subtotal = notifier.subtotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Cart'),
                  content: const Text('Remove all items from your cart?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(cartProvider.notifier).clear();
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: cartItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _CartItemCard(item: cartItems[i]),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scheduled slot indicator
                  if (_scheduledSlot != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00838F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00838F).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF00838F)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scheduled for ${AppUtils.formatTimeShort(_scheduledSlot!)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF00838F),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _scheduledSlot = null),
                            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF00838F)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Subtotal
                  Row(
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      Text(
                        'Rs. ${subtotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showScheduleSheet(context),
                          icon: const Icon(Icons.schedule_rounded, size: 16),
                          label: const Text('Schedule'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/student/payment', extra: {
                              'subtotal': subtotal,
                              'scheduledFor': _scheduledSlot?.toIso8601String(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Proceed to Pay'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ScheduleSheet(
        onSelect: (slot) {
          setState(() => _scheduledSlot = slot);
          Navigator.pop(ctx);
        },
        currentSlot: _scheduledSlot,
      ),
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(cartProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegBadge(isVeg: item.isVeg),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${item.price.toInt()} each',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${item.lineTotal.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _StepB(
                    icon: item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove,
                    onTap: () {
                      if (item.quantity == 1) {
                        notifier.removeItem(item.menuItemId);
                      } else {
                        notifier.updateQuantity(item.menuItemId, item.quantity - 1);
                      }
                    },
                    color: item.quantity == 1 ? Colors.red : theme.colorScheme.primary,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  _StepB(
                    icon: Icons.add,
                    onTap: () => notifier.updateQuantity(item.menuItemId, item.quantity + 1),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _StepB({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _ScheduleSheet extends StatefulWidget {
  final ValueChanged<DateTime> onSelect;
  final DateTime? currentSlot;

  const _ScheduleSheet({required this.onSelect, this.currentSlot});

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  DateTime? _selected;
  late final List<DateTime> _slots;

  @override
  void initState() {
    super.initState();
    _slots = AppUtils.generateScheduleSlots();
    _selected = widget.currentSlot;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Schedule Pickup',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a slot at least 30 min ahead, up to 2 hours from now',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            if (_slots.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No scheduling slots available right now',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _slots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final slot = _slots[i];
                    final isSelected = _selected == slot;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppUtils.formatTimeShort(slot),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_slots.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppButton(
                label: _selected != null
                    ? 'Confirm - ${AppUtils.formatTimeShort(_selected!)}'
                    : 'Select a slot',
                onTap: _selected != null ? () => widget.onSelect(_selected!) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
