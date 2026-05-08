import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../utils/haptics.dart';
import '../models/notification_item.dart';
import '../providers/notifications_provider.dart';
import '../services/shop_service.dart';
import 'shop_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark everything read once the user has actually looked at the inbox.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsProvider>().markAllRead();
    });
  }

  Future<void> _confirmClear() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notificationsClearConfirmTitle),
        content: Text(l10n.notificationsClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.notificationsClearAll),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<NotificationsProvider>().clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.notificationsCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final items = context.watch<NotificationsProvider>().items;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: l10n.notificationsClearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: items.isEmpty
          ? _emptyState(theme, l10n)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _NotificationCard(item: items[i], theme: theme, l10n: l10n),
            ),
    );
  }

  Widget _emptyState(ThemeData theme, AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_outlined,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.notificationsEmpty,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.notificationsEmptySubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _NotificationCard({
    required this.item,
    required this.theme,
    required this.l10n,
  });

  String _ago() {
    final diff = DateTime.now().difference(item.receivedAt);
    if (diff.inMinutes < 1) return l10n.notificationsTimeJustNow;
    if (diff.inMinutes < 60) return l10n.notificationsTimeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.notificationsTimeHours(diff.inHours);
    return l10n.notificationsTimeDays(diff.inDays);
  }

  Future<void> _openShop(BuildContext context) async {
    final shopId = item.shopId;
    if (shopId == null || shopId.isEmpty) return;
    final shop = await ShopService().getShop(shopId);
    if (shop == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = !item.read;
    final tappable = item.shopId != null && item.shopId!.isNotEmpty;
    return GestureDetector(
      onTap: tappable ? () {
        Haptics.selection();
        _openShop(context);
      } : null,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unread
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: unread
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                width: 1,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.campaign_outlined,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title.isEmpty ? '—' : item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _ago(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
