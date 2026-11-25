import 'dart:async';

import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/app/app_scope.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/app/not_found_page.dart';
import 'package:bpedia_app/app/phone_frame.dart';
import 'package:bpedia_app/app/shell.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/shot.dart';

/// Kode produk nyata dari `assets/catalog/catalog.json`.
const String _productA = 'P68B13S01000010';
const String _productB = 'P39A06S01000007';

const Size _phone = Size(390, 844);
const Size _smallPhone = Size(360, 640);
const Size _web = Size(1280, 800);

/// Gateway dengan titik "bisa diklaim" di zona Hadiah.
class _BadgeRewards extends NoRewardsGateway {
  @override
  bool get available => true;

  @override
  bool hasBadge(RewardsEntry entry) => entry == RewardsEntry.hub;
}

/// Isi tab uji dengan hitungan, untuk memeriksa keadaan tab dipertahankan.
class _CounterTab extends StatefulWidget {
  const _CounterTab({required this.name});

  final String name;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => setState(() => _count++),
          child: Text('${widget.name} $_count'),
        ),
      ),
    );
  }
}

Future<AppServices> _pumpApp(
  WidgetTester tester, {
  Size size = _phone,
  String location = '/',
  bool loggedIn = false,
  double textScale = 1,
  SyncRewardsBuilder? rewardsBuilder,
  void Function(AppServices services)? setup,
}) async {
  await loadShotFonts(tester);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final services = AppServices.forTest(
    loggedIn: loggedIn,
    rewardsBuilder: rewardsBuilder,
  );
  // dispose() menunggu I/O sungguhan yang tidak pernah selesai di jam palsu
  // testWidgets; dilepas tanpa ditunggu setelah pohon widget dibongkar.
  addTearDown(() => unawaited(services.dispose()));
  setup?.call(services);
  await tester.pumpWidget(
    BpediaApp(services: services, initialLocation: location),
  );
  await tester.pump(const Duration(milliseconds: 700));
  return services;
}

