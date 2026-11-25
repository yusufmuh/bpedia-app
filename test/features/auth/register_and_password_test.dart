import 'package:bpedia_app/design/design.dart';
import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account/f3_harness.dart';

Finder _field(String key) => find.byKey(ValueKey<String>(key));

void main() {
  group('Daftar', () {
    testWidgets('daftar cepat: validasi lalu akun aktif setelah setuju S&K', (
      tester,
    ) async {
      final services = f3Services();
      await openF3(tester, services, '/daftar');
      await tester.pumpAndSettle();

      await tapVisible(tester, find.widgetWithText(PillButton, 'Daftar'));
      expect(find.text('Isi nama dulu ya, Babes.'), findsOneWidget);
      expect(find.text('Isi nomor HP dulu ya, Babes.'), findsOneWidget);
      expect(find.text('Isi email dulu ya, Babes.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('register-password')),
        findsNothing,
      );

      await tester.enterText(_field('register-name'), 'Ayu Lestari');
      await tester.enterText(_field('register-phone'), '0812 3456 7890');
      await tester.enterText(_field('register-email'), 'ayu@example.com');
      await tapVisible(tester, find.widgetWithText(PillButton, 'Daftar'));

      expect(find.text('Setujui Syarat & Ketentuan'), findsOneWidget);
      await tester.tap(find.text('Setuju'));
      // Di bawahnya Beranda pengganti dengan Bipy yang bergerak terus.
      await pumpFor(tester);

      final profile = services.auth.profile!;
      expect(profile.name, 'Ayu Lestari');
      expect(profile.email, 'ayu@example.com');
      expect(profile.termsAccepted, isTrue);
      expect(
        services.analyticsLog.eventNames,
        contains(AfEvent.completeRegistration),
      );
    });

    testWidgets('daftar lengkap butuh kata sandi sama dan setuju S&K', (
      tester,
    ) async {
      setScreen(tester);
      final services = f3Services();
      await openF3(tester, services, '/daftar');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daftar lengkap'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('register-name'), 'Ayu Lestari');
      await tester.enterText(_field('register-phone'), '081234567890');
      await tester.enterText(_field('register-email'), 'ayu@example.com');
      await tester.enterText(_field('register-password'), 'rahasia1');
      await tester.enterText(_field('register-confirm'), 'rahasia2');
      await tapVisible(tester, find.widgetWithText(PillButton, 'Daftar'));

      expect(find.text('Konfirmasi kata sandi belum sama.'), findsOneWidget);
      expect(
        find.text('Setujui Syarat & Ketentuan untuk mendaftar.'),
        findsOneWidget,
      );
      expect(services.auth.isLoggedIn, isFalse);

      await tester.enterText(_field('register-confirm'), 'rahasia1');
      await tapVisible(tester, find.textContaining('Saya setuju'));
      await tapVisible(
        tester,
        find.widgetWithText(PillButton, 'Daftar'),
        settle: false,
      );

      // Daftar lengkap sudah menyetujui S&K: tidak ada lembar persetujuan.
      expect(find.text('Setujui Syarat & Ketentuan'), findsNothing);
      expect(services.auth.isLoggedIn, isTrue);
      expect(services.auth.profile!.termsAccepted, isTrue);
      // Kata sandi tidak pernah masuk ke dokumen tersimpan.
      expect(services.auth.toJson().toString(), isNot(contains('rahasia1')));
    });

    testWidgets('teks 200% lebar 360 tanpa luapan', (tester) async {
      setScreen(tester, size: const Size(360, 640), textScale: 2);
      final services = f3Services();
      await openF3(tester, services, '/daftar?mode=lengkap');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(PillButton, 'Daftar'));
      expect(tester.takeException(), isNull);
    });
  });

  group('Lupa sandi', () {
    testWidgets('email salah lalu layar cek email (demo)', (tester) async {
      final services = f3Services();
      await openF3(tester, services, '/lupa-sandi');
      await pumpFor(tester);

      await tester.enterText(_field('forgot-email'), 'ayu@');
      await tester.tap(find.text('Kirim tautan'));
      await pumpFor(tester);
      expect(find.text('Format email belum benar.'), findsOneWidget);

      await tester.enterText(_field('forgot-email'), 'Ayu@Example.com');
      await tester.tap(find.text('Kirim tautan'));
      await pumpFor(tester);
      expect(find.text('Cek emailmu, Babes'), findsOneWidget);
      expect(find.textContaining('ayu@example.com'), findsOneWidget);
      expect(find.text('Mode demo'), findsOneWidget);

      await tapVisible(tester, find.text('Kembali ke Masuk'), settle: false);
      expect(find.text('Masuk ke Bpedia'), findsOneWidget);
    });
  });

  group('Ubah sandi OTP', () {
    testWidgets('kode demo tampil, kode salah ditolak, kode benar berhasil', (
      tester,
    ) async {
      final services = f3Services(loggedIn: true);
      await openF3(tester, services, '/akun/sandi');
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(_field('otp-code')).enabled, isFalse);
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pumpAndSettle();
      expect(find.text('Kode OTP (demo)'), findsOneWidget);

      final code = tester
          .widget<Text>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  RegExp(r'^\d{6}$').hasMatch(widget.data ?? ''),
            ),
          )
          .data!;
      expect(code, hasLength(6));

      await tester.enterText(
        _field('otp-code'),
        code == '000000' ? '111111' : '000000',
      );
      await tester.enterText(_field('otp-password'), 'barubaru');
      await tester.enterText(_field('otp-confirm'), 'barubaru');
      await tapVisible(tester, find.text('Simpan kata sandi'));
      expect(find.text('Kode OTP belum benar.'), findsOneWidget);

      await tester.enterText(_field('otp-code'), code);
      await tapVisible(tester, find.text('Simpan kata sandi'), settle: false);
      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
    });

    testWidgets('teks 200% lebar 360 tanpa luapan', (tester) async {
      setScreen(tester, size: const Size(360, 640), textScale: 2);
      final services = f3Services(loggedIn: true);
      await openF3(tester, services, '/akun/sandi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
