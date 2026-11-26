/// Label dan warna status pesanan yang dipakai bersama layar transaksi.
library;

import '../../data/orders/order.dart';
import '../../data/wib_dates.dart';
import '../../design/design.dart';

/// Warna chip untuk [status].
StatusTone orderStatusTone(OrderStatus status) => switch (status) {
  OrderStatus.awaitingPayment => StatusTone.warning,
  OrderStatus.packing => StatusTone.brand,
  OrderStatus.shipped => StatusTone.info,
  OrderStatus.completed => StatusTone.success,
  OrderStatus.cancelled => StatusTone.danger,
};

/// Keterangan singkat status di kepala detail pesanan.
String orderStatusDescription(Order order) => switch (order.status) {
  OrderStatus.awaitingPayment =>
    order.payBy == null
        ? 'Selesaikan pembayaran supaya pesananmu segera dikemas.'
        : 'Bayar sebelum ${wibDateTimeLabel(order.payBy!)}.',
  OrderStatus.packing =>
    order.paidNote != null
        ? '${order.paidNote}. Penjual sedang mengemas pesananmu.'
        : order.isCod
        ? 'Bayar di tempat. Penjual sedang mengemas pesananmu.'
        : 'Pembayaran diterima. Penjual sedang mengemas pesananmu.',
  OrderStatus.shipped => 'Paket dalam perjalanan bersama ${order.courierName}.',
  OrderStatus.completed => 'Pesanan sudah kamu terima. Terima kasih, Babes.',
  OrderStatus.cancelled =>
    order.cancelReason == null
        ? 'Pesanan dibatalkan.'
        : 'Dibatalkan: ${order.cancelReason}.',
};

/// Teks Kelopak: "12 Kelopak".
String kelopakAmountLabel(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$buffer Kelopak';
}

/// Sisa waktu bayar yang jujur dari jam app: "Sisa 23 jam 59 menit".
/// Null bila batas sudah lewat atau tidak ada.
String? remainingPayLabel(Order order, DateTime now) {
  final payBy = order.payBy;
  if (payBy == null) return null;
  final left = payBy.difference(now);
  if (left.isNegative) return null;
  final hours = left.inHours;
  final minutes = left.inMinutes.remainder(60);
  if (hours == 0) return 'Sisa $minutes menit';
  return 'Sisa $hours jam $minutes menit';
}

/// Catatan hemat untuk layar bayar: "128 Kelopak dan voucher memotong
/// Rp22.800. Hadiah gratis ikut di paket ini." Null bila tidak ada potongan
/// maupun hadiah.
String? orderSavingsNote(Order order) {
  final sources = <String>[
    if (order.kelopakUsed > 0) kelopakAmountLabel(order.kelopakUsed),
    if (order.voucherAmount > 0) 'voucher',
  ];
  final parts = <String>[
    if (sources.isNotEmpty)
      '${sources.join(' dan ')} memotong ${formatRupiah(order.savings)}.',
    if (order.gifts.isNotEmpty) 'Hadiah gratis ikut di paket ini.',
  ];
  if (parts.isEmpty) return null;
  final text = parts.join(' ');
  return text[0].toUpperCase() + text.substring(1);
}
