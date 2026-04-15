import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = context.l10n.loginFieldsRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(email, password);
      if (!mounted) return;
      _goHome();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().loginWithGoogle();
      if (!mounted) return;
      _goHome();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _loginWithApple() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.loginAppleNotAvailable)),
    );
  }

  void _loginAsGuest() {
    context.read<AuthProvider>().loginAsGuest();
    _goHome();
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _LoginTopBar(),
                  const SizedBox(height: 32),
                  Icon(Icons.coffee, size: 52, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    l10n.appTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildField(
                    context: context,
                    controller: _emailCtrl,
                    label: l10n.emailLabel,
                    hint: l10n.emailHint,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    context: context,
                    controller: _passwordCtrl,
                    label: l10n.passwordLabel,
                    obscure: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.loginForgotPassword,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    _buildErrorBox(theme, _error!),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            l10n.loginButton,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: theme.colorScheme.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          l10n.loginOrContinueWith,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              color: theme.colorScheme.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButton(
                    context: context,
                    onPressed: _loading ? null : _loginWithGoogle,
                    icon: const _GoogleIcon(),
                    label: l10n.loginWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    context: context,
                    onPressed: _loginWithApple,
                    icon: Icon(Icons.apple,
                        size: 22,
                        color: theme.colorScheme.onSurface),
                    label: l10n.loginWithApple,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading ? null : _loginAsGuest,
                    child: Text(
                      l10n.loginAsGuest,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${l10n.loginNoAccount}  ',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: Text(
                            l10n.loginRegister,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerLow,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        backgroundColor: theme.colorScheme.surfaceContainerLow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Text(message,
          style: TextStyle(
              color: theme.colorScheme.onErrorContainer, fontSize: 13)),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  // Official Google G logo SVG paths
  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 18, height: 18);
  }
}

// ── Top bar: language picker + theme toggle ────────────────────────────────

const _kLoginLanguages = [
  (null, ''),
  ('en', 'English'),
  ('pt', 'Português'),
  ('fi', 'Suomi'),
];

class _LoginTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    final langLabel = settings.locale == null
        ? l10n.settingsLanguageSystem
        : _kLoginLanguages
            .where((e) => e.$1 == settings.locale!.languageCode)
            .map((e) => e.$2)
            .firstOrNull ?? settings.locale!.languageCode;

    final themeIcon = switch (settings.themeMode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark  => Icons.dark_mode_outlined,
      _               => Icons.brightness_auto_outlined,
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
                Icon(Icons.language_outlined, size: 16,
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
                Icon(Icons.arrow_drop_down, size: 16,
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
              ThemeMode.light  => ThemeMode.dark,
              _                => ThemeMode.system,
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
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<String?>(
              groupValue: settings.locale?.languageCode,
              onChanged: (code) {
                context.read<SettingsProvider>()
                    .setLocale(code == null ? null : Locale(code));
                Navigator.pop(ctx);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (code, name) in _kLoginLanguages)
                    RadioListTile<String?>(
                      value: code,
                      title: Text(code == null ? l10n.settingsLanguageSystem : name),
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
