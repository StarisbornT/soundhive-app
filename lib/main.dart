import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/screens/auth/create_account.dart';
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
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'lib/app_life_cycle.dart';
import 'lib/auth_state_provider.dart';
import 'lib/interceptor.dart';
import 'lib/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env.production');
  await Firebase.initializeApp(
  );
  final container = ProviderContainer();
  Dio dio = Dio();
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  // Initialize Firebase Service
  final firebaseService = FirebaseService(container);
  await firebaseService.initialize();
  initializeDioLogger(dio);

  final storage = FlutterSecureStorage();
  dio.interceptors.addAll([
    BaseUrlInterceptor(),
    TokenInterceptor(storage: storage),
  ]);
  final navigatorKey = GlobalKey<NavigatorState>();
  LoaderService.navigatorKey = navigatorKey;
  runApp(
    ProviderScope(
      child: AppLifecycleManager(
        child: SoundHive(storage: storage, dio: dio, navigatorKey: navigatorKey),
      ),
    ),
  );
}

final routeObserverProvider = Provider<RouteObserver<ModalRoute>>(
      (ref) => RouteObserver<ModalRoute>(),
);

class SoundHive extends ConsumerWidget {
  final FlutterSecureStorage storage;
  final Dio dio;
  final GlobalKey<NavigatorState> navigatorKey;
  const SoundHive({super.key, required this.dio, required this.storage, required this.navigatorKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    final routeObserver = ref.read(routeObserverProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        fontFamily: 'Nohemi',
      ),
      navigatorKey: navigatorKey,
      initialRoute: authState.token != null ? DashboardScreen.id : SplashScreen.id,
      routes: {
        SplashScreen.id: (context) => const SplashScreen(),
        Onboard.id: (context) => const Onboard(),
        IdentityScreen.id: (context) =>  IdentityScreen(storage: storage),
        CreateAccount.id: (context) => CreateAccount(storage: storage, dio: dio,),
        Login.id: (context) =>  Login(storage: storage, dio: dio,),
        ForgotPassword.id: (context) =>  ForgotPassword(storage: storage, dio: dio,),
        OtpScreen.id: (context) => OtpScreen(storage: storage, dio: dio,),
        ForgotOtpScreen.id: (context) => ForgotOtpScreen(storage: storage, dio: dio,),
        ResetPassword.id: (context) => ResetPassword(storage: storage, dio: dio,),
        UpdateProfile1.id: (context) => UpdateProfile1(storage: storage, dio: dio,),
        JustCurious.id: (context) => JustCurious(storage: storage, dio: dio,),
        DashboardScreen.id: (context) => const DashboardScreen(),
        TermsAndCondition.id: (context) =>  TermsAndCondition(storage: storage, dio: dio,),
        CreatorDashboard.id: (context) => CreatorDashboard(),
        NonCreatorDashboard.id: (context) => NonCreatorDashboard(),
      },
    );
  }
}
