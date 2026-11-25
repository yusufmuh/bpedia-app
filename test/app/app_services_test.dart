import 'dart:convert';
import 'dart:io';

import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/app/app_scope.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/catalog/catalog_repository.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/promo/promo_repository.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/data/storage/app_document.dart';
import 'package:bpedia_app/data/storage/migrate_v2.dart';
import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:bpedia_app/services/reminders/reminder_service.dart';
import 'package:bpedia_app/services/sound/haptics.dart';
import 'package:bpedia_app/services/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart';

import '../data/support/fakes.dart';

/// Bundel aset yang membaca berkas proyek; jalur di [missing] dianggap hilang.
class FileAssetBundle extends CachingAssetBundle {
  FileAssetBundle({this.missing = const <String>{}});

  final Set<String> missing;

  @override
  Future<ByteData> load(String key) async {
    if (missing.contains(key)) throw FlutterError('Aset $key tidak ada');
    final bytes = File(key).readAsBytesSync();
    return ByteData.sublistView(bytes);
  }
}

/// Tujuan analitik palsu yang mencatat panggilan.
class RecordingAnalytics implements Analytics {
  final List<String> calls = <String>[];
  DeepLinkHandler? onDeepLink;

  @override
  bool isEnabled = false;

  @override
  Future<void> start({DeepLinkHandler? onDeepLink}) async {
    this.onDeepLink = onDeepLink;
    isEnabled = true;
    calls.add('start');
  }

  @override
  Future<void> setUserId(String? userId) async => calls.add('user:$userId');

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) async => calls.add(name);
}

