import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundhive2/screens/auth/create_account.dart';
import 'package:soundhive2/screens/auth/creator_identity.dart';
import 'package:soundhive2/screens/auth/forgot_otp_screen.dart';
import 'package:soundhive2/screens/auth/forgot_password.dart';
import 'package:soundhive2/screens/auth/identity_screen.dart';
import 'package:soundhive2/screens/auth/login.dart';
import 'package:soundhive2/screens/auth/otp_screen.dart';
import 'package:soundhive2/screens/auth/reset_password.dart';
import 'package:soundhive2/screens/auth/terms_and_condition.dart';
import 'package:soundhive2/screens/auth/update_profile1.dart';
import 'package:soundhive2/screens/creator/creator_dashboard.dart';
import 'package:soundhive2/screens/dashboard/dashboard.dart';
import 'package:soundhive2/screens/non_creator/non_creator.dart';
import 'package:soundhive2/screens/onboarding/just_curious.dart';
import 'package:soundhive2/screens/onboarding/onboard.dart';
import 'package:soundhive2/screens/onboarding/splash_screen.dart';
import 'package:soundhive2/services/creator_profile_loader.dart';
import 'package:soundhive2/services/firebase_service.dart';
import 'package:soundhive2/services/loader_service.dart';
import 'package:soundhive2/theme/theme_provider.dart';
import 'package:soundhive2/utils/app_colors.dart';

import 'lib/app_life_cycle.dart';
import 'lib/auth_state_provider.dart';
import 'lib/interceptor.dart';
import 'lib/no_network_overlay.dart';
import 'lib/provider.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ────────────────────────────────────────────────
  // 1. Load environment variables
  // ────────────────────────────────────────────────
  try {
    await dotenv.load(fileName: '.env.production');
    print('✅ Dotenv loaded successfully');
  } catch (e, stack) {
    print('❌ Failed to load .env.production: $e\n$stack');
  }

  // ────────────────────────────────────────────────
  // 2. Initialize Firebase
  // ────────────────────────────────────────────────
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e, stack) {
    print('❌ Firebase initialization failed: $e\n$stack');
    // You could show an error screen here instead of proceeding
  }

  // ────────────────────────────────────────────────
  // 3. Prepare shared dependencies
  // ────────────────────────────────────────────────
  const storage = FlutterSecureStorage();
  final prefs = await SharedPreferences.getInstance();

  final dio = Dio();
  initializeDioLogger(dio);
  dio.interceptors.addAll([
    BaseUrlInterceptor(),
    TokenInterceptor(storage: storage),
  ]);
  await _restoreFirebaseSession(storage, dio);

  final navigatorKey = GlobalKey<NavigatorState>();
  LoaderService.navigatorKey = navigatorKey;

  final deepLinkHandler = _DeepLinkHandler(navigatorKey);
  deepLinkHandler.init();

  // ────────────────────────────────────────────────
  // 4. Create Riverpod container & initialize services
  // ────────────────────────────────────────────────
  final container = ProviderContainer();

  try {
    final firebaseService = FirebaseService(container);
    await firebaseService.initialize();
    print('✅ FirebaseService initialized');
  } catch (e, stack) {
    print('❌ FirebaseService initialization failed: $e\n$stack');
  }

  // ────────────────────────────────────────────────
  // 5. Run the app
  // ────────────────────────────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: AppLifecycleManager(
        child: SoundHive(
          storage: storage,
          dio: dio,
          navigatorKey: navigatorKey,
        ),
      ),
    ),
  );

  // Now that runApp() has been called, the widget tree exists. Wait for
  // the first real frame to be drawn before allowing any deep link to be
  // dispatched — this is what actually eliminates the race, not just a
  // currentState != null check.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    deepLinkHandler.markFirstFrameRendered();
  });
}

/// Handles cre8hive:// deep links (e.g. cre8hive://creator/42).
///
/// Two things make this safe:
/// 1. It waits for the very first frame to have actually rendered (not
///    just for `navigatorKey.currentState` to be non-null) before it will
///    dispatch anything — queuing links that arrive earlier.
/// 2. It serializes navigation: a second link can never be pushed while
///    a previous deep-link push is still installing/animating, and an
///    identical URI arriving twice (a known app_links quirk on cold
///    start, where both getInitialLink() and the stream fire the same
///    link) is ignored.
///
/// Note: this alone fixes the "second push races the first" symptom.
/// The other half of the original crash — the app swapping its entire
/// MaterialApp/Navigator tree while loading auth state — is fixed in
/// SoundHive.build() below by keeping a single stable MaterialApp for
/// the whole app lifetime instead of returning a different MaterialApp
/// during the loading state.
class _DeepLinkHandler {
  _DeepLinkHandler(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  bool _firstFrameRendered = false;
  bool _isNavigating = false;
  Uri? _lastHandledUri;
  final List<Uri> _pending = [];

  void init() {
    final appLinks = AppLinks();

    // Cold start: the app was launched by this link.
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _enqueue(uri);
    });

