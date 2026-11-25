/// Lapisan analitik app (KEPUTUSAN §7). Layar dan repositori hanya mengenal
/// antarmuka [Analytics], bukan SDK.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Nama event standar AppsFlyer yang dipakai app.
abstract final class AfEvent {
  static const String login = 'af_login';
  static const String completeRegistration = 'af_complete_registration';
  static const String search = 'af_search';
  static const String contentView = 'af_content_view';
  static const String addToCart = 'af_add_to_cart';
  static const String addToWishlist = 'af_add_to_wishlist';
  static const String initiatedCheckout = 'af_initiated_checkout';
  static const String purchase = 'af_purchase';
}

/// Nama event khusus Bpedia (hadiah Kelopak).
abstract final class BpEvent {
  static const String checkInClaim = 'bp_checkin_claim';
  static const String wheelSpin = 'bp_wheel_spin';
  static const String missionComplete = 'bp_mission_complete';
  static const String voucherRedeem = 'bp_voucher_redeem';
  static const String kelopakRedeem = 'bp_kelopak_redeem';
  static const String giftAttached = 'bp_gift_attached';
}

/// Nama parameter event.
abstract final class AfParam {
  static const String revenue = 'af_revenue';
  static const String currency = 'af_currency';
  static const String orderId = 'af_order_id';
  static const String contentId = 'af_content_id';
  static const String contentType = 'af_content_type';
  static const String contentList = 'af_content_list';
  static const String price = 'af_price';
  static const String quantity = 'af_quantity';
  static const String searchString = 'af_search_string';
  static const String registrationMethod = 'af_registration_method';
  static const String loginMethod = 'bp_login_method';
  static const String kelopak = 'bp_kelopak';
  static const String voucherId = 'bp_voucher_id';
  static const String giftCount = 'bp_gift_count';
}

/// Dipanggil saat tautan OneLink membuka app. [deepLinkValue] adalah lokasi
/// rute (contoh `hadiah/roda`); [deferred] true untuk tautan yang dibuka
/// sebelum app terpasang.
typedef DeepLinkHandler =
    void Function(String deepLinkValue, {required bool deferred});

/// Pencatat event. Implementasi tidak pernah melempar ke pemanggil.
abstract interface class Analytics {
  /// False bila tidak ada tujuan aktif (tanpa kunci atau platform tak didukung).
  bool get isEnabled;

  /// Menyiapkan SDK dan mulai melaporkan sesi. Aman dipanggil berulang.
  Future<void> start({DeepLinkHandler? onDeepLink});

  /// ID pelanggan; null saat keluar.
  Future<void> setUserId(String? userId);

  /// Mencatat event [name] dengan [values].
  Future<void> logEvent(String name, [Map<String, Object?> values]);
}

/// Bantuan bertipe supaya nama event dan parameter tidak ditulis ulang.
extension CommerceEvents on Analytics {
  /// `af_login` dengan cara masuk ("password", "google").
  Future<void> logLogin({required String method}) =>
      logEvent(AfEvent.login, <String, Object?>{AfParam.loginMethod: method});

  /// `af_complete_registration`.
  Future<void> logRegistration({required String method}) => logEvent(
    AfEvent.completeRegistration,
    <String, Object?>{AfParam.registrationMethod: method},
  );

  /// `af_search`.
  Future<void> logSearch(String query) =>
      logEvent(AfEvent.search, <String, Object?>{AfParam.searchString: query});

  /// `af_content_view` (dipanggil layar detail produk).
  Future<void> logContentView({
    required String productCode,
    required String category,
    required int price,
  }) => logEvent(AfEvent.contentView, <String, Object?>{
    AfParam.contentId: productCode,
    AfParam.contentType: category,
    AfParam.price: price,
    AfParam.currency: 'IDR',
  });

  /// `af_add_to_cart`.
  Future<void> logAddToCart({
    required String productCode,
    required String category,
    required int price,
    required int quantity,
  }) => logEvent(AfEvent.addToCart, <String, Object?>{
    AfParam.contentId: productCode,
    AfParam.contentType: category,
    AfParam.price: price,
    AfParam.quantity: quantity,
    AfParam.currency: 'IDR',
  });

  /// `af_add_to_wishlist`.
  Future<void> logAddToWishlist({
    required String productCode,
    required String category,
    required int price,
  }) => logEvent(AfEvent.addToWishlist, <String, Object?>{
    AfParam.contentId: productCode,
    AfParam.contentType: category,
    AfParam.price: price,
    AfParam.currency: 'IDR',
  });

