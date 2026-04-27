import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/order.dart';
import '../providers/active_orders_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../services/order_history_service.dart';
import '../services/websocket_service.dart';
import 'menu_screen.dart';
import 'receipt_screen.dart';
import 'scan_screen.dart';

class OrderStatusScreen extends StatefulWidget {
  final Order order;

  // When opened from My Orders we may have no active SessionProvider session
  // (or it could belong to a different shop). These overrides let the screen
  // talk to the right server regardless of session state.
  final String? serverUrlOverride;
  final String? shopNameOverride;

  const OrderStatusScreen({
    super.key,
    required this.order,
    this.serverUrlOverride,
    this.shopNameOverride,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with SingleTickerProviderStateMixin {
  late Order _order;
  final WebSocketService _ws = WebSocketService();
  bool _wsConnected = false;
  late final AnimationController _radarController;

  static const _statusSteps = ['new', 'making', 'ready', 'completed'];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _connectWebSocket();
    // Hide the floating active-orders bubble while we're already showing
    // the same order in detail. Pop the suppression when this screen is torn
    // down so the bubble can come back on the previous route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ActiveOrdersProvider>().pushSuppression();
      }
    });
  }

  String? get _effectiveServerUrl =>
      widget.serverUrlOverride ??
      context.read<SessionProvider>().session?.serverUrl;

  void _connectWebSocket() {
    final serverUrl = _effectiveServerUrl;
    if (serverUrl == null) return;

    _ws.connect(
      serverUrl,
      _onWsMessage,
      onDone: () {
        if (mounted) setState(() => _wsConnected = false);
      },
      onError: (_) {
        if (mounted) setState(() => _wsConnected = false);
      },
    );
  }

  // The server wraps every event as { type, payload: {...} }. We mark
  // _wsConnected on the first message (the server sends 'realtime_connected'
  // immediately on accept), which is more honest than setting it optimistically
  // at connect-time.
  void _onWsMessage(Map<String, dynamic> msg) {
    if (!_wsConnected && mounted) setState(() => _wsConnected = true);

    final payload = msg['payload'] as Map<String, dynamic>?;
    if (payload == null) return;
    if (payload['id'] != _order.id) return;

    switch (msg['type']) {
      case 'order_status_changed':
        final newStatus = payload['status'] as String?;
        if (newStatus == null || newStatus == _order.status) return;
        // Persist BEFORE updating UI state so a fast back-press sees the new
        // status in local storage when My Orders re-reads it.
        unawaited(
            OrderHistoryService().updateStatus(_order.id, newStatus));
        if (mounted) setState(() => _order.status = newStatus);
        // Sync the floating bubble — its active-orders set might shrink
        // (e.g. status moved to completed/cancelled) while this screen is up.
        if (mounted) {
          unawaited(context.read<ActiveOrdersProvider>().refresh());
        }
        break;

      case 'order_payment_changed':
        final newPayment = payload['payment_status'] as String?;
        if (newPayment == null || newPayment == _order.paymentStatus) return;
        if (mounted) setState(() => _order.paymentStatus = newPayment);
        break;
    }
  }

  // Pull-to-refresh fallback for when the WebSocket has dropped or the user
  // wants to force a fresh status read.
  Future<void> _refreshOrder() async {
    final serverUrl = _effectiveServerUrl;
    if (serverUrl == null) return;
    try {
      final fresh = await ApiService(serverUrl).getOrder(_order.id);
      if (!mounted) return;
      if (fresh.status != _order.status) {
        OrderHistoryService().updateStatus(_order.id, fresh.status);
      }
      setState(() => _order = fresh);
    } catch (_) {
      // Silently swallow — the user can try again. The offline icon in the
      // app bar already signals connectivity issues.
    }
  }

  @override
  void deactivate() {
    // Best-effort: drop our suppression slot before the State is torn down so
    // the bubble can become visible again on the previous route.
    try {
      context.read<ActiveOrdersProvider>()
        ..popSuppression()
        ..refresh();
    } catch (_) {/* provider may already be gone */}
    super.deactivate();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _ws.disconnect();
    super.dispose();
  }

  int get _currentStepIndex {
    final idx = _statusSteps.indexOf(_order.status);
    return idx >= 0 ? idx : 0;
  }

  bool get _isCancelled => _order.status == 'cancelled';
  bool get _isDone =>
      _order.status == 'completed' || _order.status == 'cancelled';
  bool get _isProgressing => !_isDone;

  Map<String, String> _statusLabels(AppLocalizations l10n) => {
        'new': l10n.statusNew,
        'making': l10n.statusMaking,
        // Table orders are brought to the table by staff — saying "Ready for
        // Pickup" would be misleading. Use a delivery-flavoured label instead.
        'ready': _order.fulfillmentType == 'table'
            ? l10n.statusReadyTable
            : l10n.statusReady,
        'completed': l10n.statusCompleted,
        'cancelled': l10n.statusCancelled,
      };

  static const _statusIcons = {
    'new': Icons.receipt_long,
    'making': Icons.coffee_maker,
    'ready': Icons.check_circle_outline,
    'completed': Icons.check_circle,
    'cancelled': Icons.cancel_outlined,
  };

  Color _statusColor(ThemeData theme, String status) {
    return switch (status) {
      'new' => Colors.blue.shade600,
      'making' => Colors.orange.shade600,
      'ready' => Colors.green.shade600,
      'completed' => theme.colorScheme.primary,
      'cancelled' => theme.colorScheme.error,
      _ => theme.colorScheme.onSurface.withValues(alpha: 0.5),
    };
  }

  // Convert chosen-modifier values (string OR legacy {type,name} object) into
  // user-readable strings — same logic as the server-side helper.
  String _formatModifier(dynamic value) {
    if (value == null) return '';
    if (value is String) {
      if (value.startsWith('size:')) return value.substring(5);
      if (value.startsWith('milk:')) return '${value.substring(5)} milk';
      return value.replaceAll('_', ' ');
    }
    if (value is Map) {
      final name = value['name'];
      final type = value['type'];
      if (name != null) return name.toString();
      if (type != null) return type.toString();
    }
    return value.toString();
  }

  // Parse the server-supplied "YYYY-MM-DD HH:MM:SS" into a "HH:MM" display.
  String _formatTime(String createdAt) {
    if (createdAt.isEmpty) return '';
    final parts = createdAt.split(' ');
    if (parts.length < 2) return createdAt;
    final hms = parts[1].split(':');
    if (hms.length < 2) return parts[1];
    return '${hms[0]}:${hms[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final session = context.watch<SessionProvider>().session;
    final labels = _statusLabels(l10n);
    final color = _statusColor(theme, _order.status);
    final shopName =
        widget.shopNameOverride ?? session?.shopName ?? l10n.appName;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: canPop,
        title: Text(
          shopName,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_wsConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: l10n.orderStatusOffline,
                child: Icon(Icons.wifi_off,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(theme, l10n, color, labels),
              const SizedBox(height: 24),
              if (!_isCancelled) _buildStepBar(theme, color),
              if (_isCancelled) _buildCancelledBanner(theme, l10n),
              const SizedBox(height: 24),
              _buildOrderMetaCard(theme, l10n),
              const SizedBox(height: 16),
              _buildItemsCard(theme, l10n),
              if (_order.paymentStatus == 'paid') ...[
                const SizedBox(height: 12),
                _buildReceiptButton(theme, l10n, shopName),
              ],
              if (_order.note.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildNoteCard(theme, l10n),
              ],
              const SizedBox(height: 24),
              if (_isDone) _buildDoneActions(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Hero (radar circle around the current status icon) ---------------

  Widget _buildHero(
    ThemeData theme,
    AppLocalizations l10n,
    Color color,
    Map<String, String> labels,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar waves only animate while the order is in progress.
                if (_isProgressing) ..._buildRadarWaves(color),
                // Main status disc
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _statusIcons[_order.status] ?? Icons.info_outline,
                      key: ValueKey(_order.status),
                      color: color,
                      size: 56,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          labels[_order.status] ?? _order.status,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.orderNumber(_order.orderNumber),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 3 staggered expanding-fading circles — gives the "progress is happening"
  // signal the user explicitly asked for. Driven by a single repeating
  // controller; phase shift of 1/3 between waves keeps the rhythm steady.
  List<Widget> _buildRadarWaves(Color color) {
    return List.generate(3, (i) {
      return AnimatedBuilder(
        animation: _radarController,
        builder: (_, _) {
          final offset = i / 3.0;
          double t = (_radarController.value + offset) % 1.0;
          final scale = 0.6 + t * 1.4;     // 0.6 → 2.0
          final opacity = (1.0 - t) * 0.55; // fade as they expand
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // ----- Step progress bar (4 dots + connectors) --------------------------

  // Compact labels for the step bar — full status labels (e.g. "Ready for
  // Pickup") would clip on narrower phones since each step only gets 1/4 of
  // the row width.
  String _shortStatusLabel(String status) {
    return switch (status) {
      'new' => 'Received',
      'making' => 'Preparing',
      'ready' => 'Ready',
      'completed' => 'Done',
      _ => status,
    };
  }

  Widget _buildStepBar(ThemeData theme, Color color) {
    // Build steps + fixed-width connectors. Using fixed connectors instead of
    // Expanded gives each step column the full width it needs, so labels like
    // "Preparing" don't get clipped on narrow screens.
    final children = <Widget>[];
    for (int i = 0; i < _statusSteps.length; i++) {
      final isDone = i <= _currentStepIndex;
      final isCurrent = i == _currentStepIndex;

      children.add(Expanded(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: isCurrent ? 16 : 12,
              height: isCurrent ? 16 : 12,
              decoration: BoxDecoration(
                color: isDone ? color : theme.colorScheme.outlineVariant,
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _shortStatusLabel(_statusSteps[i]),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: isDone
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
          ],
        ),
      ));

      if (i < _statusSteps.length - 1) {
        children.add(Container(
          width: 18,
          height: 3,
          margin: const EdgeInsets.only(bottom: 28),
          decoration: BoxDecoration(
            color: i < _currentStepIndex
                ? color
                : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildCancelledBanner(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.orderCancelledMessage,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Order meta (fulfillment + time + payment + count) ----------------

  Widget _buildOrderMetaCard(ThemeData theme, AppLocalizations l10n) {
    final fulfillmentText = _order.fulfillmentType == 'counter_pickup'
        ? (_order.customerLabel.isNotEmpty
            ? l10n.orderStatusPickupFor(_order.customerLabel)
            : l10n.menuPickupOrder)
        : l10n.tableLabel(_order.tableLabel);

    final timeText = _formatTime(_order.createdAt);
    final isPaid = _order.paymentStatus == 'paid';

    return _Card(
      theme: theme,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MetaIcon(
                  icon: _order.fulfillmentType == 'counter_pickup'
                      ? Icons.takeout_dining
                      : Icons.table_restaurant,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fulfillmentText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _PaymentChip(isPaid: isPaid, theme: theme, l10n: l10n),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  timeText.isEmpty
                      ? '—'
                      : l10n.orderStatusPlacedAt(timeText),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.shopping_bag_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  l10n.orderStatusItemCount(
                      _order.items.fold<int>(0, (s, i) => s + i.qty)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----- Items list with totals -------------------------------------------

  Widget _buildItemsCard(ThemeData theme, AppLocalizations l10n) {
    return _Card(
      theme: theme,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Text(
                  l10n.orderStatusItems,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ..._order.items.map((item) => _ItemRow(
                item: item,
                theme: theme,
                modifierFormatter: _formatModifier,
              )),
          Divider(
              height: 1,
              indent: 18,
              endIndent: 18,
              color: theme.colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.total,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '€${(_order.totalCents / 100).toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptButton(
    ThemeData theme,
    AppLocalizations l10n,
    String shopName,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptScreen(order: _order, shopName: shopName),
            ),
          );
        },
        icon: const Icon(Icons.receipt_outlined),
        label: Text(l10n.receiptViewButton),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildNoteCard(ThemeData theme, AppLocalizations l10n) {
    return _Card(
      theme: theme,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetaIcon(
              icon: Icons.sticky_note_2_outlined,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.orderStatusNote,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _order.note,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () {
            context.read<CartProvider>().clear();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MenuScreen()),
            );
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(l10n.orderAgain,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            context.read<SessionProvider>().clearSession();
            context.read<CartProvider>().clear();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ScanScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(l10n.orderScanDifferentTable,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ---- Reusable bits --------------------------------------------------------

class _Card extends StatelessWidget {
  final ThemeData theme;
  final Widget child;
  const _Card({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetaIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MetaIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final bool isPaid;
  final ThemeData theme;
  final AppLocalizations l10n;
  const _PaymentChip(
      {required this.isPaid, required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final color =
        isPaid ? Colors.green.shade600 : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isPaid ? l10n.orderStatusPaid : l10n.orderStatusUnpaid,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  final ThemeData theme;
  final String Function(dynamic) modifierFormatter;
  const _ItemRow({
    required this.item,
    required this.theme,
    required this.modifierFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final modifierText = item.chosenModifiers.isEmpty
        ? null
        : item.chosenModifiers.map(modifierFormatter).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.qty}×',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600)),
                if (modifierText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    modifierText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '€${(item.lineTotalCents / 100).toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
