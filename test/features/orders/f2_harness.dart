/// Perlengkapan tes layar transaksi (F2): gateway hadiah palsu yang
/// mengikuti urutan hitung KEPUTUSAN §1, data contoh, dan pemasang app.
library;

import 'dart:async';

import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/address/address_repository.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/features/order_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart' show WibClock;

import '../../support/shot.dart';

/// Produk nyata dari `assets/catalog/catalog.json` (potret 25 Nov 2026).
const String sunscreen = 'P68B13S01000010'; // Rp46.196, stok 10
const String nightCream = 'P39A06S01000007'; // Rp26.000
const String hotDayCream = 'P39A06S01000052'; // Hot Item Rp10.000, maks. 1
const String facialWash = 'P39A06S01000021'; // Rp17.800, produk misi
const String giftLipgloss = 'P21P03C01000082'; // hadiah Roda Sabtu

/// Voucher palsu.
final class FakeVoucher {
  FakeVoucher({
    required this.id,
    required this.amount,
    required this.minSpend,
    this.title,
  });

  final String id;
  final int amount;
  final int minSpend;
  final String? title;
  String? usedBy;
}

/// Gateway hadiah palsu untuk tes dan tangkap layar F2. Hitungan mengikuti
/// KEPUTUSAN §1: subtotal → voucher → Kelopak (pecahan < Rp100 tetap dibayar)
/// → ongkir.
class FakeRewards extends RewardsGateway {
  FakeRewards({
    this.balance = 128,
    List<GiftLine>? gifts,
    List<FakeVoucher>? vouchers,
    Set<String>? missionCodes,
    this.missionTarget = 75000,
    this.celebrateMission = false,
  }) : _gifts =
           gifts ??
           const <GiftLine>[
             GiftLine(
               id: 'G1',
               productCode: giftLipgloss,
               name: 'Pinkflash Duo Lipgloss Pf-L13 - D02',
               sourceLabel: 'Roda Sabtu, 21 Nov',
             ),
           ],
       vouchers =
           vouchers ??
           <FakeVoucher>[
             FakeVoucher(
               id: 'V1',
               amount: 10000,
               minSpend: 100000,
               title: 'Voucher Misi Belanja',
             ),
             FakeVoucher(
               id: 'V2',
               amount: 12000,
               minSpend: 120000,
               title: 'Voucher 12.12',
             ),
           ],
       missionCodes = missionCodes ?? const <String>{facialWash, nightCream};

  int balance;
  final List<GiftLine> _gifts;
  final List<FakeVoucher> vouchers;
  final Set<String> missionCodes;
  final int missionTarget;
  final bool celebrateMission;
  final Map<String, FakeCommit> commits = <String, FakeCommit>{};
  int celebrations = 0;

  Set<String> get _attached => <String>{
    for (final commit in commits.values) ...commit.giftIds,
  };

  @override
  bool get available => true;

  @override
  int get kelopakBalance => balance;

  @override
  int get voucherCount => vouchers.where((v) => v.usedBy == null).length;

  @override
  List<GiftLine> get pendingGifts => <GiftLine>[
    for (final gift in _gifts)
      if (!_attached.contains(gift.id)) gift,
  ];

  @override
  bool hasBadge(RewardsEntry entry) => false;

  @override
  Set<String> get missionProductCodes => missionCodes;

  @override
  MissionHint? missionHintFor(List<PricedLine> lines) {
    var current = 0;
    for (final line in lines) {
      if (missionCodes.contains(line.productCode)) current += line.lineTotal;
    }
    final reached = current >= missionTarget;
    final left = missionTarget - current;
    return MissionHint(
      message: reached
          ? 'Produk misi cukup. Voucher Rp10.000 cair saat pesanan selesai.'
          : 'Tambah Rp${_thousands(left)} produk misi untuk voucher Rp10.000',
      current: current,
      target: missionTarget,
      reached: reached,
    );
  }

  @override
  List<VoucherOption> vouchersFor(int goodsSubtotal) => <VoucherOption>[
    for (final voucher in vouchers)
      if (voucher.usedBy == null)
        VoucherOption(
          id: voucher.id,
          title: voucher.title ?? 'Voucher',
          amount: voucher.amount,
          minSpend: voucher.minSpend,
          expiresLabel: 'Berlaku s.d. 25 Des 2026',
          usable: goodsSubtotal >= voucher.minSpend,
          reason: goodsSubtotal >= voucher.minSpend
              ? null
              : 'Tambah Rp${_thousands(voucher.minSpend - goodsSubtotal)} lagi',
        ),
  ];

  @override
  CheckoutQuote quote(CheckoutRequest request) {
    var subtotal = 0;
    for (final line in request.lines) {
      subtotal += line.lineTotal;
    }
    var voucherAmount = 0;
    String? voucherId;
    for (final option in vouchersFor(subtotal)) {
      if (option.id == request.voucherId && option.usable) {
        voucherAmount = option.amount;
        voucherId = option.id;
      }
    }
    final rest = subtotal - voucherAmount < 0 ? 0 : subtotal - voucherAmount;
    final used = request.useKelopak
        ? (balance < rest ~/ 100 ? balance : rest ~/ 100)
        : 0;
    return CheckoutQuote(
      goodsSubtotal: subtotal,
      shippingFee: request.shippingFee,
      voucherId: voucherId,
      voucherAmount: voucherAmount,
      kelopakUsed: used,
      kelopakValue: used * 100,
      kelopakBalance: balance,
      gifts: request.lines.isEmpty ? const <GiftLine>[] : pendingGifts,
      total: rest - used * 100 + request.shippingFee,
      token: 'palsu:$subtotal:$voucherAmount:$used',
    );
  }