    // Warm start: app already running, link received while active.
    appLinks.uriLinkStream.listen((uri) {
      _enqueue(uri);
    }, onError: (err) {
      debugPrint('Deep link stream error: $err');
    });
  }

  void markFirstFrameRendered() {
    if (_firstFrameRendered) return;
    _firstFrameRendered = true;
    _drainPending();
  }

  void _enqueue(Uri uri) {
    // Ignore the exact same URI if we've already handled/queued it once —
    // covers the known duplicate-emission quirk on cold start.
    if (_lastHandledUri == uri) {
      debugPrint('Ignoring duplicate deep link: $uri');
      return;
    }

    if (!_firstFrameRendered) {
      debugPrint('First frame not ready yet — queuing deep link: $uri');
      _pending.add(uri);
      return;
    }

    _dispatch(uri);
  }

  void _drainPending() {
    for (final uri in List<Uri>.from(_pending)) {
      _dispatch(uri);
    }
    _pending.clear();
  }

  Future<void> _dispatch(Uri uri) async {
    _lastHandledUri = uri;

    // Belt-and-braces: navigatorKey.currentState should already be set by
    // the time the first frame renders, but wait briefly just in case.
    var attempts = 0;
    while (navigatorKey.currentState == null && attempts < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    if (navigatorKey.currentState == null) {
      debugPrint('Navigator never became ready — dropping deep link: $uri');
      return;
    }

    // Never let two deep-link navigations overlap.
    if (_isNavigating) {
      debugPrint('Navigation already in progress — dropping deep link: $uri');
      return;
    }

    _isNavigating = true;
    try {
      // Let any in-flight build/route transition settle before pushing.
      await SchedulerBinding.instance.endOfFrame;
      _handle(uri);
    } finally {
      _isNavigating = false;
    }
  }

  void _handle(Uri uri) {
    debugPrint(
        'Received deep link: $uri (host: ${uri.host}, segments: ${uri.pathSegments})');

    if (uri.host == 'creator' && uri.pathSegments.isNotEmpty) {
      final creatorId = int.tryParse(uri.pathSegments.first);
      if (creatorId != null) {
        final state = navigatorKey.currentState;
        if (state == null) {
          debugPrint('Navigator became unavailable — dropping deep link: $uri');
          return;
        }
        try {
          state.pushNamed(
            '/creator-profile-view',
            arguments: creatorId,
          );
        } catch (e, stack) {
          // Defensive: never let a bad deep link crash the app.
          debugPrint('Failed to navigate for deep link $uri: $e\n$stack');
        }
      } else {
        debugPrint(
            'Could not parse creator ID from segment: ${uri.pathSegments.first}');
      }
      return;
    }

    debugPrint('Unhandled deep link: $uri');
  }
}

/// Checks if Firebase is already signed in. If not but a Laravel token
/// exists, hits the backend for a fresh Firebase custom token and
/// signs in silently — invisible to the user.
Future<void> _restoreFirebaseSession(
    FlutterSecureStorage storage, Dio dio) async {
  try {
    // Already signed in (e.g. normal app resume) — nothing to do
    if (FirebaseAuth.instance.currentUser != null) return;

    final laravelToken = await storage.read(key: 'auth_token');
    if (laravelToken == null) return; // Not logged in at all

    // Ask your Laravel backend for a fresh Firebase custom token
    final response = await dio.get(
      '/auth/firebase-token',
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $laravelToken',
        },
      ),
    );

    if (response.statusCode == 200) {
      final firebaseToken = response.data['firebase_token'] as String?;
      if (firebaseToken != null) {
        await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
        debugPrint('Firebase session restored silently');
      }
    }
  } catch (e) {
    // Non-fatal: user still gets to dashboard via Laravel token.
    // Firebase rules will block DB access until they re-login,
    // which is acceptable — just log it.
    debugPrint('Could not restore Firebase session: $e');
  }
}

final routeObserverProvider = Provider<RouteObserver<ModalRoute>>(
  (ref) => RouteObserver<ModalRoute>(),
);

class SoundHive extends ConsumerWidget {
  final FlutterSecureStorage storage;
  final Dio dio;
  final GlobalKey<NavigatorState> navigatorKey;

