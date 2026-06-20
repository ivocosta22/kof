import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/settings_provider.dart';

const _kLanguages = [
  (null, ''),
  ('en', 'English'),
  ('pt', 'Português'),
  ('fi', 'Suomi'),
];

/// Compact row with a language picker (left) and a theme-mode toggle (right).
///
/// Shared by the login screen and the onboarding screen so both expose the
/// same pre-auth language/theme controls.
class LanguageThemeBar extends StatelessWidget {
  const LanguageThemeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    final langLabel = settings.locale == null
        ? l10n.settingsLanguageSystem
        : _kLanguages
                .where((e) => e.$1 == settings.locale!.languageCode)
                .map((e) => e.$2)
                .firstOrNull ??
            settings.locale!.languageCode;

    final themeIcon = switch (settings.themeMode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      _ => Icons.brightness_auto_outlined,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Language button ──────────────────────────────────────
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _pickLanguage(context, settings, l10n),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  langLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
        // ── Theme toggle ─────────────────────────────────────────
        IconButton(
          icon: Icon(themeIcon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          tooltip: l10n.loginSelectTheme,
          onPressed: () {
            final next = switch (settings.themeMode) {
              ThemeMode.system => ThemeMode.light,
              ThemeMode.light => ThemeMode.dark,
              _ => ThemeMode.system,
            };
            context.read<SettingsProvider>().setThemeMode(next);
          },
        ),
      ],
    );
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<String?>(
              groupValue: settings.locale?.languageCode,
              onChanged: (code) {
                context
                    .read<SettingsProvider>()
                    .setLocale(code == null ? null : Locale(code));
                Navigator.pop(ctx);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (code, name) in _kLanguages)
                    RadioListTile<String?>(
                      value: code,
                      title: Text(
                          code == null ? l10n.settingsLanguageSystem : name),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
