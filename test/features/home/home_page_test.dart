import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/data/promo/promo_repository.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/features/home/app_flyer.dart';
import 'package:bpedia_app/features/home/home_sections.dart';
import 'package:bpedia_app/features/hot/hot_deal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalog/shop_test_support.dart';

void main() {
  testWidgets('tamu melihat tombol Masuk, sakelar tema, banner, pintasan', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/');
    expect(
      find.byKey(const ValueKey<String>('beranda-strip-tamu')),
      findsOneWidget,
    );
    expect(find.text('Masuk'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('beranda-banner')),
      findsOneWidget,
    );
    expect(find.text('Event Promo'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('beranda-kepercayaan')),
      findsOneWidget,
    );
    expect(find.text('100% Original'), findsOneWidget);
    expect(find.text('Ongkir mulai 8rb'), findsOneWidget);
    expect(find.text('Kategori'), findsNothing);
    expect(find.text('Masuk dan kumpulkan Kelopak'), findsOneWidget);
    for (final label in <String>['Check-in', 'Roda Sabtu', 'Misi Belanja']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byTooltip('Ganti ke tema gelap'), findsOneWidget);
    await tester.tap(find.byTooltip('Ganti ke tema gelap'));
    await settle(tester);
    expect(services.settings.themeMode, ThemeMode.dark);
    expect(find.byTooltip('Ganti ke tema terang'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('beranda-bipy')), findsNothing);
  });

  testWidgets('tombol Masuk tamu membuka rute masuk', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/');
    await tester.tap(find.byKey(const ValueKey<String>('beranda-masuk')));
    await settle(tester);
    expect(services.router.navigatorKey.currentState!.canPop(), isTrue);
    expect(
      find.byKey(const ValueKey<String>('beranda-strip-tamu')),
      findsNothing,
    );
  });

  testWidgets(
    'sudah masuk: lonceng dan keranjang di kepala, dompet, game, bayar',
    (tester) async {
      final services = shopServices(loggedIn: true, rewards: FakeShopRewards());
      await tester.runAsync(() => placeUnpaidOrder(services, plainCode));
      await pumpShop(tester, services, '/');
      expect(
        find.byKey(const ValueKey<String>('beranda-avatar')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('beranda-kepala-masuk')),
        findsNothing,
      );
      expect(find.byTooltip('Notifikasi'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('beranda-strip-tamu')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('fake-dompet')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('fake-game')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('beranda-bayar')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('beranda-bipy')), findsNothing);
      expect(find.bySemanticsLabel('Check-in, bisa diklaim'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('pintasan-roda-gratis')),
        findsNothing,
      );
    },
  );

  testWidgets('pintasan Hot Item membuka halaman Hot Item', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/');
    await tester.tap(find.byKey(const ValueKey<String>('pintasan-hot')));
    await settle(tester);
    expect(find.byKey(const ValueKey<String>('hot-cari')), findsOneWidget);
  });

  testWidgets('pintasan Skincare membuka tab Katalog berfilter', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/');
    await tester.tap(find.byKey(const ValueKey<String>('pintasan-skincare')));
    await settle(tester);
    final route = services.router.tabRoute.value;
    expect(route, isA<CatalogRoute>());
    expect((route as CatalogRoute).category, 'skincare');
  });

  testWidgets('rekomendasi bertambah 12 saat digulir ke bawah', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/');
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 30; i++) {
      await tester.drag(scrollable, const Offset(0, -900));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await settle(tester);
    expect(find.text('Lihat semua di Katalog'), findsOneWidget);
  });

  testWidgets('tab rekomendasi menyaring per kategori', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/');
    final tab = find.byKey(const ValueKey<String>('rekomendasi-tab-makeup'));
    await tester.scrollUntilVisible(
      tab,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tab);
    await settle(tester);
    final makeup = services.catalog.products
        .where((product) => product.categoryId == 'makeup')
        .first;
    final other = services.catalog.products
        .where((product) => product.categoryId != 'makeup')
        .first;
    expect(
      find.byKey(ValueKey<String>('produk-${makeup.code}')),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey<String>('produk-${other.code}')), findsNothing);
    expect(find.bySemanticsLabel('Makeup, terpilih'), findsOneWidget);
  });

  testWidgets('Semua brand membuka Katalog', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/');
    final action = find.text('Semua brand');
    await tester.scrollUntilVisible(
      action,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(action);
    await settle(tester);
    expect(services.router.tabRoute.value, isA<CatalogRoute>());
  });

  testWidgets('lencana Gratis di Roda Sabtu saat putaran gratis tersedia', (
    tester,
  ) async {
    final services = shopServices(
      loggedIn: true,
      rewards: FakeShopRewards(
        badges: const <RewardsEntry>{RewardsEntry.wheel},
      ),
    );
    await pumpShop(tester, services, '/');
    expect(
      find.byKey(const ValueKey<String>('pintasan-roda-gratis')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Roda Sabtu, bisa diklaim'), findsOneWidget);
  });

  testWidgets('App Flyer tampil sekali per hari WIB dan bisa ditutup', (
    tester,
  ) async {
    final services = shopServices(showFlyer: true);
    expect(services.promo.shouldShowFlyerToday(), isTrue);
    await pumpShop(tester, services, '/');
    expect(find.byType(AppFlyerDialog), findsOneWidget);
    expect(services.promo.shouldShowFlyerToday(), isFalse);
    await tester.tap(find.byKey(const ValueKey<String>('flyer-tutup')));
    await settle(tester);
    expect(find.byType(AppFlyerDialog), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('pintasan-hot')));
    await settle(tester);
    await tester.tap(find.byTooltip('Kembali'));
    await settle(tester);
    expect(find.byType(AppFlyerDialog), findsNothing);
  });

  testWidgets('App Flyer membuka rute promo saat gambar diketuk', (
    tester,
  ) async {
    final services = shopServices(showFlyer: true);
    await pumpShop(tester, services, '/');
    await tester.tap(find.byKey(const ValueKey<String>('flyer-lihat')));
    await settle(tester);
    expect(find.text('Black Friday'), findsWidgets);
    expect(find.text('Lihat Hot Item'), findsOneWidget);
  });

  testWidgets('App Flyer punya CTA dan petunjuk tutup', (tester) async {
    final services = shopServices(showFlyer: true);
    await pumpShop(tester, services, '/');
    expect(find.text('Ketuk di luar gambar untuk menutup'), findsOneWidget);
    expect(find.text('Lihat promo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('flyer-cta')));
    await settle(tester);
    expect(find.byType(AppFlyerDialog), findsNothing);
    expect(find.text('Black Friday'), findsWidgets);
  });

  test('label CTA flyer Kelopak mengajak main', () {
    const kelopak = PromoFlyer(
      id: 'kelopak',
      image: 'assets/promo/flyer_kelopak.webp',
      title: 'Main bareng Bipy',
      route: '/hadiah',
    );
    const promo = PromoFlyer(
      id: 'bf',
      image: 'assets/promo/flyer_black_friday.webp',
      title: 'Black Friday',
      route: '/event/black-friday',
    );
    expect(flyerCtaLabel(kelopak), 'Main sekarang');
    expect(flyerCtaLabel(promo), 'Lihat promo');
  });

  testWidgets('teks 200% pada lebar 360 tanpa luapan', (tester) async {
    final services = shopServices(loggedIn: true, rewards: FakeShopRewards());
    await pumpShop(tester, services, '/', size: narrowPhone, textScale: 2);
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('teks 200% tamu pada lebar 360 tanpa luapan', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/', size: narrowPhone, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets('Hot Item Beranda hanya menampilkan kampanye berjalan', (
    tester,
  ) async {
    final services = shopServices(now: DateTime.utc(2026, 11, 26, 3));
    await pumpShop(tester, services, '/');
    final hot = find.byType(HomeHotSection);
    await tester.scrollUntilVisible(
      hot,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    expect(
      find.descendant(of: hot, matching: find.byType(HotItemCard)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: hot, matching: find.textContaining('Animate')),
      findsNothing,
    );
    expect(
      find.descendant(of: hot, matching: find.textContaining('Brighty')),
      findsOneWidget,
    );
  });

  testWidgets('Hot Item Beranda tersembunyi bila tidak ada kampanye berjalan', (
    tester,
  ) async {
    final services = shopServices(now: DateTime.utc(2026, 12, 12, 3));
    await pumpShop(tester, services, '/');
    expect(find.byType(HotItemTitle), findsNothing);
    expect(find.byType(HotItemCard), findsNothing);
  });
}
