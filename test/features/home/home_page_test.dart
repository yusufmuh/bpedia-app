import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/features/home/app_flyer.dart';
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
    'sudah masuk: avatar, strip dompet, strip game, pengingat bayar',
    (tester) async {
      final services = shopServices(loggedIn: true, rewards: FakeShopRewards());
      await tester.runAsync(() => placeUnpaidOrder(services, plainCode));
      await pumpShop(tester, services, '/');
      expect(
        find.byKey(const ValueKey<String>('beranda-avatar')),
        findsOneWidget,
      );
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
      expect(
        find.byKey(const ValueKey<String>('beranda-bipy')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Check-in, bisa diklaim'), findsOneWidget);
    },
  );

  testWidgets('pintasan Hot Item membuka halaman Hot Item', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/');
    await tester.tap(find.byKey(const ValueKey<String>('pintasan-hot')));
    await settle(tester);
    expect(find.text('5 produk harga spesial'), findsOneWidget);
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
    expect(find.text('100% Original'), findsOneWidget);
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
}
