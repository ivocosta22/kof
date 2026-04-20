import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/cart_bottom_sheet.dart';
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

  static const _hintFadeDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _loadMenu();
    // Show the coachmark only for walk-in (counter_pickup) sessions
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
    // Fade out first, then remove widget after animation completes
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
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
        child: Text(
          l10n.menuNoItems,
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMenu,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _items.length,
        itemBuilder: (_, i) => MenuItemCard(item: _items[i]),
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
        // Tail pointing up toward the QR icon (right-aligned)
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CustomPaint(
            size: const Size(12, 8),
            painter: _UpArrowPainter(color: bg),
          ),
        ),
        // Bubble body
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
