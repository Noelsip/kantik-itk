import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import '/core/app_error_screen.dart';
import '/core/app_util.dart';
import 'package:provider/provider.dart';
import '/pages/pages.dart';
import '/services/push_notification_service.dart';
import '/state/app_state.dart';
import '/state/notifikasi_state.dart';
import '/state/session_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Widget yang gagal terbentuk menampilkan panel berisi keterangan, bukan kotak kosong.
  ErrorWidget.builder = (details) => AppErrorScreen(details: details);

  // Galat widget dicetak utuh ke konsol agar penyebabnya tetap bisa dilacak.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Galat widget: ${details.exceptionAsString()}');
  };

  // Galat asinkron di luar pohon widget tidak menjatuhkan aplikasi.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Galat tak tertangani: $error');
    return true;
  };

  // Notifikasi disiapkan tanpa menahan tampilan pertama dan kegagalannya diabaikan.
  unawaited(PushNotificationService.instance.init());

  runApp(
    MultiProvider(
      providers: [
        // Sesi dipulihkan lebih dulu agar splash tahu tujuan berikutnya.
        ChangeNotifierProvider(create: (_) => SessionState()..restore()),
        // Keranjang dan pesanan mengikuti sesi, termuat saat masuk dan kosong saat keluar.
        ChangeNotifierProxyProvider<SessionState, AppState>(
          create: (context) => AppState(context.read<SessionState>()),
          update: (_, session, state) => (state ?? AppState(session))
            ..syncWith(session),
        ),
        // Lencana notifikasi mengikuti sesi dengan cara yang sama.
        ChangeNotifierProxyProvider<SessionState, NotifikasiState>(
          create: (context) => NotifikasiState(context.read<SessionState>()),
          update: (_, session, state) => (state ?? NotifikasiState(session))
            ..syncWith(session),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    // Sesi yang gugur di tengah pemakaian dibawa kembali ke halaman masuk.
    context.read<SessionState>().onSessionExpired = () {
      if (!mounted) return;
      _router.goNamed(LoginPage.routeName);
    };
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Kantin ITK',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', ''), Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
