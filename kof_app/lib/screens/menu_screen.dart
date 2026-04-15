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

  @override
  void initState() {
    super.initState();
    _loadMenu();
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
                l10n.tableLabel(session.tableLabel),
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
      body: _buildBody(theme, l10n),
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
