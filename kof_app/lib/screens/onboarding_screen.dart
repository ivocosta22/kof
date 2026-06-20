import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/settings_provider.dart';
import '../utils/haptics.dart';
import '../widgets/language_theme_bar.dart';
import 'auth/login_screen.dart';

/// One-time intro carousel shown ahead of the login screen on first launch.
///
/// Each page pairs a short headline with an animation. The animation layer
/// prefers a Lottie asset (see `assets/animations/README.md` for how to drop
/// real `.json` files in) and gracefully falls back to a hand-built, fully
/// offline Flutter animation when the asset is missing — so the screen always
/// looks alive even before any Lottie file is added.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_OnboardPage> _pages(AppLocalizations l10n) => [
        _OnboardPage(
          title: l10n.onboardingWelcomeTitle,
          body: l10n.onboardingWelcomeBody,
          lottieAsset: 'assets/animations/coffee_pour.json',
          fallback: (accent) => _CoffeePourArt(accent: accent),
        ),
        _OnboardPage(
          title: l10n.onboardingScanTitle,
          body: l10n.onboardingScanBody,
          lottieAsset: 'assets/animations/scan.json',
          fallback: (accent) =>
              _PulseIconArt(accent: accent, icon: Icons.qr_code_scanner_rounded),
        ),
        _OnboardPage(
          title: l10n.onboardingTrackTitle,
          body: l10n.onboardingTrackBody,
          lottieAsset: 'assets/animations/track.json',
          fallback: (accent) => _PulseIconArt(
              accent: accent, icon: Icons.local_cafe_rounded, radar: true),
        ),
        _OnboardPage(
          title: l10n.onboardingFollowTitle,
          body: l10n.onboardingFollowBody,
          lottieAsset: 'assets/animations/follow.json',
          fallback: (accent) =>
              _PulseIconArt(accent: accent, icon: Icons.favorite_rounded),
        ),
      ];

  Future<void> _finish() async {
    Haptics.light();
    await context.read<SettingsProvider>().setOnboardingSeen(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next(int total) {
    if (_page >= total - 1) {
      _finish();
      return;
    }
    Haptics.light();
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final pages = _pages(l10n);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: language + theme controls on the welcome page,
            // a Skip shortcut on the rest (hidden on the final page).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 48,
                child: _page == 0
                    ? const LanguageThemeBar()
                    : Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedOpacity(
                          opacity: isLast ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: isLast ? null : _finish,
                            child: Text(
                              l10n.onboardingSkip,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _OnboardPageView(page: pages[i]),
              ),
            ),
            // Page indicator dots.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _page ? 24 : 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            // Bottom buttons.
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () => _next(pages.length),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isLast ? l10n.onboardingGetStarted : l10n.onboardingNext,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _finish,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.onboardingSkip,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Immutable description of a single onboarding page.
class _OnboardPage {
  const _OnboardPage({
    required this.title,
    required this.body,
    required this.lottieAsset,
    required this.fallback,
  });

  final String title;
  final String body;
  final String lottieAsset;
  final Widget Function(Color accent) fallback;
}

class _OnboardPageView extends StatelessWidget {
  const _OnboardPageView({required this.page});

  final _OnboardPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation centerpiece. Prefer Lottie, fall back to native art.
          SizedBox(
            height: 280,
            child: Center(
              child: Lottie.asset(
                page.lottieAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) =>
                    page.fallback(accent),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.45,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Offline fallback animations (used when the matching Lottie asset is absent).
// ───────────────────────────────────────────────────────────────────────────

/// A mug that fills with coffee from a pouring stream, topped with rising steam.
class _CoffeePourArt extends StatefulWidget {
  const _CoffeePourArt({required this.accent});

  final Color accent;

  @override
  State<_CoffeePourArt> createState() => _CoffeePourArtState();
}

class _CoffeePourArtState extends State<_CoffeePourArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: const Size(220, 260),
        painter: _CoffeePourPainter(t: _c.value, accent: widget.accent),
      ),
    );
  }
}

class _CoffeePourPainter extends CustomPainter {
  _CoffeePourPainter({required this.t, required this.accent});

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Mug geometry.
    final mugRect = Rect.fromLTWH(w * 0.28, h * 0.42, w * 0.40, h * 0.42);
    final mugRadius = const Radius.circular(20);
    final mugRRect = RRect.fromRectAndCorners(
      mugRect,
      bottomLeft: mugRadius,
      bottomRight: mugRadius,
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );

    // Handle.
    final handle = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset(mugRect.right + 2, mugRect.center.dy + 4),
          radius: w * 0.11,
        ),
        -math.pi / 2.4,
        math.pi * 1.2,
      );
    canvas.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.55),
    );

    // Pour stream — visible while the mug is filling.
    final fill = (t / 0.7).clamp(0.0, 1.0);
    final streamOpacity = (1 - (t - 0.62) / 0.12).clamp(0.0, 1.0);
    if (streamOpacity > 0) {
      final streamPaint = Paint()
        ..color = accent.withValues(alpha: 0.75 * streamOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      final streamTop = h * 0.10;
      final streamBottom = mugRect.top + 14;
      canvas.drawLine(
        Offset(mugRect.center.dx, streamTop),
        Offset(mugRect.center.dx, streamBottom),
        streamPaint,
      );
    }

    // Coffee body, clipped to the mug, rising with [fill].
    canvas.save();
    canvas.clipRRect(mugRRect);
    final coffeeTop = mugRect.bottom - mugRect.height * 0.92 * fill;
    final coffeeRect =
        Rect.fromLTRB(mugRect.left, coffeeTop, mugRect.right, mugRect.bottom);
    canvas.drawRect(
      coffeeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6F4E37),
            const Color(0xFF4A3324),
          ],
        ).createShader(coffeeRect),
    );
    // Subtle surface highlight on the coffee.
    if (fill > 0.05) {
      canvas.drawLine(
        Offset(mugRect.left + 6, coffeeTop),
        Offset(mugRect.right - 6, coffeeTop),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 3,
      );
    }
    canvas.restore();

    // Mug outline (drawn after coffee so the rim stays crisp).
    canvas.drawRRect(
      mugRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = accent,
    );

    // Saucer.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.48, mugRect.bottom + 14),
          width: w * 0.62,
          height: 14,
        ),
        const Radius.circular(7),
      ),
      Paint()..color = accent.withValues(alpha: 0.30),
    );

    // Steam — fades in once the mug is mostly full.
    final steamOpacity = ((t - 0.55) / 0.3).clamp(0.0, 1.0) *
        (1 - ((t - 0.92) / 0.08).clamp(0.0, 1.0));
    if (steamOpacity > 0) {
      final steamPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.35 * steamOpacity);
      for (var i = 0; i < 2; i++) {
        final baseX = mugRect.center.dx + (i == 0 ? -16 : 16);
        final path = Path()..moveTo(baseX, mugRect.top - 4);
        for (var s = 0; s <= 6; s++) {
          final progress = s / 6;
          final y = mugRect.top - 4 - progress * 56;
          final x = baseX +
              math.sin(progress * math.pi * 2 + t * math.pi * 4 + i) * 9;
          path.lineTo(x, y);
        }
        canvas.drawPath(path, steamPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_CoffeePourPainter old) =>
      old.t != t || old.accent != accent;
}

/// A centered icon inside soft, outward-rippling pulse rings.
class _PulseIconArt extends StatefulWidget {
  const _PulseIconArt({
    required this.accent,
    required this.icon,
    this.radar = false,
  });

  final Color accent;
  final IconData icon;
  final bool radar;

  @override
  State<_PulseIconArt> createState() => _PulseIconArtState();
}

class _PulseIconArtState extends State<_PulseIconArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: const Size(220, 220),
        painter: _PulsePainter(t: _c.value, accent: widget.accent),
        child: SizedBox(
          width: 220,
          height: 220,
          child: Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: widget.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 44, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.t, required this.accent});

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const baseRadius = 52.0;
    final maxRadius = size.width / 2;

    // Three staggered expanding rings.
    for (var i = 0; i < 3; i++) {
      final progress = (t + i / 3) % 1.0;
      final radius = baseRadius + progress * (maxRadius - baseRadius);
      final opacity = (1 - progress) * 0.4;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: opacity),
      );
    }

    // Soft halo behind the badge.
    canvas.drawCircle(
      center,
      baseRadius + 6,
      Paint()..color = accent.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.accent != accent;
}
