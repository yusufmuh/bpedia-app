import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'f3_harness.dart';

/// Simpul semantik kolom isian ber-[key]: harus kolom teks dan namanya
/// diawali label tampaknya.
void _expectNamedField(WidgetTester tester, String key, String name) {
  final node = tester.getSemantics(find.byKey(ValueKey<String>(key)));
  final data = node.getSemanticsData();
  expect(data.flagsCollection.isTextField, isTrue, reason: key);
  expect(data.label, startsWith(name), reason: key);
}

void main() {
  testWidgets('formulir alamat: tiap kolom punya nama aksesibel', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/alamat/baru');
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp(r'^Nama penerima')), findsOneWidget);
    _expectNamedField(tester, 'address-recipient', 'Nama penerima');
    _expectNamedField(tester, 'address-phone', 'Nomor HP');
    _expectNamedField(tester, 'address-street', 'Alamat lengkap');
    _expectNamedField(tester, 'address-district', 'Kecamatan');
    _expectNamedField(tester, 'address-city', 'Kota atau kabupaten');
    _expectNamedField(tester, 'address-province', 'Provinsi');
    _expectNamedField(tester, 'address-postal', 'Kode pos');
    _expectNamedField(tester, 'address-note', 'Catatan untuk kurir, opsional');
    // Label tampak tidak lagi digabung menjadi satu grup teks lepas.
    expect(
      find.bySemanticsLabel(RegExp(r'Alamat lengkap\s*\n\s*Kecamatan')),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('masuk: kolom kata sandi bernama dan tombol mata tetap ada', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final services = f3Services();
    await openF3(tester, services, '/masuk');
    await tester.pumpAndSettle();

    _expectNamedField(tester, 'login-identifier', 'Nomor HP atau email');
    _expectNamedField(tester, 'login-password', 'Kata sandi');
    expect(find.byTooltip('Tampilkan kata sandi'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip('Tampilkan kata sandi')),
      matchesSemantics(
        tooltip: 'Tampilkan kata sandi',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    handle.dispose();
  });
}
