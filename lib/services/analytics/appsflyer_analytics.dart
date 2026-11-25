/// [Analytics] di atas appsflyer_sdk 7.x.
///
/// Berkas ini hanya diimpor lewat `create_analytics_io.dart`, jadi tidak ikut
/// terkompilasi di web.
library;

import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'analytics.dart';

/// Urutan wajib SDK 7: daftar pendengar deep link, `init`, setelan sesi
/// pertama, lalu pendengar sesi-siap yang memanggil `start()` tiap kali app
/// kembali ke depan. Setelan tidak tersimpan antarproses, jadi diterapkan
/// ulang tiap mulai dingin.
class AppsFlyerAnalytics implements Analytics {
  AppsFlyerAnalytics({
    required this.devKey,
    required this.iosAppId,
    this.debug = false,
    AppsFlyerSdk? sdk,
  }) : _sdk = sdk ?? AppsFlyerSdk.instance;

  /// Kunci developer AppsFlyer (dari `--dart-define`).
  final String devKey;

  /// ID App Store; wajib di iOS.
  final String iosAppId;

  /// Log debug SDK.
  final bool debug;

  final AppsFlyerSdk _sdk;
  bool _started = false;
  bool _ready = false;
  String? _userId;

  @override
  bool get isEnabled => _ready;

  @override
  Future<void> start({DeepLinkHandler? onDeepLink}) async {
    if (_started) return;
    _started = true;
    await _guard('start', () async {
      if (debug) await _sdk.enableDebug(true);
      await _sdk.registerDeepLinkListener(
        onDeepLinking: (DeepLinkResult result) {
          if (result.status != DeepLinkStatus.found) return;
          final link = result.deepLink;
          final value = link?.deepLinkValue;
          if (value == null || value.isEmpty) return;
          onDeepLink?.call(value, deferred: link?.isDeferred ?? false);
        },
      );
      await _sdk.init(devKey: devKey, appId: iosAppId.isEmpty ? null : iosAppId);
      await _sdk.setCurrencyCode('IDR');
      // Demo tidak mengumpulkan ID iklan.
      await _sdk.setDisableAdvertisingIdentifiers(true);
      final userId = _userId;
      if (userId != null) await _sdk.setCustomerUserId(userId);
      await _sdk.registerSessionReadyListener(() {
        unawaited(_guard('sesi', _sdk.start));
      });
      _ready = true;
    });
  }

  @override
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    if (!_ready || userId == null) return;
    await _guard('setUserId', () => _sdk.setCustomerUserId(userId));
  }

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) async {
    if (!_ready) return;
    await _guard(
      'logEvent($name)',
      () => _sdk.logEvent(name, eventValues: Map<String, dynamic>.of(values)),
    );
  }

  /// Analitik tidak boleh menjatuhkan app: kegagalan hanya dicatat.
  Future<void> _guard(String label, Future<void> Function() action) async {
    try {
      await action();
    } on AppsFlyerException catch (error) {
      debugPrint('AppsFlyer $label gagal: $error');
    } on PlatformException catch (error) {
      debugPrint('AppsFlyer $label gagal: ${error.code}');
    } on MissingPluginException catch (error) {
      debugPrint('AppsFlyer $label tidak tersedia: ${error.message}');
    }
  }
}
