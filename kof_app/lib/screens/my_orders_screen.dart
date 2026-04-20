import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/past_order.dart';
import '../models/order.dart';
import '../services/order_history_service.dart';
import 'scan_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<PastOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = OrderHistoryService().getAll();
  }

  void _reload() => setState(() => _future = OrderHistoryService().getAll());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myOrdersTitle)),
      body: FutureBuilder<List<PastOrder>>(
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
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (active.isNotEmpty) ...[
                  _sectionHeader(l10n.myOrdersActive, theme),
                  ...active.map((o) => _OrderCard(order: o, theme: theme, l10n: l10n)),
                  const SizedBox(height: 8),
                ],
                if (past.isNotEmpty) ...[
                  _sectionHeader(l10n.myOrdersHistory, theme),
                  ...past.map((o) => _OrderCard(order: o, theme: theme, l10n: l10n)),
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

  const _OrderCard({
    required this.order,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = order.isActive;
    final statusColor = _statusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isActive
            ? BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      color: isActive
          ? statusColor.withValues(alpha: 0.06)
          : theme.colorScheme.surfaceContainerLow,
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
                _StatusChip(status: order.status, color: statusColor, l10n: l10n),
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
    );
  }

  String _itemsSummary(List<OrderItem> items) =>
      items.map((i) => '${i.name} ×${i.qty}').join(', ');

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
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

  const _StatusChip({
    required this.status,
    required this.color,
    required this.l10n,
  });

  String _label() => switch (status) {
        'new' => l10n.statusNew,
        'making' => l10n.statusMaking,
        'ready' => l10n.statusReady,
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
