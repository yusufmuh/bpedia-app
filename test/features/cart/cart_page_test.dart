import 'package:bpedia_app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../orders/f2_harness.dart';

void main() {
  testWidgets('keranjang kosong: Bipy, ajakan belanja, rekomendasi', (
    tester,
  ) async {
    final services = f2Services();
    await pumpF2(tester, services, location: '/keranjang');
    expect(find.text('Keranjangmu masih kosong'), findsOneWidget);
    expect(find.text('Mulai belanja'), findsOneWidget);
    expect(find.text('Kamu mungkin suka'), findsOneWidget);
    expect(find.text('Checkout (0)'), findsNothing);
  });

  testWidgets('barang berbayar + hadiah Rp0 + dorongan Kelopak dan misi', (
    tester,
  ) async {
    final rewards = FakeRewards();
    final services = f2Services(rewards: rewards);
    services.cart
      ..add(sunscreen)
      ..add(facialWash);
    await pumpF2(tester, services, location: '/keranjang');

    expect(find.text('Keranjang (2)'), findsOneWidget);
    expect(find.text('Checkout (2)'), findsOneWidget);
    expect(find.textContaining('Kirim ke Rumah'), findsOneWidget);
    expect(find.text('Produk misi'), findsOneWidget);
    expect(find.text('Bpedia Official'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.byTooltip('Wishlist'), findsOneWidget);

    // Kelopak tampil di bilah lekat, tanpa gulir [K16].
    expect(find.text('Hemat Rp12.800 di checkout'), findsOneWidget);
    expect(find.text('128 Kelopak -Rp12.800'), findsOneWidget);
    // 46.196 + 17.800 = 63.996; −12.800 Kelopak.
    expect(find.text('Rp51.196'), findsOneWidget);

    await scrollTo(tester, find.text('Hadiah gratis (1)'));
    expect(find.text('Gratis'), findsWidgets);
    expect(find.text('Roda Sabtu, 21 Nov'), findsOneWidget);
    expect(find.text('Dikirim bersama pesanan ini'), findsOneWidget);
    expect(find.textContaining('Pakai 128 Kelopak'), findsNothing);
  });

  testWidgets(
    'strip Misi Belanja tampil di layar pertama di atas daftar [K4]',
    (tester) async {
      final services = f2Services(rewards: FakeRewards());
      services.cart
        ..add(sunscreen)
        ..add(facialWash)
        ..add(nightCream);
      await pumpF2(tester, services, location: '/keranjang');

      final message = find.text(
        'Tambah Rp31.200 produk misi untuk voucher Rp10.000',
      );
      expect(message, findsOneWidget);
      expect(find.text('Di keranjang Rp43.800 dari Rp75.000'), findsOneWidget);
      final messageTop = tester.getTopLeft(message).dy;
      expect(
        messageTop,
        lessThan(tester.getTopLeft(find.text('Bpedia Official')).dy),
      );
      expect(tester.getBottomLeft(message).dy, lessThan(844 / 2));
      expect(
        messageTop,
        greaterThan(tester.getTopLeft(find.textContaining('Kirim ke')).dy),
      );
    },
  );

  testWidgets('pil Kirim ke menyebut label dan area, bukan penerima', (
    tester,
  ) async {
    final services = f2Services();
    services.cart.add(nightCream);
    await pumpF2(tester, services, location: '/keranjang');
    expect(
      find.textContaining('Rumah · Cilandak, Jakarta Selatan'),
      findsOneWidget,
    );
    expect(find.textContaining('Sinta Maharani'), findsNothing);
  });

  testWidgets('bilah lekat: voucher + Kelopak dari kutipan yang sama dengan '
      'checkout [K16]', (tester) async {
    final services = f2Services(rewards: FakeRewards());
    services.cart
      ..add(sunscreen, qty: 2)
      ..add(nightCream);
    await pumpF2(tester, services, location: '/keranjang');

    // 118.392 ≥ Rp100.000: voucher Rp10.000; sisa 108.392; 128 Kelopak.
    expect(find.text('Hemat Rp22.800 di checkout'), findsOneWidget);
    expect(find.text('Voucher -Rp10.000'), findsOneWidget);
    expect(find.text('128 Kelopak -Rp12.800'), findsOneWidget);
    expect(find.text('Rp95.592'), findsOneWidget);
    expect(find.text('Rp118.392'), findsOneWidget);

    await tester.tap(find.text('Hemat Rp22.800 di checkout'));
    await settle(tester);
    expect(find.text('Rincian harga'), findsOneWidget);
    expect(find.text('Total sebelum ongkir'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);

    await tester.tap(find.text('Checkout (2)'));
    await settle(tester);
    // Ongkir gratis (≥ Rp50.000): total checkout = total keranjang.
    expect(find.text('Rp95.592'), findsWidgets);
    expect(find.text('Hemat Rp22.800 · 128 Kelopak'), findsOneWidget);
  });

  testWidgets('tanpa barang tercentang: hadiah menunggu, Checkout nonaktif', (
    tester,
  ) async {
    final services = f2Services(rewards: FakeRewards());
    services.cart.add(nightCream);
    await pumpF2(tester, services, location: '/keranjang');

    await tester.tap(find.bySemanticsLabel('Pilih semua'));
    await settle(tester);
    expect(services.cart.hasSelection, isFalse);
    expect(
      find.text(
        'Pilih minimal 1 produk berbayar supaya hadiahmu ikut dikirim.',
      ),
      findsOneWidget,
    );
    final button = tester.widget<PillButton>(
      find.widgetWithText(PillButton, 'Checkout (0)'),
    );
    expect(button.onPressed, isNull);
    await scrollTo(
      tester,
      find.text('Tambah minimal 1 produk supaya hadiahmu bisa dikirim'),
    );
    expect(find.text('Belanja sekarang'), findsOneWidget);
  });

  testWidgets('hanya hadiah, keranjang kosong: tetap tampil dengan ajakan', (
    tester,
  ) async {
    final services = f2Services(rewards: FakeRewards());
    await pumpF2(tester, services, location: '/keranjang');
    expect(find.text('Hadiah gratis (1)'), findsOneWidget);
    expect(
      find.text('Tambah minimal 1 produk supaya hadiahmu bisa dikirim'),
      findsOneWidget,
    );
  });

  testWidgets('stepper menambah, tong sampah menghapus, Urungkan kembali', (
    tester,
  ) async {
    final services = f2Services();
    services.cart.add(nightCream);
    await pumpF2(tester, services, location: '/keranjang');

    await tester.tap(find.bySemanticsLabel('Tambah jumlah'));
    await settle(tester);
    expect(services.cart.quantityOf(nightCream), 2);
    await tester.tap(find.bySemanticsLabel('Kurangi jumlah'));
    await settle(tester);
    expect(services.cart.quantityOf(nightCream), 1);

    await tester.tap(find.bySemanticsLabel('Hapus dari keranjang'));
    await settle(tester);
    expect(services.cart.isEmpty, isTrue);
    expect(find.text('Urungkan'), findsOneWidget);
    await tester.tap(find.text('Urungkan'));
    await settle(tester);
    expect(services.cart.quantityOf(nightCream), 1);
  });

  testWidgets('Hot Item dibatasi 1 per pesanan', (tester) async {
    final services = f2Services();
    services.cart.add(hotDayCream);
    await pumpF2(tester, services, location: '/keranjang');
    expect(find.text('Hot Item'), findsOneWidget);
    expect(find.text('Maks. 1 per pesanan'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Tambah jumlah'));
    await settle(tester);
    expect(services.cart.quantityOf(hotDayCream), 1);
  });

  testWidgets('pilih semua lalu hapus yang dicentang, bisa diurungkan', (
    tester,
  ) async {
    final services = f2Services();
    services.cart
      ..add(nightCream)
      ..add(sunscreen);
    await pumpF2(tester, services, location: '/keranjang');
    await tester.tap(find.text('Hapus'));
    await settle(tester);
    expect(services.cart.isEmpty, isTrue);
    await tester.tap(find.text('Urungkan'));
    await settle(tester);
    expect(services.cart.lineCount, 2);
  });

  testWidgets('tamu: strip Masuk, Checkout diarahkan ke halaman masuk', (
    tester,
  ) async {
    final services = f2Services(loggedIn: false, rewards: FakeRewards());
    services.cart.add(nightCream);
    await pumpF2(tester, services, location: '/keranjang');
    expect(
      find.text('Masuk untuk checkout dan pakai Kelopak, Babes.'),
      findsOneWidget,
    );
    expect(find.textContaining('di checkout'), findsNothing);
    await tester.tap(find.text('Checkout (1)'));
    await settle(tester);
    expect(find.text('Halaman masuk /checkout'), findsOneWidget);
  });

  testWidgets('Checkout membuka halaman checkout', (tester) async {
    final services = f2Services();
    services.cart.add(nightCream);
    await pumpF2(tester, services, location: '/keranjang');
    await tester.tap(find.text('Checkout (1)'));
    await settle(tester);
    expect(find.text('Buat pesanan'), findsOneWidget);
  });

  for (final dark in <bool>[false, true]) {
    testWidgets(
      'skala teks 200% lebar 360 tanpa luapan (${dark ? 'gelap' : 'terang'})',
      (tester) async {
        final services = f2Services(rewards: FakeRewards(), dark: dark);
        services.cart
          ..add(sunscreen, qty: 2)
          ..add(hotDayCream)
          ..add(facialWash);
        await pumpF2(
          tester,
          services,
          location: '/keranjang',
          size: const Size(360, 640),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        await scrollTo(tester, find.text('Hadiah gratis (1)'));
        expect(tester.takeException(), isNull);
        await scrollTo(tester, find.text('Kamu mungkin suka'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
