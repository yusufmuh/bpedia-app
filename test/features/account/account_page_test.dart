import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'f3_harness.dart';

void main() {
  testWidgets('tamu: ajakan masuk/daftar, tanpa dompet, tanpa Keluar', (
    tester,
  ) async {
    final services = f3Services(rewards: FakeRewards());
    await openF3(tester, services, '/akun');
    await tester.pumpAndSettle();

    expect(find.text('Hai, Babes!'), findsOneWidget);
    expect(find.text('Pesanan saya'), findsOneWidget);
    expect(find.text('Kelopak'), findsNothing);
    expect(find.text('Profil'), findsNothing);
    await scrollTo(tester, find.text('Mode Demo'));
    expect(find.widgetWithText(PillButton, 'Keluar'), findsNothing);

    await scrollTo(tester, find.text('Hai, Babes!'), -400);
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar akun Bpedia'), findsOneWidget);
  });

  testWidgets('masuk: profil, dompet, lencana pesanan dan notifikasi', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true, rewards: FakeRewards());
    seedInbox(services);
    await placeUnpaidOrder(services);
    await openF3(tester, services, '/akun');
    await tester.pumpAndSettle();

    expect(find.text('Babes Demo'), findsWidgets);
    expect(find.text('0812-3456-7890'), findsOneWidget);
    expect(find.text('128 Kelopak', findRichText: true), findsWidgets);
    expect(find.text('Rp12.800'), findsOneWidget);
    expect(find.text('1 menunggu'), findsOneWidget);
    // Satu pesanan menunggu pembayaran berlencana pada ikon "Belum bayar".
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Belum bayar'),
          matching: find.byType(BpTappable),
        ),
        matching: find.byType(CountBadge),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Belum bayar'));
    await pumpFor(tester);
    expect(
      services.router.tabRoute.value,
      const OrdersRoute(status: 'menunggu'),
    );
  });

  testWidgets('ketuk sel dompet dan menu membuka rute yang benar', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true, rewards: FakeRewards());
    services.router
      ..register<LedgerRoute>((context, route) => const Text('riwayat-uji'))
      ..register<RewardsRoute>((context, route) => const Text('hadiah-uji'));
    await openF3(tester, services, '/akun');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rp12.800'));
    await tester.pumpAndSettle();
    expect(find.text('riwayat-uji'), findsOneWidget);
    services.router.back(tester.element(find.text('riwayat-uji')));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Pengaturan'));
    expect(find.text('Tampilan'), findsOneWidget);
  });

  testWidgets('keluar dengan konfirmasi', (tester) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun');
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Keluar'));
    expect(find.text('Keluar dari akun?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(services.auth.isLoggedIn, isTrue);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar').last);
    await tester.pumpAndSettle();
    expect(services.auth.isLoggedIn, isFalse);
    await scrollTo(tester, find.text('Hai, Babes!'), -400);
    expect(find.text('Hai, Babes!'), findsOneWidget);
  });

  testWidgets('gateway hadiah tidak tersedia: menu hadiah disembunyikan', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun');
    await tester.pumpAndSettle();
    expect(find.text('Zona Hadiah'), findsNothing);
    expect(find.text('Rp12.800'), findsNothing);
    expect(find.text('Wishlist'), findsOneWidget);
  });

  for (final loggedIn in <bool>[false, true]) {
    testWidgets('teks 200% lebar 360 tanpa luapan (masuk: $loggedIn)', (
      tester,
    ) async {
      setScreen(tester, size: const Size(360, 640), textScale: 2);
      final services = f3Services(loggedIn: loggedIn, rewards: FakeRewards());
      await openF3(tester, services, '/akun');
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Mode Demo'), 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