  /// `af_initiated_checkout` (dipanggil layar checkout saat dibuka).
  Future<void> logInitiatedCheckout({
    required List<String> productCodes,
    required int total,
    required int itemCount,
  }) => logEvent(AfEvent.initiatedCheckout, <String, Object?>{
    AfParam.contentList: productCodes,
    AfParam.price: total,
    AfParam.quantity: itemCount,
    AfParam.currency: 'IDR',
  });

  /// `af_purchase`. [paid] adalah jumlah yang benar-benar dibayar setelah
  /// voucher dan Kelopak; AppsFlyer menghitung `af_revenue` sebagai pendapatan
  /// dan menolak pemisah ribuan maupun simbol mata uang.
  Future<void> logPurchase({
    required String orderId,
    required int paid,
    required List<String> productCodes,
    required int itemCount,
  }) => logEvent(AfEvent.purchase, <String, Object?>{
    AfParam.revenue: paid,
    AfParam.currency: 'IDR',
    AfParam.orderId: orderId,
    AfParam.contentList: productCodes,
    AfParam.quantity: itemCount,
  });
}

/// Satu event yang tercatat secara lokal.
final class AnalyticsRecord {
  const AnalyticsRecord({
    required this.name,
    required this.values,
    required this.at,
  });

  /// Nama event.
  final String name;

  /// Parameter event.
  final Map<String, Object?> values;

  /// Waktu pencatatan.
  final DateTime at;
}

/// Pencatat lokal: menyimpan [capacity] event terakhir di memori untuk Mode
/// Demo dan tes. Tidak mengirim apa pun ke luar perangkat.
class LocalAnalytics extends ChangeNotifier implements Analytics {
  LocalAnalytics({this.capacity = 200, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Jumlah event yang disimpan.
  final int capacity;

  final DateTime Function() _now;
  final List<AnalyticsRecord> _records = <AnalyticsRecord>[];
  String? _userId;
  DeepLinkHandler? _onDeepLink;
  bool _started = false;

  /// Event tercatat, terbaru lebih dulu.
  List<AnalyticsRecord> get records =>
      List<AnalyticsRecord>.unmodifiable(_records.reversed);

  /// Nama event tercatat, terlama lebih dulu.
  List<String> get eventNames => <String>[
    for (final record in _records) record.name,
  ];

  /// ID pelanggan yang terakhir diset.
  String? get userId => _userId;

  /// Apakah [start] sudah dipanggil.
  bool get isStarted => _started;

  @override
  bool get isEnabled => true;

  @override
  Future<void> start({DeepLinkHandler? onDeepLink}) async {
    _started = true;
    _onDeepLink = onDeepLink ?? _onDeepLink;
  }

  @override
  Future<void> setUserId(String? userId) async {
    _userId = userId;
  }

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) async {
    _records.add(
      AnalyticsRecord(
        name: name,
        values: Map<String, Object?>.unmodifiable(values),
        at: _now(),
      ),
    );
    if (_records.length > capacity) {
      _records.removeRange(0, _records.length - capacity);
    }
    notifyListeners();
  }

  /// Mengosongkan log.
  void clear() {
    if (_records.isEmpty) return;
    _records.clear();
    notifyListeners();
  }

  /// Meniru tautan OneLink yang membuka app (Mode Demo dan tes).
  void simulateDeepLink(String deepLinkValue, {bool deferred = false}) =>
      _onDeepLink?.call(deepLinkValue, deferred: deferred);
}

/// Meneruskan tiap panggilan ke semua [targets]; kegagalan satu tujuan tidak
/// menghentikan yang lain.
class CompositeAnalytics implements Analytics {
  CompositeAnalytics(List<Analytics> targets)
    : targets = List<Analytics>.unmodifiable(targets);

  /// Tujuan, urut pemanggilan.
  final List<Analytics> targets;

  @override
  bool get isEnabled => targets.any((target) => target.isEnabled);

  @override
  Future<void> start({DeepLinkHandler? onDeepLink}) =>
      _each((target) => target.start(onDeepLink: onDeepLink));

  @override
  Future<void> setUserId(String? userId) =>
      _each((target) => target.setUserId(userId));

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) => _each((target) => target.logEvent(name, values));

  Future<void> _each(Future<void> Function(Analytics target) action) async {
    for (final target in targets) {
      try {
        await action(target);
      } on Object catch (error) {
        debugPrint('Analitik gagal: $error');
      }
    }
  }
}
