import 'package:flutter/material.dart';
import '../demo/demo_api_service.dart';
import '../demo/demo_mode.dart';
import '../l10n/l10n.dart';
import '../models/menu_item.dart';
import '../models/shop.dart';
import '../services/api_service.dart';
import '../utils/menu_item_image.dart';

/// Read-only preview of a shop's menu — no cart, no ordering, just an
/// at-a-glance look at what they sell. Falls back to a friendly empty state
/// when the shop hasn't published a server URL or the server is unreachable.
class ShopMenuPreviewScreen extends StatefulWidget {
  final Shop shop;
  const ShopMenuPreviewScreen({super.key, required this.shop});

  @override
  State<ShopMenuPreviewScreen> createState() => _ShopMenuPreviewScreenState();
}

class _ShopMenuPreviewScreenState extends State<ShopMenuPreviewScreen> {
  List<MenuItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final serverUrl = widget.shop.serverUrl;
    if (serverUrl == null || serverUrl.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'unavailable';
      });
      return;
    }
    try {
      final items = kDemoMode
          ? await DemoApiService().getMenu()
          : await ApiService(serverUrl).getMenu();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'unreachable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.shopMenuPreviewHeading,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(theme, l10n),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                _error == 'unavailable'
                    ? l10n.shopPreviewNotAvailable
                    : l10n.shopPreviewUnreachable,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              if (_error == 'unreachable') ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  child: Text(l10n.menuRetry),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(l10n.menuNoItems,
            style: TextStyle(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      );
    }

    // Group items by category, preserving the global category order so the
    // UI stays consistent with the ordering menu screen.
    final grouped = _groupByCategory(_items);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                _localizedCategory(l10n, entry.key),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ...entry.value.map((it) => _PreviewCard(item: it)),
          ],
        ],
      ),
    );
  }

  Map<String, List<MenuItem>> _groupByCategory(List<MenuItem> items) {
    const order = [
      'Espresso',
      'Hot Drinks',
      'Cold Drinks',
      'Pastries',
      'Food',
      'Other',
    ];
    final groups = <String, List<MenuItem>>{};
    for (final item in items) {
      final key = order.contains(item.category) ? item.category : 'Other';
      groups.putIfAbsent(key, () => []).add(item);
    }
    final sorted = <String, List<MenuItem>>{};
    for (final cat in order) {
      if (groups.containsKey(cat)) sorted[cat] = groups[cat]!;
    }
    return sorted;
  }

  String _localizedCategory(AppLocalizations l10n, String category) {
    return switch (category) {
      'Espresso' => l10n.categoryEspresso,
      'Hot Drinks' => l10n.categoryHotDrinks,
      'Cold Drinks' => l10n.categoryColdDrinks,
      'Pastries' => l10n.categoryPastries,
      'Food' => l10n.categoryFood,
      _ => l10n.categoryOther,
    };
  }
}

class _PreviewCard extends StatelessWidget {
  final MenuItem item;
  const _PreviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailable = !item.isOrderable;
    final imagePath = imageAssetForItem(item.name);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unavailable
            ? theme.colorScheme.surfaceContainerLowest
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: imagePath != null
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(imagePath, fit: BoxFit.contain),
                    )
                  : Icon(
                      iconForMenuItem(
                        name: item.name,
                        category: item.category,
                      ),
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unavailable
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : null,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '€${(item.priceCents / 100).toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: unavailable
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
