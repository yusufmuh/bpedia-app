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
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    final profile = services.auth.profile!;
    expect(profile.name, 'Ayu Lestari');
    expect(profile.email, 'ayu@example.com');
    expect(profile.phone, '6281399998888');
    expect(find.text('Profil tersimpan.'), findsOneWidget);
  });

  testWidgets('galat validasi tidak menyimpan', (tester) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/profil');
    await tester.pumpAndSettle();

    await tester.enterText(_field('profile-email'), 'bukan-email');
    await tester.enterText(_field('profile-phone'), '12');
    await tester.tap(find.text('Simpan perubahan'));
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
