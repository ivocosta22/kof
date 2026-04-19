import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/l10n.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages handled here when backend sends push notifications.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
    // Restore settings and auth session in parallel
    await Future.wait([
      context.read<SettingsProvider>().load(),
      context.read<AuthProvider>().tryRestoreSession(),
    ]);
    if (!mounted) return;

    // Request notification permissions (no-op until APNs is configured on iOS)
    await FirebaseMessaging.instance.requestPermission();

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final Widget next;
    if (!auth.isLoggedIn) {
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