Finder _navTab(String label) =>
    find.descendant(of: find.byType(BpBottomNav), matching: find.text(label));

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(_navTab(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await _settle(tester);
}

void main() {
  group('navigasi tab', () {
    testWidgets('lima tab tampil dan tab awal Beranda', (tester) async {
      final services = await _pumpApp(tester);
      for (final label in <String>[
        'Beranda',
        'Katalog',
        'Hadiah',
        'Transaksi',
        'Akun',
      ]) {
        expect(_navTab(label), findsOneWidget, reason: label);
      }
      expect(services.router.currentTab, AppTab.home);
      expect(find.text('Beranda sedang disiapkan'), findsOneWidget);
      expect(
        tester.widget<BpBottomNav>(find.byType(BpBottomNav)).currentIndex,
        0,
      );
    });

    testWidgets('tab tanpa fitur menampilkan halaman pengganti', (
      tester,
    ) async {
      final services = await _pumpApp(tester);
      const expected = <String, (AppTab, String)>{
        'Katalog': (AppTab.catalog, 'Katalog sedang disiapkan'),
        'Hadiah': (AppTab.rewards, 'Zona Hadiah segera dibuka'),
        'Transaksi': (AppTab.orders, 'Transaksi sedang disiapkan'),
        'Akun': (AppTab.account, 'Akun sedang disiapkan'),
        'Beranda': (AppTab.home, 'Beranda sedang disiapkan'),
      };
      for (final entry in expected.entries) {
        await _tapTab(tester, entry.key);
        expect(services.router.currentTab, entry.value.$1);
        expect(find.text(entry.value.$2), findsOneWidget);
        expect(
          tester.widget<BpBottomNav>(find.byType(BpBottomNav)).currentIndex,
          entry.value.$1.index,
        );
      }
    });

    testWidgets('halaman pengganti katalog memakai jumlah produk nyata', (
      tester,
    ) async {
      final services = await _pumpApp(tester, location: '/katalog');
      final products = services.catalog.products.length;
      final categories = services.catalog.categories.length;
      expect(products, greaterThan(0));
      expect(
        find.textContaining('$products produk asli Bpedia dari $categories'),
        findsOneWidget,
      );
    });

    testWidgets('tab terdaftar lewat registerTab menggantikan pengganti', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        setup: (services) => services.router
          ..registerTab(
            AppTab.home,
            (context) => const _CounterTab(name: 'beranda'),
          )
          ..registerTab(
            AppTab.catalog,
            (context) => const _CounterTab(name: 'katalog'),
          ),
      );
      expect(find.text('beranda 0'), findsOneWidget);
      expect(find.text('Beranda sedang disiapkan'), findsNothing);
      await _tapTab(tester, 'Katalog');
      expect(find.text('katalog 0'), findsOneWidget);
      await _tapTab(tester, 'Akun');
      expect(find.text('Akun sedang disiapkan'), findsOneWidget);
    });

    testWidgets('tab dibangun saat pertama dibuka dan keadaannya bertahan', (
      tester,
    ) async {
      var catalogBuilds = 0;
      await _pumpApp(
        tester,
        setup: (services) => services.router
          ..registerTab(
            AppTab.home,
            (context) => const _CounterTab(name: 'beranda'),
          )
          ..registerTab(AppTab.catalog, (context) {
            catalogBuilds++;
            return const _CounterTab(name: 'katalog');
          }),
      );
      expect(catalogBuilds, 0);
      await tester.tap(find.text('beranda 0'));
      await tester.pump();
      expect(find.text('beranda 1'), findsOneWidget);

      await _tapTab(tester, 'Katalog');
      expect(catalogBuilds, greaterThan(0));
      expect(find.text('beranda 1'), findsNothing);
      expect(find.text('beranda 1', skipOffstage: false), findsOneWidget);

      await _tapTab(tester, 'Beranda');
      expect(find.text('beranda 1'), findsOneWidget);
    });

    testWidgets('animasi tab tersembunyi berhenti', (tester) async {
      await _pumpApp(tester);
      await _tapTab(tester, 'Katalog');
      final hidden = tester.element(
        find.text('Beranda sedang disiapkan', skipOffstage: false),
      );
      final shown = tester.element(find.text('Katalog sedang disiapkan'));
      expect(TickerMode.valuesOf(hidden).enabled, isFalse);
      expect(TickerMode.valuesOf(shown).enabled, isTrue);
    });

    testWidgets('ketuk tab aktif menggulir isi ke atas', (tester) async {
      await _pumpApp(
        tester,
        setup: (services) => services.router.registerTab(
          AppTab.home,
          (context) => Scaffold(
            body: ListView.builder(
              itemCount: 60,
              itemBuilder: (context, index) =>
                  SizedBox(height: 64, child: Text('baris $index')),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await _settle(tester);
      expect(find.text('baris 0'), findsNothing);
      await _tapTab(tester, 'Beranda');
      await _settle(tester);
      expect(find.text('baris 0'), findsOneWidget);
    });

    testWidgets('bagian tombol Hadiah yang menonjol bisa diketuk', (
      tester,
    ) async {
      final services = await _pumpApp(tester);
      final lift = find.byKey(const ValueKey<String>('shell-reward-lift'));
      expect(lift, findsOneWidget);
      final nav = tester.getRect(find.byType(BpBottomNav));
      final area = tester.getRect(lift);
      expect(area.bottom, moreOrLessEquals(nav.top, epsilon: 0.5));
      expect(area.center.dx, moreOrLessEquals(nav.center.dx, epsilon: 0.5));
      await tester.tapAt(area.center);
      await _settle(tester);
      expect(services.router.currentTab, AppTab.rewards);
    });

    testWidgets('titik Hadiah mengikuti gateway hadiah', (tester) async {
      await _pumpApp(tester, rewardsBuilder: (_) => _BadgeRewards());
      expect(
        tester.widget<BpBottomNav>(find.byType(BpBottomNav)).rewardDot,
        isTrue,
      );
    });

    testWidgets('tanpa hadiah tidak ada titik maupun lencana', (tester) async {
      await _pumpApp(tester);
      final nav = tester.widget<BpBottomNav>(find.byType(BpBottomNav));
      expect(nav.rewardDot, isFalse);
      expect(nav.trailing.first.badgeCount, 0);
    });
  });

  group('tombol kembali', () {
    testWidgets('dari tab lain kembali ke Beranda', (tester) async {
      final services = await _pumpApp(tester);
      await _tapTab(tester, 'Transaksi');
      expect(services.router.currentTab, AppTab.orders);
      await _systemBack(tester);
      expect(services.router.currentTab, AppTab.home);
      expect(find.text('Beranda sedang disiapkan'), findsOneWidget);
    });

    testWidgets('menutup halaman di atas kerangka lebih dulu', (tester) async {
      final services = await _pumpApp(
        tester,
        setup: (services) => services.router.register<CartRoute>(
          (context, route) =>
              const Scaffold(body: Center(child: Text('isi keranjang'))),
        ),
      );
      await _tapTab(tester, 'Katalog');
      await tester.tap(find.byTooltip('Keranjang').hitTestable());
      await _settle(tester);
      expect(find.text('isi keranjang'), findsOneWidget);

      await _systemBack(tester);
      expect(find.text('isi keranjang'), findsNothing);
      expect(services.router.currentTab, AppTab.catalog);

      await _systemBack(tester);
      expect(services.router.currentTab, AppTab.home);
    });

    testWidgets('di Beranda tombol kembali diteruskan ke sistem', (
      tester,
    ) async {
      await _pumpApp(tester);
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _systemBack(tester);
      expect(calls, contains('SystemNavigator.pop'));
      expect(find.byType(AppShell), findsOneWidget);
    });
  });

  group('rute tak dikenal', () {
    testWidgets('lokasi awal tak dikenal menampilkan 404 berdesain', (
      tester,
    ) async {
      final services = await _pumpApp(tester, location: '/promo-rahasia/2026');
      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.text(NotFoundPage.unknownTitle), findsOneWidget);
      expect(find.text('/promo-rahasia/2026'), findsOneWidget);
      expect(find.byTooltip('Kembali'), findsOneWidget);

      await tester.tap(find.text('Ke Beranda'));
      await _settle(tester);
      expect(find.byType(NotFoundPage), findsNothing);
      expect(services.router.currentTab, AppTab.home);
      expect(find.text('Beranda sedang disiapkan'), findsOneWidget);
    });

    testWidgets('tautan tak dikenal saat app berjalan', (tester) async {
      final services = await _pumpApp(tester, location: '/akun');
      services.router.openLocation('bpedia://entah/ke/mana');
      await _settle(tester);
      expect(find.text(NotFoundPage.unknownTitle), findsOneWidget);

      await tester.tap(find.text('Lihat katalog'));
      await _settle(tester);
      expect(find.byType(NotFoundPage), findsNothing);
      expect(services.router.currentTab, AppTab.catalog);
    });

    testWidgets('rute dikenal tanpa halaman memberi tahu belum tersedia', (
      tester,
    ) async {
      final services = await _pumpApp(tester);
      services.router.openLocation('/keranjang');
      await _settle(tester);
      expect(find.text(NotFoundPage.unavailableTitle), findsOneWidget);
      expect(find.text(NotFoundPage.unknownTitle), findsNothing);

      await tester.tap(find.text('Kembali'));
      await _settle(tester);
      expect(find.byType(NotFoundPage), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('tautan akar tab dari platform tidak menumpuk kerangka', (
      tester,
    ) async {
      final services = await _pumpApp(tester);
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(
          const MethodCall('pushRouteInformation', <String, Object?>{
            'location': '/hadiah',
            'state': null,
          }),
        ),
        (_) {},
      );
      await _settle(tester);
      expect(services.router.currentTab, AppTab.rewards);
      expect(find.byType(AppShell), findsOneWidget);
      expect(services.router.navigatorKey.currentState!.canPop(), isFalse);
    });
  });

  group('lebar layar', () {
    for (final size in <Size>[_smallPhone, _phone]) {
      testWidgets('ponsel ${size.width.toInt()} tampil penuh', (tester) async {
        await _pumpApp(tester, size: size);
        expect(
          find.byKey(const ValueKey<String>('phone-frame-column')),
          findsNothing,
        );
        expect(tester.getSize(find.byType(AppShell)), size);
        expect(tester.getSize(find.byType(BpBottomNav)).width, size.width);
        for (final label in <String>[
          'Katalog',
          'Hadiah',
          'Transaksi',
          'Akun',
        ]) {
          await _tapTab(tester, label);
        }
      });
    }

    testWidgets('lebar 1280 menampilkan kolom ponsel 430 di tengah', (
      tester,
    ) async {
      await _pumpApp(tester, size: _web);
      final column = tester.getRect(
        find.byKey(const ValueKey<String>('phone-frame-column')),
      );
      expect(column.width, PhoneFrame.columnWidth);
      expect(column.center.dx, moreOrLessEquals(_web.width / 2));
      expect(column.height, _web.height);
      expect(tester.getSize(find.byType(AppShell)).width, 430);
      final inner = tester.element(find.byType(AppShell));
      expect(MediaQuery.sizeOf(inner).width, 430);
      expect(find.text('Hai, Babes!'), findsOneWidget);
      for (final label in <String>['Katalog', 'Hadiah', 'Transaksi', 'Akun']) {
        await _tapTab(tester, label);
      }
    });

    testWidgets('layar lebar dan tinggi menampilkan kolom melayang', (
      tester,
    ) async {
      await _pumpApp(tester, size: const Size(1600, 1040));
      final column = tester.getRect(
        find.byKey(const ValueKey<String>('phone-frame-column')),
      );
      expect(column.size, const Size(430, PhoneFrame.maxColumnHeight));
      expect(column.center, const Offset(800, 520));
    });

    testWidgets('halaman 404 di kolom ponsel web', (tester) async {
      await _pumpApp(tester, size: _web, location: '/x/y/z');
      expect(find.text(NotFoundPage.unknownTitle), findsOneWidget);
      expect(tester.getSize(find.byType(NotFoundPage)).width, 430);
    });

    testWidgets('batas kolom ponsel', (tester) async {
      expect(PhoneFrame.isFramed(360), isFalse);
      expect(PhoneFrame.isFramed(390), isFalse);
      expect(PhoneFrame.isFramed(520), isFalse);
      expect(PhoneFrame.isFramed(521), isTrue);
      expect(PhoneFrame.isFramed(1280), isTrue);
    });

    testWidgets('huruf 200% di lebar 360 tanpa luapan', (tester) async {
      final services = await _pumpApp(
        tester,
        size: _smallPhone,
        textScale: 2,
        setup: (services) => services.cart.add(_productA),
      );
      for (final label in <String>['Katalog', 'Hadiah', 'Transaksi', 'Akun']) {
        await _tapTab(tester, label);
      }
      services.router.openLocation('/alamat-yang-sangat-panjang/sekali/banget');
      await _settle(tester);
      expect(find.text(NotFoundPage.unknownTitle), findsOneWidget);
      services.router.openLocation('/keranjang');
      await _settle(tester);
      expect(find.text(NotFoundPage.unavailableTitle), findsOneWidget);
    });

    testWidgets('skala huruf sistem dibatasi 200%', (tester) async {
      await _pumpApp(tester, size: _smallPhone, textScale: 3);
      final context = tester.element(find.byType(AppShell));
      expect(MediaQuery.textScalerOf(context).scale(10), 20);
    });
  });

  group('aplikasi', () {
    testWidgets('lokal Indonesia dan judul app', (tester) async {
      await _pumpApp(tester);
      final context = tester.element(find.byType(AppShell));
      expect(Localizations.localeOf(context), const Locale('id', 'ID'));
      expect(MaterialLocalizations.of(context).backButtonTooltip, 'Kembali');
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        'Bpedia Demo',
      );
    });

    testWidgets('tema mengikuti pengaturan', (tester) async {
      final services = await _pumpApp(
        tester,
        setup: (services) => services.settings.setThemeMode(ThemeMode.dark),
      );
      BuildContext context() => tester.element(find.byType(AppShell));
      expect(Theme.of(context()).brightness, Brightness.dark);
      expect(context().bp.canvas, BpColors.dark.canvas);

      services.settings.setThemeMode(ThemeMode.light);
      await _settle(tester);
      expect(Theme.of(context()).brightness, Brightness.light);
      expect(context().bp.canvas, BpColors.light.canvas);
    });

    testWidgets('sakelar tema di bilah atas mengubah dan menyimpan tema', (
      tester,
    ) async {
      final services = await _pumpApp(
        tester,
        setup: (services) => services.settings.setThemeMode(ThemeMode.light),
      );
      await tester.tap(find.byTooltip('Ganti ke tema gelap').hitTestable());
      await _settle(tester);
      expect(services.settings.themeMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(AppShell))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.byTooltip('Ganti ke tema terang').hitTestable());
      await _settle(tester);
      expect(services.settings.themeMode, ThemeMode.light);
    });

    testWidgets('tombol Masuk tampil untuk tamu dan membuka /masuk', (
      tester,
    ) async {
      final services = await _pumpApp(
        tester,
        setup: (services) => services.router.register<LoginRoute>(
          (context, route) =>
              const Scaffold(body: Center(child: Text('formulir masuk'))),
        ),
      );
      expect(find.byType(LoginButton), findsOneWidget);
      await tester.tap(find.text('Masuk'));
      await _settle(tester);
      expect(find.text('formulir masuk'), findsOneWidget);

      services.signInAsDemo();
      await _systemBack(tester);
      expect(find.text('Masuk'), findsNothing);
    });

    testWidgets('lencana keranjang mengikuti isi keranjang', (tester) async {
      final services = await _pumpApp(
        tester,
        setup: (services) => services.cart.add(_productA),
      );
      CartBadgeIcon badge() => tester.widget<CartBadgeIcon>(
        find.byType(CartBadgeIcon).hitTestable(),
      );
      expect(badge().count, 1);
      services.cart.add(_productB, qty: 2);
      await _settle(tester);
      expect(badge().count, 3);
    });

    testWidgets('pengaturan kurangi gerak sampai ke MediaQuery', (
      tester,
    ) async {
      final services = await _pumpApp(tester);
      BuildContext context() => tester.element(find.byType(AppShell));
      expect(MediaQuery.disableAnimationsOf(context()), isFalse);
      services.settings.setReduceMotion(true);
      await _settle(tester);
      expect(MediaQuery.disableAnimationsOf(context()), isTrue);
    });

    testWidgets('transisi halaman Bpedia terpasang di kedua tema', (
      tester,
    ) async {
      for (final theme in <ThemeData>[
        BpediaApp.lightTheme(),
        BpediaApp.darkTheme(),
      ]) {
        final builders = theme.pageTransitionsTheme.builders;
        expect(
          builders[TargetPlatform.android],
          isA<BpPageTransitionsBuilder>(),
        );
        expect(
          builders[TargetPlatform.windows],
          isA<BpPageTransitionsBuilder>(),
        );
        expect(
          builders[TargetPlatform.iOS],
          isA<CupertinoPageTransitionsBuilder>(),
        );
        expect(theme.extension<BpColors>(), isNotNull);
      }
      const builder = BpPageTransitionsBuilder();
      expect(builder.transitionDuration, const Duration(milliseconds: 280));
      expect(
        builder.reverseTransitionDuration,
        const Duration(milliseconds: 240),
      );
    });

    testWidgets('halaman baru masuk bertahap lalu diam di tempat', (
      tester,
    ) async {
      final services = await _pumpApp(tester);
      services.router.openLocation('/tidak-ada');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final moving = tester.getTopLeft(find.byType(NotFoundPage)).dx;
      expect(moving, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getTopLeft(find.byType(NotFoundPage)).dx, 0);
    });

    testWidgets('kurangi gerak: halaman baru tidak bergeser', (tester) async {
      final services = await _pumpApp(
        tester,
        setup: (services) => services.settings.setReduceMotion(true),
      );
      services.router.openLocation('/tidak-ada');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.getTopLeft(find.byType(NotFoundPage)).dx, 0);
    });

    testWidgets('layanan tersedia lewat AppScope di dalam tab', (tester) async {
      final services = await _pumpApp(tester);
      final context = tester.element(find.byType(TabPlaceholderPage));
      expect(identical(AppScope.of(context), services), isTrue);
    });

    testWidgets('layar galat penyiapan punya tombol coba lagi', (tester) async {
      await loadShotFonts(tester);
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var retries = 0;
      await tester.pumpWidget(
        BootstrapFailureApp(onRetry: () async => retries++),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Bpedia belum bisa dibuka'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      await _settle(tester);
      expect(retries, 1);
    });
  });
}
