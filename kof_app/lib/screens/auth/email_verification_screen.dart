import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_error_messages.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _poll;
  bool _checking = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Poll every 4 seconds so if the user verifies in their mail app and
    // comes back, the screen auto-advances.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check({bool silent = false}) async {
    if (!silent) setState(() => _checking = true);
    try {
      final verified = await context.read<AuthProvider>().refreshEmailVerified();
      if (!mounted) return;
      if (verified) {
        _poll?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }
      if (!silent) {
        setState(() => _error = context.l10n.verifyEmailNotYet);
      }
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = localizedAuthError(context.l10n, e));
    } finally {
      if (mounted && !silent) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().resendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.verifyEmailResent)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = localizedAuthError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _changeAccount() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final email = context.watch<AuthProvider>().user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyEmailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.mark_email_unread_outlined,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                l10n.verifyEmailTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.verifyEmailSentTo(email),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _checking ? null : () => _check(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.verifyEmailCheck,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _resending ? null : _resend,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _resending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.verifyEmailResend),
              ),
              const Spacer(),
              TextButton(
                onPressed: _changeAccount,
                child: Text(l10n.verifyEmailChangeAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
