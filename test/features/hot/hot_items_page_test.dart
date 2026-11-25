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

  testWidgets('daftar Hot Item: hitung mundur, kuota, filter tema, cari', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/hot-item');
    expect(find.text('5 produk harga spesial'), findsOneWidget);
    expect(find.text('14:00:00'), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HotQuotaBar), findsWidgets);
    await tester.ensureVisible(find.text('Tuesday Body Treatment'));
    await tester.pump();
    await tester.tap(find.text('Tuesday Body Treatment'));
    await tester.pump();
    expect(find.text('2 produk harga spesial'), findsOneWidget);
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
    expect(find.text('5 produk harga spesial'), findsOneWidget);
  });

  testWidgets('+ Keranjang di kartu Hot Item menambah satu', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/hot-item');
    await tester.tap(find.text('+ Keranjang').first);
    await tester.pump();
    expect(services.cart.count, 1);
  });

  testWidgets('di luar periode tampil tanggal, bukan hitung mundur', (
    tester,
  ) async {
    final services = shopServices(now: DateTime.utc(2026, 12, 3, 3));
    await pumpShop(tester, services, '/hot-item');
    expect(find.text('14:00:00'), findsNothing);
    expect(find.text('25 Nov'), findsWidgets);
    expect(find.text('Berakhir dalam '), findsNothing);
  });

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
