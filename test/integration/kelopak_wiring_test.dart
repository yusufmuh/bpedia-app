import 'dart:convert';
import 'dart:io';

import 'package:bpedia_app/config/demo_campaign.dart';
import 'package:bpedia_app/data/inbox/inbox_repository.dart';
import 'package:bpedia_app/integration/bpedia_kelopak_host.dart';
import 'package:bpedia_app/integration/kelopak_event_bridge.dart';
import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:bpedia_app/services/reminders/reminder_service.dart';
import 'package:bpedia_app/services/sound/sound_service.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart' as hub;

import 'i1_harness.dart';

const String _v2Key = 'bpedia_preview_state_v1';

hub.KelopakVoucher _voucher() => const hub.KelopakVoucher(
  id: 'V-1',
  kind: hub.VoucherKind.mission,
  title: 'Voucher Misi Belanja',
  amount: 10000,
  minSpend: 100000,
  issuedDay: 20417,
  expiresDay: 20447,
  stageNumber: 1,
  sourceOrderId: 'BP-1',
);

void main() {
  group('kampanye demo (RENCANA §12, KEPUTUSAN §1-§4)', () {
    final services = AppServices.forTest();
    final products = services.catalog.products;
    final campaign = buildDemoCampaign(products);

    test('semua kode produk kampanye ada di katalog', () {
      final known = <String>{for (final product in products) product.code};
      expect(known, containsAll(demoMissionStage1Codes));
      expect(known, containsAll(demoWheelProductCodes));
      expect(known, contains(demoCheckIn30ProductCode));
      expect(campaign.wheelProductCodes, demoWheelProductCodes);
      expect(campaign.checkIn30ProductCode, demoCheckIn30ProductCode);
    });

    test('tahap 1 Animate skincare, tahap 2 semua Pinkflash dan Focallure', () {
      final stages = campaign.missionStages;
      expect(stages, hasLength(2));
      expect(stages[0].productCodes, demoMissionStage1Codes);
      for (final code in stages[0].productCodes) {
        final product = services.catalog.byCode(code)!;
        expect(product.brand, 'Animate');
        expect(product.categoryId, 'skincare');
      }
      final brand2 = <String>[
        for (final product in products)
          if (product.brand == 'Pinkflash' || product.brand == 'Focallure')
            product.code,
      ];
      expect(stages[1].productCodes, brand2);
      expect(brand2, isNotEmpty);
      expect(
        <int>[
          stages[0].minOrderSubtotal,
          stages[0].voucherAmount,
          stages[0].voucherMinSpend,
          stages[0].voucherValidDays,
        ],
        <int>[75000, 10000, 100000, 30],
      );
      expect(
        <int>[
          stages[1].minOrderSubtotal,
          stages[1].voucherAmount,
          stages[1].voucherMinSpend,
        ],
        <int>[100000, 15000, 150000],
      );
    });

    test('roda: peluang KEPUTUSAN §4, kuota 3/pekan, Kelopak boleh menutup '
        'seluruh harga barang', () {
      final weights = <String, int>{
        for (final prize in campaign.wheel.prizes) prize.id: prize.weight,
      };
      expect(weights, <String, int>{
        'product': 500,
        'kelopak-10': 500,
        'kelopak-5': 1500,
        'kelopak-3': 3000,
        'kelopak-1': 4500,
      });
      expect(campaign.wheel.fallbackPrizeId, 'kelopak-1');
      expect(campaign.wheelQuota, 3);
      expect(campaign.wheelQuotaRefillsWeekly, isTrue);
      expect(campaign.policy.redeemShareBp, 10000);
      expect(campaign.policy.rupiahPerKelopak, 100);
    });

    test('kode yang hilang dari katalog dibuang', () {
      final trimmed = buildDemoCampaign(
        products.where((p) => p.code != demoWheelProductCodes.first).toList(),
      );
      expect(trimmed.wheelProductCodes, demoWheelProductCodes.sublist(1));
    });
  });

  group('suara game', () {
    test('setiap GameCue punya SoundCue dan berkasnya ada', () {
      for (final cue in hub.GameCue.values) {
        final sounds = soundCuesFor(cue);
        expect(sounds, isNotEmpty, reason: cue.name);
        for (final sound in sounds) {
          expect(
            File('assets/${sound.asset}').existsSync(),
            isTrue,
            reason: sound.asset,
          );
        }
      }
      expect(soundCuesFor(hub.GameCue.winProduct), <SoundCue>[
        SoundCue.winProduct,
        SoundCue.winJingle,
      ]);
      expect(soundCuesFor(hub.GameCue.missionDone), <SoundCue>[
        SoundCue.missionDone,
      ]);
      expect(File('assets/$bgmWheelAsset').existsSync(), isTrue);
      expect(SoundCue.byId('pop'), SoundCue.pop);
    });

    test('host memutar cue game tanpa getar, menang produk disusul jingle', () {
      final services = i1Services();
      final host = gatewayOf(services).controller.host! as BpediaKelopakHost;
      host
        ..playCue(hub.GameCue.claim)
        ..playCue(hub.GameCue.winProduct);
      expect(services.sound.history, <SoundCue>[
        SoundCue.claim,
        SoundCue.winProduct,
        SoundCue.winJingle,
      ]);
    });

    test('musik: permintaan terakhir berbunyi, kembali saat dilepas', () {
      final sound = SoundService.silent()..musicOn = true;
      sound.startMusic();
      expect(sound.currentMusicAsset, bgmAsset);
      sound.startMusic(asset: bgmWheelAsset);
      expect(sound.currentMusicAsset, bgmWheelAsset);
      sound.stopMusic(asset: bgmWheelAsset);
      expect(sound.currentMusicAsset, bgmAsset);
      sound.stopMusic();
      expect(sound.currentMusicAsset, isNull);
      expect(sound.wantsMusic, isFalse);
    });
  });

  group('peristiwa Kelopak -> analitik + kotak masuk', () {
    late LocalAnalytics analytics;
    late InboxRepository inbox;

    setUp(() {
      final services = AppServices.forTest();
      analytics = services.analyticsLog;
      inbox = services.inbox;
    });

    void record(hub.KelopakEvent event) =>
        recordKelopakEvent(event, analytics: analytics, inbox: inbox);

    test('check-in: analitik; kotak masuk hanya bila dapat produk', () {
      record(const hub.CheckInClaimedEvent(streak: 3, kelopak: 1));
      expect(analytics.eventNames, <String>['bp_checkin_claim']);
      expect(analytics.records.single.values['streak'], 3);
      expect(inbox.messages, isEmpty);

      record(
        const hub.CheckInClaimedEvent(
          streak: 30,
          kelopak: 1,
          gift: hub.PendingGift(
            id: 'HG-1',
            source: hub.GiftSource.checkIn30,
            wonDay: 20417,
            productCode: demoCheckIn30ProductCode,
          ),
        ),
      );
      expect(inbox.messages.single.kind, InboxKind.reward);
      expect(inbox.messages.single.route, '/hadiah/hadiahku');
    });

    test('roda produk masuk kotak masuk; misi hanya analitik', () {
      record(
        const hub.WheelSpunEvent(
          prizeId: 'product',
          kelopak: 0,
          gift: hub.PendingGift(
            id: 'HG-2',
            source: hub.GiftSource.wheel,
            wonDay: 20420,
            productCode: 'P21P03C01000082',
          ),
        ),
      );
      record(
        hub.MissionCompletedEvent(
          orderId: 'BP-1',
          stageNumber: 1,
          voucher: _voucher(),
        ),
      );
      expect(
        analytics.eventNames,
        containsAll(<String>['bp_wheel_spin', 'bp_mission_complete']),
      );
      expect(inbox.messages.single.title, 'Kamu menang produk gratis');
    });

    test('peristiwa terikat pesanan tidak dicatat dua kali', () {
      record(
        const hub.VoucherRedeemedEvent(
          orderId: 'BP-1',
          voucherId: 'V-1',
          amount: 1,
        ),
      );
      record(
        const hub.KelopakRedeemedEvent(orderId: 'BP-1', kelopak: 5, value: 500),
      );
      record(
        hub.GiftAttachedEvent(orderId: 'BP-1', gifts: <hub.PendingGift>[]),
      );
      record(
        hub.OrderRefundedEvent(
          orderId: 'BP-1',
          kelopak: 5,
          gifts: <hub.PendingGift>[],
        ),
      );
      expect(analytics.eventNames, isEmpty);
      expect(inbox.messages, isEmpty);
    });
  });

  group('host', () {
    test('produk, keranjang, dan baris misi dari layanan app', () async {
      final services = i1Services();
      final host = gatewayOf(services).controller.host! as BpediaKelopakHost;
      final product = host.productOf(nightCream)!;
      expect(product.price, 26000);
      expect(product.image, isNotNull);
      expect(identical(host.productOf(nightCream), product), isTrue);
      expect(host.productOf('TIDAK-ADA'), isNull);

      expect(await host.addToCart(nightCream, quantity: 2), isTrue);
      expect(await host.addToCart('TIDAK-ADA'), isFalse);
      expect(host.cartLines.single.quantity, 2);
      expect(await host.setCartQuantity(nightCream, 0), isTrue);
      expect(services.cart.isEmpty, isTrue);
      expect(host.isLoggedIn, isTrue);
      expect(host.soundOn, services.settings.soundOn);
    });

    test('pengingat Roda Sabtu memakai ReminderService app', () async {
      final reminders = MemoryReminderService();
      final reminder = AppKelopakReminder(reminders);
      expect(reminder.isSupported, reminders.isSupported);
      expect(await reminder.isEnabled(), isFalse);
      expect(await reminder.setEnabled(true), isTrue);
      expect(reminders.scheduled.single.id, wheelReminder.id);
      expect(await reminder.isEnabled(), isTrue);
      expect(await reminder.setEnabled(false), isFalse);
      expect(await reminder.isEnabled(), isFalse);
    });
  });

  test('data Kelopak v2 dipindahkan saat app pertama dibuka', () async {
    final store = hub.MemoryKeyValueStore();
    const tuesday = 20416;
    await store.write(
      _v2Key,
      jsonEncode(<String, Object?>{
        'schema': 1,
        'revision': 3,
        'clockOffsetDays': 0,
        'settings': <String, Object?>{'sfxEnabled': true},
        'shop': <String, Object?>{
          'cart': <Object?>[],
          'orders': <Object?>[],
          'orderSeq': 0,
        },
        'rewards': <String, Object?>{
          'ledger': <Object?>[
            <String, Object?>{
              'id': 'L000001',
              'wibDay': tuesday,
              'amount': 25,
              'kind': 'checkIn',
              'note': 'Check-in hari ke-1',
            },
          ],
          'streak': 1,
          'lastClaimDay': tuesday,
          'entitlements': <Object?>[
            <String, Object?>{
              'id': 'HP-0001',
              'source': 'spin',
              'wibDay': tuesday - 3,
              'status': 'pending',
            },
          ],
          'spins': <Object?>[],
          'vouchers': <Object?>[],
          'ledgerSeq': 1,
          'entitlementSeq': 1,
        },
      }),
    );
    final services = i1Services(store: store);
    final gateway = await loadKelopak(services);
    await services.load();

    final backend = gateway.controller.backend as hub.LocalKelopakBackend;
    expect(backend.origin, hub.KelopakOrigin.migratedV2);
    expect(gateway.kelopakBalance, 25);
    expect(gateway.pendingGifts, hasLength(1));
    expect(await store.read(hub.kelopakDocumentKey), isNotNull);
    expect(await store.read(_v2Key), isNotNull, reason: 'kunci lama tetap');
  });

  testWidgets('musik zona Hadiah: jingle di tab, musik roda di Roda Sabtu, '
      'berhenti saat keluar', (tester) async {
    final services = i1Services();
    services.settings.setMusicOn(true);
    await loadKelopak(services);
    await pumpI1(tester, services, location: '/hadiah');
    expect(services.sound.currentMusicAsset, bgmAsset);

    await openLocation(tester, services, '/hadiah/roda');
    expect(services.sound.currentMusicAsset, bgmWheelAsset);

    services.router.back(tester.element(find.byType(hub.KelopakWheelScreen)));
    await settle(tester);
    expect(services.sound.currentMusicAsset, bgmAsset);

    await openLocation(tester, services, '/');
    expect(services.sound.musicHolders, 0);
  });
}
