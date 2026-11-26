/// Penyambung app Bpedia dengan zona Hadiah Kelopak (RENCANA §10):
/// pembuat gateway, rute `/hadiah/*` + tab Hadiah, dan pembungkus navigator.
///
/// ```dart
/// runBpediaApp(
///   routes: [..., registerKelopakRoutes],
///   rewardsBuilder: buildKelopakRewards,
///   configure: attachKelopak,
/// );
/// ```
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kelopak_hub/kelopak_hub.dart' as hub;

import '../app/app_router.dart';
import '../app/app_scope.dart';
import '../app/app_services.dart';
import '../app/shell.dart' show CartButton;
import '../config/demo_campaign.dart';
import '../data/rewards/rewards_gateway.dart';
import '../features/catalog/shop_common.dart' show InboxButton;
import '../platform/browser.dart';
import '../services/sound/sound_service.dart';
import 'bpedia_kelopak_host.dart';
import 'kelopak_rewards_gateway.dart';

/// Membuat gateway Kelopak di atas [services] tanpa memuat data; panggil
/// `controller.load()` sesudahnya. Data Kelopak disimpan di penyimpanan app
/// ([store] menggantinya, untuk tes). [random] mengganti pengundi roda
/// (tes). [watchDayChange] false di tes widget (tanpa timer 00.00 WIB).
KelopakRewardsGateway createKelopakGateway(
  AppServices services, {
  hub.KeyValueStore? store,
  Random? random,
  bool watchDayChange = true,
}) {
  final host = BpediaKelopakHost(
    auth: services.auth,
    cart: services.cart,
    catalog: services.catalog,
    settings: services.settings,
    router: services.router,
    sound: services.sound,
    analytics: services.analytics,
    inbox: services.inbox,
    reminders: services.reminders,
  );
  final controller = hub.KelopakController(
    backend: hub.LocalKelopakBackend(
      store: store ?? services.store,
      campaign: buildDemoCampaign(services.catalog.products),
      random: random,
    ),
    clock: services.clock,
    host: host,
    watchDayChange: watchDayChange,
  );
  return KelopakRewardsGateway(
    controller: controller,
    auth: services.auth,
    catalog: services.catalog,
    promo: services.promo,
    router: services.router,
    sound: services.sound,
    demoClock: services.demoClock,
  );
}

/// `rewardsBuilder` untuk `runBpediaApp`: membuat gateway lalu memuat data
/// Kelopak. Pemuatan pertama memindahkan data v2 (`bpedia_preview_state_v1`:
/// saldo, riwayat, rentetan, putaran, voucher, hak produk) bila dokumen v3
/// belum ada.
Future<RewardsGateway> buildKelopakRewards(AppServices services) async {
  final gateway = createKelopakGateway(services);
  try {
    await gateway.controller.load();
  } on hub.KelopakBackendException {
    // Data Kelopak tak terbaca: zona Hadiah mulai kosong, app tetap jalan.
  }
  return gateway;
}

/// `configure` untuk `runBpediaApp`: memasang `KelopakScope` dan navigasi
/// hub di atas navigator app. Tanpa gateway Kelopak tidak berbuat apa-apa.
void attachKelopak(AppServices services) {
  final gateway = services.rewards;
  if (gateway is! KelopakRewardsGateway) return;
  services.navigatorWrapper = (context, navigator) => KelopakRoot(
    controller: gateway.controller,
    router: services.router,
    child: navigator ?? const SizedBox.shrink(),
  );
}

