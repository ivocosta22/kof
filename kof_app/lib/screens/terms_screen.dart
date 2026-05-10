import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final sections = <(String, String)>[
      (l10n.termsSection1Title, l10n.termsSection1Body),
      (l10n.termsSection2Title, l10n.termsSection2Body),
      (l10n.termsSection3Title, l10n.termsSection3Body),
      (l10n.termsSection4Title, l10n.termsSection4Body),
      (l10n.termsSection5Title, l10n.termsSection5Body),
      (l10n.termsSection6Title, l10n.termsSection6Body),
      (l10n.termsSection7Title, l10n.termsSection7Body),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.drawerTerms)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            l10n.drawerTerms,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.termsLastUpdated,
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
