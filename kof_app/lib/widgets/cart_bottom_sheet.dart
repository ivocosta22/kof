import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/cart_provider.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../screens/order_status_screen.dart';

class CartBottomSheet extends StatefulWidget {
  const CartBottomSheet({super.key});

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  bool _isPlacing = false;
  String? _error;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final session = context.read<SessionProvider>().session;
    if (session == null || cart.isEmpty) return;

    setState(() {
      _isPlacing = true;
      _error = null;
    });

    try {
      final order = await ApiService(session.serverUrl).placeOrder(
        tableLabel: session.tableLabel,
        tableToken: session.tableToken,
        items: cart.toOrderItems(),
        note: _noteController.text.trim(),
      );

      cart.clear();

      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderStatusScreen(order: order)),
      );
    } catch (e) {
      setState(() {
        _isPlacing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cart = context.watch<CartProvider>();
    final session = context.read<SessionProvider>().session;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.cartYourOrder,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (session != null)
                      Text(
                        l10n.tableLabel(session.tableLabel),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ...cart.items.map(
                      (item) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 2),
                        title: Text(
                          item.menuItem.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          l10n.cartEach(
                            '€${(item.menuItem.priceCents / 100).toStringAsFixed(2)}',
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '€${(item.totalCents / 100).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            _SmallQtyControl(
                              qty: item.qty,
                              onIncrement: () => context
                                  .read<CartProvider>()
                                  .add(item.menuItem),
                              onDecrement: () => context
                                  .read<CartProvider>()
                                  .decrement(item.menuItem.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: TextField(
                        controller: _noteController,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: l10n.cartNoteHint,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.total,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '€${(cart.totalCents / 100).toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: theme.colorScheme.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed:
                          _isPlacing ? null : () => _placeOrder(context),
                      style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: _isPlacing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              l10n.cartPlaceOrder,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallQtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _SmallQtyControl({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrement,
          child: Icon(Icons.remove_circle_outline,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$qty',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        GestureDetector(
          onTap: onIncrement,
          child: Icon(Icons.add_circle_outline,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
