import 'dart:convert';

import 'package:bpedia_app/features/account/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'f3_harness.dart';

Finder _field(String key) => find.byKey(ValueKey<String>(key));

void main() {
  testWidgets('ubah nama, email, dan nomor HP', (tester) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/profil');
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(_field('profile-phone')).controller!.text,
      '0812-3456-7890',
    );
    await tester.enterText(_field('profile-name'), 'Ayu Lestari');
    await tester.enterText(_field('profile-email'), 'Ayu@Example.com');
    await tester.enterText(_field('profile-phone'), '0813 9999 8888');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final profile = services.auth.profile!;
    expect(profile.name, 'Ayu Lestari');
    expect(profile.email, 'ayu@example.com');
    expect(profile.phone, '6281399998888');
    expect(find.text('Profil tersimpan.'), findsOneWidget);
  });

  testWidgets('judul Ubah profil, foto Bipy bawaan, ganti foto tersimpan', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/profil');
    await tester.pumpAndSettle();

    expect(find.text('Ubah profil'), findsOneWidget);
    expect(
      find.text('Foto profil bawaan memakai Bipy, maskot Bpedia.'),
      findsOneWidget,
    );
    expect(find.text('BD'), findsNothing);

    await tester.tap(find.text('Ganti foto'));
    await tester.pumpAndSettle();
    expect(find.text('Ganti foto profil'), findsOneWidget);
    await tester.tap(find.text('Menyapa'));
    await tester.pumpAndSettle();
    expect(find.text('Foto profil diganti.'), findsOneWidget);

    final id = services.auth.profile!.id;
    final raw = await services.store.read(ProfileExtras.storageKey(id));
    expect(
      (jsonDecode(raw!) as Map<String, Object?>)['avatar'],
      'assets/bipy/bipy_menyapa.webp',
    );
  });

  testWidgets('tanggal lahir dan jenis kelamin tersimpan saat Simpan', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/profil');
    await tester.pumpAndSettle();

    expect(find.text('Pilih tanggal'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('profile-birthdate')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih tanggal lahir'), findsOneWidget);
    await tester.tap(find.text('15'));
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih tanggal'), findsNothing);

    await scrollTo(tester, find.text('Perempuan'));
    await tester.tap(find.text('Perempuan'));
    await tester.pump();
    await tester.enterText(_field('profile-email'), 'ayu@example.com');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Profil tersimpan.'), findsOneWidget);

    final id = services.auth.profile!.id;
    final saved = ProfileExtras.fromJson(
      jsonDecode((await services.store.read(ProfileExtras.storageKey(id)))!),
    );
    expect(saved.gender, ProfileGender.female);
    expect(saved.birthDate?.day, 15);
  });

  test('ProfileExtras JSON bolak-balik dan menolak nilai asing', () {
    final extras = ProfileExtras(
      avatar: 'assets/bipy/bipy_wajah_wink.webp',
      birthDate: DateTime(1998, 8, 17),
      gender: ProfileGender.male,
    );
    final back = ProfileExtras.fromJson(
      jsonDecode(jsonEncode(extras.toJson())),
    );
    expect(back.avatar, extras.avatar);
    expect(back.birthDate, DateTime(1998, 8, 17));
    expect(back.gender, ProfileGender.male);
    expect(birthDateLabel(DateTime(1998, 8, 17)), endsWith('1998'));

    final bad = ProfileExtras.fromJson(<String, Object?>{
      'avatar': 'https://contoh.id/foto.png',
      'birthDate': '1998-02-31',
      'gender': 'lain',
    });
    expect(bad.avatar, isNull);
    expect(bad.birthDate, isNull);
    expect(bad.gender, isNull);
  });

  testWidgets('galat validasi tidak menyimpan', (tester) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/profil');
    await tester.pumpAndSettle();

    await tester.enterText(_field('profile-email'), 'bukan-email');
    await tester.enterText(_field('profile-phone'), '12');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Format email belum benar.'), findsOneWidget);
    expect(
      find.text('Nomor HP belum benar. Contoh: 0812 3456 7890.'),
      findsOneWidget,
    );
    expect(services.auth.profile!.phone, '6281234567890');
  });

  testWidgets('tamu yang membuka profil diarahkan ke Masuk', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/akun/profil');
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Bpedia'), findsOneWidget);
  });

  testWidgets('teks 200% lebar 360 tanpa luapan', (tester) async {
    setScreen(tester, size: const Size(360, 640), textScale: 2);
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/profil');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Bergabung'));
    expect(tester.takeException(), isNull);
  });
}
