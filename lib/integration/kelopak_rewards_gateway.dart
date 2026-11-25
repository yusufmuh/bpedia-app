/// Adaptor port hadiah app ([RewardsGateway], RENCANA §7.4) di atas
/// [hub.KelopakController].
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kelopak_hub/kelopak_hub.dart' as hub;

import '../app/app_router.dart';
import '../data/auth/auth_repository.dart';
import '../data/catalog/catalog_repository.dart';
import '../data/demo/demo_clock_repository.dart';
import '../data/promo/promo_repository.dart';
import '../data/rewards/rewards_gateway.dart';
import '../features/demo/demo_rewards_tools.dart';
import '../services/sound/sound_service.dart';
import 'bpedia_kelopak_host.dart';

/// Gateway hadiah Kelopak. Tamu melihat saldo, voucher, dan hadiah kosong;
/// data Kelopak tetap tersimpan di perangkat untuk saat masuk lagi.
class KelopakRewardsGateway extends RewardsGateway implements DemoRewardsTools {
  KelopakRewardsGateway({
    required this.controller,
    required this.auth,
    required this.catalog,
    required this.promo,
    required this.router,
    required this.sound,
    this.demoClock,
  }) {
    controller.addListener(notifyListeners);
    auth.addListener(notifyListeners);
    demoClock?.addListener(controller.refreshDay);
  }

  /// Controller Kelopak yang dibungkus.
  final hub.KelopakController controller;
  final AuthRepository auth;
  final CatalogRepository catalog;
  final PromoRepository promo;
  final AppRouter router;
  final SoundService sound;

  /// Jam Mode Demo; pergeseran hari memperbarui controller.
  final DemoClockRepository? demoClock;

  bool _disposed = false;

  bool get _loggedIn => auth.isLoggedIn;

  @override
  bool get available => true;

  @override
  int get kelopakBalance => _loggedIn ? controller.balance : 0;

  @override
  int get voucherCount => _loggedIn ? controller.activeVouchers.length : 0;

  @override
  List<GiftLine> get pendingGifts => _loggedIn
      ? <GiftLine>[for (final gift in controller.pendingGifts) _giftLine(gift)]
      : const <GiftLine>[];

  @override
  bool hasBadge(RewardsEntry entry) {
    if (!_loggedIn || !controller.isLoaded) return false;
    return switch (entry) {
      RewardsEntry.hub => hub.KelopakGameStatus.all(
        controller,
      ).any((status) => status.ready),
      RewardsEntry.checkIn => hub.KelopakGameStatus.checkIn(controller).ready,
      RewardsEntry.wheel => hub.KelopakGameStatus.wheel(controller).ready,
      RewardsEntry.mission => hub.KelopakGameStatus.mission(controller).ready,
    };
  }

  @override
  Set<String> get missionProductCodes => controller.missionProductCodes;

  @override
  MissionHint? missionHintFor(List<PricedLine> lines) {
    if (!_loggedIn) return null;
    final stage = controller.activeMissionStage;
    final progress = controller.missionProgressFor(_hubLines(lines));
    if (stage == null || progress == null) return null;
    final reward = 'voucher ${hub.rupiah(stage.voucherAmount)}';
    final String message;
    if (progress.reached) {
      message =
          'Produk misi ${hub.rupiah(progress.current)} sudah cukup. Selesaikan '
          'pesanan ini untuk dapat $reward.';
    } else if (progress.current == 0) {
      message =
          'Belanja produk misi ${hub.rupiah(progress.target)} untuk dapat '
          '$reward.';
    } else {
      message =
          'Produk misi di keranjang ${hub.rupiah(progress.current)} · tambah '
          '${hub.rupiah(progress.remaining)} lagi untuk $reward.';
    }
    return MissionHint(
      message: message,
      current: progress.current,
      target: progress.target,
      reached: progress.reached,
    );
  }

  @override
  List<VoucherOption> vouchersFor(int goodsSubtotal) {
    if (!_loggedIn) return const <VoucherOption>[];
    return <VoucherOption>[
      for (final voucher in controller.activeVouchers)
        _voucherOption(
          voucher,
          controller.voucherProblemFor(voucher, goodsSubtotal),
          goodsSubtotal,
        ),
    ];
  }

