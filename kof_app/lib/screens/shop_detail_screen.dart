import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/shop.dart';
import '../models/table_session.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../services/shop_service.dart';
import 'menu_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final ShopService _service = ShopService();
  final _scrollCtrl = ScrollController();
  bool? _isFollowing;
  bool _busy = false;
  bool _headerVisible = true;

  // Walk-in proximity
  double? _distanceMeters;
  bool _connectingWalkIn = false;

  static const _expandedHeight = 220.0;
  static const _proximityThresholdMeters = 150.0;

  @override
  void initState() {
    super.initState();
    _loadFollowState();
    _scrollCtrl.addListener(_onScroll);
    if (widget.shop.serverUrl != null && widget.shop.serverUrl!.isNotEmpty) {
      _computeDistance();
    }
  }

  Future<void> _computeDistance() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        widget.shop.latitude,
        widget.shop.longitude,
      );
      if (mounted) setState(() => _distanceMeters = dist);
    } catch (_) {
      // Location unavailable — walk-in button simply won't show
    }
  }

  Future<void> _startWalkIn() async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();
    // Pre-fill with user's display name if available
    nameCtrl.text = auth.user?.name ?? '';

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.shopWalkInDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shopWalkInWifi,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.shopWalkInNameLabel,
                hintText: l10n.shopWalkInNameHint,
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: Text(l10n.shopWalkInButton),
          ),
        ],
      ),
    );

    final name = confirmed?.trim() ?? '';
    if (name.isEmpty || !mounted) return;

    setState(() => _connectingWalkIn = true);
    try {
      final serverUrl = widget.shop.serverUrl!;
      final info = await ApiService(serverUrl).walkin();
      if (!mounted) return;
      if (info['ok'] != true) throw Exception(l10n.shopWalkInError);

      context.read<CartProvider>().clear();
      context.read<SessionProvider>().setSession(
            TableSession(
              serverUrl: serverUrl,
              shopName: widget.shop.name,
              fulfillmentType: 'counter_pickup',
              customerLabel: name,
            ),
          );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _connectingWalkIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shopWalkInError)),
      );
    }
  }

  void _onScroll() {
    final collapsed =
        _scrollCtrl.offset > _expandedHeight - kToolbarHeight;
    if (collapsed == _headerVisible) {
      setState(() => _headerVisible = !collapsed);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
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

    final overlayStyle = _headerVisible
        ? SystemUiOverlayStyle.light
        : (theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverAppBar(
            expandedHeight: _expandedHeight,
            pinned: true,
            backgroundColor: _headerVisible
                ? Colors.transparent
                : theme.colorScheme.surface,
            foregroundColor: _headerVisible
                ? Colors.white
                : theme.colorScheme.onSurface,
            systemOverlayStyle: overlayStyle,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                shop.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _headerVisible
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  shadows: _headerVisible
                      ? const [Shadow(color: Colors.black54, blurRadius: 8)]
                      : null,
                ),
              ),
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
                  if (_walkInAvailable) ...[
                    const SizedBox(height: 12),
                    _walkInButton(theme, l10n),
                  ],
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
      ), // AnnotatedRegion
    );
  }

  Widget _header(ThemeData theme) {
    final url = widget.shop.photoUrl;
    final image = (url != null && url.isNotEmpty)
        ? Image.network(
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
          )
        : _fallbackHeader(theme);

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
              stops: [0.4, 1.0],
            ),
          ),
        ),
      ],
    );
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

  bool get _walkInAvailable {
    final url = widget.shop.serverUrl;
    if (url == null || url.isEmpty) return false;
    final d = _distanceMeters;
    return d != null && d <= _proximityThresholdMeters;
  }

  Widget _walkInButton(ThemeData theme, AppLocalizations l10n) {
    final dist = _distanceMeters;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _connectingWalkIn ? null : _startWalkIn,
        icon: _connectingWalkIn
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.storefront_outlined),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _connectingWalkIn ? l10n.shopWalkInConnecting : l10n.shopWalkInButton,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            if (dist != null && !_connectingWalkIn)
              Text(
                l10n.shopWalkInDistanceLabel(dist.round()),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
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
