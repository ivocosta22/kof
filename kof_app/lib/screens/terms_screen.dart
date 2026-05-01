import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

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
            'Last updated: 2026-05-02',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ..._sections.expand((s) => [
                Text(
                  s.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  s.body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
              ]),
        ],
      ),
    );
  }

  static const _sections = <_Section>[
    _Section(
      '1. About this app',
      'Kof is a personal portfolio project. By using it you acknowledge that there is '
          'no real commercial entity behind the app and that orders, prices, and shops '
          'shown may be demonstrations rather than real businesses.',
    ),
    _Section(
      '2. Your account',
      'You are responsible for keeping your sign-in credentials safe. You must provide '
          'an email you control. We may suspend an account that is used to abuse the '
          'service or its participating shops.',
    ),
    _Section(
      '3. Orders and payment',
      'Orders placed through the app are sent to the relevant shop for preparation. '
          'Payment is handled at the counter or via the shop\'s own systems — the app '
          'does not currently process payments. Discount codes shown in the app are '
          'subject to the issuing shop\'s terms.',
    ),
    _Section(
      '4. Acceptable use',
      'Do not use the app to harass shop staff, place fraudulent orders, or attempt to '
          'access other users\' data. Automated scraping or load-testing without '
          'permission is not allowed.',
    ),
    _Section(
      '5. Limitation of liability',
      'The app is provided "as is" without warranties of any kind. We are not '
          'responsible for missed orders, incorrect items, or any loss arising from '
          'use of the app.',
    ),
    _Section(
      '6. Changes',
      'These terms may be updated from time to time. Continued use after changes '
          'constitutes acceptance of the updated terms.',
    ),
    _Section(
      '7. Contact',
      'Questions or complaints? Reach us at customersupport@kof.example.com.',
    ),
  ];
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}