  @override
  CheckoutQuote quote(CheckoutRequest request) {
    final lines = _hubLines(request.lines);
    if (!_loggedIn) {
      final subtotal = hub.goodsSubtotalOf(lines);
      return CheckoutQuote(
        goodsSubtotal: subtotal,
        shippingFee: request.shippingFee,
        voucherId: null,
        voucherAmount: 0,
        kelopakUsed: 0,
        kelopakValue: 0,
        kelopakBalance: 0,
        gifts: const <GiftLine>[],
        total: subtotal + request.shippingFee,
        token: 'tamu:$subtotal:${request.shippingFee}',
      );
    }
    final quote = controller.quote(
      hub.CheckoutRequest(
        lines: lines,
        shippingFee: request.shippingFee,
        voucherId: request.voucherId,
        useKelopak: request.useKelopak,
      ),
    );
    return CheckoutQuote(
      goodsSubtotal: quote.goodsSubtotal,
      shippingFee: quote.shippingFee,
      voucherId: quote.voucherApplied ? quote.voucherId : null,
      voucherAmount: quote.voucherAmount,
      kelopakUsed: quote.kelopakUsed,
      kelopakValue: quote.kelopakValue,
      kelopakBalance: quote.kelopakBalance,
      gifts: <GiftLine>[for (final gift in quote.gifts) _giftLine(gift)],
      total: quote.total,
      token: quote.token,
    );
  }

  @override
  Future<CommitResult> commit(String orderId, CheckoutQuote quote) async {
    if (!_loggedIn) {
      return const CommitResult(
        ok: false,
        message: 'Masuk dulu untuk membuat pesanan, Babes.',
      );
    }
    final hubQuote = controller.quoteByToken(quote.token);
    if (hubQuote == null) {
      return const CommitResult(
        ok: false,
        message: 'Rincian harga berubah. Periksa lagi sebelum lanjut.',
      );
    }
    try {
      final outcome = await controller.commitOrder(orderId, hubQuote);
      return switch (outcome) {
        hub.OrderCommitted() => const CommitResult(ok: true),
        hub.OrderNotCommitted(:final problem) => CommitResult(
          ok: false,
          message: problem.message,
        ),
      };
    } on hub.KelopakBackendException {
      return const CommitResult(
        ok: false,
        message: 'Data Kelopak sedang tidak bisa disimpan. Coba lagi, ya.',
      );
    }
  }

  @override
  Future<void> cancel(String orderId) async {
    await controller.cancelOrder(orderId);
  }

  @override
  Future<void> ship(String orderId) async {
    await controller.shipOrder(orderId);
  }

  @override
  Future<CompletionResult> complete(String orderId) async {
    final completion = await controller.completeOrder(orderId);
    final voucher = completion?.voucher;
    if (completion == null || voucher == null) return const CompletionResult();
    final stage =
        completion.decision.issuedStage?.number ?? voucher.stageNumber ?? 1;
    return CompletionResult(
      missionMessage:
          'Misi Belanja tahap $stage tuntas. Voucher '
          '${hub.rupiah(voucher.amount)} (min. belanja '
          '${hub.rupiah(voucher.minSpend)}) sudah masuk ke Voucherku.',
      celebrate: (context) {
        sound.play(SoundCue.missionDone);
        return hub.showMissionCompleteCelebration(
          context,
          voucher: voucher,
          stageNumber: stage,
          onViewVouchers: () =>
              router.openLocation(const VouchersRoute().location),
        );
      },
    );
  }

  @override
  bool canClaimPromoVoucher(String promoId) =>
      _loggedIn && controller.canClaimPromoVoucher(promoId);

  @override
  Future<CommitResult> claimPromoVoucher({
    required String promoId,
    required int amount,
    required int minSpend,
    required int validDays,
  }) async {
    if (!_loggedIn) {
      return const CommitResult(
        ok: false,
        message: 'Masuk dulu untuk mengklaim voucher, Babes.',
      );
    }
    String? eventTitle;
    for (final event in promo.events) {
      if (event.id == promoId) eventTitle = event.title;
    }
    try {
      final outcome = await controller.claimPromoVoucher(
        promoId: promoId,
        amount: amount,
        minSpend: minSpend,
        validDays: validDays,
        title: eventTitle == null ? 'Voucher promo' : 'Voucher $eventTitle',
      );
      return switch (outcome) {
        hub.PromoVoucherClaimed() => const CommitResult(
          ok: true,
          message: 'Voucher masuk ke Voucherku.',
        ),
        hub.PromoVoucherNotClaimed(:final problem) => CommitResult(
          ok: false,
          message: problem.message,
        ),
      };
    } on hub.KelopakBackendException {
      return const CommitResult(
        ok: false,
        message: 'Voucher belum bisa diklaim. Coba lagi, ya.',
      );
    }
  }

