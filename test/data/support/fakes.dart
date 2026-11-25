/// Bantuan tes lapisan data: katalog asli dari aset, kode produk acuan, dan
/// gateway hadiah palsu yang mengikuti urutan hitung KEPUTUSAN §1.
library;

import 'dart:io';

import 'package:bpedia_app/data/address/address_repository.dart';
import 'package:bpedia_app/data/catalog/catalog_repository.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:flutter/widgets.dart';

/// Hot Item: Rp10.000, stok 20, maksimal 1 per pesanan.
const String hotCode = 'P39A06S01000052';

/// Rp46.196, stok 10.
const String codeA = 'P68B13S01000010';

/// Rp20.500, stok 12.
const String codeB = 'P39A06S01000002';

/// Rp20.500, stok 1.
const String codeLastOne = 'P39A06S01000003';

/// Rp26.000, stok 95.
const String codeMany = 'P39A06S01000007';

/// Isi `assets/catalog/catalog.json`.
String readCatalogJson() => File(catalogAsset).readAsStringSync();

/// Katalog asli (82 produk).
CatalogRepository loadCatalog() =>
    CatalogRepository()..loadFromJson(readCatalogJson());

/// Alamat contoh yang lolos validasi.
const AddressDraft sampleAddress = AddressDraft(
  label: 'Rumah',
  recipient: 'Sari Dewi',
  phone: '081234567890',
  street: 'Jl. Melati No. 12',
  district: 'Coblong',
  city: 'Bandung',
  province: 'Jawa Barat',
  postalCode: '40132',
);

/// Gateway hadiah palsu: saldo, voucher, dan hadiah menunggu bisa diatur;
/// tiap panggilan transisi dicatat di [calls].
class FakeRewardsGateway extends RewardsGateway {
  FakeRewardsGateway({
    this.balance = 0,
    List<GiftLine> gifts = const <GiftLine>[],
    this.vouchers = const <VoucherOption>[],
  }) : _pending = List<GiftLine>.of(gifts);

  /// Saldo Kelopak.
  int balance;

  /// Voucher milik pengguna.
  List<VoucherOption> vouchers;

  /// Jawaban [commit] berikutnya.
  bool commitOk = true;

  /// Kabar misi yang dikembalikan [complete].
  String? missionMessage;

  /// Panggilan transisi, contoh `commit:BP-261125-0001`.
  final List<String> calls = <String>[];

  final List<GiftLine> _pending;
  final Map<String, CheckoutQuote> _committed = <String, CheckoutQuote>{};
  final Set<String> _usedVouchers = <String>{};
  int _quoteSeq = 0;

  @override
  bool get available => true;

  @override
  int get kelopakBalance => balance;

  @override
  int get voucherCount =>
      vouchers.where((voucher) => !_usedVouchers.contains(voucher.id)).length;

  @override
  List<GiftLine> get pendingGifts => List<GiftLine>.unmodifiable(_pending);

  @override
  bool hasBadge(RewardsEntry entry) => false;

  @override
  Set<String> get missionProductCodes => const <String>{};

  @override
  MissionHint? missionHintFor(List<PricedLine> lines) => null;

  @override
  List<VoucherOption> vouchersFor(int goodsSubtotal) => <VoucherOption>[
    for (final voucher in vouchers)
      if (!_usedVouchers.contains(voucher.id))
        VoucherOption(
          id: voucher.id,
          title: voucher.title,
          amount: voucher.amount,
          minSpend: voucher.minSpend,
          expiresLabel: voucher.expiresLabel,
          usable: goodsSubtotal >= voucher.minSpend,
          reason: goodsSubtotal >= voucher.minSpend
              ? null
              : 'Belum mencapai minimum belanja.',
        ),
  ];

  @override
  CheckoutQuote quote(CheckoutRequest request) {
    var subtotal = 0;
    for (final line in request.lines) {
      subtotal += line.lineTotal;
    }
    VoucherOption? voucher;
    for (final option in vouchersFor(subtotal)) {
      if (option.id == request.voucherId && option.usable) voucher = option;
    }
    final voucherAmount = voucher == null
        ? 0
        : (voucher.amount > subtotal ? subtotal : voucher.amount);
    final remaining = subtotal - voucherAmount;
    final affordable = remaining ~/ 100;
    final used = !request.useKelopak
        ? 0
        : (balance < affordable ? balance : affordable);
    return CheckoutQuote(
      goodsSubtotal: subtotal,
      shippingFee: request.shippingFee,
      voucherId: voucher?.id,
      voucherAmount: voucherAmount,
      kelopakUsed: used,
      kelopakValue: used * 100,
      kelopakBalance: balance,
      gifts: request.lines.isEmpty ? const <GiftLine>[] : pendingGifts,
      total: remaining - used * 100 + request.shippingFee,
      token: 'q${++_quoteSeq}',
    );
  }

  @override
  Future<CommitResult> commit(String orderId, CheckoutQuote quote) async {
    calls.add('commit:$orderId');
    if (!commitOk || quote.kelopakUsed > balance) {
      return const CommitResult(ok: false, message: 'Kutipan sudah basi.');
    }
    balance -= quote.kelopakUsed;
    final voucherId = quote.voucherId;
    if (voucherId != null) _usedVouchers.add(voucherId);
    _pending.removeWhere(
      (gift) => quote.gifts.any((attached) => attached.id == gift.id),
    );
    _committed[orderId] = quote;
    notifyListeners();
    return const CommitResult(ok: true);
  }

  @override
  Future<void> cancel(String orderId) async {
    calls.add('cancel:$orderId');
    final quote = _committed.remove(orderId);
    if (quote == null) return;
    balance += quote.kelopakUsed;
    _usedVouchers.remove(quote.voucherId);
    _pending.addAll(quote.gifts);
    notifyListeners();
  }

  @override
  Future<void> ship(String orderId) async {
    calls.add('ship:$orderId');
  }

  @override
  Future<CompletionResult> complete(String orderId) async {
    calls.add('complete:$orderId');
    return CompletionResult(missionMessage: missionMessage);
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
}
