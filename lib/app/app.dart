/// Akar aplikasi: `MaterialApp` bertema Bpedia, lokal Indonesia, navigator
/// milik `AppRouter`, kolom ponsel di layar lebar, dan transisi halaman
/// SPEC §2.4.
library;

import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../design/design.dart';
import '../platform/browser.dart';
import 'app_router.dart';
import 'app_scope.dart';
import 'app_services.dart';
import 'not_found_page.dart';
import 'phone_frame.dart';
import 'shell.dart';

/// Mendaftarkan halaman dan tab satu grup fitur, mis. `registerShopRoutes`.
typedef RouteRegistrar = void Function(AppRouter router);

/// Penyambung yang butuh seluruh layanan (mis. zona Hadiah).
typedef AppConfigurator = FutureOr<void> Function(AppServices services);

/// Menyiapkan layanan lalu menjalankan app.
///
/// [routes] dipanggil berurutan dengan router app; [configure] dipanggil
/// sesudahnya dengan seluruh layanan. [rewardsBuilder] memasang gateway
/// hadiah (bawaan: tanpa hadiah). Bila penyiapan gagal, tampil layar galat
/// dengan tombol "Coba lagi", bukan layar kosong.
Future<void> runBpediaApp({
  List<RouteRegistrar> routes = const <RouteRegistrar>[],
  AppConfigurator? configure,
  RewardsBuilder? rewardsBuilder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
  }
  try {
    final services = await AppServices.bootstrap(
      rewardsBuilder: rewardsBuilder,
    );
    for (final register in routes) {
      register(services.router);
    }
    await configure?.call(services);
    runApp(BpediaApp(services: services));
  } on Object catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'bpedia_app',
        context: ErrorDescription('saat menyiapkan layanan app'),
      ),
    );
    runApp(
      BootstrapFailureApp(
        onRetry: () => runBpediaApp(
          routes: routes,
          configure: configure,
          rewardsBuilder: rewardsBuilder,
        ),
      ),
    );
  }
}

/// Aplikasi Bpedia Demo.
///
/// Memasang [AppScope], tema terang/gelap dari pengaturan, lokal `id_ID`,
/// kerangka lima tab, halaman 404 berdesain, dan [PhoneFrame]. Halaman dan
/// tab fitur harus sudah terdaftar di `services.router` sebelum widget ini
/// dibangun.
class BpediaApp extends StatefulWidget {
  const BpediaApp({required this.services, this.initialLocation, super.key});

  /// Layanan app; pemiliknya (pemanggil) yang melepasnya.
  final AppServices services;

  /// Lokasi awal, mis. `/hadiah/roda`. Bawaan: lokasi dari platform (alamat
  /// browser atau tautan pembuka).
  final String? initialLocation;

  /// Lokal app.
  static const Locale locale = Locale('id', 'ID');

  /// Tema terang dengan transisi halaman Bpedia.
  static ThemeData lightTheme() =>
      BpTheme.light().copyWith(pageTransitionsTheme: pageTransitions);

  /// Tema gelap dengan transisi halaman Bpedia.
  static ThemeData darkTheme() =>
      BpTheme.dark().copyWith(pageTransitionsTheme: pageTransitions);

  /// Transisi pindah halaman: geser-pudar Bpedia di Android, web, dan
  /// desktop; geser Cupertino (dengan usap kembali) di iOS dan macOS.
  static const PageTransitionsTheme pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: BpPageTransitionsBuilder(),
      TargetPlatform.fuchsia: BpPageTransitionsBuilder(),
      TargetPlatform.linux: BpPageTransitionsBuilder(),
      TargetPlatform.windows: BpPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  @override
  State<BpediaApp> createState() => _BpediaAppState();
}

class _BpediaAppState extends State<BpediaApp> with WidgetsBindingObserver {
  final ThemeData _light = BpediaApp.lightTheme();
  final ThemeData _dark = BpediaApp.darkTheme();
  late _TabLocationReporter _reporter;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attach(_services);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _services.router.flushPending();
    });
  }

  @override
  void didUpdateWidget(BpediaApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.services, widget.services)) return;
    _detach(oldWidget.services);
    _attach(widget.services);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detach(_services);
    super.dispose();
  }

  void _attach(AppServices services) {
    final router = services.router
      ..shellBuilder = ((context) => const AppShell())
      ..notFoundBuilder = (context, route) => NotFoundPage(route: route);
    _reporter = _TabLocationReporter(router);
    router.tabRoute.addListener(_reporter.report);
  }

  void _detach(AppServices services) {
    services.router.tabRoute.removeListener(_reporter.report);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    _services.sound.setForeground(foreground);
    if (!foreground) unawaited(_services.document.flush());
  }

  /// Tautan yang datang saat app berjalan (tautan pembuka, alamat browser
  /// diubah) dibuka lewat router supaya akar tab tidak menumpuk kerangka
  /// kedua.
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    _services.router.openLocation(routeInformation.uri.toString());
    return SynchronousFuture<bool>(true);
  }

  Widget _frame(BuildContext context, Widget? child) {
    final media = MediaQuery.of(context);
    final c = context.bp;
    final reduce =
        media.disableAnimations ||
        _services.settings.reduceMotion ||
        browserPrefersReducedMotion();
    final overlay =
        (c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: c.surface,
              systemNavigationBarIconBrightness: c.isDark
                  ? Brightness.light
                  : Brightness.dark,
            );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: MediaQuery(
        data: media.copyWith(
          disableAnimations: reduce,
          textScaler: media.textScaler.clamp(maxScaleFactor: 2),
        ),
        // Kanvas di belakang navigator: saat transisi halaman lama memudar
        // keluar, yang terlihat warna latar app, bukan hitam.
        child: PhoneFrame(
          child: ColoredBox(
            color: c.canvas,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    final router = services.router;
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) => MaterialApp(
          title: 'Bpedia Demo',
          debugShowCheckedModeBanner: false,
          navigatorKey: router.navigatorKey,
          navigatorObservers: <NavigatorObserver>[_reporter],
          theme: _light,
          darkTheme: _dark,
          themeMode: services.settings.themeMode,
          themeAnimationDuration: BpMotion.standard,
          themeAnimationCurve: BpMotion.standardCurve,
          locale: BpediaApp.locale,
          supportedLocales: const <Locale>[BpediaApp.locale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          scrollBehavior: const BpScrollBehavior(),
          initialRoute: widget.initialLocation,
          onGenerateRoute: router.onGenerateRoute,
          onGenerateInitialRoutes: router.onGenerateInitialRoutes,
          builder: _frame,
        ),
      ),
    );
  }
}

