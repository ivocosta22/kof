import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

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
      'Who we are',
      'Kof is a personal-project ordering app that lets you browse coffee shops, '
          'place orders ahead of time, and follow shops you like. This is a portfolio '
          'project — there is no real company behind it.',
    ),
    _Section(
      'What we collect',
      'When you create an account, we store your email, display name, and (optionally) '
          'a phone number and profile photo. When you place an order, we store the order '
          'contents, time, and which shop received it. If you follow a shop, we store '
          'that relationship so we can deliver notifications.',
    ),
    _Section(
      'How we use it',
      'Account data is used to sign you in and personalise the app. Order data is shown '
          'to you in My Orders and to the shop staff so they can prepare your order. '
          'Notification preferences let you receive push messages from shops you follow.',
    ),
    _Section(
      'Who we share it with',
      'We do not sell your data. Order details are shared only with the specific shop '
          'you ordered from. Authentication and push delivery are handled by Firebase '
          '(Google) under their own privacy terms.',
    ),
    _Section(
      'Your choices',
      'You can edit or remove your name, phone, and profile photo from Account Settings '
          'at any time. You can unfollow a shop to stop receiving its notifications. '
          'Sign out clears your local session.',
    ),
    _Section(
      'Contact',
      'Questions about this policy? Reach us at customersupport@kof.example.com.',
    ),
  ];
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}
