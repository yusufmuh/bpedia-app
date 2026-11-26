import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(find.text('Produk pilihan event'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Syarat dan ketentuan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Syarat dan ketentuan'), findsOneWidget);
    expect(find.text('Lihat Hot Item'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('event-cta')));
    await settle(tester);
    expect(find.byKey(const ValueKey<String>('hot-cari')), findsOneWidget);
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

  testWidgets('produk event tampil tepat di bawah judul', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/event/black-friday');
    final products = tester.getTopLeft(find.text('Produk pilihan event'));
    final detail = find.text('Detail event');
    await tester.scrollUntilVisible(
      detail,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(products.dy, lessThan(400));
    expect(find.text('Tentang event'), findsNothing);
  });

  testWidgets('event produk gratis: judul hadiah roda, pita, Cara ikut', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/event/produk-gratis');
    expect(find.text('Hadiah produk Roda Sabtu'), findsOneWidget);
    expect(find.text('Hadiah Roda'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Cara ikut'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cara ikut'), findsOneWidget);
  });

  testWidgets('event komunitas: S&K satu butir tanpa nomor, event lainnya', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/event/komunitas-whatsapp');
    final event = services.promo.eventById('komunitas-whatsapp')!;
    final terms = find.byKey(const ValueKey<String>('event-syarat'));
    await tester.scrollUntilVisible(
      terms,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(event.terms, hasLength(1));
    expect(find.descendant(of: terms, matching: find.text('1')), findsNothing);
    final detail = find.byKey(const ValueKey<String>('event-detail'));
    expect(
      find.descendant(of: detail, matching: find.text('1')),
      findsOneWidget,
    );
    final other = find.byKey(
      const ValueKey<String>('event-lain-main-bareng-bipy'),
    );
    await tester.scrollUntilVisible(
      other,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey<String>('event-lain-komunitas-whatsapp')),
      findsNothing,
    );
    await tester.tap(other);
    await settle(tester);
    expect(find.text('Mulai main'), findsOneWidget);
  });

  testWidgets('bagikan event menyalin tautan', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final services = shopServices();
    await pumpShop(tester, services, '/event/black-friday');
    await tester.tap(find.byKey(const ValueKey<String>('event-bagikan')));
    await settle(tester);
    expect(
      find.text('Tautan event disalin. Tinggal tempel, Babes.'),
      findsOneWidget,
    );
    expect(copied, endsWith('/event/black-friday'));
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
