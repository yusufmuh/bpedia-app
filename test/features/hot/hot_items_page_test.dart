import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/wib_dates.dart';
import 'package:bpedia_app/features/catalog/shop_common.dart';
import 'package:bpedia_app/features/hot/hot_deal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalog/shop_test_support.dart';

void main() {
  group('fase dan label periode Hot Item', () {
    final services = AppServices.forTest();
    tearDownAll(services.dispose);
    final deal = services.catalog.byCode('P11B11B01000004')!.hot!;

    test('fase mengikuti hari WIB', () {
      expect(hotPhaseOf(deal, wibDayFromDate(2026, 11, 11)), HotPhase.upcoming);
      expect(hotPhaseOf(deal, wibDayFromDate(2026, 11, 25)), HotPhase.running);
      expect(hotPhaseOf(deal, wibDayFromDate(2026, 11, 30)), HotPhase.ended);
      expect(hotPeriodLabel(deal), '12 Nov sampai 29 Nov');
    });

    test('hitung mundur ke 24.00 WIB hari terakhir', () {
      final end = wibEndOfDay(wibDayFromDate(2026, 11, 25));
      expect(end, DateTime.utc(2026, 11, 25, 17));
      expect(
        countdownText(const Duration(hours: 13, minutes: 5, seconds: 9)),
        '13:05:09',
      );
      expect(countdownText(const Duration(seconds: -3)), '00:00:00');
    });

    test('yang paling cepat berakhir dipilih', () {
      final soonest = soonestRunning(
        services.catalog.hotItems,
        wibDayFromDate(2026, 11, 25),
      );
      expect(soonest!.endDay, wibDayFromDate(2026, 11, 25));
      expect(
        soonestRunning(services.catalog.hotItems, wibDayFromDate(2026, 12, 1)),
        isNull,
      );
    });
  });

  test('hitung mundur >= 24 jam memakai hari', () {
    expect(
      hotCountdownText(
        const Duration(days: 1, hours: 14, minutes: 18, seconds: 59),
      ),
      '1 hari 14:18:59',
    );
    expect(hotCountdownText(const Duration(hours: 3, minutes: 2)), '03:02:00');
  });

  testWidgets('daftar Hot Item: hitung mundur, kuota, filter tema, cari', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/hot-item');
    expect(find.text('Berakhir dalam'), findsOneWidget);
    expect(find.text('14:00:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HotQuotaBar), findsWidgets);
    expect(find.text('Wednesday Bye-Bye Acne'), findsOneWidget);
    expect(find.text('s.d. Rabu, 25 Nov'), findsOneWidget);
    final chip = find.byKey(
      const ValueKey<String>('hot-tema-Tuesday Body Treatment'),
    );
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await tester.pump();
    expect(find.byType(HotItemCard), findsNWidgets(2));
    expect(find.text('Wednesday Bye-Bye Acne'), findsNothing);
    await tester.ensureVisible(find.textContaining('Semua ('));
    await tester.pump();
    await tester.tap(find.textContaining('Semua ('));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('hot-cari')).first,
      'lipstik merah',
    );
    await tester.pump();
    expect(find.text('Hot Item tidak ditemukan'), findsOneWidget);
    await tester.tap(find.text('Tampilkan semua Hot Item'));
    await tester.pump();
    expect(find.text('Hot Item tidak ditemukan'), findsNothing);
    expect(find.text('Wednesday Bye-Bye Acne'), findsOneWidget);
  });

  testWidgets('Beli di kartu Hot Item membuka checkout dengan satu produk', (
    tester,
  ) async {
    final services = shopServices(loggedIn: true);
    await pumpShop(tester, services, '/hot-item');
    await tester.tap(find.text('Beli').first);
    await settle(tester);
    expect(services.cart.count, 1);
    expect(services.router.navigatorKey.currentState!.canPop(), isTrue);
  });

  testWidgets('kampanye lewat diringkas berlabel Berakhir tanpa tombol', (
    tester,
  ) async {
    final services = shopServices(now: DateTime.utc(2026, 11, 26, 3));
    await pumpShop(tester, services, '/hot-item');
    final ended = find.byKey(
      const ValueKey<String>('hot-berakhir-Wednesday Bye-Bye Acne'),
    );
    await tester.scrollUntilVisible(
      ended,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.descendant(of: ended, matching: find.text('Berakhir')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: ended, matching: find.text('Beli')),
      findsNothing,
    );
    expect(find.text('Beli'), findsWidgets);
  });

  testWidgets(
    'di luar periode tampil ringkasan berakhir, bukan hitung mundur',
    (tester) async {
      final services = shopServices(now: DateTime.utc(2026, 12, 3, 3));
      await pumpShop(tester, services, '/hot-item');
      expect(find.text('14:00:00'), findsNothing);
      expect(find.text('Berakhir dalam'), findsNothing);
      expect(find.text('Beli'), findsNothing);
    },
  );

  testWidgets('teks 200% pada lebar 360 tanpa luapan', (tester) async {
    final services = shopServices();
    await pumpShop(
      tester,
      services,
      '/hot-item',
      size: narrowPhone,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
