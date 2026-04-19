import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/shop.dart';
import '../providers/auth_provider.dart';
import '../services/shop_service.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final ShopService _service = ShopService();
  bool? _isFollowing;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadFollowState();
  }

  Future<void> _loadFollowState() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.id;
    if (uid == null || auth.isGuest) {
      setState(() => _isFollowing = false);
      return;
    }
    final following = await _service.isFollowing(uid, widget.shop.id);
    if (!mounted) return;
    setState(() => _isFollowing = following);
  }

  Future<void> _toggleFollow() async {
    final auth = context.read<AuthProvider>();
    final l10n = context.l10n;
    final uid = auth.user?.id;
    if (uid == null || auth.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shopFollowRequiresAccount)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isFollowing == true) {
        await _service.unfollowShop(uid, widget.shop.id);
      } else {
        await _service.followShop(uid, widget.shop.id);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !(_isFollowing ?? false);
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shopFollowFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final shop = widget.shop;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(shop.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              centerTitle: true,
              background: _header(theme),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shop.rating != null) ...[
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 20, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          shop.rating!.toStringAsFixed(1),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (shop.address.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.place_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shop.address,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (shop.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: shop.tags
                          .map((t) => Chip(
                                label: Text(t),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _followButton(theme, l10n),
                  const SizedBox(height: 28),
                  if (shop.description.isNotEmpty) ...[
                    Text(l10n.shopAboutHeading,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(shop.description,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 28),
                  ],
                  _placeholderSection(
                      theme, l10n.shopMenuPreviewHeading, Icons.menu_book_outlined),
                  const SizedBox(height: 20),
                  _placeholderSection(
                      theme, l10n.shopReviewsHeading, Icons.reviews_outlined),
                  const SizedBox(height: 20),
                  _placeholderSection(
                      theme, l10n.shopDiscountsHeading, Icons.local_offer_outlined),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    final url = widget.shop.photoUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackHeader(theme),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    return _fallbackHeader(theme);
  }

  Widget _fallbackHeader(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.storefront_outlined,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _followButton(ThemeData theme, AppLocalizations l10n) {
    final isFollowing = _isFollowing == true;
    final label = isFollowing ? l10n.shopUnfollow : l10n.shopFollow;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _busy || _isFollowing == null ? null : _toggleFollow,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(isFollowing
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined),
        label: Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor:
              isFollowing ? theme.colorScheme.surfaceContainerHigh : null,
          foregroundColor: isFollowing ? theme.colorScheme.primary : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _placeholderSection(ThemeData theme, String title, IconData icon) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(l10n.shopSectionComingSoon,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
