/// Port hadiah Kelopak (RENCANA §7.4). App belanja hanya mengenal antarmuka
/// ini; adaptor di `lib/integration` menyambungkannya ke `kelopak_hub`.
/// Bawaan [NoRewardsGateway]: tanpa hadiah, kutipan polos.
library;

import 'package:flutter/widgets.dart';

/// Pintu masuk zona Hadiah, untuk titik merah "bisa diklaim".
enum RewardsEntry { hub, checkIn, wheel, mission }

/// Port hadiah. Implementasi memberi tahu pendengar saat saldo, voucher,
/// hadiah menunggu, atau lencana berubah.
abstract class RewardsGateway extends ChangeNotifier {
  /// False = sembunyikan semua UI hadiah.
  bool get available;

  /// Saldo Kelopak; 0 untuk tamu.
  int get kelopakBalance;

  /// Jumlah voucher yang masih bisa dipakai.
  int get voucherCount;

  /// Hadiah produk gratis yang menunggu pesanan berikutnya (tampil di
  /// keranjang, K17).
  List<GiftLine> get pendingGifts;

  /// Apakah [entry] punya sesuatu yang bisa diklaim sekarang.
  bool hasBadge(RewardsEntry entry);

  /// Kode produk misi tahap aktif.
  Set<String> get missionProductCodes;

  /// Dorongan misi untuk isi keranjang [lines], atau null bila tidak relevan.
  MissionHint? missionHintFor(List<PricedLine> lines);

  /// Voucher milik pengguna dengan status bisa-dipakai untuk subtotal barang
  /// [goodsSubtotal].
  List<VoucherOption> vouchersFor(int goodsSubtotal);

  /// Rincian harga untuk [request] (urutan hitung KEPUTUSAN §1).
  CheckoutQuote quote(CheckoutRequest request);

  /// Mengikat [quote] ke pesanan [orderId]: debit Kelopak, tandai voucher,
  /// lampirkan hadiah.
  Future<CommitResult> commit(String orderId, CheckoutQuote quote);

  /// Pesanan batal: kembalikan Kelopak, voucher, dan hadiah.
  Future<void> cancel(String orderId);

  /// Pesanan dikirim: hadiah terlampir ikut dikirim.
  Future<void> ship(String orderId);

  /// Pesanan selesai: hadiah diterima dan misi dievaluasi.
  Future<CompletionResult> complete(String orderId);

  /// Apakah voucher promo [promoId] masih bisa diklaim pengguna ini.
  bool canClaimPromoVoucher(String promoId);

  /// Mengklaim voucher promo.
  Future<CommitResult> claimPromoVoucher({
    required String promoId,
    required int amount,
    required int minSpend,
    required int validDays,
  });

  /// Strip dompet Beranda; null = tidak ada.
  Widget? buildWalletStrip(BuildContext context);

  /// Strip "Main bareng Bipy"; null = tidak ada.
  Widget? buildGameStrip(BuildContext context);
}

/// Satu baris barang berbayar.
final class PricedLine {
  const PricedLine({
    required this.productCode,
    required this.unitPrice,
    required this.quantity,
  });

  final String productCode;
  final int unitPrice;
  final int quantity;

  /// `unitPrice * quantity`.
  int get lineTotal => unitPrice * quantity;
}

/// Permintaan kutipan checkout.
final class CheckoutRequest {
  const CheckoutRequest({
    required this.lines,
    required this.shippingFee,
    this.voucherId,
    this.useKelopak = true,
  });

  final List<PricedLine> lines;
  final int shippingFee;
  final String? voucherId;
  final bool useKelopak;
}

/// Hadiah produk gratis (baris Rp0).
final class GiftLine {
  const GiftLine({
    required this.id,
    required this.productCode,
    required this.name,
    required this.sourceLabel,
  });

  final String id;
  final String productCode;
  final String name;
  final String sourceLabel;
}

/// Voucher di lembar pilih voucher.
final class VoucherOption {
  const VoucherOption({
    required this.id,
    required this.title,
    required this.amount,
    required this.minSpend,
    required this.expiresLabel,
    required this.usable,
    this.reason,
  });

  final String id;
  final String title;
  final int amount;
  final int minSpend;
  final String expiresLabel;
  final bool usable;
  final String? reason;
}

/// Rincian harga checkout.
final class CheckoutQuote {
  const CheckoutQuote({
    required this.goodsSubtotal,
    required this.shippingFee,
    required this.voucherId,
    required this.voucherAmount,
    required this.kelopakUsed,
    required this.kelopakValue,
    required this.kelopakBalance,
    required this.gifts,
    required this.total,
    required this.token,
  });

  final int goodsSubtotal;
  final int shippingFee;
  final String? voucherId;
  final int voucherAmount;
  final int kelopakUsed;
  final int kelopakValue;
  final int kelopakBalance;
  final List<GiftLine> gifts;
  final int total;
  final String token;
}

/// Hasil aksi gateway yang bisa gagal.
final class CommitResult {
  const CommitResult({required this.ok, this.message});

  final bool ok;
  final String? message;
}

/// Hasil penyelesaian pesanan.
final class CompletionResult {
  const CompletionResult({this.missionMessage, this.celebrate});

  final String? missionMessage;
  final Future<void> Function(BuildContext context)? celebrate;
}

/// Dorongan Misi Belanja di keranjang.
final class MissionHint {
  const MissionHint({
    required this.message,
    required this.current,
    required this.target,
    required this.reached,
  });

  final String message;
  final int current;
  final int target;
  final bool reached;
}

/// Gateway bawaan tanpa hadiah: `available = false`, kutipan = subtotal +
/// ongkir.
class NoRewardsGateway extends RewardsGateway {
  @override
  bool get available => false;

  @override
  int get kelopakBalance => 0;

  @override
  int get voucherCount => 0;

  @override
  List<GiftLine> get pendingGifts => const <GiftLine>[];

  @override
  bool hasBadge(RewardsEntry entry) => false;

  @override
  Set<String> get missionProductCodes => const <String>{};

  @override
  MissionHint? missionHintFor(List<PricedLine> lines) => null;

  @override
  List<VoucherOption> vouchersFor(int goodsSubtotal) => const <VoucherOption>[];

  @override
  CheckoutQuote quote(CheckoutRequest request) {
    var subtotal = 0;
    for (final line in request.lines) {
      subtotal += line.lineTotal;
    }
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
      token: 'polos:$subtotal:${request.shippingFee}',
    );
  }

  @override
  Future<CommitResult> commit(String orderId, CheckoutQuote quote) async =>
      const CommitResult(ok: true);

  @override
  Future<void> cancel(String orderId) async {}

  @override
  Future<void> ship(String orderId) async {}

  @override
  Future<CompletionResult> complete(String orderId) async =>
      const CompletionResult();

  @override
  bool canClaimPromoVoucher(String promoId) => false;

  @override
  Future<CommitResult> claimPromoVoucher({
    required String promoId,
    required int amount,
    required int minSpend,
    required int validDays,
  }) async => const CommitResult(
    ok: false,
    message: 'Voucher belum tersedia di versi ini.',
  );

  @override
  Widget? buildWalletStrip(BuildContext context) => null;

  @override
  Widget? buildGameStrip(BuildContext context) => null;
}
