import 'package:bpedia_app/app/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppRouter router;
  late bool loggedIn;

  Widget page(String label, {List<Widget> actions = const <Widget>[]}) =>
      Scaffold(body: Column(children: <Widget>[Text(label), ...actions]));

  void registerAll() {
    router
      ..registerTab(
        AppTab.home,
        (context) => page(
          'tab beranda',
          actions: <Widget>[
            TextButton(
              onPressed: () => router.go(context, const ProductRoute('P1')),
              child: const Text('buka produk'),
            ),
            TextButton(
              onPressed: () => router.go(context, const CheckoutRoute()),
              child: const Text('buka checkout'),
            ),
            TextButton(
              onPressed: () =>
                  router.go(context, const CatalogRoute(category: 'makeup')),
              child: const Text('buka katalog makeup'),
            ),
            TextButton(
              onPressed: () => router.go(context, const WishlistRoute()),
              child: const Text('buka wishlist'),
            ),
          ],
        ),
      )
      ..registerTab(
        AppTab.catalog,
        (context) => ValueListenableBuilder<AppRoute>(
          valueListenable: router.tabRoute,
          builder: (context, route, _) => page(
            'tab katalog ${route is CatalogRoute ? route.category : null}',
          ),
        ),
      )
      ..registerTab(AppTab.orders, (context) => page('tab pesanan'))
      ..register<ProductRoute>(
        (context, route) => page(
          'produk ${route.code}',
          actions: <Widget>[
            TextButton(
              onPressed: () => router.go(context, const CartRoute()),
              child: const Text('ke keranjang'),
            ),
            TextButton(
              onPressed: () => router.back(context),
              child: const Text('kembali'),
            ),
            TextButton(
              onPressed: () => router.go(context, const OrdersRoute()),
              child: const Text('ke pesanan'),
            ),
          ],
        ),
      )
      ..register<CartRoute>(
        (context, route) => page(
          'keranjang',
          actions: <Widget>[
            TextButton(
              onPressed: () => router.replace(context, const CheckoutRoute()),
              child: const Text('ganti ke checkout'),
            ),
            TextButton(
              onPressed: () => router.goHome(context),
              child: const Text('ke beranda'),
            ),
          ],
        ),
      )
      ..register<CheckoutRoute>((context, route) => page('checkout'))
      ..register<OrderDetailRoute>(
        (context, route) => page('pesanan ${route.orderId}'),
      )
      ..register<LoginRoute>(
        (context, route) => page(
          'masuk lanjut=${route.next}',
          actions: <Widget>[
            TextButton(
              onPressed: () {
                loggedIn = true;
                router.completeLogin(context, next: route.next);
              },
              child: const Text('masuk sekarang'),
            ),
          ],
        ),
      );
  }

  Widget app({String initialRoute = '/'}) => MaterialApp(
    navigatorKey: router.navigatorKey,
    initialRoute: initialRoute,
    onGenerateRoute: router.onGenerateRoute,
    onGenerateInitialRoutes: router.onGenerateInitialRoutes,
  );

  setUp(() {
    loggedIn = false;
    router = AppRouter(isLoggedIn: () => loggedIn);
    registerAll();
  });

  tearDown(() => router.dispose());

  testWidgets('mulai di Beranda; rute biasa ditumpuk dan bisa ditutup', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('tab beranda'), findsOneWidget);
    expect(router.currentTab, AppTab.home);

    await tester.tap(find.text('buka produk'));
    await tester.pumpAndSettle();
    expect(find.text('produk P1'), findsOneWidget);

    await tester.tap(find.text('kembali'));
    await tester.pumpAndSettle();
    expect(find.text('tab beranda'), findsOneWidget);
    expect(find.text('produk P1'), findsNothing);
  });

  testWidgets('akar tab mengganti tab dan menutup halaman di atasnya', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('buka produk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ke pesanan'));
    await tester.pumpAndSettle();

    expect(find.text('tab pesanan'), findsOneWidget);
    expect(find.text('produk P1'), findsNothing);
    expect(router.currentTab, AppTab.orders);
    expect(router.navigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('parameter akar tab sampai ke halaman tab', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('buka katalog makeup'));
    await tester.pumpAndSettle();

    expect(find.text('tab katalog makeup'), findsOneWidget);
    expect(router.tabRoute.value, const CatalogRoute(category: 'makeup'));

    router.selectTab(AppTab.catalog);
    await tester.pumpAndSettle();
    expect(find.text('tab katalog makeup'), findsOneWidget);

    router.selectTab(AppTab.home);
    await tester.pumpAndSettle();
    expect(find.text('tab beranda'), findsOneWidget);
  });

  testWidgets('tamu diarahkan ke Masuk lalu lanjut ke tujuan semula', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('buka checkout'));
    await tester.pumpAndSettle();
    expect(find.text('masuk lanjut=/checkout'), findsOneWidget);
    expect(find.text('checkout'), findsNothing);

    await tester.tap(find.text('masuk sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('checkout'), findsOneWidget);

    router.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('tab beranda'), findsOneWidget);
  });

  testWidgets('yang sudah masuk langsung membuka rute wajib-masuk', (
    tester,
  ) async {
    loggedIn = true;
    await tester.pumpWidget(app());

    await tester.tap(find.text('buka checkout'));
    await tester.pumpAndSettle();

    expect(find.text('checkout'), findsOneWidget);
  });

  testWidgets('completeLogin tanpa tujuan menutup halaman Masuk', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    router.openLocation('/masuk');
    await tester.pumpAndSettle();
    expect(find.text('masuk lanjut=null'), findsOneWidget);

    await tester.tap(find.text('masuk sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('tab beranda'), findsOneWidget);
  });

  testWidgets('replace mengganti halaman teratas', (tester) async {
    loggedIn = true;
    await tester.pumpWidget(app());
    router.openLocation('/keranjang');
    await tester.pumpAndSettle();

    await tester.tap(find.text('ganti ke checkout'));
    await tester.pumpAndSettle();
    expect(find.text('checkout'), findsOneWidget);

    router.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('tab beranda'), findsOneWidget);
  });

  testWidgets('goHome menutup semua halaman dan kembali ke tab Beranda', (
    tester,
  ) async {
    await tester.pumpWidget(app(initialRoute: '/pesanan'));
    expect(find.text('tab pesanan'), findsOneWidget);
    router.openLocation('/produk/P9');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ke keranjang'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ke beranda'));
    await tester.pumpAndSettle();

    expect(find.text('tab beranda'), findsOneWidget);
    expect(router.navigatorKey.currentState!.canPop(), isFalse);
  });

  group('lokasi awal (URL web)', () {
    testWidgets('akar tab langsung aktif', (tester) async {
      await tester.pumpWidget(app(initialRoute: '/katalog?kategori=skincare'));

      expect(find.text('tab katalog skincare'), findsOneWidget);
      expect(router.navigatorKey.currentState!.canPop(), isFalse);
    });

    testWidgets('halaman dalam: kerangka di dasar, halaman di atasnya', (
      tester,
    ) async {
      await tester.pumpWidget(app(initialRoute: '/produk/P39A06S01000052'));
      await tester.pumpAndSettle();
      expect(find.text('produk P39A06S01000052'), findsOneWidget);

      await tester.tap(find.text('kembali'));
      await tester.pumpAndSettle();
      expect(find.text('tab beranda'), findsOneWidget);
    });

    testWidgets('tamu ke rute wajib-masuk mendarat di Masuk', (tester) async {
      await tester.pumpWidget(app(initialRoute: '/pesanan/BP-261125-0001'));
      await tester.pumpAndSettle();

      expect(find.text('masuk lanjut=/pesanan/BP-261125-0001'), findsOneWidget);
      await tester.tap(find.text('masuk sekarang'));
      await tester.pumpAndSettle();
      expect(find.text('pesanan BP-261125-0001'), findsOneWidget);
    });

    testWidgets('lokasi tak dikenal: halaman tidak ada, lalu ke Beranda', (
      tester,
    ) async {
      await tester.pumpWidget(app(initialRoute: '/entah/di-mana'));
      await tester.pumpAndSettle();

      expect(find.text('Waduh, tujuanmu nggak ada!'), findsOneWidget);
      await tester.tap(find.text('Ke Beranda'));
      await tester.pumpAndSettle();
      expect(find.text('tab beranda'), findsOneWidget);
      expect(find.text('Waduh, tujuanmu nggak ada!'), findsNothing);
    });
  });

  group('rute tanpa halaman', () {
    testWidgets('rute dikenal tetapi belum terdaftar memakai notFoundBuilder', (
      tester,
    ) async {
      await tester.pumpWidget(app());

      await tester.tap(find.text('buka wishlist'));
      await tester.pumpAndSettle();

      expect(find.text('Waduh, tujuanmu nggak ada!'), findsOneWidget);
      expect(router.isRegistered<WishlistRoute>(), isFalse);
      expect(router.canOpen(const WishlistRoute()), isFalse);
    });

    testWidgets('notFoundBuilder bisa diganti kerangka app', (tester) async {
      router.notFoundBuilder = (context, route) =>
          page('404 khusus ${route.location}');
      await tester.pumpWidget(app(initialRoute: '/x'));
      await tester.pumpAndSettle();

      expect(find.text('404 khusus /x'), findsOneWidget);
    });

    testWidgets('tab yang belum terdaftar tidak membuat crash', (tester) async {
      await tester.pumpWidget(app());

      router.selectTab(AppTab.rewards);
      await tester.pumpAndSettle();

      expect(find.text('Waduh, tujuanmu nggak ada!'), findsOneWidget);
      expect(router.tabBuilder(AppTab.rewards), isNull);
      expect(router.tabBuilder(AppTab.home), isNotNull);
    });
  });

  group('deep link dan notifikasi', () {
    testWidgets('openLocation menumpuk halaman dan mengembalikan rutenya', (
      tester,
    ) async {
      await tester.pumpWidget(app());

      final route = router.openLocation('produk/P7');
      await tester.pumpAndSettle();

      expect(route, const ProductRoute('P7'));
      expect(find.text('produk P7'), findsOneWidget);
    });

    testWidgets('lokasi sebelum navigator siap dibuka oleh flushPending', (
      tester,
    ) async {
      final route = router.openLocation('/produk/P8');
      expect(route, const ProductRoute('P8'));

      await tester.pumpWidget(app());
      expect(find.text('produk P8'), findsNothing);

      router.flushPending();
      await tester.pumpAndSettle();
      expect(find.text('produk P8'), findsOneWidget);

      router.navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      router.flushPending();
      await tester.pumpAndSettle();
      expect(find.text('tab beranda'), findsOneWidget);
    });

    testWidgets('tamu yang mengetuk notifikasi pesanan harus masuk dulu', (
      tester,
    ) async {
      await tester.pumpWidget(app());

      router.openLocation('/pesanan/BP-261125-0002');
      await tester.pumpAndSettle();

      expect(find.text('masuk lanjut=/pesanan/BP-261125-0002'), findsOneWidget);
    });
  });

  testWidgets('kerangka kustom dan pabrik rute dipakai', (tester) async {
    var built = 0;
    router
      ..shellBuilder = ((context) => page('kerangka ${router.currentTab.name}'))
      ..pageRouteFactory = (settings, builder) {
        built++;
        return PageRouteBuilder<Object?>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        );
      };

    await tester.pumpWidget(app(initialRoute: '/produk/P1'));
    await tester.pumpAndSettle();

    expect(built, 2);
    expect(find.text('produk P1'), findsOneWidget);
    router.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('kerangka home'), findsOneWidget);
  });

  test('canOpen: halaman atau tab terdaftar; tak dikenal selalu false', () {
    expect(router.canOpen(const ProductRoute('P1')), isTrue);
    expect(router.canOpen(const HomeRoute()), isTrue);
    expect(router.canOpen(const RewardsRoute()), isFalse);
    expect(router.canOpen(const NotFoundRoute('/x')), isFalse);
    expect(router.isRegistered<CartRoute>(), isTrue);
  });

  testWidgets('halaman tidak ada: target sentuh, semantik, skala teks 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: DefaultNotFoundPage(location: '/x', onHome: (_) {}),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final button = find.widgetWithText(FilledButton, 'Ke Beranda');
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(button);
    await tester.pump();
    expect(
      tester.getSemantics(button),
      isSemantics(
        label: 'Ke Beranda',
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
