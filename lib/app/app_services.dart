/// Akar komposisi app: semua repositori dan layanan dibuat dan disambungkan
/// di sini. Layar mengambilnya lewat `AppScope.of(context)`.
library;

import 'dart:async';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter/widgets.dart' show TransitionBuilder;
import 'package:kelopak_hub/kelopak_hub.dart'
    show KeyValueStore, MemoryKeyValueStore, WibClock;

import '../config/app_config.dart';
import '../data/address/address_repository.dart';
import '../data/auth/auth_repository.dart';
import '../data/cart/cart_repository.dart';
import '../data/catalog/catalog_repository.dart';
import '../data/demo/demo_clock_repository.dart';
import '../data/inbox/inbox_repository.dart';
import '../data/orders/order_repository.dart';
import '../data/promo/promo_repository.dart';
import '../data/rewards/rewards_gateway.dart';
import '../data/search/search_history_repository.dart';
import '../data/settings/settings_repository.dart';
import '../data/shipping/shipping_repository.dart';
import '../data/storage/app_document.dart';
import '../data/storage/document_repository.dart';
import '../data/storage/shared_preferences_store.dart';
import '../data/wishlist/wishlist_repository.dart';
import '../platform/browser.dart';
import '../platform/test_assets.dart';
import '../services/analytics/analytics.dart';
import '../services/analytics/create_analytics.dart';
import '../services/links.dart';
import '../services/reminders/create_reminder_service.dart';
import '../services/reminders/reminder_service.dart';
import '../services/sound/haptics.dart';
import '../services/sound/sound_service.dart';
import 'app_router.dart';

/// Membuat gateway hadiah di atas layanan app. Dipanggil setelah katalog dan
/// promo dimuat dan semua layanan lain siap, kecuali `orders` (yang
/// membutuhkan gateway): pembangun tidak boleh menyentuh `services.orders`
/// saat dipanggil. Data tersimpan dimuat sesudahnya.
typedef RewardsBuilder =
    FutureOr<RewardsGateway> Function(AppServices services);

/// Padanan sinkron [RewardsBuilder] untuk [AppServices.forTest].
typedef SyncRewardsBuilder = RewardsGateway Function(AppServices services);

/// Semua repositori dan layanan app.
class AppServices {
  AppServices._({
    required this.clock,
    required KeyValueStore store,
    required Duration saveDelay,
    required this.analyticsLog,
    required Analytics? appsFlyer,
    required this.sound,
    required this.reminders,
    required this.links,
  }) : document = AppDocument(store: store, saveDelay: saveDelay),
       _appsFlyer = appsFlyer,
       analytics = appsFlyer == null
           ? analyticsLog
           : CompositeAnalytics(<Analytics>[analyticsLog, appsFlyer]),
       settings = SettingsRepository(),
       demoClock = DemoClockRepository(clock: clock),
       catalog = CatalogRepository(),
       addresses = AddressRepository(),
       inbox = InboxRepository(clock: clock),
       promo = PromoRepository(clock: clock),
       shipping = const ShippingRepository(),
       router = AppRouter() {
    _localAuth = LocalAuthRepository(
      analytics: analytics,
      now: () => clock.instant,
    );
    cart = CartRepository(catalog: catalog, analytics: analytics);
    wishlist = WishlistRepository(catalog: catalog, analytics: analytics);
    searchHistory = SearchHistoryRepository(analytics: analytics);
    router.isLoggedIn = () => auth.isLoggedIn;
    for (final repository in <DocumentRepository>[
      settings,
      demoClock,
      _localAuth,
      cart,
      addresses,
      wishlist,
      searchHistory,
      inbox,
      promo,
    ]) {
      repository.attach(document);
    }
    settings.addListener(_applySettings);
    _applySettings();
  }

