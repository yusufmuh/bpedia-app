import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../orders/f2_harness.dart';

Future<void> _tapBuy(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await settle(tester);
}

void main() {
  testWidgets('rincian KEPUTUSAN §1: Kelopak menyala bawaan, bisa dimatikan', (
    tester,
  ) async {
    final rewards = FakeRewards();
    final services = f2Services(rewards: rewards);
    services.cart
      ..add(sunscreen)
      ..add(nightCream);
    await pumpF2(tester, services, location: '/checkout');

    expect(find.text('Sinta Maharani'), findsOneWidget);
    expect(find.text('Bpedia Express'), findsOneWidget);
    await scrollTo(tester, find.text('Saldo 128 Kelopak · potong Rp12.800'));
    final toggle = tester.widget<BpSwitchTile>(find.byType(BpSwitchTile));
    expect(toggle.value, isTrue);

    await scrollTo(tester, find.text('Kelopak dipakai · 128 Kelopak'));
    expect(find.text('-Rp12.800'), findsOneWidget);
    expect(find.text('Gratis'), findsWidgets);
    // 46.196 + 26.000 = 72.196; −12.800 Kelopak; ongkir gratis.
    expect(find.text('Rp59.396'), findsWidgets);

    await tester.ensureVisible(find.byType(BpSwitchTile));
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('Kelopak dipakai · 128 Kelopak'), findsNothing);
    expect(find.text('Rp72.196'), findsWidgets);
  });

  testWidgets('alur utama: buat pesanan → bayar simulasi → sukses', (
    tester,
  ) async {
    final rewards = FakeRewards();
    final services = f2Services(rewards: rewards);
    services.cart
      ..add(sunscreen)
      ..add(nightCream);
    await pumpF2(tester, services, location: '/checkout');
    await _tapBuy(tester, 'Buat pesanan');

    final order = services.orders.orders.single;
    expect(order.status, OrderStatus.awaitingPayment);
    expect(order.kelopakUsed, 128);
    expect(order.gifts, hasLength(1));
    expect(rewards.balance, 0);
    expect(services.cart.isEmpty, isTrue);
    expect(find.text('Simulasikan pembayaran (DEMO)'), findsOneWidget);
    expect(
      find.text('Kode QR contoh (DEMO), tidak bisa dipindai.'),
      findsOneWidget,
    );

    await _tapBuy(tester, 'Simulasikan pembayaran (DEMO)');
    expect(services.orders.byId(order.id)!.status, OrderStatus.packing);
    expect(find.text('Pembayaran berhasil'), findsOneWidget);
    expect(find.textContaining('1 hadiah gratis ikut dikirim'), findsOneWidget);
    await tester.tap(find.text('Lihat pesanan'));
    await settle(tester);
    expect(find.text('Detail pesanan'), findsOneWidget);
  });

  testWidgets('total Rp0: Lunas dengan Kelopak, tanpa metode bayar', (
    tester,
  ) async {
    final services = f2Services(rewards: FakeRewards(balance: 1000));
    services.cart.add(nightCream, qty: 2);
    await pumpF2(tester, services, location: '/checkout');

    await scrollTo(tester, find.text('Lunas dengan Kelopak'));
    await scrollTo(tester, find.text('Rincian pembayaran'));
    expect(find.text('Metode pembayaran'), findsNothing);
    await _tapBuy(tester, 'Buat pesanan · Lunas dengan Kelopak');

    final order = services.orders.orders.single;
    expect(order.total, 0);
    expect(order.status, OrderStatus.packing);
    expect(order.paidNote, 'Lunas dengan Kelopak');
    expect(find.text('Pesanan berhasil dibuat'), findsOneWidget);
  });

  testWidgets('voucher: yang belum memenuhi syarat redup, yang sah memotong', (
    tester,
  ) async {
    final services = f2Services(rewards: FakeRewards(balance: 0));
    services.cart
      ..add(sunscreen, qty: 2)
      ..add(nightCream);
    await pumpF2(tester, services, location: '/checkout');

    await scrollTo(tester, find.text('1 bisa dipakai'));
    await tester.tap(find.text('1 bisa dipakai'));
    await settle(tester);
    expect(find.text('Tambah Rp1.608 lagi'), findsOneWidget);
    await tester.tap(find.text('Pakai'));
    await settle(tester);
    expect(find.text('-Rp10.000'), findsWidgets);
    await scrollTo(
      tester,
      find.text('Saldo 0 Kelopak. Kumpulkan lewat Check-in Harian.'),
    );
    // 118.392 − 10.000, ongkir gratis.
    expect(find.text('Rp108.392'), findsWidgets);
  });

  testWidgets('metode bayar COD: pesanan langsung dikemas', (tester) async {
    final services = f2Services();
    services.cart.add(sunscreen);
    await pumpF2(tester, services, location: '/checkout');
    await scrollTo(tester, find.text('QRIS'));
    await tester.tap(find.text('QRIS'));
    await settle(tester);
    await tester.ensureVisible(find.text('Bayar di tempat (COD)'));
    await settle(tester);
    await tester.tap(find.text('Bayar di tempat (COD)'));
    await settle(tester);
    expect(find.textContaining('Bayar tunai ke kurir'), findsOneWidget);
    await _tapBuy(tester, 'Buat pesanan');
    expect(services.orders.orders.single.status, OrderStatus.packing);
    expect(find.text('Pesanan berhasil dibuat'), findsOneWidget);
  });

  testWidgets('kurir bisa diganti dan ongkir ikut total', (tester) async {
    final services = f2Services();
    services.cart.add(nightCream);
    await pumpF2(tester, services, location: '/checkout');
    // Rp26.000 < Rp50.000: Bpedia Express Rp8.000.
    expect(find.text('Rp34.000'), findsWidgets);
    await tester.tap(find.text('Wahana Express'));
    await settle(tester);
    expect(find.text('Rp36.000'), findsWidgets);
  });

  testWidgets('tanpa alamat: ajakan tambah alamat, pesanan ditolak', (
    tester,
  ) async {
    final services = f2Services(withAddress: false);
    services.cart.add(nightCream);
    await pumpF2(tester, services, location: '/checkout');
    expect(find.text('Tambah alamat'), findsOneWidget);
    await _tapBuy(tester, 'Buat pesanan');
    expect(find.text('Tambah alamat pengiriman dulu.'), findsOneWidget);
    expect(services.orders.isEmpty, isTrue);
  });

  testWidgets('tidak ada produk dipilih: ajakan kembali ke keranjang', (
    tester,
  ) async {
    final services = f2Services();
    await pumpF2(tester, services, location: '/checkout');
    expect(find.text('Belum ada produk dipilih'), findsOneWidget);
  });

  testWidgets('tamu dialihkan ke halaman masuk', (tester) async {
    final services = f2Services(loggedIn: false);
    services.cart.add(nightCream);
    await pumpF2(tester, services, location: '/checkout');
    expect(find.text('Halaman masuk /checkout'), findsOneWidget);
  });

  testWidgets('skala teks 200% lebar 360 tanpa luapan', (tester) async {
    final services = f2Services(rewards: FakeRewards());
    services.cart
      ..add(sunscreen)
      ..add(facialWash);
    await pumpF2(
      tester,
      services,
      location: '/checkout',
      size: const Size(360, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.text('Rincian pembayaran'));
    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.textContaining('Dengan membuat pesanan'));
    expect(tester.takeException(), isNull);
  });
}
