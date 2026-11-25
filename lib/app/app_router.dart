/// Navigator app: tabel pembangun halaman per tipe [AppRoute], tab kerangka,
/// gerbang masuk untuk tamu, dan pintu untuk deep link serta ketukan
/// notifikasi.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_routes.dart';

export 'app_routes.dart';

/// Pembangun halaman untuk rute bertipe [T].
typedef AppPageBuilder<T extends AppRoute> =
    Widget Function(BuildContext context, T route);

/// Pembangun kerangka (nav bawah) yang menampilkan tab aktif.
typedef AppShellBuilder = Widget Function(BuildContext context);

/// Pembungkus halaman menjadi [Route] (transisi khusus).
typedef AppPageRouteFactory =
    Route<Object?> Function(RouteSettings settings, WidgetBuilder builder);

/// Navigator app.
///
/// Fitur mendaftarkan halamannya dengan [register] dan [registerTab];
/// kerangka memasang [onGenerateRoute], [onGenerateInitialRoutes], dan
/// [navigatorKey] ke `MaterialApp`. Navigasi antarfitur hanya lewat [go].
class AppRouter {
  AppRouter({bool Function()? isLoggedIn})
    : _isLoggedIn = isLoggedIn ?? _alwaysLoggedIn {
    notFoundBuilder = (context, route) =>
        DefaultNotFoundPage(location: route.location, onHome: goHome);
  }

