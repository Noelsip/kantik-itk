import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/app_util.dart';

import '/pages/pages.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => const SplashPage(),
      routes: [
        AppRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => const SplashPage(),
        ),
        AppRoute(
          name: SplashPage.routeName,
          path: SplashPage.routePath,
          builder: (context, params) => const SplashPage(),
        ),
        AppRoute(
          name: LoginPage.routeName,
          path: LoginPage.routePath,
          builder: (context, params) => const LoginPage(),
        ),
        AppRoute(
          name: BerandaPage.routeName,
          path: BerandaPage.routePath,
          builder: (context, params) => const BerandaPage(),
        ),
        AppRoute(
          name: DaftarKantinPage.routeName,
          path: DaftarKantinPage.routePath,
          builder: (context, params) => const DaftarKantinPage(),
        ),
        AppRoute(
          name: DetailKantinPage.routeName,
          path: DetailKantinPage.routePath,
          builder: (context, params) => DetailKantinPage(
            canteenId: params.getParam(
              'canteenId',
              ParamType.String,
            ),
          ),
        ),
        AppRoute(
          name: DetailMakananPage.routeName,
          path: DetailMakananPage.routePath,
          builder: (context, params) => DetailMakananPage(
            menuId: params.getParam(
              'menuId',
              ParamType.String,
            ),
          ),
        ),
        AppRoute(
          name: KeranjangPage.routeName,
          path: KeranjangPage.routePath,
          builder: (context, params) => const KeranjangPage(),
        ),
        AppRoute(
          name: CheckoutPage.routeName,
          path: CheckoutPage.routePath,
          builder: (context, params) => const CheckoutPage(),
        ),
        AppRoute(
          name: PesananBerhasilPage.routeName,
          path: PesananBerhasilPage.routePath,
          builder: (context, params) => PesananBerhasilPage(
            orderId: params.getParam(
              'orderId',
              ParamType.String,
            ),
          ),
        ),
        AppRoute(
          name: StatusPesananPage.routeName,
          path: StatusPesananPage.routePath,
          builder: (context, params) => StatusPesananPage(
            orderId: params.getParam(
              'orderId',
              ParamType.String,
            ),
          ),
        ),
        AppRoute(
          name: RiwayatPesananPage.routeName,
          path: RiwayatPesananPage.routePath,
          builder: (context, params) => const RiwayatPesananPage(),
        ),
        AppRoute(
          name: DetailRiwayatPage.routeName,
          path: DetailRiwayatPage.routePath,
          builder: (context, params) => DetailRiwayatPage(
            orderId: params.getParam(
              'orderId',
              ParamType.String,
            ),
          ),
        ),
        AppRoute(
          name: NotifikasiPembeliPage.routeName,
          path: NotifikasiPembeliPage.routePath,
          builder: (context, params) => const NotifikasiPembeliPage(),
        ),
        AppRoute(
          name: ProfilPembeliPage.routeName,
          path: ProfilPembeliPage.routePath,
          builder: (context, params) => const ProfilPembeliPage(),
        ),
        AppRoute(
          name: UbahProfilPembeliPage.routeName,
          path: UbahProfilPembeliPage.routePath,
          builder: (context, params) => const UbahProfilPembeliPage(),
        ),
        AppRoute(
          name: SyaratKetentuanPage.routeName,
          path: SyaratKetentuanPage.routePath,
          builder: (context, params) => const SyaratKetentuanPage(),
        ),
        AppRoute(
          name: PusatBantuanPage.routeName,
          path: PusatBantuanPage.routePath,
          builder: (context, params) => const PusatBantuanPage(),
        ),
        AppRoute(
          name: DashboardPage.routeName,
          path: DashboardPage.routePath,
          builder: (context, params) => const DashboardPage(),
        ),
        AppRoute(
          name: PesananMasukPage.routeName,
          path: PesananMasukPage.routePath,
          builder: (context, params) => const PesananMasukPage(),
        ),
        AppRoute(
          name: DetailPesananMasukPage.routeName,
          path: DetailPesananMasukPage.routePath,
          builder: (context, params) => DetailPesananMasukPage(
            orderId: params.getParam(
              'orderId',
              ParamType.String,
            ),
          ),
        ),
        AppRoute(
          name: KelolaMenuPage.routeName,
          path: KelolaMenuPage.routePath,
          builder: (context, params) => const KelolaMenuPage(),
        ),
        AppRoute(
          name: FormMenuPage.routeName,
          path: FormMenuPage.routePath,
          builder: (context, params) => FormMenuPage(
            menuId: params.getParam(
              'menuId',
              ParamType.String,
            ),
          ),
        ),
        AppRoute(
          name: ProfilPenjualPage.routeName,
          path: ProfilPenjualPage.routePath,
          builder: (context, params) => const ProfilPenjualPage(),
        ),
        AppRoute(
          name: UbahProfilPenjualPage.routeName,
          path: UbahProfilPenjualPage.routePath,
          builder: (context, params) => const UbahProfilPenjualPage(),
        ),
        AppRoute(
          name: PengaturanWarungPage.routeName,
          path: PengaturanWarungPage.routePath,
          builder: (context, params) => const PengaturanWarungPage(),
        ),
        AppRoute(
          name: NotifikasiPenjualPage.routeName,
          path: NotifikasiPenjualPage.routePath,
          builder: (context, params) => const NotifikasiPenjualPage(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class AppParameters {
  AppParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
    );
  }
}

class AppRoute {
  const AppRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, AppParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final routeParams = AppParameters(state, asyncParams);
          final page = routeParams.hasFutures
              ? FutureBuilder(
                  future: routeParams.completeFutures(),
                  builder: (context, _) => builder(context, routeParams),
                )
              : builder(context, routeParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => const TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
