import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/orders/f2_harness.dart';
import '../support/shot.dart';

const Size _long = Size(390, 1900);

Future<void> _fillCart(AppServices services) async {
  services.cart
    ..add(sunscreen)
    ..add(facialWash, qty: 2)
    ..add(hotDayCream);
}

/// Pesanan di semua status untuk daftar Transaksi.
Future<String> _history(AppServices services) async {
  final done = await placeOrder(
    services,
    lines: const <String, int>{facialWash: 3},
    paymentId: 'cod',
  );
  await services.orders.ship(done.id);
  await services.orders.complete(done.id);
  final cancelled = await placeOrder(
    services,
    lines: const <String, int>{hotDayCream: 1},
  );
  await services.orders.cancel(cancelled.id);
  final shipped = await placeOrder(
    services,
    lines: const <String, int>{nightCream: 2},
    paymentId: 'va-bca',
  );
  await services.orders.pay(shipped.id);
  await services.orders.ship(shipped.id);
  final unpaid = await placeOrder(services);
  return unpaid.id;
}

void main() {
  for (final dark in <bool>[false, true]) {
    final t = dark ? 'gelap' : 'terang';

    testWidgets('keranjang $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      await _fillCart(services);
      final app = BpediaApp(services: services, initialLocation: '/keranjang');
      await shot(tester, app, name: 'f2_keranjang_$t');
      await shot(tester, app, name: 'f2_keranjang_panjang_$t', size: _long);
    });

    testWidgets('keranjang 360 $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      await _fillCart(services);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/keranjang'),
        name: 'f2_keranjang_360_$t',
        size: shotSmallPhone,
      );
    });

    testWidgets('keranjang kosong $t', (tester) async {
      final services = f2Services(dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/keranjang'),
        name: 'f2_keranjang_kosong_$t',
      );
    });

    testWidgets('keranjang tamu, hanya hadiah $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/keranjang'),
        name: 'f2_keranjang_hadiah_saja_$t',
      );
    });

    testWidgets('checkout $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      await _fillCart(services);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/checkout'),
        name: 'f2_checkout_panjang_$t',
        size: const Size(390, 2300),
      );
    });

    testWidgets('checkout 360 $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      await _fillCart(services);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/checkout'),
        name: 'f2_checkout_360_$t',
        size: shotSmallPhone,
      );
    });

    testWidgets('checkout lunas Kelopak $t', (tester) async {
      final services = f2Services(
        rewards: FakeRewards(balance: 2000),
        dark: dark,
      );
      services.cart.add(nightCream, qty: 2);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/checkout'),
        name: 'f2_checkout_lunas_$t',
        size: const Size(390, 1700),
      );
    });

    testWidgets('bayar QRIS $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      final order = await placeOrder(services);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/bayar/${order.id}'),
        name: 'f2_bayar_qris_$t',
      );
    });

    testWidgets('bayar VA 360 $t', (tester) async {
      final services = f2Services(dark: dark);
      final order = await placeOrder(services, paymentId: 'va-bca');
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/bayar/${order.id}'),
        name: 'f2_bayar_va_360_$t',
        size: shotSmallPhone,
      );
    });

    testWidgets('sukses $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      final order = await placeOrder(services);
      await services.orders.pay(order.id);
      await shot(
        tester,
        BpediaApp(
          services: services,
          initialLocation: '/pesanan/${order.id}/sukses',
        ),
        name: 'f2_sukses_$t',
        settle: const Duration(milliseconds: 1200),
      );
    });

    testWidgets('transaksi $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      await _history(services);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/pesanan'),
        name: 'f2_transaksi_$t',
        size: _long,
      );
    });

    testWidgets('transaksi 360 $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      await _history(services);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/pesanan'),
        name: 'f2_transaksi_360_$t',
        size: shotSmallPhone,
      );
    });

    testWidgets('transaksi kosong dan tamu $t', (tester) async {
      final services = f2Services(dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/pesanan'),
        name: 'f2_transaksi_kosong_$t',
      );
      final guest = f2Services(loggedIn: false, dark: dark);
      await shot(
        tester,
        BpediaApp(services: guest, initialLocation: '/pesanan'),
        name: 'f2_transaksi_tamu_$t',
      );
    });

    testWidgets('detail pesanan $t', (tester) async {
      final services = f2Services(rewards: FakeRewards(), dark: dark);
      final id = await _history(services);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/pesanan/$id'),
        name: 'f2_detail_panjang_$t',
        size: const Size(390, 2300),
      );
    });
  }
}
