import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
import 'package:soundhive2/services/firebase_service.dart';
import 'package:soundhive2/services/loader_service.dart';
import 'package:soundhive2/theme/theme_provider.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lib/app_life_cycle.dart';
import 'lib/auth_state_provider.dart';
import 'lib/interceptor.dart';
import 'lib/provider.dart';

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

  final navigatorKey = GlobalKey<NavigatorState>();
  LoaderService.navigatorKey = navigatorKey;

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
}

final routeObserverProvider = Provider<RouteObserver<ModalRoute<void>>>(
  (ref) => RouteObserver<ModalRoute<void>>(),
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
    final authState = ref.watch(authStateProvider);
    final themeState = ref.watch(themeModeProvider);

    // Show loading while critical state is being determined
    if (authState.isLoading || themeState.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final routeObserver = ref.read(routeObserverProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      navigatorKey: navigatorKey,
      themeMode: themeState.themeMode,
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
      initialRoute: authState.token != null ? DashboardScreen.id : SplashScreen.id,
      routes: {
        SplashScreen.id: (_) => const SplashScreen(),
        Onboard.id: (_) => const Onboard(),
        IdentityScreen.id: (_) => IdentityScreen(storage: storage),
        CreatorIdentityScreen.id: (_) => CreatorIdentityScreen(storage: storage),
        CreateAccount.id: (_) => CreateAccount(storage: storage, dio: dio),
        Login.id: (_) => Login(storage: storage, dio: dio),
        ForgotPassword.id: (_) => ForgotPassword(storage: storage, dio: dio),
        OtpScreen.id: (_) => OtpScreen(storage: storage, dio: dio),
        ForgotOtpScreen.id: (_) => ForgotOtpScreen(storage: storage, dio: dio),
        ResetPassword.id: (_) => ResetPassword(storage: storage, dio: dio),
        UpdateProfile1.id: (_) => UpdateProfile1(storage: storage, dio: dio),
        JustCurious.id: (_) => JustCurious(storage: storage, dio: dio),
        DashboardScreen.id: (_) => const DashboardScreen(),
        TermsAndCondition.id: (_) => TermsAndCondition(storage: storage, dio: dio),
        CreatorDashboard.id: (_) => CreatorDashboard(),
        NonCreatorDashboard.id: (_) => NonCreatorDashboard(),
      },
    );
  }
}