import 'dart:async';

import 'package:bpedia_app/app/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account/f3_harness.dart';

Finder _field(String key) => find.byKey(ValueKey<String>(key));

void main() {
  testWidgets('kosong: tambah alamat pertama menjadi utama', (tester) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/alamat');
    await tester.pumpAndSettle();

    expect(find.text('Belum ada alamat'), findsOneWidget);
    await tester.tap(find.text('Tambah alamat'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah alamat'), findsWidgets);
    // Nama dan nomor HP penerima terisi dari profil.
    expect(
      tester.widget<TextField>(_field('address-recipient')).controller!.text,
      'Babes Demo',
    );

    await tapVisible(tester, find.text('Simpan alamat'));
    expect(
      find.text('Isi alamat lengkap (jalan dan nomor rumah).'),
      findsOneWidget,
    );
    expect(services.addresses.isEmpty, isTrue);

    await scrollTo(tester, find.text('Kantor'), -300);
    await tester.tap(find.text('Kantor'));
    await tester.pump();
    await tester.enterText(_field('address-street'), 'Jl. Melati No. 12');
    await tester.enterText(_field('address-district'), 'Coblong');
    await tester.enterText(_field('address-city'), 'Bandung');
    await tester.enterText(_field('address-province'), 'Jawa Barat');
    await tester.enterText(_field('address-postal'), '40132');
    await tapVisible(tester, find.text('Simpan alamat'));

    expect(services.addresses.addresses, hasLength(1));
    final saved = services.addresses.primary!;
    expect(saved.label, 'Kantor');
    expect(saved.city, 'Bandung');
    expect(find.text('Alamat saya'), findsOneWidget);
    expect(find.text('Utama'), findsOneWidget);
  });

  testWidgets('jadikan utama dan ubah alamat', (tester) async {
    final services = f3Services(loggedIn: true);
    services.addresses
      ..add(sampleAddress)
      ..add(officeAddress);
    await openF3(tester, services, '/akun/alamat');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadikan utama'));
    await tester.pumpAndSettle();
    expect(services.addresses.primary!.label, 'Kantor');

    await tester.tap(find.text('Ubah').last);
    await tester.pumpAndSettle();
    await tester.enterText(_field('address-postal'), '40135');
    await tapVisible(tester, find.text('Simpan alamat'));
    expect(services.addresses.byId('A1')!.postalCode, '40135');
  });

  testWidgets('hapus alamat dengan konfirmasi', (tester) async {
    final services = f3Services(loggedIn: true);
    final address = services.addresses.add(sampleAddress);
    await openF3(
      tester,
      services,
      AddressFormRoute(addressId: address.id).location,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hapus alamat'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus alamat ini?'), findsOneWidget);
    await tester.tap(find.text('Hapus'));
    await pumpFor(tester);
    expect(services.addresses.isEmpty, isTrue);
  });

  testWidgets('alamat yang tidak ada menampilkan keadaan kosong', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true);
    await openF3(tester, services, '/akun/alamat/A99');
    await tester.pumpAndSettle();
    expect(find.text('Alamat tidak ditemukan'), findsOneWidget);
  });

  testWidgets('mode pilih: ketuk kartu menjadikan alamat kirim lalu kembali', (
    tester,
  ) async {
    final services = f3Services(loggedIn: true);
    services.addresses
      ..add(sampleAddress)
      ..add(officeAddress);
    await openF3(tester, services, '/akun');
    await tester.pumpAndSettle();
    unawaited(
      services.router.go(
        tester.element(find.text('Pesanan saya')),
        const AddressesRoute(selecting: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pilih alamat kirim'), findsOneWidget);

    await tester.tap(find.text('Kantor'));
    await tester.pumpAndSettle();
    expect(services.addresses.primary!.label, 'Kantor');
    expect(find.text('Pilih alamat kirim'), findsNothing);
  });

  testWidgets('tamu diarahkan ke Masuk', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/akun/alamat');
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Bpedia'), findsOneWidget);
  });

  testWidgets('teks 200% lebar 360 tanpa luapan', (tester) async {
    setScreen(tester, size: const Size(360, 640), textScale: 2);
    final services = f3Services(loggedIn: true);
    services.addresses.add(sampleAddress);
    await openF3(tester, services, '/akun/alamat');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Ubah'));
    await tester.dragUntilVisible(
      find.text('Jadikan alamat utama'),
      find.byType(ListView),
      const Offset(0, -250),
    );
    expect(tester.takeException(), isNull);
  });
}
