import 'package:bpedia_app/config/app_config.dart';
import 'package:bpedia_app/features/info/help_page.dart';
import 'package:bpedia_app/features/info/legal_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account/f3_harness.dart';

Future<void> _searchHelp(WidgetTester tester, String query) async {
  tester.state<ScrollableState>(mainScrollable()).position.jumpTo(0);
  await tester.pump();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey<String>('help-search')),
      matching: find.byType(TextField),
    ),
    query,
  );
}

void main() {
  testWidgets('Bantuan: WhatsApp Bpedia Care dan FAQ', (tester) async {
    final opened = <Uri>[];
    final services = f3Services(
      opener: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    await openF3(tester, services, '/bantuan');
    await pumpFor(tester);

    await tester.tap(find.text('Chat Bpedia Care'));
    await pumpFor(tester);
    expect(opened.single.host, 'wa.me');
    expect(opened.single.path, '/${AppConfig.whatsAppNumber}');

    await tester.tap(find.text('Chat CS WhatsApp'));
    await pumpFor(tester);
    expect(opened, hasLength(2));

    await tapVisible(tester, find.text(helpFaq.first.question), settle: false);
    await pumpFor(tester);
    expect(find.text(helpFaq.first.answer), findsOneWidget);
    await scrollTo(tester, find.text(AppConfig.whatsAppDisplay));
    expect(find.text(AppConfig.whatsAppDisplay), findsOneWidget);
  });

  testWidgets('Bantuan: cari menyaring FAQ dan topik memilih FAQ', (
    tester,
  ) async {
    final services = f3Services();
    await openF3(tester, services, '/bantuan');
    await pumpFor(tester);

    expect(find.text('Pusat bantuan'), findsOneWidget);
    expect(find.text('Chat CS WhatsApp'), findsOneWidget);
    await _searchHelp(tester, 'lacak pesanan');
    await pumpFor(tester);
    await scrollTo(tester, find.text('Bagaimana cara melacak pesanan?'));
    expect(find.text('Apa itu Kelopak?'), findsNothing);

    await _searchHelp(tester, 'zzz tidak ada');
    await pumpFor(tester);
    await scrollTo(tester, find.textContaining('Belum ada jawaban'));

    await _searchHelp(tester, '');
    await pumpFor(tester);
    await tapVisible(tester, find.text('Retur & refund'), settle: false);
    await pumpFor(tester);
    expect(find.text('Pertanyaan: Retur & refund'), findsOneWidget);
    expect(
      find.text('Bagaimana cara mengajukan retur atau refund?'),
      findsOneWidget,
    );
    expect(find.text('Apa itu Kelopak?'), findsNothing);
  });

  test('filterFaq mencocokkan semua kata dan topik', () {
    expect(
      filterFaq(helpFaq, query: 'kelopak checkout').map((f) => f.question),
      contains('Bagaimana memakai Kelopak saat checkout?'),
    );
    expect(filterFaq(helpFaq, topic: HelpTopic.payment), hasLength(1));
    for (final topic in HelpTopic.values) {
      expect(filterFaq(helpFaq, topic: topic), isNotEmpty, reason: '$topic');
    }
  });

  testWidgets('Bantuan: kartu pesanan terakhir untuk pengguna masuk', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true);
    final order = await placeUnpaidOrder(services);
    await openF3(tester, services, '/bantuan');
    await pumpFor(tester);
    await scrollTo(tester, find.text('Bantuan pesanan terakhir'));
    expect(find.textContaining(order!.id), findsOneWidget);
  });

  testWidgets('Tentang: slogan, Cerita Bpedia, dan Kenalan dengan Bipy', (
    tester,
  ) async {
    final services = f3Services();
    await openF3(tester, services, '/tentang');
    await pumpFor(tester);
    expect(find.byKey(const ValueKey<String>('about-slogan')), findsOneWidget);
    await scrollTo(tester, find.text('Kenalan dengan Bipy'));
    await scrollTo(tester, find.text('Menyapa'));
    for (final label in <String>['Wink', 'Senyum', 'Ngintip', 'Dalam tas']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Bipy, maskot Bpedia'), findsOneWidget);
    await scrollTo(tester, find.text('Cerita Bpedia'), -200);
  });

  testWidgets('Bantuan: tautan gagal menampilkan nomor', (tester) async {
    final services = f3Services(opener: (uri) async => false);
    await openF3(tester, services, '/bantuan');
    await pumpFor(tester);
    await tester.tap(find.text('Chat Bpedia Care'));
    await pumpFor(tester);
    expect(
      find.text(
        'WhatsApp belum bisa dibuka. Hubungi ${AppConfig.whatsAppDisplay}.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Bantuan: lapor masalah memakai pesan khusus', (tester) async {
    final opened = <Uri>[];
    final services = f3Services(
      opener: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    await openF3(tester, services, '/bantuan');
    await pumpFor(tester);
    await tapVisible(
      tester,
      find.text('Laporkan masalah aplikasi'),
      settle: false,
    );
    expect(opened.single.queryParameters['text'], reportProblemMessage);
  });

  testWidgets('Tentang: unduh app dan media sosial', (tester) async {
    final opened = <Uri>[];
    final services = f3Services(
      opener: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    await openF3(tester, services, '/tentang');
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Google Play'));
    await tapVisible(tester, find.text('App Store'));
    await tapVisible(tester, find.text('Instagram'));
    await tapVisible(tester, find.text('TikTok'));
    expect(opened.map((uri) => uri.toString()), <String>[
      AppConfig.playStoreListing,
      AppConfig.appStoreListing,
      AppConfig.instagram,
      AppConfig.tiktok,
    ]);
  });

  testWidgets('S&K: Isi dokumen menggulir ke bagian terakhir', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/snk');
    await tester.pumpAndSettle();
    expect(find.text('Syarat dan ketentuan Bpedia Demo'), findsOneWidget);
    expect(find.text('Syarat dan ketentuan'), findsOneWidget);
    expect(find.text('Isi dokumen'), findsOneWidget);

    final last = termsSections.length;
    final header = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == '$last. ${termsSections.last.title}',
    );
    expect(header, findsNothing);
    await tester.ensureVisible(find.byKey(ValueKey<String>('toc-$last')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey<String>('toc-$last')));
    await tester.pumpAndSettle();
    expect(header, findsOneWidget);
    final top = tester.getTopLeft(header).dy;
    expect(top, lessThan(800));
    expect(top, greaterThanOrEqualTo(0));
  });

  testWidgets('Privasi menjelaskan kata sandi tidak disimpan', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/privasi');
    await tester.pumpAndSettle();
    expect(find.text('Kebijakan privasi Bpedia Demo'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Kata sandi hanya diperiksa'));
    expect(find.textContaining('Kata sandi hanya diperiksa'), findsOneWidget);
  });

  for (final location in <String>['/bantuan', '/tentang', '/snk', '/privasi']) {
    testWidgets('teks 200% lebar 360 tanpa luapan $location', (tester) async {
      setScreen(tester, size: const Size(360, 640), textScale: 2);
      final services = f3Services();
      await openF3(tester, services, location);
      await pumpFor(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await pumpFor(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
