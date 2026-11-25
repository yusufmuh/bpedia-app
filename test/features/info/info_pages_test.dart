import 'package:bpedia_app/config/app_config.dart';
import 'package:bpedia_app/features/info/help_page.dart';
import 'package:bpedia_app/features/info/legal_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account/f3_harness.dart';

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

    expect(find.text(AppConfig.whatsAppDisplay), findsOneWidget);
    await tester.tap(find.text('Chat Bpedia Care'));
    await pumpFor(tester);
    expect(opened.single.host, 'wa.me');
    expect(opened.single.path, '/${AppConfig.whatsAppNumber}');

    await tester.tap(find.text(helpFaq.first.question));
    await pumpFor(tester);
    expect(find.text(helpFaq.first.answer), findsOneWidget);
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

  testWidgets('S&K menampilkan semua bagian', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/snk');
    await tester.pumpAndSettle();
    expect(find.text('Syarat & Ketentuan Bpedia Demo'), findsOneWidget);
    await scrollTo(tester, find.text('${termsSections.length}. Bantuan'), 400);
  });

  testWidgets('Privasi menjelaskan kata sandi tidak disimpan', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/privasi');
    await tester.pumpAndSettle();
    expect(find.text('Kebijakan Privasi Bpedia Demo'), findsOneWidget);
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
