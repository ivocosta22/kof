import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../demo/demo_api_service.dart';
import '../demo/demo_mode.dart';
import '../l10n/l10n.dart';
import '../models/shop.dart';
import '../models/shop_discount.dart';
import '../services/api_service.dart';

/// Customer-facing discounts list. Pulls active discounts from the shop's
/// kof_server (`GET /api/discounts`). Falls back to a friendly empty state
/// when the shop hasn't published a server URL or has no active promotions.
class ShopDiscountsScreen extends StatefulWidget {
  final Shop shop;
  const ShopDiscountsScreen({super.key, required this.shop});

  @override
  State<ShopDiscountsScreen> createState() => _ShopDiscountsScreenState();
}

class _ShopDiscountsScreenState extends State<ShopDiscountsScreen> {
  List<ShopDiscount> _discounts = [];
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
        _error = 'unreachable';
      });
      return;
    }
    try {
      final list = kDemoMode
          ? await DemoApiService().getDiscounts()
          : await ApiService(serverUrl).getDiscounts();
      if (!mounted) return;
      setState(() {
        _discounts = list;
        _loading = false;
        _error = null;
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
          l10n.shopDiscountsHeading,
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
              Icon(Icons.local_offer_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                l10n.shopDiscountsUnreachable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
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
          ),
        ),
      );
    }

    if (_discounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_offer_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                l10n.shopDiscountsEmpty,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _discounts.length,
        itemBuilder: (_, i) =>
            _DiscountCard(discount: _discounts[i], theme: theme, l10n: l10n),
      ),
    );
  }
}

class _DiscountCard extends StatelessWidget {
  final ShopDiscount discount;
  final ThemeData theme;
  final AppLocalizations l10n;
  const _DiscountCard({
    required this.discount,
    required this.theme,
    required this.l10n,
  });

  // Use the brighter primary as a coupon-style accent to make discount cards
  // feel "promotional" rather than just another list item.
  Color get _accent => theme.colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final hasPercent = discount.percentageOff > 0;
    final hasAmount = discount.amountOffCents > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.95),
            _accent.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    discount.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            if (discount.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                discount.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hasPercent)
                  _Pill(
                    text: l10n.shopDiscountsPercentOff(discount.percentageOff),
                  ),
                if (hasAmount)
                  _Pill(
                    text: l10n.shopDiscountsAmountOff(
                      (discount.amountOffCents / 100).toStringAsFixed(2),
                    ),
                  ),
                if (discount.validUntil.isNotEmpty)
                  _Pill(
                    text: l10n.shopDiscountsValidUntil(discount.validUntil),
                    icon: Icons.event_outlined,
                  )
                else if (discount.validFrom.isNotEmpty)
                  _Pill(
                    text: l10n.shopDiscountsValidFrom(discount.validFrom),
                    icon: Icons.event_outlined,
                  ),
                if (discount.requiredCategory.isNotEmpty)
                  _Pill(
                    text: l10n.shopDiscountsRequires(discount.requiredCategory),
                    icon: Icons.shopping_bag_outlined,
                  ),
                if (discount.targetCategory.isNotEmpty)
                  _Pill(
                    text: discount.targetQty > 0
                        ? l10n.shopDiscountsAppliesQty(
                            discount.targetQty, discount.targetCategory)
                        : l10n.shopDiscountsAppliesAll(discount.targetCategory),
                    icon: Icons.local_offer_outlined,
                  ),
              ],
            ),
            if (discount.code.isNotEmpty) ...[
              const SizedBox(height: 14),
              _CodeChip(code: discount.code, l10n: l10n),
            ] else ...[
              const SizedBox(height: 14),
              _ClaimAtCounterBanner(text: l10n.shopDiscountsClaimAtCounter),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown on discount cards that have no promo code — explains how to redeem
/// the offer in person since the user can't apply it at app checkout.
class _ClaimAtCounterBanner extends StatelessWidget {
  final String text;
  const _ClaimAtCounterBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _Pill({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Tap-to-copy promo code chip — uses dashed strokes to read like a real
// coupon perforation. Snackbar confirms the copy so users get feedback.
class _CodeChip extends StatelessWidget {
  final String code;
  final AppLocalizations l10n;
  const _CodeChip({required this.code, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shopDiscountsCode(code))),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_copy_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              code,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
