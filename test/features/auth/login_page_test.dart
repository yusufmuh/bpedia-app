import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/design/design.dart';
import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account/f3_harness.dart';

Finder _field(String key) => find.byKey(ValueKey<String>(key));

void main() {
  testWidgets('galat validasi tampil per kolom', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/masuk');
    await tester.pumpAndSettle();

    await tester.enterText(_field('login-identifier'), '0812');
    await tester.tap(_field('login-submit'));
    await tester.pumpAndSettle();

    expect(
      find.text('Masukkan nomor HP atau email yang benar.'),
      findsOneWidget,
    );
    expect(find.text('Isi kata sandi dulu ya, Babes.'), findsOneWidget);
    expect(services.auth.isLoggedIn, isFalse);

    await tester.enterText(_field('login-identifier'), '081234567890');
    await tester.pumpAndSettle();
    expect(find.text('Masukkan nomor HP atau email yang benar.'), findsNothing);
  });

  testWidgets('masuk dengan nomor HP lalu kembali ke tujuan', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/akun');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk').first);
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Bpedia'), findsOneWidget);

    await tester.enterText(_field('login-identifier'), '0812 3456 7890');
    await tester.enterText(_field('login-password'), 'rahasia1');
    await tester.tap(_field('login-submit'));
    await tester.pumpAndSettle();

    // Profil baru belum menyetujui S&K: lembar persetujuan muncul.
    expect(find.text('Setujui Syarat & Ketentuan'), findsOneWidget);
    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();

    expect(services.auth.isLoggedIn, isTrue);
    expect(services.auth.profile!.termsAccepted, isTrue);
    expect(services.auth.profile!.phone, '6281234567890');
    expect(find.text('Masuk ke Bpedia'), findsNothing);
    expect(find.text('Pesanan saya'), findsOneWidget);
    expect(services.analyticsLog.eventNames, contains(AfEvent.login));
  });

  testWidgets('menolak S&K membatalkan sesi', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/masuk');
    await tester.pumpAndSettle();

    await tester.enterText(_field('login-identifier'), 'ayu@example.com');
    await tester.enterText(_field('login-password'), 'rahasia1');
    await tester.tap(_field('login-submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nanti saja'));
    await tester.pumpAndSettle();

    expect(services.auth.isLoggedIn, isFalse);
    expect(find.text('Masuk ke Bpedia'), findsOneWidget);
  });

  testWidgets('masuk dengan Google (demo) membuka lanjut', (tester) async {
    final services = f3Services();
    await openF3(
      tester,
      services,
      const LoginRoute(next: AppRoutes.settings).location,
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Masuk dengan Google (demo)'));
    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();

    expect(services.auth.profile!.viaGoogle, isTrue);
    expect(find.text('Tampilan'), findsOneWidget);
  });

  testWidgets('lanjut sebagai tamu menutup layar', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/akun');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk').first);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Lanjut sebagai tamu'));

    expect(find.text('Masuk ke Bpedia'), findsNothing);
    expect(find.text('Hai, Babes!'), findsOneWidget);
    expect(services.auth.isLoggedIn, isFalse);
  });

  testWidgets('tautan daftar dan lupa sandi', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/masuk');
    await tester.pumpAndSettle();

    // Bipy di layar lupa sandi bergerak terus: tunggu transisi saja.
    await tapVisible(tester, find.text('Lupa kata sandi?'), settle: false);
    expect(find.text('Atur ulang kata sandi'), findsOneWidget);
    await tester.tap(find.byType(BpBackButton));
    await pumpFor(tester);

    await tapVisible(tester, find.text('Daftar'));
    expect(find.text('Daftar akun Bpedia'), findsOneWidget);
  });

  testWidgets('kata sandi tersembunyi dan bisa ditampilkan', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/masuk');
    await tester.pumpAndSettle();

    TextField password() => tester.widget<TextField>(_field('login-password'));
    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('teks 200% lebar 360 tanpa luapan', (tester) async {
    setScreen(tester, size: const Size(360, 640), textScale: 2);
    final services = f3Services();
    await openF3(tester, services, '/masuk');
    await tester.pumpAndSettle();
    await tapVisible(tester, _field('login-submit'));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Lanjut sebagai tamu'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