  @override
  Widget? buildWalletStrip(BuildContext context) =>
      const hub.KelopakWalletStrip(margin: EdgeInsets.zero);

  @override
  Widget? buildGameStrip(BuildContext context) => const hub.KelopakGameStrip();

  // ------------------------------------------------------------ Mode Demo

  @override
  Future<bool> grantKelopak(int amount) async {
    if (!_loggedIn || amount <= 0) return false;
    return controller.grantKelopak(amount);
  }

  @override
  Future<void> resetRewards() async {
    await controller.resetAll();
  }

  @override
  List<DemoRewardsAction> get demoActions => <DemoRewardsAction>[
    DemoRewardsAction(
      id: 'refill-wheel-quota',
      label: 'Isi kuota produk roda',
      description:
          'Kuota hadiah produk Roda Sabtu pekan ini kembali '
          '${controller.campaign.wheelQuota} (demo).',
      run: () async {
        final ok = await controller.refillWheelQuota();
        return ok
            ? 'Kuota produk roda: ${controller.wheelQuotaLeft}.'
            : 'Kuota roda tidak bisa diatur di backend ini.';
      },
    ),
    DemoRewardsAction(
      id: 'empty-wheel-quota',
      label: 'Habiskan kuota produk roda',
      description: 'Bagian produk pindah ke hadiah cadangan 1 Kelopak.',
      run: () async {
        final ok = await controller.setWheelQuotaLeft(0);
        return ok
            ? 'Kuota produk roda habis.'
            : 'Kuota roda tidak bisa diatur di backend ini.';
      },
    ),
    DemoRewardsAction(
      id: 'toggle-wheel-promo',
      label: controller.promoActive
          ? 'Hentikan promo Roda Sabtu'
          : 'Jalankan promo Roda Sabtu',
      description: 'Menguji tampilan saat promo roda berhenti.',
      run: () async {
        final next = !controller.promoActive;
        final ok = await controller.setPromoActive(next);
        if (!ok) return 'Promo roda tidak bisa diatur di backend ini.';
        return next
            ? 'Promo Roda Sabtu berjalan.'
            : 'Promo Roda Sabtu berhenti.';
      },
    ),
  ];

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    controller.removeListener(notifyListeners);
    auth.removeListener(notifyListeners);
    demoClock?.removeListener(controller.refreshDay);
    final host = controller.host;
    controller.dispose();
    if (host is BpediaKelopakHost) host.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- bantuan

  List<hub.CheckoutLine> _hubLines(List<PricedLine> lines) =>
      <hub.CheckoutLine>[
        for (final line in lines)
          hub.CheckoutLine(
            productCode: line.productCode,
            unitPrice: line.unitPrice,
            quantity: line.quantity,
          ),
      ];

  GiftLine _giftLine(hub.PendingGift gift) {
    final code = gift.productCode ?? '';
    return GiftLine(
      id: gift.id,
      productCode: code,
      name: catalog.byCode(code)?.name ?? 'Produk hadiah',
      sourceLabel: gift.source.label,
    );
  }

  VoucherOption _voucherOption(
    hub.KelopakVoucher voucher,
    hub.RedeemProblem? problem,
    int goodsSubtotal,
  ) => VoucherOption(
    id: voucher.id,
    title: voucher.title,
    amount: voucher.amount,
    minSpend: voucher.minSpend,
    expiresLabel: 'Berlaku s.d. ${hub.shortDateLabel(voucher.expiresDay)}',
    usable: problem == null,
    reason: switch (problem) {
      null => null,
      hub.RedeemProblem.belowMinimum =>
        'Belanja ${hub.rupiah(voucher.minSpend - goodsSubtotal)} lagi untuk '
            'memakai voucher ini.',
      hub.RedeemProblem.sameOrder =>
        'Tidak bisa dipakai di pesanan yang menerbitkannya.',
      hub.RedeemProblem.alreadyUsed => 'Voucher sudah dipakai.',
      hub.RedeemProblem.expired => 'Voucher sudah tidak berlaku.',
    },
  );
}
