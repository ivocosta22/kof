import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'demo/demo_mode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/l10n.dart';
import 'providers/active_orders_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'navigation.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/active_orders_bubble.dart';
import 'widgets/cart_bubble.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages handled here when backend sends push notifications.
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDemoMode) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  runApp(const KofApp());
}

class KofApp extends StatelessWidget {
  const KofApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        // Reacts to AuthProvider so the order-history scope (and the bubble's
        // in-memory state) follows whichever user is signed in. Without this,
        // logging in as a different user — or as a guest — would briefly
        // surface the previous account's active orders.
        ChangeNotifierProxyProvider<AuthProvider, ActiveOrdersProvider>(
          create: (_) => ActiveOrdersProvider(),
          update: (_, auth, prev) =>
              (prev ?? ActiveOrdersProvider())..onAuthChanged(auth.user?.id),
        ),
        // Per-user inbox of received FCM notifications. The provider hooks
        // its own FCM stream listeners on first build and re-scopes its
        // storage key whenever the auth user changes.
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (_) => NotificationsProvider()..hookFcm(),
          update: (_, auth, prev) {
            final p = prev ?? (NotificationsProvider()..hookFcm());
            p.onAuthChanged(auth.user?.id);
            return p;
          },
        ),
      ],
      child: const _KofMaterialApp(),
    );
  }
}

class _KofMaterialApp extends StatelessWidget {
  const _KofMaterialApp();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
        title: 'Kof',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        // ── Localisation ──────────────────────────────────────────
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: settings.locale,
        // ── Themes ───────────────────────────────────────────────
        themeMode: settings.themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3D6B52),
            brightness: Brightness.light,
          ).copyWith(
            surface: const Color(0xFFF4EFE7),
            surfaceContainerLow: Colors.white,
            surfaceContainerLowest: const Color(0xFFF8F5EF),
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3D6B52),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const _StartupGate(),
        // Overlay the active-orders + cart bubbles over every screen. The
        // Stack wraps the Navigator (the `child`) so they sit above any
        // route's content and stay put across navigations.
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: ActiveOrdersBubble(),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: CartBubble(),
                ),
              ),
            ],
          );
        },
    );
  }
}

/// Restores any saved session on launch, then routes to HomeScreen or LoginScreen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Restore settings, auth session, and saved carts in parallel
    await Future.wait([
      context.read<SettingsProvider>().load(),
      context.read<AuthProvider>().tryRestoreSession(),
      context.read<CartProvider>().hydrate(),
    ]);
    if (!mounted) return;

    // Request notification permissions (skipped in demo mode and until APNs is configured on iOS)
    if (!kDemoMode) await FirebaseMessaging.instance.requestPermission();

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final Widget next;
    if (!auth.isLoggedIn && !settings.onboardingSeen) {
      next = const OnboardingScreen();
    } else if (!auth.isLoggedIn) {
      next = const LoginScreen();
    } else if (!auth.isGuest && !auth.emailVerified) {
      next = const EmailVerificationScreen();
    } else {
      next = const HomeScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
