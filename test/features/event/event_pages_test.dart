import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalog/shop_test_support.dart';

final DateTime _claimDay = DateTime.utc(2026, 12, 12, 3);

void main() {
  testWidgets('hub menampilkan semua event dan membuka halaman event', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/event');
    expect(
      find.text(
        '${services.promo.events.length} event berjalan dan akan datang',
      ),
      findsOneWidget,
    );
    expect(find.text('Main bareng Bipy'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('event-black-friday')));
    await settle(tester);
    expect(find.text('Syarat dan ketentuan'), findsOneWidget);
    expect(find.text('Lihat Hot Item'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('event-cta')));
    await settle(tester);
    expect(find.text('5 produk harga spesial'), findsOneWidget);
  });

  testWidgets('voucher 12.12 sebelum hari klaim belum bisa diklaim', (
    tester,
  ) async {
    final rewards = FakeShopRewards();
    final services = shopServices(loggedIn: true, rewards: rewards);
    await pumpShop(tester, services, '/event/tanggal-kembar-1212');
    expect(find.text('Segera'), findsOneWidget);
    expect(find.text('Klaim dibuka Sabtu, 12 Des 2026 (WIB).'), findsOneWidget);
    await tester.tap(find.text('Segera'));
    await tester.pump();
    expect(rewards.claims, isEmpty);
  });

  testWidgets('voucher 12.12: tamu diminta masuk pada hari klaim', (
    tester,
  ) async {
    final services = shopServices(rewards: FakeShopRewards(), now: _claimDay);
    await pumpShop(tester, services, '/event/tanggal-kembar-1212');
    expect(find.text('Masuk dulu untuk klaim voucher, Babes.'), findsOneWidget);
    await tester.tap(find.text('Masuk'));
    await settle(tester);
    expect(find.text('Syarat dan ketentuan'), findsNothing);
  });

  testWidgets('voucher 12.12 diklaim lewat port hadiah', (tester) async {
    final rewards = FakeShopRewards();
    final services = shopServices(
      loggedIn: true,
      rewards: rewards,
      now: _claimDay,
    );
    await pumpShop(tester, services, '/event/tanggal-kembar-1212');
    await tester.tap(find.text('Klaim'));
    await settle(tester);
    expect(rewards.claims, <String>['tanggal-kembar-1212']);
    expect(find.text('Diklaim'), findsOneWidget);
    expect(
      find.text('Voucher Rp12.000 masuk ke Voucher Saya.'),
      findsOneWidget,
    );
  });

  testWidgets('tanpa Zona Hadiah voucher tampil redup dengan alasan', (
    tester,
  ) async {
    final services = shopServices(loggedIn: true, now: _claimDay);
    await pumpShop(tester, services, '/event/tanggal-kembar-1212');
    expect(
      find.text('Klaim voucher aktif saat Zona Hadiah tersambung.'),
      findsOneWidget,
    );
  });

  testWidgets('event tidak dikenal menampilkan keadaan kosong', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/event/tidak-ada');
    expect(find.text('Event tidak ditemukan'), findsOneWidget);
    await tester.tap(find.text('Lihat semua event'));
    await settle(tester);
    expect(find.text('Main bareng Bipy'), findsOneWidget);
  });

  testWidgets('teks 200% pada lebar 360 tanpa luapan', (tester) async {
    final services = shopServices(
      loggedIn: true,
      rewards: FakeShopRewards(),
      now: _claimDay,
    );
    await pumpShop(
      tester,
      services,
      '/event/tanggal-kembar-1212',
      size: narrowPhone,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Kembali'));
    await settle(tester);
    await pumpShop(tester, services, '/event', size: narrowPhone, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
