import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration/i1_harness.dart';
import '../support/shot.dart';

const Size _long = Size(390, 2200);

/// Membuat pesanan COD dari isi keranjang yang dicentang.
Future<Order> _placeCod(AppServices services) async {
  final cart = services.cart;
  final shipping = services.shipping
      .options(
        weightGrams: cart.selectedWeightGrams,
        goodsSubtotal: cart.selectedSubtotal,
      )
      .first;
  final placed = await services.orders.place(
    OrderDraft(
      items: cart.selectedItems,
      address: services.addresses.primary,
      shipping: shipping,
      payment: PaymentCatalog.byId('cod'),
      quote: services.rewards.quote(
        CheckoutRequest(
          lines: cart.linesForCheckout,
          shippingFee: shipping.fee,
        ),
      ),
    ),
  );
  return placed.order!;
}

/// Akun demo pada Sabtu: menang produk roda, 128 Kelopak, satu voucher misi
/// dari pesanan selesai, dan keranjang berisi produk misi.
Future<AppServices> _richServices({required bool dark}) async {
  final services = i1Services(now: saturday, roll: 0, dark: dark);
  final gateway = await loadKelopak(services);
  services.cart.add(nightCream, qty: 3);
  final placed = await _placeCod(services);
  await services.orders.ship(placed.id);
  await services.orders.complete(placed.id);
  await gateway.controller.spin();
  await gateway.grantKelopak(128);
  services.cart
    ..add(nightCream, qty: 2)
    ..add(sunscreen);
  services.promo.markFlyerShown();
  return services;
}

void main() {
  for (final dark in <bool>[false, true]) {
    final t = dark ? 'gelap' : 'terang';

    testWidgets('beranda dengan strip hadiah $t', (tester) async {
      final services = await _richServices(dark: dark);
      final app = BpediaApp(services: services, initialLocation: '/');
      await shot(tester, app, name: 'i1_beranda_$t');
      await shot(tester, app, name: 'i1_beranda_panjang_$t', size: _long);
    });

    testWidgets('zona hadiah $t', (tester) async {
      final services = await _richServices(dark: dark);
      final app = BpediaApp(services: services, initialLocation: '/hadiah');
      await shot(tester, app, name: 'i1_hadiah_$t');
      await shot(tester, app, name: 'i1_hadiah_panjang_$t', size: _long);
    });

    testWidgets('keranjang dengan hadiah gratis $t', (tester) async {
      final services = await _richServices(dark: dark);
      final app = BpediaApp(services: services, initialLocation: '/keranjang');
      await shot(tester, app, name: 'i1_keranjang_$t');
      await shot(tester, app, name: 'i1_keranjang_panjang_$t', size: _long);
    });

    testWidgets('keranjang saat pesanan misi menunggu diterima $t', (
      tester,
    ) async {
      final services = i1Services(dark: dark);
      await loadKelopak(services);
      services.cart.add(nightCream, qty: 3);
      final waiting = await _placeCod(services);
      services.cart
        ..add(nightCream, qty: 3)
        ..add(sunscreen);
      services.promo.markFlyerShown();
      final app = BpediaApp(services: services, initialLocation: '/keranjang');
      await shot(tester, app, name: 'i1_keranjang_misi_menunggu_$t');
      expect(
        find.textContaining('Tahap 1 menunggu pesanan #${waiting.id}'),
        findsOneWidget,
      );
      expect(find.text('Target misi tercapai'), findsNothing);
    });

    testWidgets('checkout dengan potongan Kelopak $t', (tester) async {
      final services = await _richServices(dark: dark);
      final app = BpediaApp(services: services, initialLocation: '/checkout');
      await shot(tester, app, name: 'i1_checkout_panjang_$t', size: _long);
    });

    testWidgets('beranda tamu $t', (tester) async {
      final services = i1Services(loggedIn: false, dark: dark);
      await loadKelopak(services);
      services.promo.markFlyerShown();
      final app = BpediaApp(services: services, initialLocation: '/');
      await shot(tester, app, name: 'i1_beranda_tamu_$t');
    });
  }
}
