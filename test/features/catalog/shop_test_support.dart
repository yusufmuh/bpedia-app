/// Bantuan tes layar jelajah (F1): layanan uji dengan rute F1 terdaftar,
/// gateway hadiah palsu yang menampilkan strip dompet dan strip game, dan
/// pemasang aplikasi.
library;

import 'dart:async';

import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/address/address_repository.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/design/design.dart';
import 'package:bpedia_app/features/shop_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;

import '../../support/shot.dart';

/// Produk Hot Item nyata (periode 25 Nov 2026).
const String hotCode = 'P39A06S01000052';

/// Produk biasa dengan dua foto.
const String plainCode = 'P68B13S01000010';

/// Lebar ponsel sempit untuk uji huruf 200%.
const Size narrowPhone = Size(360, 760);

/// Gateway palsu: hadiah tersedia, saldo dan voucher contoh, produk misi,
/// dan strip sederhana pengganti widget tanam hub.
class FakeShopRewards extends NoRewardsGateway {
  FakeShopRewards({
    this.missionCodes = const <String>{},
    this.claimable = true,
  });

  final Set<String> missionCodes;
  bool claimable;
  final List<String> claims = <String>[];

  @override
  bool get available => true;

  @override
  int get kelopakBalance => 128;

  @override
  int get voucherCount => 2;

  @override
  bool hasBadge(RewardsEntry entry) =>
      entry == RewardsEntry.checkIn || entry == RewardsEntry.hub;

  @override
  Set<String> get missionProductCodes => missionCodes;

  @override
  bool canClaimPromoVoucher(String promoId) => claimable;

  @override
  Future<CommitResult> claimPromoVoucher({
    required String promoId,
    required int amount,
    required int minSpend,
    required int validDays,
  }) async {
    claims.add(promoId);
    claimable = false;
    notifyListeners();
    return const CommitResult(ok: true);
  }

  @override
  Widget? buildWalletStrip(BuildContext context) =>
      const _FakeWallet(key: ValueKey<String>('fake-dompet'));

  @override
  Widget? buildGameStrip(BuildContext context) =>
      const _FakeGameStrip(key: ValueKey<String>('fake-game'));
}

class _FakeWallet extends StatelessWidget {
  const _FakeWallet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    Widget cell(String icon, String title, String caption) => Expanded(
      child: Row(
        children: <Widget>[
          AssetPicture(
            'assets/icons3d/$icon.webp',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            showSkeleton: false,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: BpText.bodyS.copyWith(
                    color: c.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(caption, style: BpText.label.copyWith(color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(BpSpace.x2),
      decoration: BoxDecoration(
        color: c.goldTint,
        borderRadius: BpRadius.cardAll,
      ),
      child: Row(
        children: <Widget>[
          cell('kelopak', '128 Kelopak', 'senilai Rp12.800'),
          cell('voucher', '2 voucher', 'siap dipakai'),
          cell('hadiah', '1 hadiah', 'menunggu'),
        ],
      ),
    );
  }
}

class _FakeGameStrip extends StatelessWidget {
  const _FakeGameStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      margin: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[BpFest.festTop, BpFest.festMid, BpFest.festBottom],
        ),
      ),
      child: Row(
        children: <Widget>[
          const BipySprite(BipySprites.walk, height: 110),
          Expanded(
            child: Text(
              'Main bareng Bipy',
              style: BpText.title.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layanan uji dengan rute F1 terdaftar. Flyer hari ini ditandai sudah tampil
/// kecuali [showFlyer].
AppServices shopServices({
  bool dark = false,
  bool loggedIn = false,
  RewardsGateway? rewards,
  bool showFlyer = false,
  DateTime? now,
}) {
  final gateway = rewards;
  final services = AppServices.forTest(
    now: now,
    loggedIn: loggedIn,
    rewardsBuilder: gateway == null ? null : (_) => gateway,
  );
  services.settings.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
  if (!showFlyer) services.promo.markFlyerShown();
  registerShopRoutes(services.router);
  // dispose() menunggu I/O sungguhan yang tidak selesai di jam palsu.
  addTearDown(() => unawaited(services.dispose()));
  return services;
}

/// Membuat satu pesanan Menunggu pembayaran dari isi keranjang.
Future<void> placeUnpaidOrder(AppServices services, String code) async {
  services.addresses.add(
    const AddressDraft(
      label: 'Rumah',
      recipient: 'Sari Dewi',
      phone: '081234567890',
      street: 'Jl. Melati No. 12',
      district: 'Coblong',
      city: 'Bandung',
      province: 'Jawa Barat',
      postalCode: '40132',
    ),
  );
  services.cart.add(code);
  final shipping = services.shipping
      .options(
        weightGrams: services.cart.selectedWeightGrams,
        goodsSubtotal: services.cart.selectedSubtotal,
      )
      .first;
  await services.orders.place(
    OrderDraft(
      items: services.cart.selectedItems,
      address: services.addresses.primary,
      shipping: shipping,
      payment: PaymentCatalog.byId('qris'),
      quote: services.rewards.quote(
        CheckoutRequest(
          lines: services.cart.linesForCheckout,
          shippingFee: shipping.fee,
          useKelopak: false,
        ),
      ),
    ),
  );
}

/// Memasang app di [location] dengan ukuran [size] dan skala huruf
/// [textScale]. Tidak menunggu animasi selesai (sprite berulang).
Future<void> pumpShop(
  WidgetTester tester,
  AppServices services,
  String location, {
  Size size = shotPhone,
  double textScale = 1,
}) async {
  await loadShotFonts(tester);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(
    BpediaApp(services: services, initialLocation: location),
  );
  await settle(tester);
}

/// Beberapa bingkai supaya transisi selesai tanpa menunggu animasi berulang.
Future<void> settle(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
