import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/design/design.dart';
import 'package:bpedia_app/features/demo/demo_page.dart';
import 'package:bpedia_app/features/demo/demo_rewards_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration/i1_harness.dart' show i1Services, loadKelopak;
import '../account/f3_harness.dart';

Finder _key(String key) => find.byKey(ValueKey<String>(key));

void main() {
  testWidgets('geser hari WIB, ke Sabtu, kembali ke hari ini', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();

    expect(find.text('Rabu, 25 Nov 2026'), findsOneWidget);
    await tester.tap(find.text('+1 hari'));
    await tester.pumpAndSettle();
    expect(services.demoClock.offsetDays, 1);
    expect(find.text('Kamis, 26 Nov 2026'), findsWidgets);

    await tester.tap(find.text('Ke Sabtu berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Sabtu, 28 Nov 2026'), findsWidgets);
    expect(services.demoClock.offsetDays, 3);
    // Geseran tersimpan di dokumen app.
    expect(services.demoClock.toJson(), <String, Object?>{'offsetDays': 3});

    await tester.tap(find.text('-1 hari'));
    await tester.pumpAndSettle();
    expect(services.demoClock.offsetDays, 2);
    expect(find.text('Jumat, 27 Nov 2026'), findsWidgets);

    await tester.tap(find.text('Waktu nyata'));
    await tester.pumpAndSettle();
    expect(services.demoClock.offsetDays, 0);
    // Di tanggal nyata tidak bisa mundur lagi.
    expect(tester.widget<PillButton>(_key('demo-day-back')).onPressed, isNull);
  });

  test('stepBackOneDay melewati batas satu kali geser', () {
    final services = AppServices.forTest();
    addTearDown(services.dispose);
    final clock = services.demoClock;
    clock
      ..advanceDays(30)
      ..advanceDays(30)
      ..advanceDays(5);
    stepBackOneDay(clock);
    expect(clock.offsetDays, 64);
    clock.reset();
    stepBackOneDay(clock);
    expect(clock.offsetDays, 0);
  });

  testWidgets('status Roda Sabtu dan Check-in mengikuti tanggal demo', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true, rewards: FakeRewards());
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: _key('demo-status-wheel'),
        matching: find.text('Roda Sabtu buka Sabtu, 28 Nov 2026'),
      ),
      findsOneWidget,
    );
    expect(find.text('Check-in hari ini belum diklaim'), findsOneWidget);

    await tester.tap(find.text('Ke Sabtu berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Roda Sabtu terbuka hari ini'), findsOneWidget);
  });

  testWidgets('gateway Kelopak asli: alat demo tampil, bukan catatan kosong', (
    tester,
  ) async {
    final services = i1Services(withAddress: false);
    final gateway = await loadKelopak(services);
    expect(services.rewards, isA<DemoRewardsTools>());
    await openF3(tester, services, '/demo');
    await pumpFor(tester);

    expect(find.textContaining('belum tersambung'), findsNothing);
    await scrollTo(tester, _key('demo-grant-100'));
    final before = gateway.kelopakBalance;
    await tester.tap(_key('demo-grant-100'));
    await pumpFor(tester);
    expect(gateway.kelopakBalance, before + 100);
    await scrollTo(tester, _key('demo-action-refill-wheel-quota'));
    expect(_key('demo-action-refill-wheel-quota'), findsOneWidget);
  });

  testWidgets('isi saldo dan aksi gateway lewat DemoRewardsTools', (
    tester,
  ) async {
    final rewards = FakeRewards();
    final services = f3Services(loggedIn: true, rewards: rewards);
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();

    await tapVisible(tester, _key('demo-grant-1000'));
    expect(rewards.balance, 1128);
    expect(find.text('1.000 Kelopak ditambahkan.'), findsOneWidget);

    await tapVisible(tester, _key('demo-action-refill-quota'));
    expect(rewards.actionsRun, <String>['refill-quota']);
    expect(find.text('Kuota produk roda diisi ulang.'), findsOneWidget);
  });

  testWidgets('tamu tidak bisa isi saldo; masuk akun demo', (tester) async {
    final services = f3Services(rewards: FakeRewards());
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();

    await scrollTo(tester, _key('demo-grant-10'));
    expect(find.text('Masuk dulu untuk mengisi saldo.'), findsOneWidget);
    await tapVisible(tester, find.text('Masuk akun demo'));
    expect(services.auth.isLoggedIn, isTrue);
    expect(find.textContaining('Saldo 128 Kelopak'), findsOneWidget);
  });

  testWidgets('tanpa gateway hadiah: keterangan belum tersambung', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.textContaining('Zona Hadiah belum tersambung'));
    expect(find.textContaining('Zona Hadiah belum tersambung'), findsOneWidget);
  });

  testWidgets('status AppsFlyer dan log event analitik', (tester) async {
    final services = f3Services(loggedIn: true);
    services.searchHistory.record('serum');
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('AppsFlyer nonaktif'), 300);
    expect(find.text('af_search'), findsOneWidget);
    expect(find.text('af_login'), findsOneWidget);

    await tapVisible(tester, find.text('Kosongkan'));
    expect(services.analyticsLog.records, isEmpty);
    expect(find.textContaining('Belum ada event'), findsOneWidget);
  });

  testWidgets('deep link tiruan membuka rute', (tester) async {
    final services = f3Services();
    services.router.register<WheelRoute>(
      (context, route) => const Text('roda-uji'),
    );
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(demoDeepLinks.first.$1));
    expect(find.text('roda-uji'), findsOneWidget);
  });

  testWidgets('App Flyer tampil, ditutup, dan "Lihat promo" membuka rute', (
    tester,
  ) async {
    final services = f3Services();
    services.router.register<EventRoute>(
      (context, route) => Text('event-${route.id}'),
    );
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();

    // Gambar flyer masih memuat (kerangka berkilau): jangan tunggu tenang.
    await tapVisible(tester, find.text('Tampilkan App Flyer'), settle: false);
    expect(find.text('Lihat promo'), findsOneWidget);
    await tester.tap(find.byTooltip('Tutup'));
    await pumpFor(tester);
    expect(find.text('Lihat promo'), findsNothing);
    // Pratinjau tidak memakai jatah tampil harian Beranda.
    expect(services.promo.shouldShowFlyerToday(), isTrue);

    await tapVisible(tester, find.text('Tampilkan App Flyer'), settle: false);
    await tester.tap(find.text('Lihat promo'));
    await pumpFor(tester);
    expect(find.text('event-black-friday'), findsOneWidget);
  });

  testWidgets('atur ulang semua data dengan konfirmasi', (tester) async {
    final rewards = FakeRewards();
    final services = f3Services(loggedIn: true, rewards: rewards);
    services.addresses.add(sampleAddress);
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Atur ulang semua data'));
    expect(find.text('Atur ulang semua data?'), findsOneWidget);
    await tester.tap(find.text('Atur ulang'));
    await pumpFor(tester);

    expect(rewards.resets, 1);
    expect(services.auth.isLoggedIn, isFalse);
    expect(services.addresses.isEmpty, isTrue);
    expect(find.text('Mode Demo'), findsNothing);
  });

  testWidgets('galeri desain terbuka dari Mode Demo', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.text('Galeri komponen desain'),
      settle: false,
    );
    expect(services.router.isRegistered<GalleryRoute>(), isTrue);
    expect(find.text('Mode Demo'), findsNothing);
  });

  testWidgets('teks 200% lebar 360 tanpa luapan', (tester) async {
    setScreen(tester, size: const Size(360, 640), textScale: 2);
    final services = f3Services(loggedIn: true, rewards: FakeRewards());
    await openF3(tester, services, '/demo');
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
