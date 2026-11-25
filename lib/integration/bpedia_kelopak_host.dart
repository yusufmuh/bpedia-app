/// Implementasi [KelopakHost] untuk app Bpedia: login, router, keranjang,
/// katalog, suara, pengingat, analitik, dan kotak masuk.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:kelopak_hub/kelopak_hub.dart'
    show
        CheckoutLine,
        GameCue,
        KelopakEvent,
        KelopakGameActions,
        KelopakHost,
        KelopakProduct,
        KelopakReminder;

import '../app/app_router.dart';
import '../data/auth/auth_repository.dart';
import '../data/cart/cart_repository.dart';
import '../data/catalog/catalog_repository.dart';
import '../data/inbox/inbox_repository.dart';
import '../data/settings/settings_repository.dart';
import '../services/analytics/analytics.dart';
import '../services/reminders/reminder_service.dart';
import '../services/sound/sound_service.dart';
import 'kelopak_event_bridge.dart';

/// Lebar dekode gambar produk di halaman hadiah (kartu dan lembar hasil).
const int kelopakProductImageWidth = 400;

/// Jeda jingle menang sesudah efek menang produk.
const Duration winJingleDelay = Duration(milliseconds: 700);

/// Host Kelopak di atas layanan app.
class BpediaKelopakHost extends KelopakHost implements KelopakGameActions {
  BpediaKelopakHost({
    required this.auth,
    required this.cart,
    required this.catalog,
    required this.settings,
    required this.router,
    required this.sound,
    required this.analytics,
    required this.inbox,
    required ReminderService reminders,
  }) : reminder = AppKelopakReminder(reminders),
       changes = Listenable.merge(<Listenable>[auth, cart]);

  final AuthRepository auth;
  final CartRepository cart;
  final CatalogRepository catalog;
  final SettingsRepository settings;
  final AppRouter router;
  final SoundService sound;
  final Analytics analytics;
  final InboxRepository inbox;

  @override
  final KelopakReminder reminder;

  @override
  final Listenable changes;

  final Map<String, KelopakProduct> _products = <String, KelopakProduct>{};
  Timer? _jingle;

  @override
  bool get isLoggedIn => auth.isLoggedIn;

  @override
  void openLogin() => _open(const LoginRoute());

  @override
  void openShop() => _open(const CatalogRoute());

  @override
  void openCart() => _open(const CartRoute());

  @override
  void openProduct(String productCode) => _open(ProductRoute(productCode));

  @override
  void openCheckout() => _open(const CheckoutRoute());

  @override
  void openOrder(String orderId) => _open(OrderDetailRoute(orderId));

  @override
  Future<bool> addToCart(String productCode, {int quantity = 1}) async {
    if (quantity < 1 || catalog.byCode(productCode) == null) return false;
    return cart.add(productCode, qty: quantity).added > 0;
  }

  @override
  Future<bool> setCartQuantity(String productCode, int quantity) async {
    if (catalog.byCode(productCode) == null) return false;
    final change = cart.setQty(productCode, quantity);
    return quantity < 1 || change.qty > 0;
  }

  @override
  List<CheckoutLine> get cartLines => <CheckoutLine>[
    for (final line in cart.pricedLines)
      CheckoutLine(
        productCode: line.productCode,
        unitPrice: line.unitPrice,
        quantity: line.quantity,
      ),
  ];

  @override
  KelopakProduct? productOf(String code) {
    final cached = _products[code];
    if (cached != null) return cached;
    final product = catalog.byCode(code);
    if (product == null) return null;
    return _products[code] = KelopakProduct(
      code: product.code,
      name: product.name,
      price: product.price,
      strikePrice: product.hasDiscount ? product.strikePrice : null,
      image: ResizeImage(
        AssetImage(product.primaryImage),
        width: kelopakProductImageWidth,
      ),
    );
  }

  @override
  bool? get soundOn => settings.soundOn;

  @override
  void setSoundOn(bool value) => settings.setSoundOn(value);

  @override
  void playCue(GameCue cue) {
    final cues = soundCuesFor(cue);
    // Game memberi getar sendiri lewat kit, jadi cue app tanpa getar.
    sound.play(cues.first, withHaptic: false);
    if (cues.length < 2) return;
    final rest = cues.sublist(1);
    _jingle?.cancel();
    if (sound.isSilent) {
      for (final next in rest) {
        sound.play(next, withHaptic: false);
      }
      return;
    }
    _jingle = Timer(winJingleDelay, () {
      for (final next in rest) {
        sound.play(next, withHaptic: false);
      }
    });
  }

  @override
  void onEvent(KelopakEvent event) =>
      recordKelopakEvent(event, analytics: analytics, inbox: inbox);

  /// Membatalkan jingle yang belum berbunyi.
  void dispose() {
    _jingle?.cancel();
    _jingle = null;
  }

  void _open(AppRoute route) => router.openLocation(route.location);
}

/// "Ingatkan saya" Roda Sabtu di atas [ReminderService] app
/// (`wheelReminder`, Sabtu 09.00 WIB).
class AppKelopakReminder implements KelopakReminder {
  AppKelopakReminder(this._reminders);

  final ReminderService _reminders;

  @override
  bool get isSupported => _reminders.isSupported;

  @override
  Future<bool> isEnabled() => _reminders.isScheduled(wheelReminder.id);

  @override
  Future<bool> setEnabled(bool enabled) async {
    if (!enabled) {
      await _reminders.cancel(wheelReminder.id);
      return false;
    }
    final result = await _reminders.scheduleWeekly(wheelReminder);
    return result == ReminderResult.scheduled;
  }
}
