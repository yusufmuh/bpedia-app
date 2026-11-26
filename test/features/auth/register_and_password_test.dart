import 'package:bpedia_app/data/auth/auth_validators.dart';
import 'package:bpedia_app/design/design.dart';
import 'package:bpedia_app/features/auth/forgot_password_page.dart';
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

    testWidgets('kartu manfaat member tampil bila Zona Hadiah tersedia', (
      tester,
    ) async {
      final services = f3Services(rewards: FakeRewards());
      await openF3(tester, services, '/daftar?mode=lengkap');
      await tester.pumpAndSettle();
      expect(find.text('Untung jadi member Bpedia'), findsOneWidget);
      expect(find.text('Check-in harian'), findsOneWidget);
      expect(find.text('+1 Kelopak/hari'), findsOneWidget);
      expect(find.text('Roda Sabtu'), findsOneWidget);
      expect(find.text('Misi Belanja'), findsOneWidget);
      // Petunjuk kata sandi sama dengan aturan validasi.
      expect(find.text('Minimal $minPasswordLength karakter'), findsOneWidget);
    });

    testWidgets('tanpa Zona Hadiah kartu manfaat disembunyikan', (
      tester,
    ) async {
      final services = f3Services();
      await openF3(tester, services, '/daftar');
      await tester.pumpAndSettle();
      expect(find.text('Untung jadi member Bpedia'), findsNothing);
    });

    testWidgets('daftar dengan Google (demo) langsung masuk', (tester) async {
      final services = f3Services();
      await openF3(tester, services, '/daftar');
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Daftar dengan Google (demo)'));
      await tester.tap(find.text('Setuju'));
      await pumpFor(tester);
      expect(services.auth.profile!.viaGoogle, isTrue);
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
    test('maskEmail menyamarkan bagian sebelum @', () {
      expect(maskEmail('nadia@contoh.id'), 'n***a@contoh.id');
      expect(maskEmail('ab@x.co'), 'a***b@x.co');
      expect(maskEmail('a@x.co'), 'a***@x.co');
      expect(maskEmail('tanpa-at'), 'tanpa-at');
    });

    testWidgets('email salah lalu layar cek email (demo)', (tester) async {
      final services = f3Services();
      await openF3(tester, services, '/lupa-sandi');
      await pumpFor(tester);

      expect(find.text('Isi email akun terdaftar'), findsOneWidget);
      expect(find.text('Buat kata sandi baru'), findsOneWidget);
      expect(find.text('Ingat kata sandimu?'), findsOneWidget);
      await tester.enterText(_field('forgot-email'), 'ayu@');
      await tester.tap(find.text('Kirim tautan'));
      await pumpFor(tester);
      expect(find.text('Format email belum benar.'), findsOneWidget);

      await tester.enterText(_field('forgot-email'), 'Ayu@Example.com');
      await tester.tap(find.text('Kirim tautan'));
      await pumpFor(tester);
      expect(find.text('Cek emailmu, Babes'), findsOneWidget);
      // Email disamarkan; alamat utuh tidak tampil.
      expect(
        find.textContaining('a***u@example.com', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('ayu@example.com', findRichText: true),
        findsNothing,
      );
      expect(find.text('Mode demo'), findsOneWidget);
      expect(find.text('Hubungi CS'), findsOneWidget);

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
