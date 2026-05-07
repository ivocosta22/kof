import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/active_orders_provider.dart';
import '../services/order_history_service.dart';
import '../services/shop_service.dart';

/// Call after a successful sign-in/registration. If the device has any past
/// orders or followed shops sitting in the local guest buckets, prompts the
/// user to move them into [newUid]'s account. Triggered by data presence —
/// not by the prior auth state — so it still fires when the user logged
/// out as guest before signing in to a real account.
Future<void> maybePromptGuestMigration(
  BuildContext context, {
  required String newUid,
}) async {
  if (newUid.isEmpty) return;

  final orderCount = await OrderHistoryService.guestOrderCount();
  final followCount = await ShopService.guestFollowedCount();
  if (orderCount == 0 && followCount == 0) return;
  if (!context.mounted) return;

  final l10n = context.l10n;
  final move = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.guestMigrateTitle),
      content: Text(l10n.guestMigrateBody(
        orderCount,
        followCount,
        (orderCount > 0 && followCount > 0).toString(),
      )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.guestMigrateDiscard),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.guestMigrateKeep),
        ),
      ],
    ),
  );

  if (move == true) {
    if (orderCount > 0) {
      await OrderHistoryService.migrateGuestToUser(newUid);
    }
    if (followCount > 0) {
      await ShopService().migrateGuestFollowsToUser(newUid);
    }
    if (!context.mounted) return;
    // Pick up the freshly-merged orders so the bubble + My Orders update.
    await context.read<ActiveOrdersProvider>().refresh();
  } else {
    // User declined — drop both guest buckets so the prompt doesn't re-fire.
    if (orderCount > 0) await OrderHistoryService.clearGuestBucket();
    if (followCount > 0) await ShopService.clearGuestFollows();
  }
}