Future<Order> placeOrder(AppServices s, {String paymentId = 'qris'}) async {
  final shipping = s.shipping
      .options(
        weightGrams: s.cart.selectedWeightGrams,
        goodsSubtotal: s.cart.selectedSubtotal,
      )
      .first;
  final result = await s.orders.place(
    OrderDraft(
      items: s.cart.selectedItems,
      address: s.addresses.primary,
      shipping: shipping,
      payment: PaymentCatalog.byId(paymentId),
      quote: s.rewards.quote(
        CheckoutRequest(
          lines: s.cart.linesForCheckout,
          shippingFee: shipping.fee,
          voucherId: null,
          useKelopak: true,
        ),
      ),
    ),
  );
  expect(result.ok, isTrue, reason: result.message);
  return result.order!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppServices.forTest', () {
    test('sinkron: katalog dan promo asli, jam tetap, tamu', () {
      final s = AppServices.forTest();
      addTearDown(s.dispose);

      expect(s.catalog.products.length, 82);
      expect(s.catalog.hotItems.length, 5);
      expect(s.promo.banners, isNotEmpty);
      expect(s.clock.instant, AppServices.testNow);
      expect(wibDateLabel(s.clock.today), contains('25 Nov 2026'));
      expect(s.auth.isLoggedIn, isFalse);
      expect(s.rewards, isA<NoRewardsGateway>());
      expect(s.rewards.available, isFalse);
      expect(s.store, isA<MemoryKeyValueStore>());
      expect(s.origin, DocumentOrigin.fresh);
      expect(s.appsFlyerConfigured, isFalse);
      expect(s.appsFlyerEnabled, isFalse);
      expect(s.analytics, same(s.analyticsLog));
      expect(s.sound.isSilent, isTrue);
      expect(s.reminders, isA<MemoryReminderService>());
      expect(s.cart.isEmpty, isTrue);
      expect(s.orders.orders, isEmpty);
    });

    test('loggedIn: profil contoh siap checkout', () {
      final s = AppServices.forTest(loggedIn: true);
      addTearDown(s.dispose);

      expect(s.auth.isLoggedIn, isTrue);
      expect(s.auth.profile!.name, 'Babes Demo');
      expect(s.auth.needsTermsAcceptance, isFalse);
      expect(s.analyticsLog.userId, s.auth.profile!.id);
    });

    test('jam dan katalog bisa diganti', () {
      final s = AppServices.forTest(
        now: DateTime.utc(2026, 12, 11, 17),
        catalogJson: jsonEncode(<String, Object?>{'products': <Object?>[]}),
        promoJson: '{rusak',
      );
      addTearDown(s.dispose);

      expect(wibDateLabel(s.clock.today), contains('12 Des 2026'));
      expect(s.catalog.products, isEmpty);
      expect(s.promo.banners, isEmpty);
      expect(s.promo.loadError, isNotNull);
    });

    testWidgets('aman di testWidgets: menyimpan tanpa Timer tertunda', (
      tester,
    ) async {
      final store = MemoryKeyValueStore();
      final s = AppServices.forTest(store: store, loggedIn: true);

      s.cart.add(codeB, qty: 2);
      s.settings.setThemeMode(ThemeMode.dark);
      await tester.pump();
      await s.document.flush();

      expect(await store.read(appDocumentKey), contains(codeB));
      await s.dispose();
    });

    test('gateway hadiah dipasang lewat rewardsBuilder', () async {
      final gateway = FakeRewardsGateway(balance: 50);
      late AppServices seen;
      final s = AppServices.forTest(
        loggedIn: true,
        rewardsBuilder: (services) {
          seen = services;
          expect(services.catalog.products, isNotEmpty);
          expect(services.cart.isEmpty, isTrue);
          return gateway;
        },
      );
      addTearDown(s.dispose);

      expect(seen, same(s));
      expect(s.rewards, same(gateway));
      s.addresses.add(sampleAddress);
      s.cart.add(codeB);
      final order = await placeOrder(s);
      expect(gateway.calls, <String>['commit:${order.id}']);
      expect(order.kelopakUsed, 50);
    });
  });

  group('alur data ujung ke ujung (tanpa hadiah)', () {
    test('keranjang, pesanan, kotak masuk, dan analitik tersambung', () async {
      final s = AppServices.forTest(loggedIn: true);
      addTearDown(s.dispose);
      s.addresses.add(sampleAddress);
      s.cart.add(codeB, qty: 2);
      s.wishlist.toggle(codeA);
      s.searchHistory.record('serum');

      final order = await placeOrder(s);
      expect(order.status, OrderStatus.awaitingPayment);
      expect(order.total, order.goodsSubtotal + order.shippingFee);
      expect(s.cart.isEmpty, isTrue);
      expect(s.inbox.unreadCount, 1);

      expect((await s.orders.pay(order.id)).ok, isTrue);
      expect((await s.orders.ship(order.id)).ok, isTrue);
      expect((await s.orders.complete(order.id)).ok, isTrue);

      expect(s.orders.byId(order.id)!.status, OrderStatus.completed);
      expect(s.inbox.unreadCount, 4);
      expect(
        s.analyticsLog.eventNames,
        containsAllInOrder(<String>[
          AfEvent.addToCart,
          AfEvent.addToWishlist,
          AfEvent.search,
          AfEvent.purchase,
        ]),
      );
    });

    test('data bertahan setelah app dibuka lagi', () async {
      final store = MemoryKeyValueStore();
      final first = AppServices.forTest(store: store, loggedIn: true);
      first.addresses.add(sampleAddress);
      first.cart.add(codeB);
      final order = await placeOrder(first, paymentId: 'cod');
      first.cart.add(codeA, qty: 3);
      first.wishlist.toggle(codeMany);
      first.searchHistory.record('toner');
      first.settings
        ..setThemeMode(ThemeMode.dark)
        ..setSoundOn(false);
      first.demoClock.advanceDays(2);
      await first.dispose();

      final second = AppServices.forTest(store: store);
      addTearDown(second.dispose);
      expect(second.auth.isLoggedIn, isFalse);
      expect(await second.load(), DocumentOrigin.loaded);

      expect(second.auth.isLoggedIn, isTrue);
      expect(second.analyticsLog.userId, second.auth.profile!.id);
      expect(second.cart.quantityOf(codeA), 3);
      expect(second.wishlist.contains(codeMany), isTrue);
      expect(second.searchHistory.terms, <String>['toner']);
      expect(second.settings.themeMode, ThemeMode.dark);
      expect(second.settings.soundOn, isFalse);
      expect(second.sound.soundOn, isFalse);
      expect(second.demoClock.offsetDays, 2);
      expect(second.addresses.primary!.recipient, 'Sari Dewi');
      expect(second.orders.byId(order.id)!.status, OrderStatus.packing);
      expect(second.inbox.messages, isNotEmpty);
    });

    test('dokumen rusak: mulai bersih tanpa crash', () async {
      final store = MemoryKeyValueStore();
      await store.write(appDocumentKey, '{"schema":1,"revision":"x"');
      final s = AppServices.forTest(store: store);
      addTearDown(s.dispose);

      expect(await s.load(), DocumentOrigin.corrupt);

      expect(s.origin, DocumentOrigin.corrupt);
      expect(s.cart.isEmpty, isTrue);
      expect(s.auth.isLoggedIn, isFalse);
      s.cart.add(codeB);
      await s.document.flush();
      expect(await store.read(appDocumentKey), contains(codeB));
    });

    test('migrasi v2: keranjang dan pengaturan dibawa; akun tidak', () async {
      final store = MemoryKeyValueStore();
      final v2 = jsonEncode(<String, Object?>{
        'schema': 1,
        'clockOffsetDays': 1,
        'settings': <String, Object?>{
          'themeMode': 'dark',
          'sfxEnabled': false,
          'musicEnabled': true,
          'hapticsEnabled': false,
        },
        'shop': <String, Object?>{
          'cart': <Object?>[
            <String, Object?>{'productId': codeB, 'qty': 2},
            <String, Object?>{'productId': 'SUDAH-TIDAK-ADA', 'qty': 1},
            <String, Object?>{'productId': codeLastOne, 'qty': 9},
          ],
        },
      });
      await store.write(v2DocumentKey, v2);
      final s = AppServices.forTest(store: store);
      addTearDown(s.dispose);

      expect(await s.load(), DocumentOrigin.migratedV2);
      await s.document.flush();

      expect(s.cart.quantityOf(codeB), 2);
      expect(s.cart.quantityOf(codeLastOne), 1);
      expect(s.cart.lineCount, 2);
      expect(s.settings.themeMode, ThemeMode.dark);
      expect(s.settings.soundOn, isFalse);
      expect(s.settings.musicOn, isTrue);
      expect(s.settings.hapticsOn, isFalse);
      expect(s.demoClock.offsetDays, 1);
      expect(s.auth.isLoggedIn, isFalse);
      expect(await store.read(v2DocumentKey), v2);
      expect(await store.read(appDocumentKey), isNotNull);

      final again = AppServices.forTest(store: store);
      addTearDown(again.dispose);
      expect(await again.load(), DocumentOrigin.loaded);
      expect(again.cart.quantityOf(codeB), 2);
    });

    test('pesanan lewat batas bayar dibatalkan saat dimuat', () async {
      final store = MemoryKeyValueStore();
      var now = AppServices.testNow;
      final first = AppServices.forTest(
        store: store,
        clock: WibClock(now: () => now),
        loggedIn: true,
      );
      first.addresses.add(sampleAddress);
      first.cart.add(codeB);
      final order = await placeOrder(first);
      await first.dispose();

      now = now.add(const Duration(hours: 25));
      final second = AppServices.forTest(
        store: store,
        clock: WibClock(now: () => now),
      );
      addTearDown(second.dispose);
      await second.load();

      expect(second.orders.byId(order.id)!.status, OrderStatus.cancelled);
    });

    test('resetData: semua data kembali awal dan tersimpan', () async {
      final store = MemoryKeyValueStore();
      final s = AppServices.forTest(store: store, loggedIn: true);
      addTearDown(s.dispose);
      s.addresses.add(sampleAddress);
      s.cart.add(codeB);
      await placeOrder(s);
      s.settings.setThemeMode(ThemeMode.dark);
      s.router.selectTab(AppTab.orders);

      await s.resetData();

      expect(s.auth.isLoggedIn, isFalse);
      expect(s.cart.isEmpty, isTrue);
      expect(s.orders.orders, isEmpty);
      expect(s.inbox.messages, isEmpty);
      expect(s.addresses.addresses, isEmpty);
      expect(s.settings.themeMode, ThemeMode.system);
      expect(s.analyticsLog.records, isEmpty);
      expect(s.router.currentTab, AppTab.home);

      final reopened = AppServices.forTest(store: store);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.auth.isLoggedIn, isFalse);
      expect(reopened.orders.orders, isEmpty);
    });
  });

  group('sambungan layanan', () {
    test('pengaturan suara, musik, dan getar diteruskan ke layanan', () {
      final s = AppServices.forTest();
      addTearDown(s.dispose);
      expect(s.sound.soundOn, isTrue);
      expect(s.sound.musicOn, isFalse);
      expect(s.haptics.enabled, isTrue);
      expect(s.haptics, same(s.sound.haptics));

      s.settings
        ..setSoundOn(false)
        ..setMusicOn(true)
        ..setHapticsOn(false);

      expect(s.sound.soundOn, isFalse);
      expect(s.sound.musicOn, isTrue);
      expect(s.haptics.enabled, isFalse);
      s.sound.play(SoundCue.claim);
      expect(s.sound.history, isEmpty);
    });

    test('router memakai status masuk dari akun', () async {
      final s = AppServices.forTest();
      addTearDown(s.dispose);

      final asGuest = s.router.onGenerateInitialRoutes('/checkout');
      expect(asGuest.last.settings.name, '/masuk?lanjut=%2Fcheckout');

      s.signInAsDemo();
      final asMember = s.router.onGenerateInitialRoutes('/checkout');
      expect(asMember.last.settings.name, '/checkout');

      await s.auth.signOut();
      expect(
        s.router.onGenerateInitialRoutes('/checkout').last.settings.name,
        '/masuk?lanjut=%2Fcheckout',
      );
    });

    testWidgets('deep link dan ketukan pengingat membuka rute', (tester) async {
      final reminders = MemoryReminderService();
      final s = AppServices.forTest(reminders: reminders);
      s.router
        ..registerTab(AppTab.home, (context) => const Text('beranda'))
        ..register<WheelRoute>((context, route) => const Text('roda'))
        ..register<ProductRoute>(
          (context, route) => Text('produk ${route.code}'),
        );
      await tester.pumpWidget(
        AppScope(
          services: s,
          child: MaterialApp(
            navigatorKey: s.router.navigatorKey,
            onGenerateRoute: s.router.onGenerateRoute,
            onGenerateInitialRoutes: s.router.onGenerateInitialRoutes,
          ),
        ),
      );
      expect(s.analyticsLog.isStarted, isTrue);

      s.analyticsLog.simulateDeepLink('produk/$hotCode');
      await tester.pumpAndSettle();
      expect(find.text('produk $hotCode'), findsOneWidget);

      expect(
        await reminders.scheduleWeekly(wheelReminder),
        ReminderResult.scheduled,
      );
      reminders.tap(wheelReminder.id);
      await tester.pumpAndSettle();
      expect(find.text('roda'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await s.dispose();
    });

    test('tautan keluar memakai pembuka yang disuntik', () async {
      final opened = <Uri>[];
      final s = AppServices.forTest(
        uriOpener: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      addTearDown(s.dispose);

      expect(await s.links.openWhatsAppCare(), isTrue);

      expect(opened.single.host, 'wa.me');
      expect(opened.single.path, '/6282318591288');
    });

    test('dispose aman dipanggil dua kali', () async {
      final s = AppServices.forTest();

      await s.dispose();
      await s.dispose();
    });
  });

  group('AppServices.bootstrap', () {
    Future<AppServices> boot({
      KeyValueStore? store,
      AssetBundle? bundle,
      RewardsBuilder? rewardsBuilder,
      Analytics? attribution,
    }) => AppServices.bootstrap(
      bundle: bundle ?? FileAssetBundle(),
      store: store ?? MemoryKeyValueStore(),
      clock: WibClock(now: () => AppServices.testNow),
      rewardsBuilder: rewardsBuilder,
      attribution: attribution,
      sound: SoundService.silent(haptics: Haptics(runner: (_) async {})),
      reminders: MemoryReminderService(),
    );

    test('memuat aset dari bundel dan data dari penyimpanan', () async {
      final store = MemoryKeyValueStore();
      final first = await boot(store: store);
      expect(first.catalog.products.length, 82);
      expect(first.promo.events, isNotEmpty);
      expect(first.origin, DocumentOrigin.fresh);
      expect(first.rewards, isA<NoRewardsGateway>());
      first.cart.add(codeB);
      await first.dispose();

      final second = await boot(store: store);
      addTearDown(second.dispose);
      expect(second.origin, DocumentOrigin.loaded);
      expect(second.cart.quantityOf(codeB), 1);
    });

    test('tulis tertunda 300 ms ditulis saat dispose', () async {
      final store = MemoryKeyValueStore();
      final s = await boot(store: store);
      expect(s.document.saveDelay, const Duration(milliseconds: 300));

      s.cart.add(codeA);
      expect(await store.read(appDocumentKey), isNull);
      await s.dispose();

      expect(await store.read(appDocumentKey), contains(codeA));
    });

    test('aset hilang: katalog kosong, app tetap hidup', () async {
      final s = await boot(
        bundle: FileAssetBundle(missing: <String>{catalogAsset, promoAsset}),
      );
      addTearDown(s.dispose);

      expect(s.catalog.products, isEmpty);
      expect(s.catalog.loadError, isNotNull);
      expect(s.promo.banners, isEmpty);
      expect(s.cart.add(codeB).changed, isFalse);
    });

    test('rewardsBuilder asinkron dipanggil sebelum data dimuat', () async {
      final store = MemoryKeyValueStore();
      final seed = await boot(store: store);
      seed.cart.add(codeB);
      await seed.dispose();

      final gateway = FakeRewardsGateway(balance: 7);
      int? cartLinesAtBuild;
      final s = await boot(
        store: store,
        rewardsBuilder: (services) async {
          await Future<void>.delayed(Duration.zero);
          cartLinesAtBuild = services.cart.lineCount;
          return gateway;
        },
      );
      addTearDown(s.dispose);

      expect(cartLinesAtBuild, 0);
      expect(s.rewards, same(gateway));
      expect(s.cart.lineCount, 1);
    });

    test('AppsFlyer aktif: event diteruskan ke log lokal dan SDK', () async {
      final attribution = RecordingAnalytics();
      final s = await boot(attribution: attribution);
      addTearDown(s.dispose);

      expect(s.appsFlyerConfigured, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(s.appsFlyerEnabled, isTrue);
      expect(s.analytics, isA<CompositeAnalytics>());

      s.signInAsDemo();
      s.cart.add(codeB);
      await Future<void>.delayed(Duration.zero);

      expect(attribution.calls.first, 'start');
      expect(attribution.calls, contains('user:${s.auth.profile!.id}'));
      expect(attribution.calls, contains(AfEvent.login));
      expect(attribution.calls, contains(AfEvent.addToCart));
      expect(s.analyticsLog.eventNames, contains(AfEvent.addToCart));

      final opened = s.router.openLocation('hadiah/roda');
      expect(opened, const WheelRoute());
      expect(attribution.onDeepLink, isNotNull);
    });
  });

  group('AppScope', () {
    testWidgets('of dan maybeOf', (tester) async {
      final s = AppServices.forTest();
      AppServices? found;
      AppServices? outside;

      await tester.pumpWidget(
        Column(
          children: <Widget>[
            Builder(
              builder: (context) {
                outside = AppScope.maybeOf(context);
                return const SizedBox();
              },
            ),
            AppScope(
              services: s,
              child: Builder(
                builder: (context) {
                  found = AppScope.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      );

      expect(found, same(s));
      expect(outside, isNull);
      await tester.pumpWidget(const SizedBox());
      await s.dispose();
    });

    testWidgets('memberi tahu hanya bila layanan diganti', (tester) async {
      final a = AppServices.forTest();
      final b = AppServices.forTest();

      expect(
        AppScope(
          services: a,
          child: const SizedBox(),
        ).updateShouldNotify(AppScope(services: a, child: const SizedBox())),
        isFalse,
      );
      expect(
        AppScope(
          services: b,
          child: const SizedBox(),
        ).updateShouldNotify(AppScope(services: a, child: const SizedBox())),
        isTrue,
      );
      await a.dispose();
      await b.dispose();
    });
  });
}
