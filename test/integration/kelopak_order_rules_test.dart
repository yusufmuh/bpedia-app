import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/inbox/inbox_repository.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/data/storage/app_document.dart';
import 'package:bpedia_app/integration/bpedia_kelopak_host.dart';
import 'package:bpedia_app/integration/kelopak_rewards_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart' as hub;

import 'i1_harness.dart';

Future<OrderResult> _checkout(
  AppServices services, {
  Map<String, int> lines = const <String, int>{},
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
    CheckoutRequest(lines: cart.linesForCheckout, shippingFee: shipping.fee),
  );
  return services.orders.place(
    OrderDraft(
      items: cart.selectedItems,
      address: services.addresses.primary,
      shipping: shipping,
      payment: PaymentCatalog.byId('cod'),
      quote: quote,
    ),
  );
}

BpediaKelopakHost _hostOf(AppServices services) =>
    gatewayOf(services).controller.host! as BpediaKelopakHost;

void main() {
  group('B1-01 progres misi hanya dari barang yang dicentang', () {
    test(
      'produk misi yang tidak dicentang tidak menjanjikan voucher',
      () async {
        final services = i1Services();
        final gateway = await loadKelopak(services);
        services.cart
          ..add(nightCream, qty: 3)
          ..add(sunscreen)
          ..setSelected(nightCream, false);

        final hint = gateway.missionHintFor(services.cart.pricedLines)!;
        expect(hint.reached, isFalse);
        expect(hint.current, 0);
        expect(hint.message, isNot(contains('sudah cukup')));

        final host = _hostOf(services);
        expect(host.cartLines.map((line) => line.productCode), <String>[
          sunscreen,
        ]);
        expect(gateway.controller.cartMissionProgress!.reached, isFalse);
        expect(
          hub.KelopakGameStatus.mission(gateway.controller).ready,
          isFalse,
        );

        services.cart.setSelected(nightCream, true);
        final ready = gateway.missionHintFor(services.cart.pricedLines)!;
        expect(ready.reached, isTrue);
        expect(ready.current, 78000);
        expect(hub.KelopakGameStatus.mission(gateway.controller).ready, isTrue);
      },
    );

    test('ubah jumlah dari halaman misi mencentang produknya', () async {
      final services = i1Services();
      await loadKelopak(services);
      services.cart
        ..add(nightCream)
        ..setSelected(nightCream, false);
      final host = _hostOf(services);
      expect(host.cartLines, isEmpty);

      expect(await host.setCartQuantity(nightCream, 3), isTrue);
      expect(services.cart.quantityOf(nightCream), 3);
      expect(host.cartLines.single.quantity, 3);
      expect(services.cart.selectedItems.single.product.code, nightCream);
    });
  });

  group('B1-02 pesanan misi lain menunggu selesai', () {
    test('keranjang tidak menjanjikan voucher tahap yang sudah ditunggu '
        'pesanan lain', () async {
      final services = i1Services();
      final gateway = await loadKelopak(services);
      final first = await _checkout(
        services,
        lines: const <String, int>{nightCream: 3},
      );
      expect(first.ok, isTrue);
      expect(gateway.controller.view.ordersAwaitingMission, hasLength(1));

      services.cart.add(nightCream, qty: 3);
      final hint = gateway.missionHintFor(services.cart.pricedLines)!;
      expect(hint.reached, isFalse);
      expect(hint.message, isNot(contains('sudah cukup')));
      expect(
        hint.message,
        contains('Tahap 1 menunggu pesanan #${first.order!.id} diterima'),
      );
      expect(hint.message, contains('Tahap 2: belanja produk misi Rp100.000'));
      expect(
        gateway.missionProductCodes,
        isNot(contains(nightCream)),
        reason: 'lencana Misi mengikuti tahap yang dihitung keranjang',
      );
      expect(hint.current, 0, reason: 'krim malam bukan produk tahap 2');
      expect(hint.target, 100000);

      final stage2 = gateway.controller.missionStages[1].productCodes.first;
      expect(gateway.missionProductCodes, contains(stage2));
      services.cart.add(stage2);
      final price = services.catalog.byCode(stage2)!.price;
      final next = gateway.missionHintFor(services.cart.pricedLines)!;
      expect(next.current, price);
      expect(next.reached, isFalse);
      expect(next.message, contains('Tahap 2: produk misi'));
    });
  });

  group('B1-03 nomor pesanan dan catatan Kelopak', () {
    test('dokumen app hilang: pesanan hub yatim dibatalkan, Kelopak kembali, '
        'checkout berikutnya tetap jalan', () async {
      final store = hub.MemoryKeyValueStore();
      final services = i1Services(store: store);
      final gateway = await loadKelopak(services);
      expect(await gateway.grantKelopak(100), isTrue);
      final first = await _checkout(
        services,
        lines: const <String, int>{sunscreen: 1},
      );
      expect(first.ok, isTrue);
      expect(first.order!.kelopakUsed, 100);
      expect(gateway.kelopakBalance, 0);
      await services.document.flush();

      await store.delete(appDocumentKey);
      final reopened = i1Services(store: store, withAddress: false);
      final again = await loadKelopak(reopened);
      await reopened.load();
      expect(reopened.orders.orders, isEmpty);
      expect(
        again.kelopakBalance,
        100,
        reason: 'Kelopak pesanan yatim kembali',
      );
      expect(again.cancellableOrderIds, isEmpty);
      expect(
        reopened.inbox.messages.any(
          (message) =>
              message.kind == InboxKind.order &&
              message.body.contains('#${first.order!.id}') &&
              message.body.contains('100 Kelopak'),
        ),
        isTrue,
      );

      reopened.addresses.add(sampleAddress);
      final second = await _checkout(
        reopened,
        lines: const <String, int>{sunscreen: 1},
      );
      expect(second.ok, isTrue, reason: second.message);
      expect(second.order!.id, isNot(first.order!.id));
      expect(second.order!.kelopakUsed, 100);
      expect(again.kelopakBalance, 0);
    });

    test('nomor yang sudah terpakai di catatan hub dilewati', () async {
      final store = hub.MemoryKeyValueStore();
      final services = i1Services(store: store);
      final gateway = await loadKelopak(services);
      final first = await _checkout(
        services,
        lines: const <String, int>{sunscreen: 1},
      );
      expect((await services.orders.ship(first.order!.id)).ok, isTrue);
      await services.document.flush();

      await store.delete(appDocumentKey);
      final reopened = i1Services(store: store);
      await loadKelopak(reopened);
      await reopened.load();
      expect(gateway.cancellableOrderIds, isEmpty);

      final second = await _checkout(
        reopened,
        lines: const <String, int>{sunscreen: 1},
      );
      expect(second.ok, isTrue, reason: second.message);
      expect(second.order!.id, 'BP-261125-0002');
    });

    test('kalimat batal mengikuti yang benar-benar dikembalikan hub', () async {
      final services = i1Services();
      final gateway = await loadKelopak(services);
      expect(await gateway.grantKelopak(100), isTrue);
      final placed = await _checkout(
        services,
        lines: const <String, int>{sunscreen: 1},
      );
      expect(placed.order!.kelopakUsed, 100);

      await gateway.resetRewards();
      final cancelled = await services.orders.cancel(placed.order!.id);
      expect(cancelled.ok, isTrue);
      final note = services.inbox.messages.first;
      expect(note.title, 'Pesanan dibatalkan');
      expect(note.body, isNot(contains('sudah dikembalikan')));
      expect(note.body, contains('tidak ada yang dikembalikan'));
    });
  });

  group('B1-04 Mode Demo kembali ke hari ini', () {
    test('catatan Kelopak bertanggal geseran: aksi kembali + atur ulang '
        'muncul dan membuka check-in lagi', () async {
      final services = i1Services();
      final gateway = await loadKelopak(services);
      String? actionId(String id) {
        for (final action in gateway.demoActions) {
          if (action.id == id) return action.id;
        }
        return null;
      }

      expect(actionId(returnToTodayActionId), isNull);
      services.demoClock.advanceDays(7);
      expect(actionId(returnToTodayActionId), isNull);
      expect(
        await gateway.controller.claimCheckIn(),
        isA<hub.CheckInClaimed>(),
      );
      expect(gateway.recordsAfterRealToday, isTrue);
      expect(actionId(returnToTodayActionId), returnToTodayActionId);

      final action = gateway.demoActions.firstWhere(
        (action) => action.id == returnToTodayActionId,
      );
      expect(action.description, contains('terkunci'));
      expect(await action.run(), contains('Kembali ke tanggal nyata'));
      expect(services.demoClock.offsetDays, 0);
      expect(gateway.recordsAfterRealToday, isFalse);
      expect(gateway.controller.canCheckIn, isTrue);
    });
  });
}