  /// Kunci navigator akar, dipakai untuk membuka lokasi dari luar pohon
  /// widget (deep link, notifikasi).
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'bpedia-root',
  );

  final Map<Type, Widget Function(BuildContext, AppRoute)> _pages =
      <Type, Widget Function(BuildContext, AppRoute)>{};
  final Map<AppTab, WidgetBuilder> _tabs = <AppTab, WidgetBuilder>{};
  final ValueNotifier<AppRoute> _tabRoute = ValueNotifier<AppRoute>(
    const HomeRoute(),
  );
  bool Function() _isLoggedIn;
  String? _pendingLocation;

  /// Kerangka app (nav bawah). Tanpa kerangka, akar tab ditampilkan sebagai
  /// halaman biasa.
  AppShellBuilder? shellBuilder;

  /// Halaman untuk rute yang tidak terdaftar atau tidak dikenal.
  late AppPageBuilder<AppRoute> notFoundBuilder;

  /// Pembungkus halaman; bawaan `MaterialPageRoute`.
  AppPageRouteFactory pageRouteFactory = _materialRoute;

  /// Rute akar tab yang sedang aktif beserta parameternya (contoh
  /// `CatalogRoute(category: 'skincare')`). Kerangka dan halaman tab
  /// mendengarkannya.
  ValueListenable<AppRoute> get tabRoute => _tabRoute;

  /// Tab aktif.
  AppTab get currentTab => _tabRoute.value.tab ?? AppTab.home;

  /// Mengganti pemeriksa status masuk (dipasang `AppServices`).
  set isLoggedIn(bool Function() value) => _isLoggedIn = value;

  // --------------------------------------------------------------- daftar

  /// Mendaftarkan halaman untuk rute bertipe [T].
  void register<T extends AppRoute>(AppPageBuilder<T> builder) {
    _pages[T] = (context, route) => builder(context, route as T);
  }

  /// Mendaftarkan isi [tab].
  void registerTab(AppTab tab, WidgetBuilder builder) {
    _tabs[tab] = builder;
  }

  /// Apakah rute bertipe [T] punya halaman.
  bool isRegistered<T extends AppRoute>() => _pages.containsKey(T);

  /// Apakah [route] bisa ditampilkan (halaman atau tab terdaftar).
  bool canOpen(AppRoute route) {
    if (route is NotFoundRoute) return false;
    final tab = route.tab;
    return _pages.containsKey(route.runtimeType) ||
        (tab != null && _tabs.containsKey(tab));
  }

  /// Pembangun isi [tab], atau null bila belum terdaftar.
  WidgetBuilder? tabBuilder(AppTab tab) => _tabs[tab];

  /// Membangun isi [tab]; tab yang belum terdaftar menampilkan halaman
  /// "tidak ada".
  Widget buildTab(BuildContext context, AppTab tab) {
    final builder = _tabs[tab];
    final root = AppRoutes.tabRoot(tab);
    if (builder != null) return builder(context);
    final page = _pages[root.runtimeType];
    return page != null
        ? page(context, root)
        : notFoundBuilder(context, NotFoundRoute(root.location));
  }

  // -------------------------------------------------------------- navigasi

  /// Membuka [route]. Akar tab mengganti tab aktif (halaman di atasnya
  /// ditutup); rute lain ditumpuk. Tamu yang membuka rute wajib-masuk
  /// diarahkan ke `/masuk` lalu kembali ke tujuan semula.
  Future<void> go(BuildContext context, AppRoute route) =>
      _open(Navigator.of(context, rootNavigator: true), route);

  /// Mengganti halaman teratas dengan [route] (contoh checkout → bayar).
  Future<void> replace(BuildContext context, AppRoute route) => _open(
    Navigator.of(context, rootNavigator: true),
    route,
    replaceTop: true,
  );

  /// Menutup halaman teratas; bila tidak ada yang bisa ditutup, ke Beranda.
  void back(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      selectTab(AppTab.home);
    }
  }

  /// Ke Beranda dari halaman mana pun, termasuk saat halaman itu satu-satunya
  /// di tumpukan (lokasi awal tidak dikenal).
  void goHome(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.popUntil((entry) => entry.isFirst);
      _tabRoute.value = const HomeRoute();
      return;
    }
    _tabRoute.value = const HomeRoute();
    navigator.pushReplacement<Object?, Object?>(
      pageRouteFactory(const RouteSettings(name: AppRoutes.home), _shell),
    );
  }

  /// Pindah ke [tab] dengan parameter bawaan dan menutup halaman di atasnya.
  void selectTab(AppTab tab) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (_tabRoute.value.tab != tab) _tabRoute.value = AppRoutes.tabRoot(tab);
  }

  /// Membuka [location] (deep link, muatan notifikasi, rute kotak masuk).
  /// Bila navigator belum siap, lokasi disimpan dan dibuka oleh
  /// [flushPending]. Mengembalikan rute hasil urai.
  AppRoute openLocation(String location) {
    final route = parseAppRoute(location);
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingLocation = location;
    } else {
      _open(navigator, route);
    }
    return route;
  }

  /// Membuka lokasi yang tertunda karena navigator belum siap. Dipanggil
  /// kerangka setelah bingkai pertama.
  void flushPending() {
    final location = _pendingLocation;
    final navigator = navigatorKey.currentState;
    if (location == null || navigator == null) return;
    _pendingLocation = null;
    _open(navigator, parseAppRoute(location));
  }

  /// Setelah berhasil masuk atau daftar: menutup halaman autentikasi dan
  /// melanjutkan ke [next] (lokasi `?lanjut=`), bila ada.
  void completeLogin(BuildContext context, {String? next}) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final target = next == null ? null : parseAppRoute(next);
    if (target == null || target is NotFoundRoute) {
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        selectTab(AppTab.home);
      }
      return;
    }
    _open(navigator, target, replaceTop: navigator.canPop());
  }

  // ----------------------------------------------------- sambungan MaterialApp

  /// Untuk `MaterialApp.onGenerateRoute`.
  Route<Object?> onGenerateRoute(RouteSettings settings) {
    final route = parseAppRoute(settings.name ?? '/');
    final named = RouteSettings(
      name: route.location,
      arguments: settings.arguments,
    );
    if (route.tab != null) {
      _tabRoute.value = route;
      return pageRouteFactory(named, _shell);
    }
    return pageRouteFactory(named, (context) => _page(context, route));
  }

  /// Untuk `MaterialApp.onGenerateInitialRoutes`: kerangka selalu di dasar,
  /// lalu halaman tujuan bila lokasi awal bukan akar tab.
  List<Route<Object?>> onGenerateInitialRoutes(String initialRoute) {
    var route = parseAppRoute(initialRoute);
    if (route.requiresLogin && !_isLoggedIn()) {
      route = LoginRoute(next: route.location);
    }
    final tabRoute = route.tab == null ? const HomeRoute() : route;
    _tabRoute.value = tabRoute;
    return <Route<Object?>>[
      pageRouteFactory(RouteSettings(name: tabRoute.location), _shell),
      if (route.tab == null)
        pageRouteFactory(
          RouteSettings(name: route.location),
          (context) => _page(context, route),
        ),
    ];
  }

  /// Melepas pendengar.
  void dispose() => _tabRoute.dispose();

  // --------------------------------------------------------------- bantuan

  Future<void> _open(
    NavigatorState navigator,
    AppRoute route, {
    bool replaceTop = false,
  }) async {
    if (route.tab != null) {
      navigator.popUntil((entry) => entry.isFirst);
      _tabRoute.value = route;
      return;
    }
    final target = route.requiresLogin && !_isLoggedIn()
        ? LoginRoute(next: route.location)
        : route;
    final pageRoute = pageRouteFactory(
      RouteSettings(name: target.location),
      (context) => _page(context, target),
    );
    if (replaceTop && navigator.canPop()) {
      await navigator.pushReplacement<Object?, Object?>(pageRoute);
    } else {
      await navigator.push<Object?>(pageRoute);
    }
  }

  Widget _shell(BuildContext context) {
    final shell = shellBuilder;
    if (shell != null) return shell(context);
    return ValueListenableBuilder<AppRoute>(
      valueListenable: _tabRoute,
      builder: (context, route, _) =>
          buildTab(context, route.tab ?? AppTab.home),
    );
  }

  Widget _page(BuildContext context, AppRoute route) {
    final builder = _pages[route.runtimeType];
    return builder != null
        ? builder(context, route)
        : notFoundBuilder(context, route);
  }

  static bool _alwaysLoggedIn() => true;

  static Route<Object?> _materialRoute(
    RouteSettings settings,
    WidgetBuilder builder,
  ) => MaterialPageRoute<Object?>(settings: settings, builder: builder);
}

/// Halaman bawaan untuk rute yang tidak ada. Kerangka app menggantinya
/// dengan halaman 404 berdesain lewat [AppRouter.notFoundBuilder].
class DefaultNotFoundPage extends StatelessWidget {
  const DefaultNotFoundPage({
    required this.location,
    required this.onHome,
    super.key,
  });

  /// Lokasi yang diminta.
  final String location;

  /// Aksi tombol "Ke Beranda".
  final void Function(BuildContext context) onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore_off_outlined,
                    size: 40,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Waduh, tujuanmu nggak ada!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Halaman yang kamu cari tidak ditemukan atau sudah pindah. '
                  'Yuk, kembali ke Beranda, Babes.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => onHome(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 48),
                  ),
                  child: const Text('Ke Beranda'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
