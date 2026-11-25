import 'dart:convert';

import 'package:bpedia_app/app/app_routes.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/inbox/inbox_repository.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/data/storage/app_document.dart';
import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

import 'support/fakes.dart';

void main() {
  late DateTime now;
  late FakeRewardsGateway gateway;
  late MemoryKeyValueStore store;

  AppServices build({bool loggedIn = true, bool withAddress = true}) {
    final services = AppServices.forTest(
      clock: WibClock(now: () => now),
      store: store,
      rewardsBuilder: (_) => gateway,
      loggedIn: loggedIn,
    );
    if (withAddress) services.addresses.add(sampleAddress);
    return services;
  }

  OrderDraft draftOf(
    AppServices s, {
    String? paymentId = 'qris',
    String? voucherId,
    bool useKelopak = true,
  }) {
    final shipping = s.shipping
        .options(
          weightGrams: s.cart.selectedWeightGrams,
          goodsSubtotal: s.cart.selectedSubtotal,
        )
        .first;
    return OrderDraft(
      items: s.cart.selectedItems,
      address: s.addresses.primary,
      shipping: shipping,
      payment: PaymentCatalog.byId(paymentId),
      quote: s.rewards.quote(
        CheckoutRequest(
          lines: s.cart.linesForCheckout,
          shippingFee: shipping.fee,
          voucherId: voucherId,
          useKelopak: useKelopak,
        ),
      ),
    );
  }

  Future<Order> placeOne(AppServices s, {String? paymentId = 'qris'}) async {
    s.cart.add(codeB);
    final result = await s.orders.place(draftOf(s, paymentId: paymentId));
    expect(result.ok, isTrue, reason: result.message);
    return result.order!;
  }

  setUp(() {
    now = AppServices.testNow;
    gateway = FakeRewardsGateway();
    store = MemoryKeyValueStore();
  });

  group('membuat pesanan', () {
    test('QRIS: menunggu pembayaran, batas 24 jam, keranjang berkurang', () async {
      final s = build();
      s.cart
        ..add(codeB, qty: 2)
        ..add(codeA)
        ..setSelected(codeA, false);

      final result = await s.orders.place(draftOf(s));

      final order = result.order!;
      expect(order.id, 'BP-261125-0001');
      expect(order.status, OrderStatus.awaitingPayment);
      expect(order.payBy, now.add(const Duration(hours: 24)));
      expect(order.items.single.productCode, codeB);
      expect(order.items.single.qty, 2);
      expect(order.goodsSubtotal, 41000);
      expect(order.shippingFee, 8000);
      expect(order.total, 49000);
      expect(order.paymentMethodName, 'QRIS');
      expect(order.address.recipient, 'Sari Dewi');
      expect(order.courierName, 'Bpedia Express');
      expect(s.cart.lines.single.productCode, codeA);
      expect(gateway.calls, <String>['commit:BP-261125-0001']);
      expect(s.orders.unpaid.single.id, order.id);
      expect(s.analyticsLog.eventNames, isNot(contains(AfEvent.purchase)));

      final message = s.inbox.messages.first;
      expect(message.kind, InboxKind.order);
      expect(message.title, 'Menunggu pembayaran');
      expect(message.body, contains('Rp49.000'));
      expect(message.body, contains('26 Nov 2026, 10.00 WIB'));
      expect(
        parseAppRoute(message.route!),
        OrderDetailRoute(order.id),
      );
    });

    test('COD langsung dikemas dan tercatat sebagai pembelian', () async {
      final s = build();
      final order = await placeOne(s, paymentId: 'cod');

      expect(order.status, OrderStatus.packing);
      expect(order.isCod, isTrue);
      expect(order.payBy, isNull);
      expect(order.paidNote, isNull);
      expect(s.inbox.messages.first.body, contains('bayar di tempat'));
      final purchase = s.analyticsLog.records.firstWhere(
        (record) => record.name == AfEvent.purchase,
      );
      expect(purchase.values[AfParam.revenue], order.total);
      expect(purchase.values[AfParam.orderId], order.id);
    });

    test('total Rp0 langsung dikemas: Lunas dengan Kelopak', () async {
      gateway.balance = 600;
      final s = build();
      s.cart.add(codeMany, qty: 2);

      final result = await s.orders.place(draftOf(s));

      final order = result.order!;
      expect(order.goodsSubtotal, 52000);
      expect(order.shippingFee, 0);
      expect(order.kelopakUsed, 520);
      expect(order.kelopakValue, 52000);
      expect(order.total, 0);
      expect(order.status, OrderStatus.packing);
      expect(order.paidNote, OrderRepository.paidWithKelopakNote);
      expect(order.paidNote, 'Lunas dengan Kelopak');
      expect(order.paymentMethodId, isNull);
      expect(gateway.balance, 80);
      expect(s.inbox.messages.first.body, contains('lunas dengan Kelopak'));
      final redeem = s.analyticsLog.records.firstWhere(
        (record) => record.name == BpEvent.kelopakRedeem,
      );
      expect(redeem.values[AfParam.kelopak], 520);
    });

    test('total Rp0 tidak butuh metode pembayaran', () async {
      gateway.balance = 600;
      final s = build();
      s.cart.add(codeMany, qty: 2);
      final result = await s.orders.place(draftOf(s, paymentId: null));
      expect(result.ok, isTrue);
      expect(result.order!.status, OrderStatus.packing);
    });

    test('pecahan di bawah Rp100 tetap dibayar', () async {
      gateway.balance = 1000;
      final s = build();
      s.cart.add(codeA);

      final order = (await s.orders.place(draftOf(s))).order!;

      expect(order.kelopakUsed, 461);
      expect(order.kelopakValue, 46100);
      expect(order.total, 96 + 8000);
      expect(order.status, OrderStatus.awaitingPayment);
    });

    test('sakelar Kelopak mati: saldo tidak dipakai', () async {
      gateway.balance = 1000;
      final s = build();
      s.cart.add(codeA);
      final order = (await s.orders.place(
        draftOf(s, useKelopak: false),
      )).order!;
      expect(order.kelopakUsed, 0);
      expect(order.total, 46196 + 8000);
      expect(gateway.balance, 1000);
    });

    test('voucher dan hadiah gratis tersimpan di pesanan', () async {
      gateway = FakeRewardsGateway(
        gifts: const <GiftLine>[
          GiftLine(
            id: 'G1',
            productCode: hotCode,
            name: 'Hadiah Roda',
            sourceLabel: 'Roda Sabtu, 22 Nov',
          ),
        ],
        vouchers: const <VoucherOption>[
          VoucherOption(
            id: 'V1',
            title: 'Voucher Misi Rp10.000',
            amount: 10000,
            minSpend: 100000,
            expiresLabel: 'Berlaku sampai 25 Des 2026',
            usable: true,
          ),
        ],
      );
      final s = build();
      s.cart.add(codeMany, qty: 4);

      final order = (await s.orders.place(draftOf(s, voucherId: 'V1'))).order!;

      expect(order.goodsSubtotal, 104000);
      expect(order.voucherId, 'V1');
      expect(order.voucherTitle, 'Voucher Misi Rp10.000');
      expect(order.voucherAmount, 10000);
      expect(order.total, 94000);
      expect(order.savings, 10000);
      expect(order.gifts.single.id, 'G1');
      expect(order.gifts.single.sourceLabel, 'Roda Sabtu, 22 Nov');
      expect(order.gifts.single.image, isNotNull);
      expect(gateway.pendingGifts, isEmpty);
      expect(
        s.analyticsLog.eventNames,
        containsAll(<String>[BpEvent.voucherRedeem, BpEvent.giftAttached]),
      );
    });

    test('nomor pesanan memakai tanggal WIB dan nomor urut', () async {
      now = DateTime.utc(2026, 11, 25, 17, 30);
      final s = build();
      final first = await placeOne(s);
      final second = await placeOne(s);
      expect(first.id, 'BP-261126-0001');
      expect(second.id, 'BP-261126-0002');
      expect(s.orders.orders.first.id, second.id);
    });
  });

  group('pesanan ditolak', () {
    test('tamu harus masuk dulu', () async {
      final s = build(loggedIn: false);
      s.cart.add(codeB);
      final result = await s.orders.place(draftOf(s));
      expect(result.problem, OrderProblem.notLoggedIn);
      expect(result.message, contains('Masuk dulu'));
      expect(s.orders.isEmpty, isTrue);
      expect(gateway.calls, isEmpty);
    });

    test('tanpa barang, alamat, kurir, atau metode bayar', () async {
      final s = build(withAddress: false);
      expect(
        (await s.orders.place(draftOf(s))).problem,
        OrderProblem.emptyCart,
      );
      s.cart.add(codeB);
      expect(
        (await s.orders.place(draftOf(s))).problem,
        OrderProblem.missingAddress,
      );
      s.addresses.add(sampleAddress);
      final draft = draftOf(s);
      expect(
        (await s.orders.place(
          OrderDraft(
            items: draft.items,
            address: draft.address,
            shipping: null,
            payment: draft.payment,
            quote: draft.quote,
          ),
        )).problem,
        OrderProblem.missingShipping,
      );
      expect(
        (await s.orders.place(draftOf(s, paymentId: null))).problem,
        OrderProblem.missingPayment,
      );
      expect(s.orders.isEmpty, isTrue);
      expect(s.cart.count, 1);
    });

    test('kutipan basi tidak bisa dipakai', () async {
      final s = build();
      s.cart.add(codeB);
      final stale = draftOf(s);
      s.cart.setQty(codeB, 3);
      final result = await s.orders.place(
        OrderDraft(
          items: s.cart.selectedItems,
          address: stale.address,
          shipping: stale.shipping,
          payment: stale.payment,
          quote: stale.quote,
        ),
      );
      expect(result.problem, OrderProblem.staleQuote);
      expect(gateway.calls, isEmpty);
    });

    test('gateway menolak: tidak ada pesanan, nomor urut tidak terpakai', () async {
      final s = build();
      s.cart.add(codeB);
      gateway.commitOk = false;
      final rejected = await s.orders.place(draftOf(s));
      expect(rejected.problem, OrderProblem.rewardsRejected);
      expect(rejected.message, 'Kutipan sudah basi.');
      expect(s.orders.isEmpty, isTrue);
      expect(s.cart.count, 1);
      expect(s.inbox.messages, isEmpty);

      gateway.commitOk = true;
      final accepted = await s.orders.place(draftOf(s));
      expect(accepted.order!.id, 'BP-261125-0001');
    });
  });

  group('transisi', () {
    test('bayar, kirim, selesai memanggil gateway dan menulis notifikasi', () async {
      gateway.missionMessage = 'Misi tahap 1 tuntas. Voucher Rp10.000 siap.';
      final s = build();
      final order = await placeOne(s);

      final paid = await s.orders.pay(order.id);
      expect(paid.order!.status, OrderStatus.packing);
      expect(paid.order!.payBy, isNull);
      expect(s.inbox.messages.first.title, 'Pembayaran diterima');
      expect(s.analyticsLog.eventNames, contains(AfEvent.purchase));

      now = now.add(const Duration(hours: 2));
      final shipped = await s.orders.ship(order.id);
      expect(shipped.order!.status, OrderStatus.shipped);
      expect(shipped.order!.timeOf(OrderStatus.shipped), now);
      expect(s.inbox.messages.first.body, contains('Bpedia Express'));

      final done = await s.orders.complete(order.id);
      expect(done.order!.status, OrderStatus.completed);
      expect(done.completion!.missionMessage, gateway.missionMessage);
      expect(done.order!.missionMessage, gateway.missionMessage);
      expect(s.inbox.messages.first.kind, InboxKind.reward);
      expect(parseAppRoute(s.inbox.messages.first.route!), const MissionRoute());
      expect(s.inbox.messages[1].title, 'Pesanan selesai');

      expect(gateway.calls, <String>[
        'commit:${order.id}',
        'ship:${order.id}',
        'complete:${order.id}',
      ]);
      expect(s.orders.countOf(OrderStatus.completed), 1);
      expect(s.orders.byStatus(OrderStatus.packing), isEmpty);
      expect(s.orders.byStatus(null).length, 1);
    });

    test('batal mengembalikan Kelopak, voucher, dan hadiah', () async {
      gateway = FakeRewardsGateway(
        balance: 50,
        gifts: const <GiftLine>[
          GiftLine(
            id: 'G1',
            productCode: hotCode,
            name: 'Hadiah Roda',
            sourceLabel: 'Roda Sabtu, 22 Nov',
          ),
        ],
      );
      final s = build();
      final order = await placeOne(s);
      expect(gateway.balance, 0);
      expect(
        s.orders.cancelSummary(order),
        'Pesanan #${order.id} akan dibatalkan. '
        '50 Kelopak dan 1 hadiah gratis dikembalikan ke akunmu.',
      );

      final result = await s.orders.cancel(order.id);

      expect(result.order!.status, OrderStatus.cancelled);
      expect(gateway.calls.last, 'cancel:${order.id}');
      expect(gateway.balance, 50);
      expect(gateway.pendingGifts.single.id, 'G1');
      expect(s.inbox.messages.first.title, 'Pesanan dibatalkan');
      expect(
        s.inbox.messages.first.body,
        contains('50 Kelopak dan hadiah gratis sudah dikembalikan'),
      );
    });

    test('batal boleh saat dikemas, tidak setelah dikirim', () async {
      final s = build();
      final packing = await placeOne(s, paymentId: 'cod');
      expect((await s.orders.cancel(packing.id)).ok, isTrue);

      final shipped = await placeOne(s, paymentId: 'cod');
      await s.orders.ship(shipped.id);
      expect(
        (await s.orders.cancel(shipped.id)).problem,
        OrderProblem.wrongStatus,
      );
      await s.orders.complete(shipped.id);
      expect(
        (await s.orders.cancel(shipped.id)).problem,
        OrderProblem.wrongStatus,
      );
      expect(
        (await s.orders.cancel(packing.id)).problem,
        OrderProblem.wrongStatus,
      );
    });

    test('transisi di luar urutan ditolak', () async {
      final s = build();
      final order = await placeOne(s);
      expect((await s.orders.ship(order.id)).problem, OrderProblem.wrongStatus);
      expect(
        (await s.orders.complete(order.id)).problem,
        OrderProblem.wrongStatus,
      );
      await s.orders.pay(order.id);
      expect((await s.orders.pay(order.id)).problem, OrderProblem.wrongStatus);
      expect(
        (await s.orders.complete(order.id)).problem,
        OrderProblem.wrongStatus,
      );
      expect((await s.orders.pay('BP-000000-9999')).problem, OrderProblem.notFound);
      expect(gateway.calls, <String>['commit:${order.id}']);
    });

    test('ketukan ganda: aksi kedua ditolak selagi yang pertama berjalan', () async {
      final s = build();
      final order = await placeOne(s);
      final first = s.orders.pay(order.id);
      expect(s.orders.isBusy(order.id), isTrue);
      final second = await s.orders.pay(order.id);
      expect(second.problem, OrderProblem.busy);
      expect((await first).ok, isTrue);
      expect(s.orders.isBusy(order.id), isFalse);
    });

    test('lewat batas bayar: bayar ditolak dan pesanan dibatalkan', () async {
      gateway.balance = 30;
      final s = build();
      final order = await placeOne(s);
      now = now.add(const Duration(hours: 24, minutes: 1));

      final result = await s.orders.pay(order.id);

      expect(result.problem, OrderProblem.expired);
      final cancelled = s.orders.byId(order.id)!;
      expect(cancelled.status, OrderStatus.cancelled);
      expect(cancelled.cancelReason, OrderRepository.expiredReason);
      expect(gateway.balance, 30);
    });

    test('cancelOverdue hanya membatalkan yang lewat batas', () async {
      final s = build();
      final old = await placeOne(s);
      now = now.add(const Duration(hours: 23));
      final fresh = await placeOne(s);
      now = now.add(const Duration(hours: 2));

      expect(await s.orders.cancelOverdue(), <String>[old.id]);
      expect(s.orders.byId(fresh.id)!.status, OrderStatus.awaitingPayment);
    });

    test('beli lagi memasukkan barang pesanan ke keranjang', () async {
      final s = build();
      final order = await placeOne(s);
      expect(s.cart.isEmpty, isTrue);
      expect(s.orders.buyAgain(order.id), 1);
      expect(s.cart.quantityOf(codeB), 1);
      expect(s.orders.buyAgain('tidak-ada'), 0);
    });
  });

  group('persistensi', () {
    test('pesanan bertahan setelah dimuat ulang dan nomor urut berlanjut', () async {
      gateway.balance = 10;
      final first = build();
      final order = await placeOne(first);
      await first.orders.pay(order.id);
      await first.document.flush();

      final second = build(withAddress: false);
      expect(await second.load(), DocumentOrigin.loaded);

      final restored = second.orders.byId(order.id)!;
      expect(jsonEncode(restored.toJson()), jsonEncode(
        first.orders.byId(order.id)!.toJson(),
      ));
      expect(restored.status, OrderStatus.packing);
      expect(restored.kelopakUsed, 10);
      expect((await placeOne(second)).id, 'BP-261125-0002');
    });

    test('pesanan lewat batas dibatalkan saat app dimuat', () async {
      final first = build();
      final order = await placeOne(first);
      await first.document.flush();

      now = now.add(const Duration(days: 2));
      final second = build(withAddress: false);
      await second.load();

      expect(second.orders.byId(order.id)!.status, OrderStatus.cancelled);
      expect(gateway.calls.last, 'cancel:${order.id}');
    });

    test('seksi pesanan rusak diatur ulang tanpa mengganggu seksi lain', () async {
      final first = build();
      await placeOne(first);
      first.cart.add(codeA);
      await first.document.flush();

      final saved =
          jsonDecode(store.values[appDocumentKey]!) as Map<String, Object?>;
      final sections = saved['sections']! as Map<String, Object?>;
      sections['orders'] = <String, Object?>{
        'seq': 1,
        'items': <Object?>[
          <String, Object?>{'id': 'BP-1', 'status': 'ngawur'},
        ],
      };
      await store.write(appDocumentKey, jsonEncode(saved));

      final second = build(withAddress: false);
      await second.load();

      expect(second.orders.isEmpty, isTrue);
      expect(second.document.resetSections, <String>['orders']);
      expect(second.cart.quantityOf(codeA), 1);
      expect(second.addresses.addresses.length, 1);
    });

    test('JSON pesanan yang mustahil ditolak', () {
      Map<String, Object?> valid() => <String, Object?>{
        'id': 'BP-261125-0001',
        'status': 'dikemas',
        'items': <Object?>[
          <String, Object?>{
            'productCode': codeB,
            'name': 'Produk',
            'image': 'img/x.webp',
            'unitPrice': 20500,
            'qty': 1,
          },
        ],
        'gifts': <Object?>[],
        'address': <String, Object?>{
          'label': 'Rumah',
          'recipient': 'Sari',
          'phone': '0812',
          'fullAddress': 'Jl. Melati',
        },
        'courierId': 'bpedia-express',
        'courierName': 'Bpedia Express',
        'goodsSubtotal': 20500,
        'shippingFee': 8000,
        'total': 28500,
        'placedAtMs': 1,
      };
      expect(Order.fromJson(valid()).status, OrderStatus.packing);
      expect(
        () => Order.fromJson(valid()..['total'] = -1),
        throwsFormatException,
      );
      expect(
        () => Order.fromJson(valid()..['items'] = <Object?>[]),
        throwsFormatException,
      );
      expect(
        () => Order.fromJson(valid()..['status'] = 'entah'),
        throwsFormatException,
      );
      expect(() => Order.fromJson('bukan peta'), throwsFormatException);
    });
  });

  test('OrderStatus: parameter URL, label, dan aturan batal', () {
    expect(OrderStatus.fromParam('menunggu'), OrderStatus.awaitingPayment);
    expect(OrderStatus.fromParam('entah'), isNull);
    expect(OrderStatus.fromParam(null), isNull);
    expect(
      <String>[for (final status in OrderStatus.values) status.label],
      <String>[
        'Menunggu pembayaran',
        'Dikemas',
        'Dikirim',
        'Selesai',
        'Dibatalkan',
      ],
    );
    expect(
      OrderStatus.values.where((status) => status.canCancel),
      <OrderStatus>[OrderStatus.awaitingPayment, OrderStatus.packing],
    );
    expect(OrderStatus.completed.isActive, isFalse);
    expect(OrderStatus.shipped.isActive, isTrue);
  });
}
