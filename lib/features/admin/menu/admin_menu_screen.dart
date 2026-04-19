import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/menu_repository.dart';
import 'package:campus_eats_ag/models/menu_item.dart';

/// Phase 7: Admin view of menu management (same backend as CanteenMenuManageScreen
/// but located in the admin shell for the admin/management user).
class AdminMenuScreen extends ConsumerStatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  ConsumerState<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends ConsumerState<AdminMenuScreen> {
  List<MenuItem> _items = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final Set<String> _toggling = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final repo = ref.read(menuRepositoryProvider);
    final items = await repo.getManagementItems();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  List<MenuItem> get _filtered {
    if (_search.isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items.where((i) =>
        i.name.toLowerCase().contains(q) ||
        i.description.toLowerCase().contains(q)).toList();
  }

  Future<void> _toggleUnavailable(MenuItem item) async {
    setState(() => _toggling.add(item.id));
    try {
      final repo = ref.read(menuRepositoryProvider);
      final updated = await repo.setUnavailableToday(
        item.id,
        isUnavailableToday: !item.isUnavailableToday,
      );
      if (mounted && updated != null) {
        setState(() {
          final idx = _items.indexWhere((i) => i.id == item.id);
          if (idx >= 0) _items[idx] = updated;
        });
        _showSnack(
          updated.isUnavailableToday
              ? '${item.name} marked unavailable'
              : '${item.name} is available again',
          updated.isUnavailableToday ? Colors.orange : AppColors.vegGreen,
        );
      }
    } catch (e) {
      _showSnack('Failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _toggling.remove(item.id));
    }
  }

  Future<void> _toggleSpecial(MenuItem item) async {
    if (!item.isSpecial) {
      await _showSpecialDialog(item);
    } else {
      setState(() => _toggling.add(item.id));
      try {
        final repo = ref.read(menuRepositoryProvider);
        final updated = await repo.setSpecial(item.id, isSpecial: false);
        if (mounted && updated != null) {
          setState(() {
            final idx = _items.indexWhere((i) => i.id == item.id);
            if (idx >= 0) _items[idx] = updated;
          });
          _showSnack('Special flag removed from ${item.name}', Colors.grey);
        }
      } catch (e) {
        _showSnack('Failed: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _toggling.remove(item.id));
      }
    }
  }

  Future<void> _showSpecialDialog(MenuItem item) async {
    final presets = ["Today's Special", 'Event Food', 'Limited', 'Chef Special', 'Festival Special'];
    String? chosen;
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Mark as Special'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a label for "${item.name}"'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((p) => ChoiceChip(
                  label: Text(p),
                  selected: chosen == p,
                  onSelected: (_) => setS(() { chosen = p; ctrl.text = ''; }),
                )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                onChanged: (_) => setS(() => chosen = null),
                decoration: const InputDecoration(
                  hintText: 'Custom label (optional)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () { Navigator.pop(ctx, true); },
              child: const Text('Mark Special'),
            ),
          ],
        ),
      ),
    );

    final label = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : (chosen ?? '');
    setState(() => _toggling.add(item.id));
    try {
      final repo = ref.read(menuRepositoryProvider);
      final updated = await repo.setSpecial(item.id, isSpecial: true, specialLabel: label);
      if (mounted && updated != null) {
        setState(() {
          final idx = _items.indexWhere((i) => i.id == item.id);
          if (idx >= 0) _items[idx] = updated;
        });
        _showSnack('${item.name} marked as special', const Color(0xFFFF6B2B));
      }
    } catch (e) {
      _showSnack('Failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _toggling.remove(item.id));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;

    // Counts
    final unavailableCount = _items.where((i) => i.isUnavailableToday).length;
    final specialCount = _items.where((i) => i.isSpecial).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadItems,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search items…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadItems,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Summary chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          _SummaryChip(
                            label: '$unavailableCount Unavailable Today',
                            icon: Icons.block_rounded,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: '$specialCount Special',
                            icon: Icons.star_rounded,
                            color: const Color(0xFFFF6B2B),
                          ),
                          const SizedBox(width: 8),
                          Text('${_items.length} total',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),

                  if (items.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.restaurant_menu_rounded,
                        title: 'No items found',
                        subtitle: 'Try a different search',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          final isToggling = _toggling.contains(item.id);
                          return _AdminMenuItemCard(
                            item: item,
                            isToggling: isToggling,
                            onToggleUnavailable: () => _toggleUnavailable(item),
                            onToggleSpecial: () => _toggleSpecial(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ─── Summary Chip ────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ─── Menu Item Card ──────────────────────────────────────────────────────────

class _AdminMenuItemCard extends StatelessWidget {
  final MenuItem item;
  final bool isToggling;
  final VoidCallback onToggleUnavailable;
  final VoidCallback onToggleSpecial;

  const _AdminMenuItemCard({
    required this.item,
    required this.isToggling,
    required this.onToggleUnavailable,
    required this.onToggleSpecial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnavailable = item.isUnavailableToday;
    final isSpecial = item.isSpecial;

    return Opacity(
      opacity: isUnavailable ? 0.6 : 1.0,
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isUnavailable
                    ? Colors.grey.withValues(alpha: 0.12)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),

            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            decoration: isUnavailable
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSpecial)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.star_rounded,
                              color: const Color(0xFFFF6B2B), size: 16),
                        ),
                      if (isUnavailable)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.block_rounded,
                              color: Colors.orange, size: 14),
                        ),
                    ],
                  ),
                  Text(
                    'Rs. ${item.price.toInt()}${isSpecial && item.specialLabel.isNotEmpty ? " • ${item.specialLabel}" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isUnavailable)
                    Text('Unavailable today',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Toggle controls
            if (isToggling)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Column(
                children: [
                  // Unavailable toggle
                  Tooltip(
                    message: isUnavailable ? 'Mark Available' : 'Mark Unavailable Today',
                    child: InkWell(
                      onTap: onToggleUnavailable,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUnavailable
                                ? Colors.orange.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          isUnavailable ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          size: 16,
                          color: isUnavailable ? Colors.orange : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Special toggle
                  Tooltip(
                    message: isSpecial ? 'Remove Special' : 'Mark as Special',
                    child: InkWell(
                      onTap: onToggleSpecial,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSpecial
                              ? const Color(0xFFFF6B2B).withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSpecial
                                ? const Color(0xFFFF6B2B).withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          isSpecial ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 16,
                          color: isSpecial ? const Color(0xFFFF6B2B) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
