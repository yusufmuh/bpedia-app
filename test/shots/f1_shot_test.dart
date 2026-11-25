import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/catalog/shop_test_support.dart';
import '../support/shot.dart';

const Size _long = Size(390, 2600);

Future<void> _open(
  WidgetTester tester,
  AppServices services,
  String location, {
  Size size = shotPhone,
  double ratio = 2,
}) async {
  await pumpShot(
    tester,
    BpediaApp(services: services, initialLocation: location),
    size: size,
    pixelRatio: ratio,
  );
  await tester.pump(const Duration(milliseconds: 900));
  await settleImages(tester, rounds: 4);
}

void main() {
  for (final dark in <bool>[false, true]) {
    final s = dark ? 'gelap' : 'terang';

    testWidgets('beranda tamu $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/');
      await saveShot(tester, 'f1_beranda_tamu_$s');
    });

    testWidgets('beranda panjang masuk $s', (tester) async {
      final services = shopServices(
        dark: dark,
        loggedIn: true,
        rewards: FakeShopRewards(missionCodes: <String>{plainCode}),
      );
      await tester.runAsync(() => placeUnpaidOrder(services, plainCode));
      await _open(tester, services, '/', size: _long, ratio: 1);
      await saveShot(tester, 'f1_beranda_panjang_$s', pixelRatio: 1);
    });

    testWidgets('beranda 360 $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/', size: shotSmallPhone);
      await saveShot(tester, 'f1_beranda_360_$s');
    });

    testWidgets('app flyer $s', (tester) async {
      final services = shopServices(dark: dark, showFlyer: true);
      await _open(tester, services, '/');
      await tester.pump(const Duration(milliseconds: 700));
      await settleImages(tester, rounds: 4);
      await saveShot(tester, 'f1_flyer_$s');
    });

    testWidgets('katalog $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/katalog');
      await saveShot(tester, 'f1_katalog_$s');
    });

    testWidgets('katalog filter aktif $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(
        tester,
        services,
        '/katalog?kategori=skincare&brand=Animate&urut=termurah&maks=50000',
      );
      await saveShot(tester, 'f1_katalog_filter_$s');
    });

    testWidgets('lembar filter $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/katalog?kategori=makeup');
      await tester.tap(find.byKey(const ValueKey<String>('katalog-filter')));
      await settle(tester);
      await settleImages(tester, rounds: 2);
      await saveShot(tester, 'f1_lembar_filter_$s');
    });

    testWidgets('katalog kosong $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/katalog?q=sepatu');
      await saveShot(tester, 'f1_katalog_kosong_$s');
    });

    testWidgets('cari riwayat $s', (tester) async {
      final services = shopServices(dark: dark);
      services.searchHistory
        ..record('sunscreen')
        ..record('lip cream')
        ..record('serum');
      await _open(tester, services, '/cari');
      await saveShot(tester, 'f1_cari_$s');
    });

    testWidgets('cari saran $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/cari?q=acne');
      await saveShot(tester, 'f1_cari_saran_$s');
    });

    testWidgets('detail produk $s', (tester) async {
      final services = shopServices(
        dark: dark,
        rewards: FakeShopRewards(missionCodes: <String>{plainCode}),
      );
      await _open(tester, services, '/produk/$plainCode');
      await saveShot(tester, 'f1_detail_$s');
    });

    testWidgets('detail produk panjang $s', (tester) async {
      final services = shopServices(
        dark: dark,
        rewards: FakeShopRewards(missionCodes: <String>{plainCode}),
      );
      await _open(
        tester,
        services,
        '/produk/$plainCode',
        size: _long,
        ratio: 1,
      );
      await saveShot(tester, 'f1_detail_panjang_$s', pixelRatio: 1);
    });

    testWidgets('detail hot item $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/produk/$hotCode');
      await saveShot(tester, 'f1_detail_hot_$s');
    });

    testWidgets('lembar jumlah $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/produk/$plainCode');
      await tester.tap(find.byKey(const ValueKey<String>('detail-tambah')));
      await settle(tester);
      await settleImages(tester, rounds: 2);
      await saveShot(tester, 'f1_lembar_jumlah_$s');
    });

    testWidgets('hot item $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/hot-item');
      await saveShot(tester, 'f1_hot_$s');
    });

    testWidgets('event hub $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(tester, services, '/event');
      await saveShot(tester, 'f1_event_hub_$s');
    });

    testWidgets('event 12.12 $s', (tester) async {
      final services = shopServices(
        dark: dark,
        loggedIn: true,
        rewards: FakeShopRewards(),
        now: DateTime.utc(2026, 12, 12, 3),
      );
      await _open(tester, services, '/event/tanggal-kembar-1212');
      await saveShot(tester, 'f1_event_1212_$s');
    });

    testWidgets('event black friday panjang $s', (tester) async {
      final services = shopServices(dark: dark);
      await _open(
        tester,
        services,
        '/event/black-friday',
        size: _long,
        ratio: 1,
      );
      await saveShot(tester, 'f1_event_bf_panjang_$s', pixelRatio: 1);
    });

    testWidgets('wishlist $s', (tester) async {
      final services = shopServices(dark: dark);
      for (final code in <String>[plainCode, hotCode, 'P39A06S01000007']) {
        services.wishlist.toggle(code);
      }
      await _open(tester, services, '/wishlist');
      await saveShot(tester, 'f1_wishlist_$s');
    });

    testWidgets('wishlist kosong $s', (tester) async {
      final services = shopServices(dark: dark, loggedIn: true);
      await _open(tester, services, '/wishlist');
      await saveShot(tester, 'f1_wishlist_kosong_$s');
    });
  }
}
