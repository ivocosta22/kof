import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/session_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onClose;

  const AppDrawer({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final user = context.watch<AuthProvider>().user;
    final initial = (user != null && user.name.isNotEmpty)
        ? user.name[0].toUpperCase()
        : '?';

    // Local helper — replaces Navigator.pop which was used for the Scaffold drawer
    void close() => onClose?.call();

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? l10n.drawerGuestName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          (user != null && !user.isGuest)
                              ? user.email
                              : l10n.drawerBrowsingAsGuest,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Main nav ────────────────────────────────────────────
            _DrawerItem(
              icon: Icons.receipt_long_outlined,
              label: l10n.drawerMyOrders,
              onTap: () {
                close();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: l10n.drawerSettings,
              onTap: () {
                close();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.logout,
              label: l10n.drawerLogout,
              color: theme.colorScheme.error,
              onTap: () => _logout(context, close),
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: theme.colorScheme.outlineVariant),
            ),
            const SizedBox(height: 4),

            // ── Legal / support ─────────────────────────────────────
            _DrawerItem(
              icon: Icons.shield_outlined,
              label: l10n.drawerPrivacyPolicy,
              small: true,
              onTap: () {
                close();
                // TODO: open privacy policy URL
              },
            ),
            _DrawerItem(
              icon: Icons.description_outlined,
              label: l10n.drawerTerms,
              small: true,
              onTap: () {
                close();
                // TODO: open terms URL
              },
            ),
            _DrawerItem(
              icon: Icons.mail_outline,
              label: l10n.drawerContactUs,
              small: true,
              onTap: () {
                close();
                // TODO: open contact URL or email
              },
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l10n.drawerVersion,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, VoidCallback close) async {
    close();
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    context.read<CartProvider>().clear();
    context.read<SessionProvider>().clearSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool small;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c, size: small ? 20 : 24),
      title: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: small ? 14 : 15,
          fontWeight: small ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: small,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
