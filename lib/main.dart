import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:run_4_tree/features/onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:run_4_tree/features/onboarding/domain/usecases/has_completed_onboarding_usecase.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/services/anonymous_auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/garden/data/services/planting_orders_sync.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await SentryFlutter.init((options) {
    options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
    options.environment = dotenv.env['SENTRY_ENVIRONMENT'] ?? 'production';
    options.sendDefaultPii = false;
    options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
  }, appRunner: _runApp);
}

Future<void> _runApp() async {
  await _configureFirebase();
  await _configurePushNotifications();
  await _configureRevenueCat();
  await MobileAds.instance.initialize();

  // Status bar transparente para o mapa ocupar a tela toda
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final hasCompleted = await HasCompletedOnboardingUseCase(
    UserProfileRepositoryImpl(),
  )();
  final initialRoute = hasCompleted ? '/home' : '/login';

  runApp(Run4TreeApp(initialRoute: initialRoute));
}

/// Inicializa o Firebase (Firestore do mural global e dos desafios em grupo,
/// com login anônimo). Best-effort: se o app rodar numa plataforma sem
/// `firebase_options.dart` configurado (ex: linux/web ainda não registrados)
/// ou sem rede, essas funcionalidades simplesmente ficam indisponíveis em vez
/// de travar o boot do app inteiro.
Future<void> _configureFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Adianta o login anônimo sem segurar o boot: a home já o encontra pronto.
    unawaited(AnonymousAuthService.instance.ensureUserId());
  } catch (e) {
    debugPrint('Firebase: initializeApp falhou: $e');
  }
}

/// Inicializa o OneSignal e liga o aparelho ao `uid` anônimo do Firebase, que
/// é como as Cloud Functions escolhem para quem mandar o push quando uma
/// árvore é plantada. A permissão NÃO é pedida aqui: ela só faz sentido
/// depois de o usuário entrar num grupo ou terminar um exercício.
Future<void> _configurePushNotifications() async {
  await PushNotificationService.instance.initialize();
  // Não segura o boot: o login anônimo pode demorar ou falhar sem rede.
  unawaited(
    AnonymousAuthService.instance.ensureUserId().then((uid) {
      if (uid == null) return;
      PushNotificationService.instance.login(uid);
      // Árvores "a caminho" viram árvores reais quando o pedido é cumprido.
      PlantingOrdersSync.instance.start(uid);
    }),
  );
}

/// Configura o SDK da RevenueCat com a chave pública da plataforma atual.
/// As chaves ficam no .env (Project Settings > API Keys no dashboard da RevenueCat).
Future<void> _configureRevenueCat() async {
  final apiKey = defaultTargetPlatform == TargetPlatform.iOS
      ? dotenv.env['REVENUECAT_API_KEY_IOS']
      : dotenv.env['REVENUECAT_API_KEY_ANDROID'];

  if (apiKey == null || apiKey.isEmpty) {
    debugPrint('RevenueCat: API key ausente no .env, SDK não configurado.');
    return;
  }

  await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
  await Purchases.configure(PurchasesConfiguration(apiKey));
}

class Run4TreeApp extends StatelessWidget {
  const Run4TreeApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Run4Tree',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [SentryNavigatorObserver()],
      // English is the app's default/fallback locale — the device locale is
      // used only when it matches one of the locales we actually ship.
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (final locale in supportedLocales) {
            if (locale.languageCode == deviceLocale.languageCode) {
              return locale;
            }
          }
        }
        return const Locale('en');
      },
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
