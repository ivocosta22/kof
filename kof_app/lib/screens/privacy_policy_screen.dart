import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final sections = <(String, String)>[
      (l10n.privacySection1Title, l10n.privacySection1Body),
      (l10n.privacySection2Title, l10n.privacySection2Body),
      (l10n.privacySection3Title, l10n.privacySection3Body),
      (l10n.privacySection4Title, l10n.privacySection4Body),
      (l10n.privacySection5Title, l10n.privacySection5Body),
      (l10n.privacySection6Title, l10n.privacySection6Body),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.drawerPrivacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            l10n.drawerPrivacyPolicy,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.privacyLastUpdated,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ...sections.expand((s) => [
                Text(
                  s.$1,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  s.$2,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
              ]),
        ],
      ),
    );
  }
}