/// Transisi pindah halaman (SPEC §2.4, kelas Standar), pola pudar-tembus:
/// halaman lama bergeser sedikit ke kiri dan memudar keluar lebih dulu, lalu
/// halaman baru masuk dari kanan sambil memudar masuk, sehingga teks dua
/// halaman tidak bertumpuk. Saat gerak dikurangi hanya silang-pudar.
class BpPageTransitionsBuilder extends PageTransitionsBuilder {
  const BpPageTransitionsBuilder();

  static final Animatable<Offset> _enterSlide = Tween<Offset>(
    begin: const Offset(0.16, 0),
    end: Offset.zero,
  ).chain(CurveTween(curve: BpMotion.standardCurve));
  static final Animatable<double> _enterFade = CurveTween(
    curve: const Interval(0.3, 1, curve: Curves.easeOut),
  );
  static final Animatable<Offset> _leaveSlide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.06, 0),
  ).chain(CurveTween(curve: BpMotion.standardCurve));
  static final Animatable<double> _leaveFade = Tween<double>(
    begin: 1,
    end: 0,
  ).chain(CurveTween(curve: const Interval(0, 0.35, curve: Curves.easeIn)));
  static final Animatable<double> _plainFade = CurveTween(
    curve: Curves.easeOut,
  );

  @override
  Duration get transitionDuration => BpMotion.standard;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (BpMotion.reduced(context)) {
      return FadeTransition(opacity: animation.drive(_plainFade), child: child);
    }
    return SlideTransition(
      position: secondaryAnimation.drive(_leaveSlide),
      child: FadeTransition(
        opacity: secondaryAnimation.drive(_leaveFade),
        child: SlideTransition(
          position: animation.drive(_enterSlide),
          child: FadeTransition(
            opacity: animation.drive(_enterFade),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Perilaku gulir app: bisa diseret dengan tetikus (kolom ponsel di web)
/// dan tanpa bilah gulir desktop.
class BpScrollBehavior extends MaterialScrollBehavior {
  const BpScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// Di web, menjaga alamat browser sama dengan tab aktif selama kerangka
/// berada di puncak tumpukan (tab berganti tanpa menumpuk rute).
class _TabLocationReporter extends NavigatorObserver {
  _TabLocationReporter(this._router);

  final AppRouter _router;

  void report() {
    if (!kIsWeb) return;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        final navigator = _router.navigatorKey.currentState;
        if (navigator == null || navigator.canPop()) return;
        unawaited(
          SystemNavigator.routeInformationUpdated(
            uri: Uri.parse(_router.tabRoute.value.location),
            replace: true,
          ),
        );
      })
      ..ensureVisualUpdate();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => report();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      report();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      report();
}

/// Layar galat saat layanan app gagal disiapkan.
class BootstrapFailureApp extends StatefulWidget {
  const BootstrapFailureApp({required this.onRetry, super.key});

  /// Mengulang penyiapan; app ini diganti bila berhasil.
  final Future<void> Function() onRetry;

  @override
  State<BootstrapFailureApp> createState() => _BootstrapFailureAppState();
}

class _BootstrapFailureAppState extends State<BootstrapFailureApp> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onRetry();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bpedia Demo',
      debugShowCheckedModeBanner: false,
      theme: BpTheme.light(),
      darkTheme: BpTheme.dark(),
      locale: BpediaApp.locale,
      supportedLocales: const <Locale>[BpediaApp.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) =>
          PhoneFrame(child: child ?? const SizedBox.shrink()),
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.bp.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  illustration: const BipyPose(
                    'assets/bipy/bipy_pose_semangat.webp',
                    height: 168,
                  ),
                  title: 'Bpedia belum bisa dibuka',
                  message:
                      'Data aplikasi gagal dimuat. Tutup aplikasi lain yang '
                      'berat, lalu coba lagi ya, Babes.',
                  actionLabel: _busy ? 'Memuat ulang' : 'Coba lagi',
                  onAction: _busy ? null : _retry,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