/// Mendaftarkan tab Hadiah dan halaman `/hadiah/*`.
void registerKelopakRoutes(AppRouter router) {
  router
    ..registerTab(
      AppTab.rewards,
      (context) => const KelopakMusic(
        child: hub.RewardsHubPage(
          actions: <Widget>[
            InboxButton(color: Color(0xFFFFFFFF)),
            CartButton(color: Color(0xFFFFFFFF)),
          ],
        ),
      ),
    )
    ..register<CheckInRoute>(
      (context, route) => const KelopakMusic(child: hub.KelopakCheckInScreen()),
    )
    ..register<WheelRoute>(
      (context, route) => const KelopakMusic(
        asset: bgmWheelAsset,
        child: hub.KelopakWheelScreen(),
      ),
    )
    ..register<MissionRoute>(
      (context, route) => const KelopakMusic(child: hub.KelopakMissionScreen()),
    )
    ..register<MyGiftsRoute>(
      (context, route) => const KelopakMusic(child: hub.MyGiftsPage()),
    )
    ..register<VouchersRoute>(
      (context, route) => const KelopakMusic(child: hub.VouchersPage()),
    )
    ..register<LedgerRoute>(
      (context, route) => const KelopakMusic(child: hub.LedgerPage()),
    );
}

/// Akar Kelopak di atas navigator app: `KelopakScope`, navigasi hub lewat
/// router app, pembaruan hari saat app kembali ke depan, dan sinkron antartab
/// di web.
class KelopakRoot extends StatefulWidget {
  const KelopakRoot({
    required this.controller,
    required this.router,
    required this.child,
    super.key,
  });

  final hub.KelopakController controller;
  final AppRouter router;
  final Widget child;

  @override
  State<KelopakRoot> createState() => _KelopakRootState();
}

class _KelopakRootState extends State<KelopakRoot> {
  late final AppLifecycleListener _lifecycle;
  void Function()? _stopWatch;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _watch(widget.controller);
  }

  @override
  void didUpdateWidget(KelopakRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _stopWatch?.call();
      _watch(widget.controller);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _stopWatch?.call();
    super.dispose();
  }

  void _watch(hub.KelopakController controller) {
    _stopWatch = watchBrowserStorageKey(
      hub.kelopakDocumentKey,
      () => unawaited(_sync(controller)),
    );
  }

  Future<void> _sync(hub.KelopakController controller) async {
    try {
      await controller.syncFromStore();
    } on hub.KelopakBackendException {
      // Tab lain menyimpan data rusak: data sesi ini tetap dipakai.
    }
  }

  void _onResume() {
    widget.controller.refreshDay();
    unawaited(_sync(widget.controller));
  }

  void _open(BuildContext context, String location) =>
      widget.router.openLocation(location);

  @override
  Widget build(BuildContext context) => hub.KelopakScope(
    controller: widget.controller,
    child: hub.KelopakNavigation(open: _open, child: widget.child),
  );
}

/// Musik latar selama [child] terlihat (zona Hadiah: jingle Bpedia; Roda
/// Sabtu: [bgmWheelAsset]). Berhenti saat halaman tertutup halaman lain,
/// tab berganti, atau halaman ditutup; tetap mengikuti pengaturan Suara dan
/// Musik di `SoundService`.
class KelopakMusic extends StatefulWidget {
  const KelopakMusic({required this.child, this.asset = bgmAsset, super.key});

  final String asset;
  final Widget child;

  @override
  State<KelopakMusic> createState() => _KelopakMusicState();
}

class _KelopakMusicState extends State<KelopakMusic> {
  ValueListenable<TickerModeData>? _visible;
  SoundService? _sound;
  String? _holding;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sound ??= AppScope.of(context).sound;
    final visible = TickerMode.getValuesNotifier(context);
    if (!identical(visible, _visible)) {
      _visible?.removeListener(_sync);
      _visible = visible..addListener(_sync);
    }
    _sync();
  }

  @override
  void didUpdateWidget(KelopakMusic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _sync();
  }

  @override
  void dispose() {
    _visible?.removeListener(_sync);
    _release();
    super.dispose();
  }

  void _sync() {
    final want = (_visible?.value.enabled ?? false) ? widget.asset : null;
    if (want == _holding) return;
    _release();
    if (want != null) {
      _sound?.startMusic(asset: want);
      _holding = want;
    }
  }

  void _release() {
    final holding = _holding;
    if (holding == null) return;
    _sound?.stopMusic(asset: holding);
    _holding = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
