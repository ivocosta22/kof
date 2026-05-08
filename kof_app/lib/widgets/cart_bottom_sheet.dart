import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../demo/demo_api_service.dart';
import '../demo/demo_mode.dart';
import '../l10n/l10n.dart';
import '../models/cart_item.dart';
import '../models/shop_discount.dart';
import '../providers/active_orders_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/haptics.dart';
import '../providers/session_provider.dart';
import '../models/past_order.dart';
import '../services/api_error_messages.dart';
import '../services/api_service.dart';
import '../services/order_history_service.dart';
import '../screens/order_status_screen.dart';

class CartBottomSheet extends StatefulWidget {
  const CartBottomSheet({super.key});

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  bool _isPlacing = false;
  String? _error;
  final _noteController = TextEditingController();
  final _couponController = TextEditingController();

  bool _validatingCoupon = false;
  String? _couponError;
  ShopDiscount? _appliedDiscount;

  @override
  void dispose() {
    _noteController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  /// Split a discount's category field on commas. Empty list = no restriction.
  List<String> _parseCategoryList(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// Mirror of the server's discount calculation. Returns 0 when the cart
  /// doesn't satisfy the discount's conditions so the UI never previews a
  /// discount the server would reject.
  int _discountCentsFor(
    ShopDiscount d,
    int subtotalCents,
    List<CartItem> items,
  ) {
    final reqCats = _parseCategoryList(d.requiredCategory);
    if (reqCats.isNotEmpty &&
        !items.any((i) => reqCats.contains(i.menuItem.category))) {
      return 0;
    }

    int basis;
    final targetCats = _parseCategoryList(d.targetCategory);
    if (targetCats.isEmpty) {
      basis = subtotalCents;
    } else {
      final targetLines = items
          .where((i) => targetCats.contains(i.menuItem.category))
          .toList();
      if (targetLines.isEmpty) return 0;

      if (d.targetQty <= 0) {
        basis = targetLines.fold(0, (s, i) => s + i.totalCents);
      } else {
        // Cheapest N units across all matching lines.
        final unitPrices = <int>[];
        for (final line in targetLines) {
          for (var n = 0; n < line.qty; n++) {
            unitPrices.add(line.unitPriceCents);
          }
        }
        unitPrices.sort();
        basis = unitPrices.take(d.targetQty).fold(0, (s, p) => s + p);
      }
    }

    int cents = 0;
    if (d.percentageOff > 0) {
      cents = (basis * d.percentageOff) ~/ 100;
    } else if (d.amountOffCents > 0) {
      cents = d.amountOffCents;
    }
    if (cents > basis) cents = basis;
    if (cents > subtotalCents) cents = subtotalCents;
    return cents;
  }

  Future<void> _applyCoupon() async {
    final session = context.read<SessionProvider>().session;
    if (session == null) return;
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    Haptics.light();

    setState(() {
      _validatingCoupon = true;
      _couponError = null;
    });

    try {
      final discounts = kDemoMode
          ? await DemoApiService().getDiscounts()
          : await ApiService(session.serverUrl).getDiscounts();
      final match = discounts.where(
        (d) => d.code.toLowerCase() == code.toLowerCase(),
      );
      if (!mounted) return;
      if (match.isEmpty) {
        setState(() {
          _appliedDiscount = null;
          _couponError = context.l10n.cartCouponInvalid;
        });
        return;
      }

      final l10n = context.l10n;
      final discount = match.first;
      final cart = context.read<CartProvider>();
      // Cart-aware preflight: surface a friendly hint instead of silently
      // applying a 0-cent discount.
      final reqCats = _parseCategoryList(discount.requiredCategory);
      if (reqCats.isNotEmpty &&
          !cart.items.any((i) => reqCats.contains(i.menuItem.category))) {
        setState(() {
          _appliedDiscount = null;
          _couponError =
              l10n.cartCouponRequiresCategory(reqCats.join(' / '));
        });
        return;
      }
      final targetCats = _parseCategoryList(discount.targetCategory);
      if (targetCats.isNotEmpty &&
          !cart.items.any((i) => targetCats.contains(i.menuItem.category))) {
        setState(() {
          _appliedDiscount = null;
          _couponError =
              l10n.cartCouponNeedsTargetCategory(targetCats.join(' / '));
        });
        return;
      }

      setState(() {
        _appliedDiscount = discount;
        _couponError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _couponError = context.l10n.cartCouponInvalid);
    } finally {
      if (mounted) setState(() => _validatingCoupon = false);
    }
  }

  void _removeCoupon() {
    Haptics.selection();
    setState(() {
      _appliedDiscount = null;
      _couponError = null;
      _couponController.clear();
    });
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final session = context.read<SessionProvider>().session;
    if (session == null || cart.isEmpty) return;
    Haptics.medium();

    setState(() {
      _isPlacing = true;
      _error = null;
    });

    try {
      final api = kDemoMode ? DemoApiService() : ApiService(session.serverUrl);
      final order = await api.placeOrder(
        fulfillmentType: session.fulfillmentType,
        tableLabel: session.tableLabel,
        tableToken: session.tableToken,
        customerLabel: session.customerLabel,
        items: cart.toOrderItems(),
        note: _noteController.text.trim(),
        discountCode: _appliedDiscount?.code ?? '',
      );

      cart.clear();
      // Save then prime the bubble with the new active order. Awaiting save
      // before the refresh guarantees the provider sees the new entry.
      await OrderHistoryService().save(
        PastOrder.fromOrder(
          order,
          shopName: session.shopName,
          serverUrl: session.serverUrl,
        ),
      );
      if (context.mounted) {
        unawaited(context.read<ActiveOrdersProvider>().refresh());
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderStatusScreen(order: order)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPlacing = false;
        _error = localizedApiError(context.l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cart = context.watch<CartProvider>();
    final session = context.read<SessionProvider>().session;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.cartYourOrder,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (session != null)
                      Text(
                        session.fulfillmentType == 'counter_pickup'
                            ? session.customerLabel
                            : l10n.tableLabel(session.tableLabel),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ...cart.items.map(
                      (item) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 2),
                        title: Text(
                          item.menuItem.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          [
                            if (item.sizeName.isNotEmpty) item.sizeName,
                            l10n.cartEach(
                              '€${(item.unitPriceCents / 100).toStringAsFixed(2)}',
                            ),
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '€${(item.totalCents / 100).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            _SmallQtyControl(
                              qty: item.qty,
                              onIncrement: () {
                                Haptics.selection();
                                context
                                    .read<CartProvider>()
                                    .add(item.menuItem, size: item.size);
                              },
                              onDecrement: () {
                                Haptics.selection();
                                context
                                    .read<CartProvider>()
                                    .decrementLine(item.lineKey);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: TextField(
                        controller: _noteController,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: l10n.cartNoteHint,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _buildCouponField(theme, l10n),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_appliedDiscount != null) ...[
                      _totalsRow(
                        theme,
                        l10n.cartSubtotal,
                        '€${(cart.totalCents / 100).toStringAsFixed(2)}',
                        emphasised: false,
                      ),
                      const SizedBox(height: 4),
                      _totalsRow(
                        theme,
                        l10n.cartDiscount,
                        '-€${(_discountCentsFor(_appliedDiscount!, cart.totalCents, cart.items) / 100).toStringAsFixed(2)}',
                        emphasised: false,
                        valueColor: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                    ],
                    _totalsRow(
                      theme,
                      l10n.total,
                      '€${(((_appliedDiscount == null) ? cart.totalCents : (cart.totalCents - _discountCentsFor(_appliedDiscount!, cart.totalCents, cart.items))) / 100).toStringAsFixed(2)}',
                      emphasised: true,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: theme.colorScheme.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed:
                          _isPlacing ? null : () => _placeOrder(context),
                      style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: _isPlacing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              l10n.cartPlaceOrder,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _totalsRow(
    ThemeData theme,
    String label,
    String value, {
    required bool emphasised,
    Color? valueColor,
  }) {
    final style = emphasised
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style?.copyWith(color: valueColor)),
      ],
    );
  }

  Widget _buildCouponField(ThemeData theme, AppLocalizations l10n) {
    final hasApplied = _appliedDiscount != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                enabled: !hasApplied && !_validatingCoupon,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _applyCoupon(),
                decoration: InputDecoration(
                  hintText: l10n.cartCouponHint,
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            hasApplied
                ? OutlinedButton(
                    onPressed: _removeCoupon,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    child: Text(l10n.cartCouponRemove),
                  )
                : FilledButton(
                    onPressed: _validatingCoupon ? null : _applyCoupon,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    child: _validatingCoupon
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.cartCouponApply),
                  ),
          ],
        ),
        if (_couponError != null) ...[
          const SizedBox(height: 6),
          Text(
            _couponError!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
          ),
        ],
        if (hasApplied) ...[
          const SizedBox(height: 6),
          Text(
            l10n.cartCouponApplied(_appliedDiscount!.code),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SmallQtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _SmallQtyControl({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrement,
          child: Icon(Icons.remove_circle_outline,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$qty',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        GestureDetector(
          onTap: onIncrement,
          child: Icon(Icons.add_circle_outline,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
