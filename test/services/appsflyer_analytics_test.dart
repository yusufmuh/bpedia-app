import 'dart:convert';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:bpedia_app/services/analytics/appsflyer_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sisi native AppsFlyer tiruan: mencatat RPC dan bisa mengirim event.
class _FakeNative {
  _FakeNative(String name, {TargetPlatform platform = TargetPlatform.android})
    : _methods = MethodChannel('$name-api'),
      _events = EventChannel('$name-events') {
    sdk = AppsFlyerSdk.private(_methods, _events, platform: platform);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_methods, (call) async {
      final arguments = (call.arguments as Map<Object?, Object?>)
          .cast<String, Object?>();
      final method = arguments['method']! as String;
      rpcs.add(method);
      params[method] = (arguments['params']! as Map<Object?, Object?>)
          .cast<String, Object?>();
      if (failing.contains(method)) {
        throw PlatformException(code: 'AF_ERROR', message: method);
      }
      return null;
    });
    messenger.setMockStreamHandler(
      _events,
      MockStreamHandler.inline(onListen: (_, sink) => _sink = sink),
    );
  }

  final MethodChannel _methods;
  final EventChannel _events;
  late final AppsFlyerSdk sdk;
  final List<String> rpcs = <String>[];
  final Map<String, Map<String, Object?>> params =
      <String, Map<String, Object?>>{};
  final Set<String> failing = <String>{};
  MockStreamHandlerEventSink? _sink;

  void emit(String event, [Map<String, Object?> data = const {}]) => _sink!
      .success(jsonEncode(<String, Object?>{'event': event, 'data': data}));

  void dispose() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_methods, null);
    messenger.setMockStreamHandler(_events, null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var channelSeq = 0;
  late _FakeNative native;
  late List<String> printed;
  late DebugPrintCallback previousPrint;

  _FakeNative createNative({TargetPlatform platform = TargetPlatform.android}) {
    final created = _FakeNative('af-uji-${channelSeq++}', platform: platform);
    addTearDown(created.dispose);
    return created;
  }

  setUp(() {
    native = createNative();
    printed = <String>[];
    previousPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) =>
        printed.add(message ?? '');
  });

  tearDown(() => debugPrint = previousPrint);

  AppsFlyerAnalytics create({String iosAppId = '', bool debug = false}) =>
      AppsFlyerAnalytics(
        devKey: 'kunci-uji',
        iosAppId: iosAppId,
        debug: debug,
        sdk: native.sdk,
      );

  test('urutan mulai SDK 7: deep link, init, setelan, sesi-siap', () async {
    final analytics = create();
    expect(analytics.isEnabled, isFalse);

    await analytics.start();

    expect(native.rpcs, <String>[
      'subscribeForDeepLink',
      'init',
      'setCurrencyCode',
      'setDisableAdvertisingIdentifiers',
      'registerSessionReadyListener',
    ]);
    expect(native.params['init'], <String, Object?>{'devKey': 'kunci-uji'});
    expect(native.params['setCurrencyCode'], <String, Object?>{
      'currencyCode': 'IDR',
    });
    expect(native.params['setDisableAdvertisingIdentifiers'], <String, Object?>{
      'isDisable': true,
    });
    expect(analytics.isEnabled, isTrue);
    expect(printed, isEmpty);
  });

  test('start kedua tidak mengulang init', () async {
    final analytics = create();
    await analytics.start();
    final count = native.rpcs.length;

    await analytics.start();

    expect(native.rpcs, hasLength(count));
  });

  test('sesi dimulai tiap kali SDK melaporkan siap', () async {
    final analytics = create();
    await analytics.start();
    expect(native.rpcs, isNot(contains('start')));

    native.emit('onSessionReady');
    await pumpEventQueue();
    native.emit('onSessionReady');
    await pumpEventQueue();

    expect(native.rpcs.where((rpc) => rpc == 'start'), hasLength(2));
  });

  test('iOS mengirim ID App Store saat init', () async {
    native = createNative(platform: TargetPlatform.iOS);
    await create(iosAppId: '6751265630').start();

    expect(native.rpcs.first, 'registerDeeplinkListener');
    expect(native.params['init'], <String, Object?>{
      'devKey': 'kunci-uji',
      'appId': '6751265630',
    });
    expect(native.params['setDisableAdvertisingIdentifiers'], <String, Object?>{
      'disable': true,
    });
  });

  test('tautan ditemukan diteruskan; selain itu diabaikan', () async {
    final opened = <String>[];
    await create().start(
      onDeepLink: (value, {required deferred}) =>
          opened.add('$value|$deferred'),
    );

    native.emit('onDeepLinking', <String, Object?>{
      'status': 'FOUND',
      'deepLink': <String, Object?>{
        'deep_link_value': 'hadiah/roda',
        'is_deferred': false,
      },
    });
    native.emit('onDeepLinking', <String, Object?>{
      'status': 'FOUND',
      'deepLink': <String, Object?>{
        'deep_link_value': 'produk/P39A06S01000052',
        'is_deferred': true,
      },
    });
    native.emit('onDeepLinking', <String, Object?>{'status': 'NOT_FOUND'});
    native.emit('onDeepLinking', <String, Object?>{
      'status': 'FOUND',
      'deepLink': <String, Object?>{'deep_link_value': ''},
    });
    native.emit('onDeepLinking', <String, Object?>{
      'status': 'ERROR',
      'error': 'TIMEOUT',
    });
    await pumpEventQueue();

    expect(opened, <String>[
      'hadiah/roda|false',
      'produk/P39A06S01000052|true',
    ]);
  });

  test('event dan ID pelanggan sebelum mulai tidak dikirim', () async {
    final analytics = create();

    await analytics.logEvent('af_login');
    await analytics.setUserId('u-1');
    expect(native.rpcs, isEmpty);

    await analytics.start();
    expect(native.rpcs, contains('setCustomerUserId'));
    expect(
      native.rpcs.indexOf('setCustomerUserId'),
      greaterThan(native.rpcs.indexOf('init')),
    );
    expect(native.params['setCustomerUserId'], <String, Object?>{
      'customerId': 'u-1',
    });
    expect(native.rpcs, isNot(contains('logEvent')));
  });

  test('event setelah mulai dikirim dengan nama dan nilainya', () async {
    final analytics = create();
    await analytics.start();

    await analytics.logEvent('af_purchase', <String, Object?>{
      'af_revenue': 51500,
      'af_currency': 'IDR',
    });
    await analytics.setUserId('u-2');
    await analytics.setUserId(null);

    final event = native.params['logEvent']!;
    expect(event['eventName'], 'af_purchase');
    expect(event['eventValues'], <String, Object?>{
      'af_revenue': 51500,
      'af_currency': 'IDR',
    });
    expect(
      native.rpcs.where((rpc) => rpc == 'setCustomerUserId'),
      hasLength(1),
      reason: 'keluar tidak mengirim ID kosong',
    );
  });

  test('init gagal: tidak aktif, tidak melempar, event dibuang', () async {
    native.failing.add('init');
    final analytics = create();

    await analytics.start();
    await analytics.logEvent('af_login');

    expect(analytics.isEnabled, isFalse);
    expect(native.rpcs, isNot(contains('logEvent')));
    expect(printed.single, contains('AppsFlyer start gagal'));
  });

  test('logEvent gagal tidak sampai ke pemanggil', () async {
    final analytics = create();
    await analytics.start();
    native.failing.add('logEvent');

    await analytics.logEvent('af_search');

    expect(analytics.isEnabled, isTrue);
    expect(printed.single, contains('logEvent(af_search)'));
  });

  test('tanpa sisi native (plugin tidak terpasang): tidak melempar', () async {
    native.dispose();
    final analytics = create();

    await analytics.start();
    await analytics.logEvent('af_login');

    expect(analytics.isEnabled, isFalse);
    expect(printed, isNotEmpty);
  });

  test('kunci tidak pernah ikut tercetak di log kegagalan', () async {
    native.failing.add('init');
    await create().start();

    expect(printed.join('\n'), isNot(contains('kunci-uji')));
  });
}
