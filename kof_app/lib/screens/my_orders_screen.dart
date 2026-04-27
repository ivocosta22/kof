import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/past_order.dart';
import '../models/order.dart';
import '../providers/active_orders_provider.dart';
import '../services/api_service.dart';
import '../services/order_history_service.dart';
import 'order_status_screen.dart';
import 'scan_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<PastOrder>> _future;
  // Bumped on every reload — used as the FutureBuilder key so it fully resets
  // (rather than potentially showing the previous future's resolved data).
  int _reloadEpoch = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadOrders();
    // The bubble is redundant on this screen — we already show the full list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ActiveOrdersProvider>().pushSuppression();
      }
    });
  }

  @override
  void deactivate() {
    try {
      context.read<ActiveOrdersProvider>()
        ..popSuppression()
        ..refresh();
    } catch (_) {/* provider may already be gone */}
    super.deactivate();
  }

  // Load from local storage and then re-fetch from the server: active orders
  // (their status may have changed), and any entry with empty items (older
  // saves from before the server returned items on create). Falls back to the
  // cached entries if the shop is unreachable.
  Future<List<PastOrder>> _loadOrders() async {
    final service = OrderHistoryService();
    final orders = await service.getAll();
    final refreshed = await service.refreshFromServer(orders);
    // Provider is suppressed while we're on this screen, but we still keep
    // it primed so the bubble has correct data the moment we leave.
    if (mounted) {
      // Fire-and-forget — this just rereads from disk, no extra round trips.
      context.read<ActiveOrdersProvider>().refresh();
    }
    return refreshed;
  }

  // Returns a Future that resolves once the new load completes — pull-to-
  // refresh awaits this so the spinner stays visible while data is fetched.
  Future<void> _reload() async {
    final next = _loadOrders();
    setState(() {
      _future = next;
      _reloadEpoch++;
    });
    try {
      await next;
    } catch (_) {/* swallowed — FutureBuilder will surface errors */}
  }

  // Tap handler for any order card. Tries to fetch the latest order from the
  // origin server (so we have full items + current status) and opens the
  // status screen. Falls back to the cached PastOrder data if the server is
  // unreachable so the user always gets some view.
  Future<void> _openOrder(PastOrder past) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    Order order;
    try {
      order = await ApiService(past.serverUrl).getOrder(past.orderId);
      // Persist any status change immediately so the list reflects reality
      // even if the user backs out without triggering OrderStatusScreen's
      // own refresh path.
      if (order.status != past.status) {
        await OrderHistoryService().updateStatus(past.orderId, order.status);
      }
    } catch (_) {
      // Build a synthetic Order from the cached past entry. Live updates
      // won't work without the server, but the user still sees what's stored.
      order = Order(
        id: past.orderId,
        orderNumber: past.orderNumber,
        status: past.status,
        paymentStatus: 'unpaid',
        fulfillmentType: past.tableLabel.isEmpty ? 'counter_pickup' : 'table',
        tableLabel: past.tableLabel,
        customerLabel: '',
        note: '',
        items: past.items,
        createdAt: past.createdAt,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.orderStatusOffline)),
      );
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(
          order: order,
          serverUrlOverride: past.serverUrl,
          shopNameOverride: past.shopName,
        ),
      ),
    );
    // After returning, refresh the list so any status change is reflected.
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myOrdersTitle)),
      body: FutureBuilder<List<PastOrder>>(
        key: ValueKey(_reloadEpoch),
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) return _emptyState(theme, l10n);

          final active = orders.where((o) => o.isActive).toList();
          final past = orders.where((o) => !o.isActive).toList();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (active.isNotEmpty) ...[
                  _sectionHeader(l10n.myOrdersActive, theme),
                  ...active.map((o) => _OrderCard(
                        order: o,
                        theme: theme,
                        l10n: l10n,
                        onTap: () => _openOrder(o),
                      )),
                  const SizedBox(height: 8),
                ],
                if (past.isNotEmpty) ...[
                  _sectionHeader(l10n.myOrdersHistory, theme),
                  ...past.map((o) => _OrderCard(
                        order: o,
                        theme: theme,
                        l10n: l10n,
                        onTap: () => _openOrder(o),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String label, ThemeData theme) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      );

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
                child: Icon(Icons.receipt_long_outlined,
                    size: 44, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(l10n.myOrdersEmpty,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(l10n.myOrdersEmptySubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l10n.myOrdersScanCta),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _OrderCard extends StatelessWidget {
  final PastOrder order;
  final ThemeData theme;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _OrderCard({
    required this.order,
    required this.theme,
    required this.l10n,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = order.isActive;
    final statusColor = _statusColor(order.status);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: isActive
          ? BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5)
          : BorderSide.none,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      color: isActive
          ? statusColor.withValues(alpha: 0.06)
          : theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.shopName.isNotEmpty ? order.shopName : 'Coffee Shop',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  status: order.status,
                  color: statusColor,
                  l10n: l10n,
                  isTableOrder: order.tableLabel.isNotEmpty,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.orderNumber(order.orderNumber)}  ·  ${l10n.tableLabel(order.tableLabel)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _itemsSummary(order.items),
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '€${(order.totalCents / 100).toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _itemsSummary(List<OrderItem> items) =>
      items.map((i) => '${i.name} ×${i.qty}').join(', ');

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      // Drop the year for orders placed in the current year — keeps the line
      // compact without losing the date alongside the time.
      if (dt.year == now.year) return '$d/$mo · $h:$mi';
      return '$d/$mo/${dt.year} · $h:$mi';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) => switch (status) {
        'new' => Colors.blue.shade600,
        'making' => Colors.orange.shade600,
        'ready' => Colors.green.shade600,
        'completed' => Colors.green.shade700,
        'cancelled' => Colors.red.shade600,
        _ => Colors.grey,
      };
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  final AppLocalizations l10n;
  final bool isTableOrder;

  const _StatusChip({
    required this.status,
    required this.color,
    required this.l10n,
    this.isTableOrder = false,
  });

  String _label() => switch (status) {
        'new' => l10n.statusNew,
        'making' => l10n.statusMaking,
        // Table orders are delivered to the table — "Ready for Pickup" would
        // mislead. Use the delivery-flavoured copy instead.
        'ready' =>
          isTableOrder ? l10n.statusReadyTable : l10n.statusReady,
        'completed' => l10n.statusCompleted,
        'cancelled' => l10n.statusCancelled,
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
