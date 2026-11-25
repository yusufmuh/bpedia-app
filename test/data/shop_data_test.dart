import 'dart:io';

import 'package:bpedia_app/app/app_routes.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/promo/promo_repository.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/data/shipping/shipping_repository.dart';
import 'package:bpedia_app/data/wib_dates.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart';

import 'support/fakes.dart';

void main() {
  group('PromoRepository', () {
    late DateTime now;
    late PromoRepository promo;

    setUp(() {
      now = DateTime.utc(2026, 11, 25, 3);
      promo = PromoRepository(clock: WibClock(now: () => now))
        ..loadFromJson(File(promoAsset).readAsStringSync());
    });

    test('banner, flyer, dan event dimuat; gambar dan rute sah', () {
      expect(promo.loadError, isNull);
      expect(promo.banners.length, 5);
      expect(promo.events.length, 5);
      final catalog = loadCatalog();
      for (final banner in promo.banners) {
        expect(File(banner.image).existsSync(), isTrue, reason: banner.image);
        expect(
          parseAppRoute(banner.route),
          isNot(isA<NotFoundRoute>()),
          reason: banner.route,
        );
      }
      for (final flyer in promo.flyers) {
        expect(File(flyer.image).existsSync(), isTrue, reason: flyer.image);
        expect(parseAppRoute(flyer.route), isNot(isA<NotFoundRoute>()));
      }
      for (final event in promo.events) {
        expect(File(event.banner).existsSync(), isTrue, reason: event.banner);
        expect(event.title, isNotEmpty);
        expect(promo.eventById(event.id), same(event));
        expect(
          parseAppRoute(AppRoutes.event(event.id)),
          EventRoute(event.id),
        );
        for (final code in event.productCodes) {
          expect(catalog.byCode(code), isNotNull, reason: '${event.id} $code');
        }
        final route = event.cta?.route;
        if (route != null) {
          expect(parseAppRoute(route), isNot(isA<NotFoundRoute>()));
        }
      }
      expect(promo.eventById('tidak-ada'), isNull);
    });

    test('flyer aktif mengikuti jendela tanggal WIB', () {
      expect(promo.activeFlyer!.id, 'black-friday');
      now = DateTime.utc(2026, 11, 30, 16, 59);
      expect(promo.activeFlyer!.id, 'black-friday');
      now = DateTime.utc(2026, 11, 30, 17);
      expect(promo.activeFlyer!.id, 'kelopak');
      now = DateTime.utc(2026, 11, 19, 16, 59);
      expect(promo.activeFlyer!.id, 'kelopak');
      now = DateTime.utc(2026, 11, 19, 17);
      expect(promo.activeFlyer!.id, 'black-friday');
    });

    test('App Flyer tampil sekali per hari WIB', () {
      var notified = 0;
      promo.addListener(() => notified++);
      expect(promo.shouldShowFlyerToday(), isTrue);
      promo.markFlyerShown();
      promo.markFlyerShown();
      expect(notified, 1);
      expect(promo.shouldShowFlyerToday(), isFalse);

      final copy = PromoRepository(clock: WibClock(now: () => now))
        ..loadFromJson(File(promoAsset).readAsStringSync())
        ..restore(promo.toJson());
      expect(copy.shouldShowFlyerToday(), isFalse);

      now = now.add(const Duration(days: 1));
      expect(promo.shouldShowFlyerToday(), isTrue);
      expect(copy.shouldShowFlyerToday(), isTrue);
    });

    test('voucher 12.12 hanya bisa diklaim pada 12 Des WIB', () {
      final event = promo.eventById('tanggal-kembar-1212')!;
      final voucher = event.voucher!;
      expect(voucher.amount, 12000);
      expect(voucher.minSpend, 120000);
      expect(voucher.validDays, 7);
      expect(voucher.claimDay, parseWibDay('2026-12-12'));
      expect(promo.isVoucherClaimDay(event), isFalse);
      now = DateTime.utc(2026, 12, 11, 17);
      expect(promo.isVoucherClaimDay(event), isTrue);
      now = DateTime.utc(2026, 12, 12, 17);
      expect(promo.isVoucherClaimDay(event), isFalse);
      expect(promo.isVoucherClaimDay(promo.eventById('black-friday')!), isFalse);
    });

    test('promo rusak: daftar kosong, tidak crash', () {
      final broken = PromoRepository(clock: WibClock(now: () => now))
        ..loadFromJson('[1, 2');
      expect(broken.loadError, isNotNull);
      expect(broken.banners, isEmpty);
      expect(broken.activeFlyer, isNull);
      expect(broken.shouldShowFlyerToday(), isFalse);
      broken.loadFromJson('{"banners": [], "flyers": [], "events": [{}]}');
      expect(broken.loadError, isNotNull);
      expect(
        () => broken.restore(<String, Object?>{'flyerShownDay': 'kemarin'}),
        throwsFormatException,
      );
    });
  });

  group('ShippingRepository', () {
    const shipping = ShippingRepository();

    test('dua kurir Bpedia dengan ongkir demo dari berat', () {
      final options = shipping.options(weightGrams: 150, goodsSubtotal: 20000);
      expect(
        <String>[for (final option in options) option.name],
        <String>['Bpedia Express', 'Wahana Express'],
      );
      expect(options[0].fee, 8000);
      expect(options[1].fee, 10000);
      expect(options[0].isFree, isFalse);
      expect(ShippingRepository.demoTag, '(demo)');

      final heavy = shipping.options(weightGrams: 2300, goodsSubtotal: 20000);
      expect(heavy[0].fee, 8000 + 2 * 2000);
      expect(heavy[1].fee, 10000 + 2 * 3000);
    });

    test('berat dibulatkan ke atas per kilogram', () {
      expect(ShippingRepository.billableKg(0), 1);
      expect(ShippingRepository.billableKg(1000), 1);
      expect(ShippingRepository.billableKg(1001), 2);
      expect(ShippingRepository.billableKg(3000), 3);
    });

    test('gratis ongkir Bpedia Express mulai Rp50.000', () {
      final below = shipping.optionById(
        'bpedia-express',
        weightGrams: 500,
        goodsSubtotal: 49999,
      )!;
      final reached = shipping.optionById(
        'bpedia-express',
        weightGrams: 500,
        goodsSubtotal: 50000,
      )!;
      expect(below.fee, 8000);
      expect(reached.fee, 0);
      expect(reached.isFree, isTrue);
      expect(reached.note, 'Gratis ongkir');
      expect(
        shipping
            .optionById('wahana-express', weightGrams: 500, goodsSubtotal: 90000)!
            .fee,
        10000,
      );
      expect(
        shipping.optionById('entah', weightGrams: 1, goodsSubtotal: 1),
        isNull,
      );
    });
  });

  group('PaymentCatalog', () {
    test('QRIS, VA 8 bank, 2 gerai, dompet digital, dan COD', () {
      final grouped = PaymentCatalog.grouped;
      expect(grouped.keys.toList(), PaymentKind.values);
      expect(grouped[PaymentKind.qris]!.single.id, 'qris');
      expect(grouped[PaymentKind.virtualAccount]!.length, 8);
      expect(
        <String>[for (final m in grouped[PaymentKind.retail]!) m.name],
        <String>['Alfamart', 'Indomaret'],
      );
      expect(grouped[PaymentKind.ewallet]!.length, 1);
      expect(grouped[PaymentKind.cod]!.single.isCod, isTrue);
      final ids = <String>{for (final m in PaymentCatalog.methods) m.id};
      expect(ids.length, PaymentCatalog.methods.length);
      for (final bank in <String>[
        'BCA',
        'Mandiri',
        'BNI',
        'BRI',
        'CIMB Niaga',
        'BSI',
        'Permata',
        'bank bjb',
      ]) {
        expect(
          grouped[PaymentKind.virtualAccount]!.any(
            (m) => m.name.contains(bank),
          ),
          isTrue,
          reason: bank,
        );
      }
    });

    test('bawaan QRIS; pencarian ID; bertanda simulasi', () {
      expect(PaymentCatalog.byId(PaymentCatalog.defaultMethodId)!.name, 'QRIS');
      expect(PaymentCatalog.byId('entah'), isNull);
      expect(PaymentCatalog.byId(null), isNull);
      expect(PaymentCatalog.demoNote, contains('Simulasi'));
      for (final method in PaymentCatalog.methods) {
        expect(method.hint, isNotEmpty, reason: method.id);
      }
    });
  });

  group('NoRewardsGateway', () {
    testWidgets('tanpa hadiah: kutipan polos subtotal + ongkir', (tester) async {
      final gateway = NoRewardsGateway();
      expect(gateway.available, isFalse);
      expect(gateway.kelopakBalance, 0);
      expect(gateway.voucherCount, 0);
      expect(gateway.pendingGifts, isEmpty);
      expect(gateway.missionProductCodes, isEmpty);
      expect(gateway.vouchersFor(500000), isEmpty);
      expect(gateway.missionHintFor(const <PricedLine>[]), isNull);
      for (final entry in RewardsEntry.values) {
        expect(gateway.hasBadge(entry), isFalse);
      }

      final quote = gateway.quote(
        const CheckoutRequest(
          lines: <PricedLine>[
            PricedLine(productCode: codeA, unitPrice: 46196, quantity: 2),
            PricedLine(productCode: codeB, unitPrice: 20500, quantity: 1),
          ],
          shippingFee: 8000,
          voucherId: 'V1',
        ),
      );
      expect(quote.goodsSubtotal, 112892);
      expect(quote.voucherId, isNull);
      expect(quote.voucherAmount, 0);
      expect(quote.kelopakUsed, 0);
      expect(quote.kelopakValue, 0);
      expect(quote.gifts, isEmpty);
      expect(quote.total, 120892);
      expect(quote.token, isNotEmpty);

      expect((await gateway.commit('BP-1', quote)).ok, isTrue);
      await gateway.ship('BP-1');
      final completion = await gateway.complete('BP-1');
      expect(completion.missionMessage, isNull);
      expect(completion.celebrate, isNull);
      await gateway.cancel('BP-1');

      expect(gateway.canClaimPromoVoucher('tanggal-kembar-1212'), isFalse);
      final claim = await gateway.claimPromoVoucher(
        promoId: 'tanggal-kembar-1212',
        amount: 12000,
        minSpend: 120000,
        validDays: 7,
      );
      expect(claim.ok, isFalse);
      expect(claim.message, isNotEmpty);

      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(gateway.buildWalletStrip(context), isNull);
      expect(gateway.buildGameStrip(context), isNull);
      gateway.dispose();
    });
  });

  group('tanggal WIB', () {
    test('urai, format, dan batas tengah malam WIB', () {
      final day = parseWibDay('2026-11-25');
      expect(wibDayFromDate(2026, 11, 25), day);
      expect(dateOfWibDay(day), DateTime.utc(2026, 11, 25));
      expect(compactWibDate(day), '261125');
      expect(tryParseWibDay('2026-02-30'), isNull);
      expect(tryParseWibDay('25-11-2026'), isNull);
      expect(tryParseWibDay(null), isNull);
      expect(() => parseWibDay('entah'), throwsFormatException);

      expect(wibDayOfInstant(DateTime.utc(2026, 11, 25, 16, 59)), day);
      expect(wibDayOfInstant(DateTime.utc(2026, 11, 25, 17)), day + 1);
      expect(wibClockLabel(DateTime.utc(2026, 11, 25, 2, 5)), '09.05');
      expect(
        wibDateTimeLabel(DateTime.utc(2026, 11, 25, 17, 30)),
        '26 Nov 2026, 00.30 WIB',
      );
    });
  });
}
