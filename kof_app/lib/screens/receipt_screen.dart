import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/order.dart';

/// Read-only receipt for paid orders. Designed to feel like a paper receipt
/// (white card, monospaced numbers, dashed dividers) rather than the usual
/// material card. Push this from the order status screen when the order is
/// paid.
class ReceiptScreen extends StatelessWidget {
  final Order order;
  final String shopName;
  const ReceiptScreen({
    super.key,
    required this.order,
    required this.shopName,
  });

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year}  ·  $h:$mi';
    } catch (_) {
      return iso;
    }
  }

  String _formatModifier(dynamic value) {
    if (value == null) return '';
    if (value is String) {
      if (value.startsWith('size:')) return value.substring(5);
      if (value.startsWith('milk:')) return '${value.substring(5)} milk';
      return value.replaceAll('_', ' ');
    }
    if (value is Map) {
      return (value['name'] ?? value['type'] ?? '').toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isPaid = order.paymentStatus == 'paid';

    final fulfillment = order.fulfillmentType == 'counter_pickup'
        ? (order.customerLabel.isNotEmpty
            ? l10n.orderStatusPickupFor(order.customerLabel)
            : l10n.menuPickupOrder)
        : l10n.tableLabel(order.tableLabel);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.receiptTitle,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      shopName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isPaid)
                      Center(child: _PaidStamp(label: l10n.receiptPaidStamp)),
                    const SizedBox(height: 18),
                    _CenteredLine(
                      l10n.orderNumber(order.orderNumber),
                      bold: true,
                    ),
                    const SizedBox(height: 4),
                    _CenteredLine(_formatDateTime(order.createdAt)),
                    const SizedBox(height: 4),
                    _CenteredLine(fulfillment),
                    const SizedBox(height: 18),
                    const _DashedDivider(),
                    const SizedBox(height: 14),
                    ...order.items.map((item) => _ReceiptLine(
                          item: item,
                          modifierFormatter: _formatModifier,
                        )),
                    const SizedBox(height: 8),
                    const _DashedDivider(),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.total,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '€${(order.totalCents / 100).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (order.note.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _DashedDivider(),
                      const SizedBox(height: 12),
                      Text(
                        '${l10n.orderStatusNote}: ${order.note}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      l10n.receiptThankYou,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredLine extends StatelessWidget {
  final String text;
  final bool bold;
  const _CenteredLine(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final OrderItem item;
  final String Function(dynamic) modifierFormatter;
  const _ReceiptLine({required this.item, required this.modifierFormatter});

  @override
  Widget build(BuildContext context) {
    final modifierText = item.chosenModifiers.isEmpty
        ? null
        : item.chosenModifiers.map(modifierFormatter).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${item.qty}×',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '€${(item.lineTotalCents / 100).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (modifierText != null)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 2),
              child: Text(
                modifierText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashGap = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            math.max(dashCount, 1),
            (_) => const SizedBox(
              width: dashWidth,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCCCCCC)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaidStamp extends StatelessWidget {
  final String label;
  const _PaidStamp({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Colors.green.shade700;
    return Transform.rotate(
      angle: -0.08, // slight tilt for the rubber-stamp feel
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
