import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import 'auth/login_screen.dart';

// Supported languages: (languageCode, native name)
const _kLanguages = [
  (null, ''),          // system default — label built from l10n
  ('en', 'English'),
  ('pt', 'Português'),
  ('fi', 'Suomi'),
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          // ── Appearance ─────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsAppearance),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.settingsThemeMode),
            trailing: _ThemeSegmentedButton(
              current: settings.themeMode,
              onChanged: (m) => context.read<SettingsProvider>().setThemeMode(m),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.settingsLanguage),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentLanguageLabel(settings.locale, l10n),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _pickLanguage(context, settings, l10n),
          ),

          // ── Preferences ────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsPreferences),
          if (Platform.isIOS)
            SwitchListTile.adaptive(
              value: settings.hapticFeedback,
              onChanged: (v) {
                context.read<SettingsProvider>().setHapticFeedback(v);
                if (v) HapticFeedback.lightImpact();
              },
              title: Text(l10n.settingsHapticFeedback),
              subtitle: Text(
                l10n.settingsHapticFeedbackSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              activeTrackColor: theme.colorScheme.primary,
            ),

          // ── About ──────────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsAbout),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l10n.settingsPrivacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () { /* TODO: open URL */ },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsTerms),
            trailing: const Icon(Icons.chevron_right),
            onTap: () { /* TODO: open URL */ },
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l10n.settingsContactUs),
            trailing: const Icon(Icons.chevron_right),
            onTap: () { /* TODO: open URL */ },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsVersion),
            trailing: Text(
              '1.0.0',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ),

          // ── Logout ─────────────────────────────────────────────────
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: theme.colorScheme.outlineVariant),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              l10n.settingsLogout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmLogout(context, l10n),
          ),
        ],
      ),
    );
  }

  String _currentLanguageLabel(Locale? locale, AppLocalizations l10n) {
    if (locale == null) return l10n.settingsLanguageSystem;
    final match = _kLanguages.where((e) => e.$1 == locale.languageCode);
    return match.isNotEmpty ? match.first.$2 : locale.languageCode;
  }

  Future<void> _pickLanguage(
    BuildContext context,
    SettingsProvider settings,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LanguagePicker(
        current: settings.locale,
        systemLabel: l10n.settingsLanguageSystem,
        onPick: (locale) {
          context.read<SettingsProvider>().setLocale(locale);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsLogout),
        content: Text(l10n.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.settingsLogoutConfirmYes,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    context.read<CartProvider>().clear();
    context.read<SessionProvider>().clearSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

// ── Theme segmented button ─────────────────────────────────────────────────

class _ThemeSegmentedButton extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSegmentedButton({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
      ),
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto, size: 16),
          label: Text(l10n.settingsThemeSystem, style: const TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode, size: 16),
          label: Text(l10n.settingsThemeLight, style: const TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode, size: 16),
          label: Text(l10n.settingsThemeDark, style: const TextStyle(fontSize: 12)),
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

// ── Language picker bottom sheet ───────────────────────────────────────────

class _LanguagePicker extends StatelessWidget {
  final Locale? current;
  final String systemLabel;
  final ValueChanged<Locale?> onPick;

  const _LanguagePicker({
    required this.current,
    required this.systemLabel,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          RadioGroup<String?>(
            groupValue: current?.languageCode,
            onChanged: (code) => onPick(code == null ? null : Locale(code)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (code, name) in _kLanguages)
                  RadioListTile<String?>(
                    value: code,
                    title: Text(code == null ? systemLabel : name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
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
  }
}
