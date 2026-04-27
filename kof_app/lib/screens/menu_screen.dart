import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../utils/menu_item_image.dart';
import '../widgets/cart_bottom_sheet.dart';
import 'item_detail_screen.dart';
import 'scan_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<MenuItem> _items = [];
  bool _loading = true;
  String? _error;
  bool _showQrHint = false;
  bool _hintOpaque = false;
  Timer? _hintTimer;

  // 'All' means no filter; otherwise the literal category name on items.
  String _selectedCategory = 'All';

  static const _hintFadeDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _loadMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionProvider>().session;
      if (session?.fulfillmentType == 'counter_pickup') {
        setState(() {
          _showQrHint = true;
          _hintOpaque = true;
        });
        _hintTimer = Timer(const Duration(seconds: 6), _dismissHint);
      }
    });
  }

  void _dismissHint() {
    _hintTimer?.cancel();
    if (!mounted) return;
    setState(() => _hintOpaque = false);
    Future.delayed(_hintFadeDuration, () {
      if (mounted) setState(() => _showQrHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    final session = context.read<SessionProvider>().session;
    if (session == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await ApiService(session.serverUrl).getMenu();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _openCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartBottomSheet(),
    );
  }

  void _openItem(MenuItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
  }

  // Returns the categories present in the loaded menu, in a stable order
  // matching kAllCategories. Categories with zero items are omitted.
  List<String> get _availableCategories {
    final present = _items.map((i) => i.category).toSet();
    return kAllCategories.where(present.contains).toList();
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((i) => i.category == _selectedCategory).toList();
  }

  // Featured: first 3 items that have a matching cup illustration. Falls back
  // to first 3 items if none have illustrations.
  List<MenuItem> get _featuredItems {
    final withImages = _items
        .where((i) => imageAssetForItem(i.name) != null && i.isOrderable)
        .take(3)
        .toList();
    if (withImages.isNotEmpty) return withImages;
    return _items.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final session = context.watch<SessionProvider>().session;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session?.shopName ?? l10n.appName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (session != null)
              Text(
                session.fulfillmentType == 'counter_pickup'
                    ? l10n.menuPickupOrder
                    : l10n.tableLabel(session.tableLabel),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: l10n.menuScanDifferentTable,
            onPressed: () {
              context.read<SessionProvider>().clearSession();
              context.read<CartProvider>().clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(theme, l10n),
          if (_showQrHint)
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedOpacity(
                opacity: _hintOpaque ? 1.0 : 0.0,
                duration: _hintFadeDuration,
                child: GestureDetector(
                  onTap: _dismissHint,
                  child: _QrHintBubble(text: l10n.menuQrHint, theme: theme),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          cart.isEmpty ? null : _buildCartBar(context, cart, theme, l10n),
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
              Icon(Icons.wifi_off,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: _loadMenu, child: Text(l10n.menuRetry)),
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

    return RefreshIndicator(
      onRefresh: _loadMenu,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_featuredItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                l10n.menuFeatured,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _featuredItems.length,
                itemBuilder: (_, i) => _FeaturedCard(
                  item: _featuredItems[i],
                  onTap: () => _openItem(_featuredItems[i]),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (_availableCategories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                l10n.menuCategories,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryPill(
                    label: l10n.categoryAll,
                    icon: Icons.grid_view_rounded,
                    selected: _selectedCategory == 'All',
                    onTap: () => setState(() => _selectedCategory = 'All'),
                  ),
                  for (final cat in _availableCategories)
                    _CategoryPill(
                      label: localizedCategoryLabel(l10n, cat),
                      icon: iconForCategory(cat),
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              _selectedCategory == 'All'
                  ? l10n.menuAllItems
                  : localizedCategoryLabel(l10n, _selectedCategory),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ..._filteredItems.map(
            (item) => _MenuListCard(item: item, onTap: () => _openItem(item)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBar(
    BuildContext context,
    CartProvider cart,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => _openCart(context),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cart.itemCount}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.menuReviewOrder,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
              ),
              Text(
                '€${(cart.totalCents / 100).toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----- Category metadata ----------------------------------------------------

const kAllCategories = <String>[
  'Espresso',
  'Hot Drinks',
  'Cold Drinks',
  'Pastries',
  'Food',
  'Other',
];

String localizedCategoryLabel(AppLocalizations l10n, String category) {
  return switch (category) {
    'Espresso' => l10n.categoryEspresso,
    'Hot Drinks' => l10n.categoryHotDrinks,
    'Cold Drinks' => l10n.categoryColdDrinks,
    'Pastries' => l10n.categoryPastries,
    'Food' => l10n.categoryFood,
    _ => l10n.categoryOther,
  };
}

// ----- Featured tile (large green card with cup imagery) --------------------

class _FeaturedCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  const _FeaturedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = imageAssetForItem(item.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // ClipRRect lets the image visually overflow the inner padding while
        // still respecting the rounded corners.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Cup image — fills the top portion of the card, overflowing
              // beyond the text area's padding so it looks bigger without
              // changing the card dimensions.
              Positioned(
                top: -8,
                left: -8,
                right: -8,
                bottom: 60,
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.coffee,
                          color: Colors.white,
                          size: 100,
                        ),
                      )
                    : const Icon(Icons.coffee,
                        color: Colors.white, size: 100),
              ),
              // Title + price pinned to the bottom of the card.
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '€${(item.priceCents / 100).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----- Category chip --------------------------------------------------------

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Compact menu list card (under "All items"/category) ------------------

class _MenuListCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  const _MenuListCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cart = context.watch<CartProvider>();
    final qty = cart.qtyFor(item.id);
    final unavailable = !item.isOrderable;
    final imagePath = imageAssetForItem(item.name);

    return GestureDetector(
      onTap: unavailable ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unavailable
              ? theme.colorScheme.surfaceContainerLowest
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
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
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: unavailable
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4)
                                : null,
                          ),
                        ),
                      ),
                      if (item.availability == 'low')
                        _StatusChip(
                          label: l10n.menuItemLowStock,
                          color: Colors.orange.shade700,
                        ),
                      if (unavailable)
                        _StatusChip(
                          label: l10n.menuItemUnavailable,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '€${(item.priceCents / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: unavailable
                          ? theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!unavailable)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.add,
                          color: theme.colorScheme.onPrimary, size: 22),
                    ),
                    if (qty > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: theme.colorScheme.primary, width: 1),
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              '$qty',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ----- QR coachmark bubble (kept from original) -----------------------------

class _QrHintBubble extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _QrHintBubble({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    final bg = theme.colorScheme.inverseSurface;
    final fg = theme.colorScheme.onInverseSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CustomPaint(
            size: const Size(12, 8),
            painter: _UpArrowPainter(color: bg),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.close, size: 14, color: fg.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpArrowPainter extends CustomPainter {
  final Color color;
  const _UpArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_UpArrowPainter old) => old.color != color;
}
