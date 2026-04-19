import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/shop.dart';
import '../providers/auth_provider.dart';
import '../services/shop_service.dart';
import 'shop_detail_screen.dart';

class FollowedShopsScreen extends StatelessWidget {
  const FollowedShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final service = ShopService();
    final uid = auth.user?.id;

    Widget emptyState({required String title, required String body}) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.35)),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(body,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6))),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.followedShopsTitle)),
      body: (uid == null || auth.isGuest)
          ? emptyState(
              title: l10n.followedShopsGuestTitle,
              body: l10n.followedShopsGuestBody,
            )
          : StreamBuilder<List<Shop>>(
              stream: service.streamFollowedShops(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final shops = snapshot.data ?? const [];
                if (shops.isEmpty) {
                  return emptyState(
                    title: l10n.followedShopsEmptyTitle,
                    body: l10n.followedShopsEmptyBody,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: shops.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final shop = shops[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary
                            .withValues(alpha: 0.12),
                        foregroundImage:
                            (shop.photoUrl != null && shop.photoUrl!.isNotEmpty)
                                ? NetworkImage(shop.photoUrl!)
                                : null,
                        child: Icon(Icons.storefront_outlined,
                            color: theme.colorScheme.primary),
                      ),
                      title: Text(shop.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: shop.address.isNotEmpty
                          ? Text(shop.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ShopDetailScreen(shop: shop)),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
