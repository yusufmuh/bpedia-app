import 'package:bpedia_app/config/demo_campaign.dart';
import 'package:bpedia_app/data/inbox/inbox_repository.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart' as hub;

import 'i1_harness.dart';

List<String> _events(AppServices services) => services.analyticsLog.eventNames;

Future<Order> _placeOrder(
  AppServices services, {
  required Map<String, int> lines,
  String paymentId = 'cod',
  String? voucherId,
}) async {
  lines.forEach((code, qty) => services.cart.add(code, qty: qty));
  final cart = services.cart;
  final shipping = services.shipping
      .options(
        weightGrams: cart.selectedWeightGrams,
        goodsSubtotal: cart.selectedSubtotal,
      )
      .first;
  final quote = services.rewards.quote(
    CheckoutRequest(
      lines: cart.linesForCheckout,
      shippingFee: shipping.fee,
      voucherId: voucherId,
    ),
  );
  final result = await services.orders.place(
    OrderDraft(
      items: cart.selectedItems,
      address: services.addresses.primary,
      shipping: shipping,
      payment: PaymentCatalog.byId(paymentId),
      quote: quote,
    ),
  );
  expect(result.ok, isTrue, reason: result.message);
  return result.order!;
}

void main() {
  testWidgets(
    'menang produk roda -> keranjang -> checkout dengan Kelopak -> batal -> '
    'Kelopak dan hadiah kembali',
    (tester) async {
      final services = i1Services(now: saturday, roll: 0);
      final gateway = await loadKelopak(services);
      expect(await gateway.grantKelopak(300), isTrue);

      final outcome = await gateway.controller.spin();
      expect(outcome, isA<hub.SpinCompleted>());
      final gift = (outcome as hub.SpinCompleted).gift!;
      expect(demoWheelProductCodes, contains(gift.productCode));
      final giftName = services.catalog.byCode(gift.productCode!)!.name;
      expect(gateway.pendingGifts.single.name, giftName);
      expect(_events(services), contains('bp_wheel_spin'));
      expect(services.inbox.messages.first.title, 'Kamu menang produk gratis');

      services.cart.add(sunscreen);
      await pumpI1(tester, services, location: '/keranjang');
      await scrollTo(tester, find.text('Hadiah gratis (1)'));
      expect(find.text(giftName), findsOneWidget);
      expect(find.text('Dikirim bersama pesanan ini'), findsOneWidget);

      await tester.tap(find.text('Checkout (1)'));
      await settle(tester);
      await scrollTo(tester, find.text('Kelopak dipakai · 300 Kelopak'));
      expect(find.text('-Rp30.000'), findsOneWidget);
      await tester.tap(find.text('Buat pesanan'));
      await settle(tester);

      final order = services.orders.orders.single;
      expect(order.kelopakUsed, 300);
      expect(order.kelopakValue, 30000);
      expect(order.gifts.single.productCode, gift.productCode);
      expect(gateway.kelopakBalance, 0);
      expect(gateway.pendingGifts, isEmpty);
      expect(gateway.controller.gifts.single.status, hub.GiftStatus.attached);
      expect(
        _events(services).where((name) => name == 'bp_kelopak_redeem'),
        hasLength(1),
        reason: 'dicatat sekali oleh OrderRepository, tidak dobel dari hub',
      );

      await openLocation(tester, services, '/pesanan/${order.id}');
      await scrollTo(tester, find.text('Batalkan pesanan'));
      await tester.tap(find.text('Batalkan pesanan'));
      await settle(tester);
      expect(find.textContaining('300 Kelopak'), findsWidgets);
      await tester.tap(find.text('Ya, batalkan'));
      await settle(tester);

      expect(services.orders.byId(order.id)!.status, OrderStatus.cancelled);
      expect(gateway.kelopakBalance, 300);
      expect(gateway.pendingGifts.single.id, gift.id);
      expect(
        gateway.controller.ledger.last.kind,
        hub.LedgerKind.checkoutRefund,
      );

      await openLocation(tester, services, '/keranjang');
      await scrollTo(tester, find.text('Hadiah gratis (1)'));
      expect(
        find.text('Tambah minimal 1 produk supaya hadiahmu bisa dikirim'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pesanan produk misi selesai -> voucher terbit -> dipakai di pesanan '
    'berikutnya',
    (tester) async {
      final services = i1Services();
      final gateway = await loadKelopak(services);
      expect(gateway.missionProductCodes, contains(nightCream));
      expect(gateway.missionProductCodes, isNot(contains(sunscreen)));

      final hint = gateway.missionHintFor(<PricedLine>[
        const PricedLine(
          productCode: nightCream,
          unitPrice: 26000,
          quantity: 2,
        ),
        const PricedLine(productCode: sunscreen, unitPrice: 46196, quantity: 1),
      ]);
      expect(hint!.current, 52000, reason: 'hanya produk misi dihitung');
      expect(hint.message, contains('tambah Rp23.000 lagi'));

      final order = await _placeOrder(
        services,
        lines: const <String, int>{nightCream: 3},
      );
      expect(order.status, OrderStatus.packing);
      expect((await services.orders.ship(order.id)).ok, isTrue);

      await pumpI1(tester, services, location: '/pesanan/${order.id}');
      await scrollTo(tester, find.text('Pesanan diterima').last);
      await tester.tap(find.text('Pesanan diterima').last);
      await settle(tester, frames: 14);

      expect(find.text('Tahap 1 Misi Belanja selesai'), findsOneWidget);
      await tester.tap(find.text('Nanti saja'));
      await settle(tester);

      expect(services.orders.byId(order.id)!.status, OrderStatus.completed);
      expect(gateway.voucherCount, 1);
      expect(_events(services), contains('bp_mission_complete'));
      final missionNotes = services.inbox.messages.where(
        (message) =>
            message.kind == InboxKind.reward &&
            message.body.contains('Misi Belanja tahap 1 tuntas'),
      );
      expect(missionNotes, hasLength(1), reason: 'satu kabar, tidak dobel');

      final voucher = gateway.vouchersFor(46196 * 3).single;
      expect(voucher.amount, 10000);
      expect(voucher.usable, isTrue);
      expect(gateway.vouchersFor(50000).single.usable, isFalse);

      services.cart.add(sunscreen, qty: 3);
      await openLocation(tester, services, '/checkout');
      await scrollTo(tester, find.text('Voucher · 1 dipakai'));
      expect(
        find.text('-Rp10.000'),
        findsWidgets,
        reason: 'voucher misi sah terbesar dipakai otomatis',
      );
      await tester.tap(find.text('Buat pesanan'));
      await settle(tester);

      final next = services.orders.orders.first;
      expect(next.id, isNot(order.id));
      expect(next.voucherAmount, 10000);
      expect(gateway.voucherCount, 0);
      expect(
        _events(services).where((name) => name == 'bp_voucher_redeem'),
        hasLength(1),
      );
    },
  );

  testWidgets('tamu melihat zona Hadiah tanpa saldo; setelah masuk saldo '
      'tampil', (tester) async {
    final services = i1Services(loggedIn: false);
    final gateway = await loadKelopak(services);
    expect(gateway.available, isTrue);
    expect(await gateway.grantKelopak(100), isFalse);
    expect(gateway.kelopakBalance, 0);
    expect(gateway.hasBadge(RewardsEntry.hub), isFalse);
    expect(
      (await gateway.claimPromoVoucher(
        promoId: 'tanggal-kembar-1212',
        amount: 12000,
        minSpend: 120000,
        validDays: 7,
      )).ok,
      isFalse,
    );

    await pumpI1(tester, services, location: '/hadiah');
    expect(find.byType(hub.RewardsHubPage), findsOneWidget);

    await openLocation(tester, services, '/hadiah/checkin');
    await scrollTo(tester, find.text('Masuk untuk check-in'));
    await tester.tap(find.text('Masuk untuk check-in'));
    await settle(tester);
    expect(find.text('Masuk ke Bpedia'), findsWidgets);
    expect(gateway.controller.claimedToday, isFalse);

    services.signInAsDemo();
    await gateway.grantKelopak(120);
    expect(gateway.kelopakBalance, 120);
    expect(gateway.hasBadge(RewardsEntry.checkIn), isTrue);

    await openLocation(tester, services, '/');
    expect(find.byType(hub.KelopakWalletStrip), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(hub.KelopakWalletStrip),
        matching: find.textContaining('120'),
      ),
      findsWidgets,
    );
  });

  testWidgets('tamu yang membuka Voucherku diarahkan ke halaman Masuk', (
    tester,
  ) async {
    final services = i1Services(loggedIn: false);
    await loadKelopak(services);
    await pumpI1(tester, services, location: '/hadiah/voucher');
    expect(find.byType(hub.VouchersPage), findsNothing);
    expect(find.text('Masuk ke Bpedia'), findsWidgets);
  });

  testWidgets('Mode Demo: isi saldo dan atur ulang lewat gateway', (
    tester,
  ) async {
    final services = i1Services();
    final gateway = await loadKelopak(services);
    await pumpI1(tester, services, location: '/demo');

    await scrollTo(
      tester,
      find.byKey(const ValueKey<String>('demo-grant-1000')),
    );
    await tester.tap(find.text('+1.000 Kelopak'));
    await settle(tester);
    expect(gateway.kelopakBalance, 1000);

    await gateway.resetRewards();
    expect(gateway.kelopakBalance, 0);
    expect(gateway.demoActions.map((action) => action.id), <String>[
      'refill-wheel-quota',
      'empty-wheel-quota',
      'toggle-wheel-promo',
    ]);
    expect(await gateway.demoActions.first.run(), 'Kuota produk roda: 3.');
  });
}
