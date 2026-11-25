import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:bpedia_app/services/analytics/create_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tujuan analitik yang mencatat panggilan dan bisa disuruh gagal.
class _RecordingAnalytics implements Analytics {
  _RecordingAnalytics({this.enabled = true, this.failing = false});

  final bool enabled;
  final bool failing;
  final List<String> calls = <String>[];
  DeepLinkHandler? onDeepLink;

  @override
  bool get isEnabled => enabled;

  @override
  Future<void> start({DeepLinkHandler? onDeepLink}) async {
    calls.add('start');
    this.onDeepLink = onDeepLink;
    if (failing) throw StateError('start');
  }

  @override
  Future<void> setUserId(String? userId) async {
    calls.add('user:$userId');
    if (failing) throw StateError('user');
  }

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) async {
    calls.add('event:$name');
    if (failing) throw StateError('event');
  }
}

void main() {
  group('LocalAnalytics', () {
    test('mencatat event beserta parameter dan waktu', () async {
      final at = DateTime.utc(2026, 11, 25, 3);
      final analytics = LocalAnalytics(now: () => at);

      await analytics.logEvent('af_search', <String, Object?>{
        'af_search_string': 'serum',
      });

      expect(analytics.isEnabled, isTrue);
      expect(analytics.records, hasLength(1));
      final record = analytics.records.single;
      expect(record.name, 'af_search');
      expect(record.values, <String, Object?>{'af_search_string': 'serum'});
      expect(record.at, at);
    });

    test('records terbaru lebih dulu, eventNames terlama lebih dulu', () async {
      final analytics = LocalAnalytics();
      await analytics.logEvent('a');
      await analytics.logEvent('b');
      await analytics.logEvent('c');

      expect(analytics.eventNames, <String>['a', 'b', 'c']);
      expect(analytics.records.map((record) => record.name), <String>[
        'c',
        'b',
        'a',
      ]);
    });

    test('hanya 200 event terakhir yang disimpan', () async {
      final analytics = LocalAnalytics();
      for (var index = 0; index < 205; index++) {
        await analytics.logEvent('e$index');
      }

      expect(analytics.capacity, 200);
      expect(analytics.records, hasLength(200));
      expect(analytics.eventNames.first, 'e5');
      expect(analytics.eventNames.last, 'e204');
    });

    test(
      'parameter tersimpan tidak ikut berubah bersama peta pemanggil',
      () async {
        final analytics = LocalAnalytics();
        final values = <String, Object?>{'af_price': 10000};
        await analytics.logEvent('af_content_view', values);
        values['af_price'] = 1;

        final stored = analytics.records.single.values;
        expect(stored['af_price'], 10000);
        expect(() => stored['x'] = 1, throwsUnsupportedError);
        expect(
          () => analytics.records.add(analytics.records.single),
          throwsUnsupportedError,
        );
      },
    );

    test('memberi tahu pendengar saat mencatat dan saat dikosongkan', () async {
      final analytics = LocalAnalytics();
      var notified = 0;
      analytics.addListener(() => notified++);

      await analytics.logEvent('a');
      expect(notified, 1);
      analytics.clear();
      expect(notified, 2);
      expect(analytics.records, isEmpty);
      analytics.clear();
      expect(notified, 2, reason: 'log kosong tidak memberi tahu lagi');
    });

    test('start, ID pelanggan, dan tautan tiruan', () async {
      final analytics = LocalAnalytics();
      final opened = <String>[];
      expect(analytics.isStarted, isFalse);
      analytics.simulateDeepLink('hadiah/roda');
      expect(opened, isEmpty, reason: 'belum ada pendengar');

      await analytics.start(
        onDeepLink: (value, {required deferred}) =>
            opened.add('$value|$deferred'),
      );
      await analytics.start();
      await analytics.setUserId('u-1');

      expect(analytics.isStarted, isTrue);
      expect(analytics.userId, 'u-1');
      analytics.simulateDeepLink('hadiah/roda');
      analytics.simulateDeepLink('produk/P1', deferred: true);
      expect(opened, <String>['hadiah/roda|false', 'produk/P1|true']);

      await analytics.setUserId(null);
      expect(analytics.userId, isNull);
    });
  });

  group('event belanja (KEPUTUSAN §7)', () {
    late LocalAnalytics analytics;

    setUp(() => analytics = LocalAnalytics());

    Map<String, Object?> only(String name) {
      expect(analytics.eventNames, <String>[name]);
      return analytics.records.single.values;
    }

    test('af_login dan af_complete_registration', () async {
      await analytics.logLogin(method: 'google');
      expect(only(AfEvent.login), <String, Object?>{
        'bp_login_method': 'google',
      });

      analytics.clear();
      await analytics.logRegistration(method: 'phone');
      expect(only(AfEvent.completeRegistration), <String, Object?>{
        'af_registration_method': 'phone',
      });
    });

    test('af_search', () async {
      await analytics.logSearch('sunscreen');
      expect(only(AfEvent.search), <String, Object?>{
        'af_search_string': 'sunscreen',
      });
    });

    test('af_content_view, af_add_to_cart, af_add_to_wishlist', () async {
      await analytics.logContentView(
        productCode: 'P1',
        category: 'Skincare',
        price: 20500,
      );
      expect(only(AfEvent.contentView), <String, Object?>{
        'af_content_id': 'P1',
        'af_content_type': 'Skincare',
        'af_price': 20500,
        'af_currency': 'IDR',
      });

      analytics.clear();
      await analytics.logAddToCart(
        productCode: 'P1',
        category: 'Skincare',
        price: 20500,
        quantity: 2,
      );
      expect(only(AfEvent.addToCart), <String, Object?>{
        'af_content_id': 'P1',
        'af_content_type': 'Skincare',
        'af_price': 20500,
        'af_quantity': 2,
        'af_currency': 'IDR',
      });

      analytics.clear();
      await analytics.logAddToWishlist(
        productCode: 'P1',
        category: 'Skincare',
        price: 20500,
      );
      expect(only(AfEvent.addToWishlist), <String, Object?>{
        'af_content_id': 'P1',
        'af_content_type': 'Skincare',
        'af_price': 20500,
        'af_currency': 'IDR',
      });
    });

    test('af_initiated_checkout dan af_purchase memakai angka polos', () async {
      await analytics.logInitiatedCheckout(
        productCodes: <String>['P1', 'P2'],
        total: 61500,
        itemCount: 3,
      );
      expect(only(AfEvent.initiatedCheckout), <String, Object?>{
        'af_content_list': <String>['P1', 'P2'],
        'af_price': 61500,
        'af_quantity': 3,
        'af_currency': 'IDR',
      });

      analytics.clear();
      await analytics.logPurchase(
        orderId: 'BP-261125-0001',
        paid: 51500,
        productCodes: <String>['P1', 'P2'],
        itemCount: 3,
      );
      final purchase = only(AfEvent.purchase);
      expect(purchase, <String, Object?>{
        'af_revenue': 51500,
        'af_currency': 'IDR',
        'af_order_id': 'BP-261125-0001',
        'af_content_list': <String>['P1', 'P2'],
        'af_quantity': 3,
      });
      expect(purchase['af_revenue'], isA<int>());
    });

    test('nama event hadiah memakai awalan bp_', () {
      expect(<String>[
        BpEvent.checkInClaim,
        BpEvent.wheelSpin,
        BpEvent.missionComplete,
        BpEvent.voucherRedeem,
        BpEvent.kelopakRedeem,
        BpEvent.giftAttached,
      ], everyElement(startsWith('bp_')));
    });
  });

  group('CompositeAnalytics', () {
    test('meneruskan tiap panggilan ke semua tujuan, urut', () async {
      final first = _RecordingAnalytics();
      final second = _RecordingAnalytics();
      final composite = CompositeAnalytics(<Analytics>[first, second]);
      final opened = <String>[];

      await composite.start(
        onDeepLink: (value, {required deferred}) => opened.add(value),
      );
      await composite.setUserId('u-1');
      await composite.logEvent('af_login');

      const expected = <String>['start', 'user:u-1', 'event:af_login'];
      expect(first.calls, expected);
      expect(second.calls, expected);
      second.onDeepLink?.call('keranjang', deferred: false);
      expect(opened, <String>['keranjang']);
    });

    test('satu tujuan gagal tidak menghentikan yang lain', () async {
      final broken = _RecordingAnalytics(failing: true);
      final healthy = _RecordingAnalytics();
      final composite = CompositeAnalytics(<Analytics>[broken, healthy]);
      final previous = debugPrint;
      final printed = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) =>
          printed.add(message ?? '');
      addTearDown(() => debugPrint = previous);

      await composite.start();
      await composite.setUserId(null);
      await composite.logEvent('af_purchase');

      expect(healthy.calls, <String>[
        'start',
        'user:null',
        'event:af_purchase',
      ]);
      expect(printed, hasLength(3));
    });

    test('aktif bila salah satu tujuan aktif', () {
      final off = _RecordingAnalytics(enabled: false);
      final on = _RecordingAnalytics();
      expect(CompositeAnalytics(<Analytics>[off, on]).isEnabled, isTrue);
      expect(CompositeAnalytics(<Analytics>[off]).isEnabled, isFalse);
      expect(CompositeAnalytics(const <Analytics>[]).isEnabled, isFalse);
    });

    test('daftar tujuan tidak bisa diubah dari luar', () {
      final targets = <Analytics>[_RecordingAnalytics()];
      final composite = CompositeAnalytics(targets);
      targets.add(_RecordingAnalytics());
      expect(composite.targets, hasLength(1));
      expect(
        () => composite.targets.add(_RecordingAnalytics()),
        throwsUnsupportedError,
      );
    });
  });

  group('createAppsFlyerAnalytics', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('tanpa kunci: tidak ada AppsFlyer di platform mana pun', () {
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          createAppsFlyerAnalytics(devKey: ''),
          isNull,
          reason: '$platform',
        );
      }
    });

    test('dengan kunci: hanya Android dan iOS ber-ID App Store', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = createAppsFlyerAnalytics(devKey: 'kunci-uji');
      expect(android, isNotNull);
      expect(android?.isEnabled, isFalse, reason: 'belum dimulai');

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(createAppsFlyerAnalytics(devKey: 'kunci-uji'), isNull);
      expect(
        createAppsFlyerAnalytics(devKey: 'kunci-uji', iosAppId: '123456789'),
        isNotNull,
      );

      for (final platform in <TargetPlatform>[
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          createAppsFlyerAnalytics(devKey: 'kunci-uji', iosAppId: '123456789'),
          isNull,
          reason: '$platform',
        );
      }
    });
  });
}
