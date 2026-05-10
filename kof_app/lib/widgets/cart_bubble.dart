import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../navigation.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/session_provider.dart';
import '../screens/menu_screen.dart';
import '../utils/haptics.dart';

/// Floating pill that surfaces a cart the user left behind for some shop.
/// Tapping it restores that shop's session and reopens the menu so they can
/// finish the order. Sits at the bottom-LEFT — the active-orders bubble
/// occupies the bottom-right.
class CartBubble extends StatelessWidget {
  const CartBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cart = context.watch<CartProvider>();
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    // Pick a saved cart that isn't the one the user is currently editing on
    // the menu screen — that one already has its own bottom bar.
    final activeUrl = cart.activeSession?.serverUrl;
    final candidates = loggedIn
        ? cart.savedCarts
            .where((c) => c.session.serverUrl != activeUrl || cart.isEmpty)
            .toList()
        : const <SavedCart>[];

    final visible = candidates.isNotEmpty;

    // AnimatedSwitcher fades between an invisible placeholder and the actual
    // bubble — without returning early on the empty case the switcher gets to
    // see both states and tween between them.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: !visible
          ? const SizedBox.shrink(key: ValueKey('cart-hidden'))
          : _buildBubble(context, theme, l10n, candidates.first),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    SavedCart saved,
  ) {
    final shopName = saved.session.shopName;
    final itemCount = saved.itemCount;
    final totalEuros = (saved.totalCents / 100).toStringAsFixed(2);

    return SafeArea(
      key: ValueKey('cart-${saved.session.serverUrl}'),
      minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _resume(context, saved),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.35),
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
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName.isEmpty
                              ? l10n.cartBubbleContinue
                              : shopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '${l10n.cartBubbleItemsCount(itemCount)} · €$totalEuros',
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
        ),
      ),
    );
  }

  Future<void> _resume(BuildContext context, SavedCart saved) async {
    Haptics.selection();
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    context.read<SessionProvider>().setSession(saved.session);
    await context.read<CartProvider>().setActiveSession(saved.session);
    await nav.push(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }
}
