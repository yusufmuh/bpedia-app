import 'package:bpedia_app/app/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/account/f3_harness.dart';
import '../support/shot.dart';

/// Satu layar F3 yang ditangkap.
class _Screen {
  const _Screen(
    this.name,
    this.location, {
    this.loggedIn = false,
    this.rewards = false,
    this.seed,
    this.act,
    this.tall,
  });

  final String name;
  final String location;
  final bool loggedIn;
  final bool rewards;
  final Future<void> Function(AppServices services)? seed;
  final Future<void> Function(WidgetTester tester)? act;

  /// Tinggi gambar panjang (hanya ukuran 390).
  final double? tall;
}

Future<void> _seedAccount(AppServices services) async {
  seedInbox(services);
  services.addresses.add(sampleAddress);
  await placeUnpaidOrder(services);
  services.wishlist.toggle(productA);
}

final List<_Screen> _screens = <_Screen>[
  const _Screen('akun_tamu', '/akun'),
  const _Screen(
    'akun',
    '/akun',
    loggedIn: true,
    rewards: true,
    seed: _seedAccount,
    tall: 1960,
  ),
  const _Screen('masuk', '/masuk'),
  _Screen(
    'masuk_galat',
    '/masuk',
    act: (tester) async {
      await tester.enterText(
        find.byKey(const ValueKey<String>('login-identifier')),
        '0812',
      );
      await tester.tap(find.byKey(const ValueKey<String>('login-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    },
  ),
  const _Screen(
    'daftar_lengkap',
    '/daftar?mode=lengkap',
    rewards: true,
    tall: 1500,
  ),
  const _Screen('daftar_cepat', '/daftar'),
  const _Screen('lupa_sandi', '/lupa-sandi', tall: 1000),
  _Screen(
    'lupa_sandi_terkirim',
    '/lupa-sandi',
    tall: 1000,
    act: (tester) async {
      await tester.enterText(
        find.byKey(const ValueKey<String>('forgot-email')),
        'nadia@contoh.id',
      );
      await tester.tap(find.text('Kirim tautan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      // Pose Bipy baru perlu waktu dekode lebih lama dari putaran bawaan.
      await settleImages(tester);
      await tester.pump(const Duration(milliseconds: 900));
    },
  ),
  _Screen(
    'ubah_sandi',
    '/akun/sandi',
    loggedIn: true,
    act: (tester) async {
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    },
  ),
  const _Screen('profil', '/akun/profil', loggedIn: true, tall: 1400),
  _Screen(
    'alamat',
    '/akun/alamat',
    loggedIn: true,
    seed: (services) async {
      services.addresses
        ..add(sampleAddress)
        ..add(officeAddress);
    },
  ),
  _Screen(
    'alamat_hapus',
    '/akun/alamat',
    loggedIn: true,
    seed: (services) async {
      services.addresses
        ..add(sampleAddress)
        ..add(officeAddress);
    },
    act: (tester) async {
      await tester.tap(find.text('Hapus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    },
  ),
  const _Screen('alamat_kosong', '/akun/alamat', loggedIn: true),
  const _Screen('alamat_baru', '/akun/alamat/baru', loggedIn: true, tall: 1500),
  const _Screen('pengaturan', '/akun/pengaturan', tall: 1100),
  _Screen(
    'notifikasi',
    '/notifikasi',
    loggedIn: true,
    seed: (services) async => seedInbox(services),
  ),
  _Screen(
    'notifikasi_filter',
    '/notifikasi',
    loggedIn: true,
    seed: (services) async => seedInbox(services),
    act: (tester) async {
      await tester.tap(find.text('Hadiah'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    },
  ),
  const _Screen('notifikasi_kosong', '/notifikasi', loggedIn: true),
  _Screen(
    'bantuan',
    '/bantuan',
    loggedIn: true,
    seed: (services) async {
      await placeUnpaidOrder(services);
    },
    tall: 1900,
  ),
  const _Screen('tentang', '/tentang', tall: 1900),
  const _Screen('snk', '/snk', tall: 1500),
  const _Screen('privasi', '/privasi'),
  _Screen(
    'demo',
    '/demo',
    loggedIn: true,
    rewards: true,
    seed: (services) async {
      services.searchHistory.record('serum');
      services.cart.add(productA);
    },
    tall: 2300,
  ),
];

void main() {
  for (final dark in <bool>[false, true]) {
    final theme = dark ? 'gelap' : 'terang';
    for (final small in <bool>[false, true]) {
      final size = small ? shotSmallPhone : shotPhone;
      final sizeTag = small ? '360' : '390';
      for (final screen in _screens) {
        testWidgets('f3 ${screen.name} $sizeTag $theme', (tester) async {
          final services = f3Services(
            loggedIn: screen.loggedIn,
            dark: dark,
            rewards: screen.rewards ? FakeRewards() : null,
          );
          await screen.seed?.call(services);
          final tall = screen.tall;
          final shotSize = !small && tall != null
              ? Size(size.width, tall)
              : size;
          await pumpShot(
            tester,
            f3App(services, screen.location),
            size: shotSize,
          );
          await tester.pump(const Duration(milliseconds: 900));
          await settleImages(tester, rounds: 2);
          final act = screen.act;
          if (act != null) {
            await act(tester);
            await settleImages(tester, rounds: 2);
          }
          await saveShot(tester, 'f3_${screen.name}_${sizeTag}_$theme');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
