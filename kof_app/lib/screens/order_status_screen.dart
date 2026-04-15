import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/order.dart';
import '../providers/session_provider.dart';
import '../providers/cart_provider.dart';
import '../services/websocket_service.dart';
import 'scan_screen.dart';
import 'menu_screen.dart';

class OrderStatusScreen extends StatefulWidget {
  final Order order;

  const OrderStatusScreen({super.key, required this.order});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late Order _order;
  final WebSocketService _ws = WebSocketService();
  bool _wsConnected = false;

  static const _statusSteps = ['new', 'making', 'ready', 'completed'];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final session = context.read<SessionProvider>().session;
    if (session == null) return;

    _ws.connect(
      session.serverUrl,
      _onWsMessage,
      onDone: () {
        if (mounted) setState(() => _wsConnected = false);
      },
      onError: (_) {
        if (mounted) setState(() => _wsConnected = false);
      },
    );
    setState(() => _wsConnected = true);
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    if (msg['type'] != 'order_status_changed') return;
    if (msg['order_id'] != _order.id) return;

    final newStatus = msg['status'] as String?;
    if (newStatus == null) return;

    if (mounted) {
      setState(() => _order.status = newStatus);
    }
  }

  @override
  void dispose() {
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

  Map<String, String> _statusLabels(AppLocalizations l10n) => {
        'new': l10n.statusNew,
        'making': l10n.statusMaking,
        'ready': l10n.statusReady,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final session = context.watch<SessionProvider>().session;
    final labels = _statusLabels(l10n);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          session?.shopName ?? l10n.appName,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_wsConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.wifi_off,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderHeader(theme, l10n, labels),
            const SizedBox(height: 24),
            if (!_isCancelled) _buildStatusProgress(theme, l10n, labels),
            if (_isCancelled) _buildCancelledBadge(theme, l10n),
            const SizedBox(height: 24),
            _buildItemsList(theme, l10n),
            const SizedBox(height: 32),
            if (_isDone) _buildDoneActions(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(
    ThemeData theme,
    AppLocalizations l10n,
    Map<String, String> labels,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.orderNumber(_order.orderNumber),
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tableLabel(_order.tableLabel),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _statusIcons[_order.status] ?? Icons.info_outline,
                color: _statusColor(theme, _order.status),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                labels[_order.status] ?? _order.status,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _statusColor(theme, _order.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress(
    ThemeData theme,
    AppLocalizations l10n,
    Map<String, String> labels,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: List.generate(_statusSteps.length, (i) {
          final isDone = i <= _currentStepIndex;
          final isCurrent = i == _currentStepIndex;
          final isLast = i == _statusSteps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isCurrent ? 32 : 24,
                        height: isCurrent ? 32 : 24,
                        decoration: BoxDecoration(
                          color: isDone
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.circle,
                          color: isDone
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.35),
                          size: isCurrent ? 18 : 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[_statusSteps[i]] ?? _statusSteps[i],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDone
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 28),
                      color: i < _currentStepIndex
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCancelledBadge(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Text(
            l10n.orderCancelledMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme, AppLocalizations l10n) {
    final total =
        _order.items.fold<int>(0, (s, i) => s + i.lineTotalCents);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ..._order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${item.qty}×',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.name,
                        style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    '€${(item.lineTotalCents / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.total,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '€${(total / 100).toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
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
          child: Text(l10n.orderAgain),
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
          child: Text(l10n.orderScanDifferentTable),
        ),
      ],
    );
  }

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
}