  const SoundHive({
    super.key,
    required this.storage,
    required this.dio,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeObserver = ref.read(routeObserverProvider);
    // Reactive, but safe: watching this here only rebuilds MaterialApp's
    // `themeMode` argument, not the Navigator/tree identity — so it can't
    // reintroduce the earlier crash. Defaults to dark (this app's actual
    // default) rather than ThemeMode.system while themeState is loading
    // or if it has no explicit value yet.
    final themeState = ref.watch(themeModeProvider);
    final resolvedThemeMode =
        themeState.isLoading ? ThemeMode.dark : themeState.themeMode;

    // IMPORTANT: this is now the ONE AND ONLY MaterialApp for the whole
    // app lifetime. Previously, while authState/themeState were loading,
    // build() returned a *different* MaterialApp (without navigatorKey
    // attached at all), then swapped to *this* one once loading finished.
    // That swap destroyed and recreated the entire Navigator, which is
    // what actually caused the "deactivated widget's ancestor" and
    // "!_debugLocked" crashes when a deep link's pushNamed landed during
    // that swap. Keeping a single stable MaterialApp/Navigator here means
    // navigatorKey.currentState, once non-null, stays valid and pointed
    // at the same live Navigator for the rest of the app's life.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      navigatorKey: navigatorKey,
      // NOTE: restorationScopeId was removed. Flutter's state-restoration
      // tries to regenerate the initial route by NAME ("/") on cold start
      // via NavigatorState.restoreState -> defaultGenerateInitialRoutes.
      // Since this app uses `home:` (not `initialRoute:`) and `routes`
      // has no "/" entry, that lookup fails and falls through to
      // `onUnknownRoute`, which was null -> null check operator crash.
      // We don't rely on OS-level state restoration anywhere else in
      // this app, so it's simplest and safest to just not opt into it.
      // If you do need restoration later, add a `home`-less setup with
      // an explicit `initialRoute: '/'` and a `'/'` entry in `routes`
      // (or a matching `onGenerateRoute`) instead of re-adding this.
      onUnknownRoute: (settings) {
        // Defensive fallback so an unresolved route name can never
        // null-check-crash the app again, restoration or not.
        debugPrint('Unknown route: ${settings.name} — falling back to root.');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _RootGate(),
        );
      },
      builder: (context, child) {
        return NoNetworkOverlay(
          child: UpgradeAlert(
            upgrader: Upgrader(
              durationUntilAlertAgain: const Duration(days: 3),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Nohemi',
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Nohemi',
        scaffoldBackgroundColor: AppColors.BACKGROUNDCOLOR,
      ),
      themeMode: resolvedThemeMode,
      // `home` (not `initialRoute`) so that as auth/theme state resolves,
      // only this inner widget rebuilds — the MaterialApp/Navigator
      // identity above never changes.
      home: const _RootGate(),
      routes: {
        SplashScreen.id: (_) => const SplashScreen(),
        Onboard.id: (_) => const Onboard(),
        IdentityScreen.id: (_) => IdentityScreen(storage: storage),
        CreatorIdentityScreen.id: (_) =>
            CreatorIdentityScreen(storage: storage),
        CreateAccount.id: (_) => CreateAccount(storage: storage, dio: dio),
        Login.id: (_) => Login(storage: storage, dio: dio),
        ForgotPassword.id: (_) => ForgotPassword(storage: storage, dio: dio),
        OtpScreen.id: (_) => OtpScreen(storage: storage, dio: dio),
        ForgotOtpScreen.id: (_) => ForgotOtpScreen(storage: storage, dio: dio),
        ResetPassword.id: (_) => ResetPassword(storage: storage, dio: dio),
        UpdateProfile1.id: (_) => UpdateProfile1(storage: storage, dio: dio),
        JustCurious.id: (_) => JustCurious(storage: storage, dio: dio),
        DashboardScreen.id: (_) => const DashboardScreen(),
        TermsAndCondition.id: (_) =>
            TermsAndCondition(storage: storage, dio: dio),
        CreatorDashboard.id: (_) => CreatorDashboard(),
        NonCreatorDashboard.id: (_) => NonCreatorDashboard(),
        '/creator-profile-view': (context) {
          final creatorId = ModalRoute.of(context)!.settings.arguments as int;
          return CreatorProfileLoader(creatorId: creatorId);
        },
      },
    );
  }
}

/// Sits at `home`. Watches auth/theme state and decides what the user
/// sees first, without ever recreating the MaterialApp/Navigator above.
///
/// Note: themeMode is now applied via `MaterialApp.themeMode` reactively
/// through a separate mechanism if you need it to update live — since
/// this widget no longer controls the MaterialApp itself, if you need
/// live theme switching driven by themeModeProvider, hoist that back
/// into a ConsumerWidget wrapping MaterialApp.themeMode via a small
/// helper (see note below the class).
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeState = ref.watch(themeModeProvider);

    if (authState.isLoading || themeState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return authState.token != null
        ? const DashboardScreen()
        : const SplashScreen();
  }
}