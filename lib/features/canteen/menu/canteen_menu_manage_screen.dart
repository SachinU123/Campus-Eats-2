import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/l10n/canteen_language_provider.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/menu_repository.dart';
import 'package:campus_eats_ag/models/menu_item.dart';

/// Phase 6: Canteen-facing menu management screen.
/// Allows canteen staff to toggle "Unavailable Today" and "Special/Event Food"
/// for any menu item.  Simple, fast, non-technical UX.
class CanteenMenuManageScreen extends ConsumerStatefulWidget {
  const CanteenMenuManageScreen({super.key});

  @override
  ConsumerState<CanteenMenuManageScreen> createState() =>
      _CanteenMenuManageScreenState();
}

class _CanteenMenuManageScreenState
    extends ConsumerState<CanteenMenuManageScreen> {
  List<MenuItem> _items = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  // Track which item IDs are being toggled (for loading state)
  final Set<String> _toggling = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final repo = ref.read(menuRepositoryProvider);
    final items = await repo.getManagementItems();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  List<MenuItem> get _filtered {
    if (_search.isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items
        .where((i) =>
            i.name.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q))
        .toList();
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
        final s = ref.read(canteenL10nProvider);
        _showSnack(
          updated.isUnavailableToday
              ? s.markedUnavailable(item.name)
              : s.markedAvailableAgain(item.name),
          updated.isUnavailableToday ? Colors.orange : AppColors.vegGreen,
        );
      }
    } catch (e) {
      _showSnack('${ref.read(canteenL10nProvider).failedPrefix}: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _toggling.remove(item.id));
    }
  }

  Future<void> _toggleSpecial(MenuItem item) async {
    if (!item.isSpecial) {
      // Setting special: ask for optional label
      await _showSpecialLabelDialog(item);
    } else {
      // Clearing special: no label dialog needed
      setState(() => _toggling.add(item.id));
      try {
        final repo = ref.read(menuRepositoryProvider);
        final updated =
            await repo.setSpecial(item.id, isSpecial: false);
        if (mounted && updated != null) {
          setState(() {
            final idx = _items.indexWhere((i) => i.id == item.id);
            if (idx >= 0) _items[idx] = updated;
          });
          _showSnack(ref.read(canteenL10nProvider).specialRemoved(item.name), Colors.grey);
        }
      } catch (e) {
        _showSnack('${ref.read(canteenL10nProvider).failedPrefix}: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _toggling.remove(item.id));
      }
    }
  }

  Future<void> _showSpecialLabelDialog(MenuItem item) async {
    final presets = [
      "Today's Special",
      'Event Food',
      'Limited',
      'Chef Special',
      'Festival Special',
    ];
    String? chosen;
    final customCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final s = ref.read(canteenL10nProvider);
        return AlertDialog(
          title: Text(s.chooseSpecialLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.chooseForItem(item.name),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            ...presets.map((p) => StatefulBuilder(
                  builder: (ctx2, setSt) {
                    final selected = chosen == p;
                    return InkWell(
                      onTap: () => setSt(() => chosen = p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 20,
                              color: selected
                                  ? Theme.of(ctx2).colorScheme.primary
                                  : Theme.of(ctx2).colorScheme.outlineVariant,
                            ),
                            const SizedBox(width: 10),
                            Text(p, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                )),
            const SizedBox(height: 4),
            TextField(
              controller: customCtrl,
              decoration: InputDecoration(
                labelText: s.orTypeCustomLabel,
                isDense: true,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                // clear radio if user types custom
              },
            ),
          ],
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final label = customCtrl.text.trim().isNotEmpty
                    ? customCtrl.text.trim()
                    : (chosen ?? "Today's Special");
                Navigator.pop(ctx);
                setState(() => _toggling.add(item.id));
                try {
                  final repo = ref.read(menuRepositoryProvider);
                  final updated = await repo.setSpecial(
                    item.id,
                    isSpecial: true,
                    specialLabel: label,
                  );
                  if (mounted && updated != null) {
                    setState(() {
                      final idx = _items.indexWhere((i) => i.id == item.id);
                      if (idx >= 0) _items[idx] = updated;
                    });
                    _showSnack(
                      s.markedSpecial(item.name, label),
                      const Color(0xFFFF6B2B),
                    );
                  }
                } catch (e) {
                  _showSnack('${s.failedPrefix}: $e', Colors.red);
                } finally {
                  if (mounted) setState(() => _toggling.remove(item.id));
                }
              },
              child: Text(s.markSpecialBtn),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = ref.watch(canteenL10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.menuControls),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadItems,
            tooltip: s.menuRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend / quick guide
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.menuLegend,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: s.menuSearch,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                isDense: true,
              ),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.menu_book_rounded,
                        title: s.menuNoItems,
                        subtitle: s.menuNoItemsSub,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadItems,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          separatorBuilder: (_, $) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) =>
                              _MenuManageCard(
                            item: _filtered[i],
                            isToggling: _toggling.contains(_filtered[i].id),
                            onToggleUnavailable: () =>
                                _toggleUnavailable(_filtered[i]),
                            onToggleSpecial: () =>
                                _toggleSpecial(_filtered[i]),
                            s: s,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Item management card ─────────────────────────────────────────

class _MenuManageCard extends StatelessWidget {
  final MenuItem item;
  final bool isToggling;
  final VoidCallback onToggleUnavailable;
  final VoidCallback onToggleSpecial;
  final dynamic s; // CanteenStrings — kept as dynamic to avoid circular import issues

  const _MenuManageCard({
    required this.item,
    required this.isToggling,
    required this.onToggleUnavailable,
    required this.onToggleSpecial,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine card border color based on state
    final borderColor = item.isUnavailableToday
        ? theme.colorScheme.error.withValues(alpha: 0.5)
        : item.isSpecial
            ? const Color(0xFFFF6B2B).withValues(alpha: 0.5)
            : theme.colorScheme.outline.withValues(alpha: 0.2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: item.isUnavailableToday
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.15)
            : item.isSpecial
                ? const Color(0xFFFF6B2B).withValues(alpha: 0.07)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            // Emoji + isVeg indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(item.emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                if (item.isUnavailableToday)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.block_rounded,
                          color: Colors.white, size: 11),
                    ),
                  )
                else if (item.isSpecial)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B2B),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('⭐', style: TextStyle(fontSize: 9)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Name + category + special label
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
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: item.isUnavailableToday
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5)
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Rs. ${item.price.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (item.isSpecial && item.specialLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B2B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⭐ ${item.specialLabel}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF6B2B),
                            ),
                          ),
                        ),
                      ],
                      if (item.isUnavailableToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s.unavailableToday,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            if (isToggling)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Unavailable today toggle
                  Tooltip(
                    message: item.isUnavailableToday
                        ? s.markAvailable
                        : s.markUnavailable,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onToggleUnavailable,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: item.isUnavailableToday
                              ? theme.colorScheme.error.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.isUnavailableToday
                              ? Icons.check_circle_outline_rounded
                              : Icons.block_rounded,
                          size: 20,
                          color: item.isUnavailableToday
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Special/Event toggle
                  Tooltip(
                    message: item.isSpecial
                        ? s.removeSpecial
                        : s.markAsSpecial,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onToggleSpecial,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: item.isSpecial
                              ? const Color(0xFFFF6B2B).withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.isSpecial ? '⭐' : '☆',
                          style: const TextStyle(fontSize: 18),
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