  @override
  Future<CommitResult> commit(String orderId, CheckoutQuote quote) async {
    if (quote.kelopakUsed > balance) {
      return const CommitResult(ok: false, message: 'Saldo Kelopak kurang.');
    }
    balance -= quote.kelopakUsed;
    for (final voucher in vouchers) {
      if (voucher.id == quote.voucherId) voucher.usedBy = orderId;
    }
    commits[orderId] = FakeCommit(
      kelopak: quote.kelopakUsed,
      giftIds: <String>[for (final gift in quote.gifts) gift.id],
    );
    notifyListeners();
    return const CommitResult(ok: true);
  }

  @override
  Future<void> cancel(String orderId) async {
    final commit = commits.remove(orderId);
    if (commit == null) return;
    balance += commit.kelopak;
    for (final voucher in vouchers) {
      if (voucher.usedBy == orderId) voucher.usedBy = null;
    }
    notifyListeners();
  }

  @override
  Future<void> ship(String orderId) async {}

  @override
  Future<CompletionResult> complete(String orderId) async {
    if (!celebrateMission) return const CompletionResult();
    return CompletionResult(
      missionMessage: 'Misi Belanja tahap 1 tuntas. Voucher Rp10.000 masuk.',
      celebrate: (context) async {
        celebrations++;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Misi tuntas'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Mantap'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool canClaimPromoVoucher(String promoId) => false;

  @override
  Future<CommitResult> claimPromoVoucher({
    required String promoId,
    required int amount,
    required int minSpend,
    required int validDays,
  }) async => const CommitResult(ok: false);

  @override
  Widget? buildWalletStrip(BuildContext context) => null;

  @override
  Widget? buildGameStrip(BuildContext context) => null;

  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

final class FakeCommit {
  const FakeCommit({required this.kelopak, required this.giftIds});

  final int kelopak;
  final List<String> giftIds;
}

/// Alamat contoh (data karangan, bukan data pelanggan).
const AddressDraft sampleAddress = AddressDraft(
  label: 'Rumah',
  recipient: 'Sinta Maharani',
  phone: '081234567890',
  street: 'Jl. Melati Raya No. 12, RT 03/RW 05',
  district: 'Cilandak',
  city: 'Jakarta Selatan',
  province: 'DKI Jakarta',
  postalCode: '12430',
);

/// Layanan tes dengan [rewards] (bawaan [NoRewardsGateway]); dilepas setelah
/// tes tanpa ditunggu (I/O sungguhan tidak selesai di jam palsu).
AppServices f2Services({
  bool loggedIn = true,
  RewardsGateway? rewards,
  bool withAddress = true,
  bool dark = false,
  WibClock? clock,
}) {
  final services = AppServices.forTest(
    loggedIn: loggedIn,
    clock: clock,
    rewardsBuilder: rewards == null ? null : (_) => rewards,
  );
  if (loggedIn && withAddress) services.addresses.add(sampleAddress);
  services.settings.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
  registerOrderRoutes(services.router);
  services.router.register<LoginRoute>(
    (context, route) =>
        Scaffold(body: Center(child: Text('Halaman masuk ${route.next}'))),
  );
  addTearDown(() => unawaited(services.dispose()));
  return services;
}

/// Membuat pesanan langsung lewat repositori (tanpa layar checkout).
Future<Order> placeOrder(
  AppServices services, {
  Map<String, int> lines = const <String, int>{sunscreen: 1, nightCream: 1},
  String paymentId = 'qris',
  bool useKelopak = true,
}) async {
  lines.forEach((code, qty) => services.cart.add(code, qty: qty));
  final cart = services.cart;
  final shipping = services.shipping
      .options(
        weightGrams: cart.selectedWeightGrams,
        goodsSubtotal: cart.selectedSubtotal,
      )
      .first;
  final quote = services.rewards.quote(
    CheckoutRequest(
      lines: cart.linesForCheckout,
      shippingFee: shipping.fee,
      useKelopak: useKelopak,
    ),
  );
  final result = await services.orders.place(
    OrderDraft(
      items: cart.selectedItems,
      address: services.addresses.primary,
      shipping: shipping,
      payment: PaymentCatalog.byId(paymentId),
      quote: quote,
    ),
  );
  expect(result.ok, isTrue, reason: result.message);
  return result.order!;
}

/// Memasang app pada [location] dengan ukuran [size] dan skala teks.
Future<void> pumpF2(
  WidgetTester tester,
  AppServices services, {
  required String location,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await loadShotFonts(tester);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    BpediaApp(services: services, initialLocation: location),
  );
  await settle(tester);
}

/// Menunggu transisi dan animasi masuk tanpa `pumpAndSettle` (Bipy melayang
/// terus-menerus).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Gulir [finder] ke dalam layar pada daftar gulir pertama.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}
