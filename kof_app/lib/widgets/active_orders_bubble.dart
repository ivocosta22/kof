import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../main.dart' show rootNavigatorKey;
import '../models/order.dart';
import '../models/past_order.dart';
import '../providers/active_orders_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/my_orders_screen.dart';
import '../screens/order_status_screen.dart';
import '../services/api_service.dart';
import '../services/order_history_service.dart';

/// Floating pill that surfaces active orders from anywhere in the app.
/// Tapping with one active order opens its status screen; with multiple it
/// opens the My Orders list.
class ActiveOrdersBubble extends StatefulWidget {
  const ActiveOrdersBubble({super.key});

  @override
  State<ActiveOrdersBubble> createState() => _ActiveOrdersBubbleState();
}

class _ActiveOrdersBubbleState extends State<ActiveOrdersBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radar;

  @override
  void initState() {
    super.initState();
    // Single repeating controller drives both the radar waves and the pill
    // glow. No reverse — phase wraps around so each wave is a fresh outward
    // expansion, matching the order status screen.
    _radar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _radar.dispose();
    super.dispose();
  }

  // Use the app-wide root navigator since this widget lives in
  // MaterialApp.builder, OUTSIDE the Navigator's subtree — Navigator.of(context)
  // can't find a Navigator from here.
  Future<void> _onTap(List<PastOrder> active) async {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    if (active.length == 1) {
      await _openSingle(nav, active.first);
    } else {
      await nav.push(
        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
      );
    }
    if (mounted) {
      await context.read<ActiveOrdersProvider>().refresh();
    }
  }

  // Fetch the latest order from the shop's server and open the status screen.
  // Falls back to a synthetic Order built from cached PastOrder fields if the
  // shop is unreachable so the user always gets some view.
  Future<void> _openSingle(NavigatorState nav, PastOrder past) async {
    Order order;
    try {
      order = await ApiService(past.serverUrl).getOrder(past.orderId);
      if (order.status != past.status) {
        await OrderHistoryService()
            .updateStatus(past.orderId, order.status);
      }
    } catch (_) {
      order = Order(
        id: past.orderId,
        orderNumber: past.orderNumber,
        status: past.status,
        paymentStatus: 'unpaid',
        fulfillmentType:
            past.tableLabel.isEmpty ? 'counter_pickup' : 'table',
        tableLabel: past.tableLabel,
        customerLabel: '',
        note: '',
        items: past.items,
        createdAt: past.createdAt,
      );
    }
    await nav.push(
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(
          order: order,
          serverUrlOverride: past.serverUrl,
          shopNameOverride: past.shopName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<ActiveOrdersProvider>();
    final active = provider.activeOrders;
    // Hide the bubble while no user is signed in — the auth flow is the only
    // thing visible at that point and surfacing leftover order state would be
    // both confusing and a small privacy leak.
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    final visible = loggedIn && !provider.isSuppressed && active.isNotEmpty;

    // AnimatedSwitcher fades between an invisible placeholder and the actual
    // bubble. Fade-in stops the bubble from popping in abruptly when active
    // orders arrive (e.g. after the screen loads or right after placing an
    // order); fade-out keeps the dismissal smooth too.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: !visible
          ? const SizedBox.shrink(key: ValueKey('hidden'))
          : _buildBubble(theme, l10n, active),
    );
  }

  Widget _buildBubble(
    ThemeData theme,
    AppLocalizations l10n,
    List<PastOrder> active,
  ) {
    final color = _statusColor(theme, _aggregatedStatus(active));
    final icon = _statusIcon(_aggregatedStatus(active));

    final label = active.length == 1
        ? _statusLabel(
            l10n,
            active.first.status,
            isTable: active.first.tableLabel.isNotEmpty,
          )
        : '${active.length} active orders';
    final subLabel = active.length == 1
        ? l10n.orderNumber(active.first.orderNumber)
        : null;

    return SafeArea(
      key: const ValueKey('visible'),
      // Tight to the bottom-right corner — only respects the system safe
      // area so it sits as close as possible to the gesture/nav indicator.
      minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 4, 12),
          // The radar circles need room to expand beyond the pill's bounds
          // without being clipped or pushing siblings, so we render them as
          // overflowing children of a Stack with no clipping.
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ..._buildRadarWaves(color),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onTap(active),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          if (subLabel != null)
                            Text(
                              subLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  // 3 staggered expanding-fading rings, same look as the order status screen
  // hero. Each ring uses Positioned.fill so it tracks the pill's actual size
  // (Stack sizes itself to the pill, the only non-positioned child) — that
  // way longer status labels grow the radar with them.
  List<Widget> _buildRadarWaves(Color color) {
    return List.generate(3, (i) {
      return Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _radar,
            builder: (_, _) {
              final offset = i / 3.0;
              final t = (_radar.value + offset) % 1.0;
              final scale = 0.9 + t * 0.7; // 0.9 → 1.6
              final opacity = (1.0 - t) * 0.75;
              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: color, width: 2.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  // When multiple orders are active, prefer the "most progressed" status so
  // the user sees the most actionable state (Ready beats Making beats New).
  String _aggregatedStatus(List<PastOrder> active) {
    if (active.any((o) => o.status == 'ready')) return 'ready';
    if (active.any((o) => o.status == 'making')) return 'making';
    return 'new';
  }

  String _statusLabel(
    AppLocalizations l10n,
    String status, {
    bool isTable = false,
  }) {
    return switch (status) {
      'new' => l10n.statusNew,
      'making' => l10n.statusMaking,
      // Table orders get the delivery-flavoured label since staff bring them
      // over rather than the customer picking up at the counter.
      'ready' => isTable ? l10n.statusReadyTable : l10n.statusReady,
      'completed' => l10n.statusCompleted,
      'cancelled' => l10n.statusCancelled,
      _ => status,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'new' => Icons.receipt_long,
      'making' => Icons.coffee_maker,
      'ready' => Icons.check_circle_outline,
      _ => Icons.local_cafe,
    };
  }

  Color _statusColor(ThemeData theme, String status) {
    return switch (status) {
      'new' => Colors.blue.shade600,
      'making' => Colors.orange.shade600,
      'ready' => Colors.green.shade600,
      _ => theme.colorScheme.primary,
    };
  }
}
