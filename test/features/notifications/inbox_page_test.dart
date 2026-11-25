import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/data/inbox/inbox_repository.dart';
import 'package:bpedia_app/features/notifications/inbox_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account/f3_harness.dart';

void main() {
  testWidgets('daftar, saring per jenis, tandai semua dibaca', (tester) async {
    final services = f3Services(loggedIn: true);
    seedInbox(services);
    await openF3(tester, services, '/notifikasi');
    await tester.pumpAndSettle();

    expect(find.byType(InboxTile), findsNWidgets(3));
    expect(services.inbox.unreadCount, 2);

    await tester.tap(find.text('Hadiah'));
    await tester.pumpAndSettle();
    expect(find.byType(InboxTile), findsOneWidget);
    expect(find.text('+1 Kelopak dari Check-in Harian'), findsOneWidget);

    await tester.ensureVisible(find.text('Promo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Promo'));
    await tester.pumpAndSettle();
    expect(find.text('Black Friday mulai 27 Nov, 12.00 WIB'), findsOneWidget);

    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tandai dibaca'));
    await tester.pumpAndSettle();
    expect(services.inbox.unreadCount, 0);
    expect(find.text('Tandai dibaca'), findsNothing);
  });

  testWidgets('ketuk notifikasi menandai dibaca dan membuka rute', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true);
    services.router.register<LedgerRoute>(
      (context, route) => const Text('riwayat-uji'),
    );
    seedInbox(services);
    await openF3(tester, services, '/notifikasi');
    await tester.pumpAndSettle();

    await tester.tap(find.text('+1 Kelopak dari Check-in Harian'));
    await tester.pumpAndSettle();
    expect(find.text('riwayat-uji'), findsOneWidget);
    final message = services.inbox.messages.firstWhere(
      (message) => message.kind == InboxKind.reward,
    );
    expect(message.read, isTrue);
  });

  testWidgets('geser untuk hapus', (tester) async {
    final services = f3Services(loggedIn: true);
    seedInbox(services);
    await openF3(tester, services, '/notifikasi');
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('Black Friday mulai 27 Nov, 12.00 WIB'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(services.inbox.messages, hasLength(2));
    expect(find.text('Notifikasi dihapus.'), findsOneWidget);
  });

  testWidgets('kosong: ajakan belanja', (tester) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/notifikasi');
    await tester.pumpAndSettle();
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
    expect(find.text('Mulai belanja'), findsOneWidget);
  });

  testWidgets('tamu diarahkan ke Masuk, lalu kembali ke kotak masuk', (
    tester,
  ) async {
    final services = f3Services();
    await openF3(tester, services, '/notifikasi');
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Bpedia'), findsOneWidget);

    await tapVisible(tester, find.text('Masuk dengan Google (demo)'));
    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
  });

  testWidgets('teks 200% lebar 360 tanpa luapan', (tester) async {
    setScreen(tester, size: const Size(360, 640), textScale: 2);
    final services = f3Services(loggedIn: true);
    seedInbox(services);
    await openF3(tester, services, '/notifikasi');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