  /// Layanan untuk perangkat: penyimpanan perangkat, aset dari [bundle],
  /// AppsFlyer bila kunci diberikan saat build, notifikasi lokal di
  /// Android/iOS. Tidak pernah melempar karena data tersimpan rusak.
  ///
  /// [attribution], [sound], dan [reminders] menggantikan layanan plugin
  /// (dipakai tes integrasi; di perangkat biarkan kosong).
  static Future<AppServices> bootstrap({
    AssetBundle? bundle,
    KeyValueStore? store,
    WibClock? clock,
    RewardsBuilder? rewardsBuilder,
    Analytics? attribution,
    SoundService? sound,
    ReminderService? reminders,
  }) async {
    final services = AppServices._(
      clock: clock ?? WibClock(),
      store: store ?? platformKeyValueStore(),
      saveDelay: const Duration(milliseconds: 300),
      analyticsLog: LocalAnalytics(),
      appsFlyer:
          attribution ??
          createAppsFlyerAnalytics(
            devKey: AppConfig.appsFlyerDevKey,
            iosAppId: AppConfig.appsFlyerIosAppId,
            debug: AppConfig.appsFlyerDebug,
          ),
      sound: sound ?? SoundService(),
      reminders: reminders ?? createReminderService(),
      links: Links(),
    );
    final assets = bundle ?? rootBundle;
    await services.catalog.load(assets);
    await services.promo.load(assets);
    services._attachRewards(
      await (rewardsBuilder ?? _noRewards)(services),
    );
    await services.load();
    services._stopStorageWatch = watchBrowserStorageKey(
      appDocumentKey,
      () => unawaited(services.document.syncFromStore()),
    );
    services._start();
    unawaited(services.sound.warmUp());
    return services;
  }

  /// Layanan untuk tes: penyimpanan memori, jam tetap ([now], bawaan
  /// [testNow]), suara senyap, pengingat memori, tautan yang selalu berhasil,
  /// tanpa AppsFlyer. Katalog dan promo dibaca dari berkas aset proyek
  /// (atau [catalogJson]/[promoJson]). Sinkron dan aman di `testWidgets`:
  /// tidak ada `Timer` maupun I/O tertunda.
  ///
  /// Data mulai bersih; panggil [load] untuk membaca isi [store].
  factory AppServices.forTest({
    DateTime? now,
    WibClock? clock,
    KeyValueStore? store,
    String? catalogJson,
    String? promoJson,
    SyncRewardsBuilder? rewardsBuilder,
    ReminderService? reminders,
    UriOpener? uriOpener,
    bool loggedIn = false,
  }) {
    final fixed = now ?? testNow;
    final wibClock = clock ?? WibClock(now: () => fixed);
    final services = AppServices._(
      clock: wibClock,
      store: store ?? MemoryKeyValueStore(),
      saveDelay: Duration.zero,
      analyticsLog: LocalAnalytics(now: () => wibClock.instant),
      appsFlyer: null,
      sound: SoundService.silent(),
      reminders: reminders ?? MemoryReminderService(),
      links: Links(opener: uriOpener ?? (_) async => true),
    );
    final catalogSource = catalogJson ?? readProjectFileSync(catalogAsset);
    if (catalogSource != null) services.catalog.loadFromJson(catalogSource);
    final promoSource = promoJson ?? readProjectFileSync(promoAsset);
    if (promoSource != null) services.promo.loadFromJson(promoSource);
    services._attachRewards((rewardsBuilder ?? _noRewards)(services));
    services._start();
    if (loggedIn) services.signInAsDemo();
    return services;
  }

  /// Waktu bawaan [AppServices.forTest]: Rabu, 25 Nov 2026, 10.00 WIB.
  static final DateTime testNow = DateTime.utc(2026, 11, 25, 3);

  /// Jam WIB (dengan geseran hari Mode Demo).
  final WibClock clock;

  /// Dokumen `bpedia_app_v3`.
  final AppDocument document;

  final SettingsRepository settings;
  final DemoClockRepository demoClock;
  final CatalogRepository catalog;
  late final CartRepository cart;
  final AddressRepository addresses;
  late final WishlistRepository wishlist;
  late final SearchHistoryRepository searchHistory;
  final InboxRepository inbox;
  final PromoRepository promo;
  final ShippingRepository shipping;

  /// Port hadiah Kelopak; bawaan [NoRewardsGateway].
  late final RewardsGateway rewards;
  late final OrderRepository orders;

  /// Pencatat event: log lokal, ditambah AppsFlyer bila aktif.
  final Analytics analytics;

  /// Log event lokal (200 terakhir) untuk Mode Demo.
  final LocalAnalytics analyticsLog;
  final SoundService sound;
  final ReminderService reminders;
  final Links links;
  final AppRouter router;

  /// Pembungkus navigator app, dipasang penyambung integrasi (mis.
  /// `KelopakScope` zona Hadiah) supaya halaman dan lembar di navigator bisa
  /// membacanya. Null = tanpa pembungkus.
  TransitionBuilder? navigatorWrapper;

  final Analytics? _appsFlyer;
  late final LocalAuthRepository _localAuth;
  void Function()? _stopStorageWatch;
  DocumentOrigin _origin = DocumentOrigin.fresh;
  bool _disposed = false;

  /// Akun (demo lokal).
  AuthRepository get auth => _localAuth;

  /// Penyimpanan kunci-nilai yang dipakai dokumen.
  KeyValueStore get store => document.store;

  /// Getar; mengikuti pengaturan "Getar".
  Haptics get haptics => sound.haptics;

  /// Asal data pada pemuatan terakhir.
  DocumentOrigin get origin => _origin;

  /// Apakah build ini membawa kunci AppsFlyer (Android/iOS saja).
  bool get appsFlyerConfigured => _appsFlyer != null;

  /// Apakah SDK AppsFlyer sudah berjalan.
  bool get appsFlyerEnabled => _appsFlyer?.isEnabled ?? false;

  /// Membaca dokumen tersimpan ke semua repositori, lalu membatalkan pesanan
  /// yang lewat batas bayar.
  Future<DocumentOrigin> load() async {
    _origin = await document.load();
    final userId = auth.profile?.id;
    if (userId != null) unawaited(analytics.setUserId(userId));
    await orders.cancelOverdue();
    return _origin;
  }

  /// Masuk seketika dengan profil contoh (Mode Demo dan tes).
  void signInAsDemo() => _localAuth.signInAsDemo();

  /// "Atur ulang data": semua data app kembali ke keadaan awal. Data Kelopak
  /// diatur ulang terpisah oleh gateway hadiah.
  Future<void> resetData() async {
    document.resetAll();
    analyticsLog.clear();
    router.selectTab(AppTab.home);
    await document.flush();
  }

  /// Menulis perubahan tertunda dan melepas semua layanan.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopStorageWatch?.call();
    settings.removeListener(_applySettings);
    await document.dispose();
    for (final repository in <DocumentRepository>[
      settings,
      demoClock,
      _localAuth,
      cart,
      addresses,
      wishlist,
      searchHistory,
      inbox,
      promo,
      orders,
    ]) {
      repository.dispose();
    }
    catalog.dispose();
    analyticsLog.dispose();
    rewards.dispose();
    router.dispose();
    await sound.dispose();
  }

  void _attachRewards(RewardsGateway gateway) {
    rewards = gateway;
    orders = OrderRepository(
      clock: clock,
      rewards: gateway,
      inbox: inbox,
      cart: cart,
      catalog: catalog,
      auth: auth,
      analytics: analytics,
    )..attach(document);
  }

  void _start() {
    unawaited(
      analytics.start(
        onDeepLink: (value, {required deferred}) => router.openLocation(value),
      ),
    );
    unawaited(reminders.init(onTap: router.openLocation));
  }

  void _applySettings() {
    sound
      ..soundOn = settings.soundOn
      ..musicOn = settings.musicOn;
    sound.haptics.enabled = settings.hapticsOn;
  }

  static RewardsGateway _noRewards(AppServices services) => NoRewardsGateway();
}
