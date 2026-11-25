/// Model pesanan (KEPUTUSAN §6). Pesanan menyimpan potret barang, alamat,
/// kurir, cara bayar, dan hasil kutipan hadiah, jadi detail pesanan bisa
/// ditampilkan tanpa katalog maupun hub.
library;

import 'package:kelopak_hub/kelopak_hub.dart';

/// Status pesanan.
enum OrderStatus {
  /// Menunggu pembayaran.
  awaitingPayment('menunggu', 'Menunggu pembayaran'),

  /// Sudah dibayar (atau COD), sedang dikemas.
  packing('dikemas', 'Dikemas'),

  /// Dalam pengiriman.
  shipped('dikirim', 'Dikirim'),

  /// Diterima pelanggan.
  completed('selesai', 'Selesai'),

  /// Dibatalkan.
  cancelled('dibatalkan', 'Dibatalkan');

  const OrderStatus(this.param, this.label);

  /// Nilai di URL (`/pesanan?status=`) dan di JSON.
  final String param;

  /// Nama tampil.
  final String label;

  /// Status dari [param], atau null bila tidak dikenal.
  static OrderStatus? fromParam(String? param) {
    for (final status in values) {
      if (status.param == param) return status;
    }
    return null;
  }

  /// Pesanan masih berjalan (belum selesai dan belum batal).
  bool get isActive =>
      this == awaitingPayment || this == packing || this == shipped;

  /// Pesanan masih boleh dibatalkan pelanggan.
  bool get canCancel => this == awaitingPayment || this == packing;
}

/// Satu barang berbayar di pesanan.
final class OrderItem {
  const OrderItem({
    required this.productCode,
    required this.name,
    required this.image,
    required this.unitPrice,
    required this.qty,
  });

  /// Membaca barang tersimpan.
  factory OrderItem.fromJson(Object? source) {
    final json = asJsonMap(source, 'barang pesanan');
    final item = OrderItem(
      productCode: readString(json, 'productCode'),
      name: readString(json, 'name'),
      image: readString(json, 'image'),
      unitPrice: readInt(json, 'unitPrice'),
      qty: readInt(json, 'qty'),
    );
    if (item.unitPrice < 0 || item.qty < 1) {
      throw const FormatException('Barang pesanan tidak sah');
    }
    return item;
  }

  final String productCode;
  final String name;

  /// Jalur aset gambar utama.
  final String image;
  final int unitPrice;
  final int qty;

  /// `unitPrice * qty`.
  int get lineTotal => unitPrice * qty;

  /// Bentuk JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'productCode': productCode,
    'name': name,
    'image': image,
    'unitPrice': unitPrice,
    'qty': qty,
  };
}

/// Hadiah gratis yang ikut pesanan (baris Rp0).
final class OrderGift {
  const OrderGift({
    required this.id,
    required this.productCode,
    required this.name,
    required this.sourceLabel,
    this.image,
  });

  /// Membaca hadiah tersimpan.
  factory OrderGift.fromJson(Object? source) {
    final json = asJsonMap(source, 'hadiah pesanan');
    return OrderGift(
      id: readString(json, 'id'),
      productCode: readString(json, 'productCode'),
      name: readString(json, 'name'),
      sourceLabel: readString(json, 'sourceLabel'),
      image: readOptionalString(json, 'image'),
    );
  }

  final String id;
  final String productCode;
  final String name;

  /// Asal hadiah, contoh "Roda Sabtu, 22 Nov".
  final String sourceLabel;

  /// Jalur aset gambar; null bila produk tidak ada di katalog.
  final String? image;

  /// Bentuk JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'productCode': productCode,
    'name': name,
    'sourceLabel': sourceLabel,
    'image': image,
  };
}

/// Potret alamat kirim saat pesanan dibuat.
final class OrderAddress {
  const OrderAddress({
    required this.label,
    required this.recipient,
    required this.phone,
    required this.fullAddress,
    this.note = '',
  });

  /// Membaca alamat tersimpan.
  factory OrderAddress.fromJson(Object? source) {
    final json = asJsonMap(source, 'alamat pesanan');
    return OrderAddress(
      label: readString(json, 'label'),
      recipient: readString(json, 'recipient'),
      phone: readString(json, 'phone'),
      fullAddress: readString(json, 'fullAddress'),
      note: readString(json, 'note', fallback: ''),
    );
  }

  final String label;
  final String recipient;

  /// Nomor HP siap tampil.
  final String phone;
  final String fullAddress;
  final String note;

  /// Bentuk JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'recipient': recipient,
    'phone': phone,
    'fullAddress': fullAddress,
    'note': note,
  };
}

/// Satu pesanan.
final class Order {
  const Order({
    required this.id,
    required this.status,
    required this.items,
    required this.gifts,
    required this.address,
    required this.courierId,
    required this.courierName,
    required this.courierEta,
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.goodsSubtotal,
    required this.shippingFee,
    required this.voucherId,
    required this.voucherTitle,
    required this.voucherAmount,
    required this.kelopakUsed,
    required this.kelopakValue,
    required this.total,
    required this.placedAtMs,
    this.payByMs,
    this.paidAtMs,
    this.shippedAtMs,
    this.completedAtMs,
    this.cancelledAtMs,
    this.paidNote,
    this.cancelReason,
    this.missionMessage,
  });

  /// Membaca pesanan tersimpan; melempar [FormatException] bila tidak sah.
  factory Order.fromJson(Object? source) {
    final json = asJsonMap(source, 'pesanan');
    final status = OrderStatus.fromParam(readString(json, 'status'));
    if (status == null) throw const FormatException('Status pesanan tidak sah');
    final order = Order(
      id: readString(json, 'id'),
      status: status,
      items: List<OrderItem>.unmodifiable(
        readList(json, 'items', OrderItem.fromJson),
      ),
      gifts: List<OrderGift>.unmodifiable(
        readList(json, 'gifts', OrderGift.fromJson),
      ),
      address: OrderAddress.fromJson(json['address']),
      courierId: readString(json, 'courierId'),
      courierName: readString(json, 'courierName'),
      courierEta: readString(json, 'courierEta', fallback: ''),
      paymentMethodId: readOptionalString(json, 'paymentMethodId'),
      paymentMethodName: readOptionalString(json, 'paymentMethodName'),
      goodsSubtotal: readInt(json, 'goodsSubtotal'),
      shippingFee: readInt(json, 'shippingFee'),
      voucherId: readOptionalString(json, 'voucherId'),
      voucherTitle: readOptionalString(json, 'voucherTitle'),
      voucherAmount: readInt(json, 'voucherAmount', fallback: 0),
      kelopakUsed: readInt(json, 'kelopakUsed', fallback: 0),
      kelopakValue: readInt(json, 'kelopakValue', fallback: 0),
      total: readInt(json, 'total'),
      placedAtMs: readInt(json, 'placedAtMs'),
      payByMs: readOptionalInt(json, 'payByMs'),
      paidAtMs: readOptionalInt(json, 'paidAtMs'),
      shippedAtMs: readOptionalInt(json, 'shippedAtMs'),
      completedAtMs: readOptionalInt(json, 'completedAtMs'),
      cancelledAtMs: readOptionalInt(json, 'cancelledAtMs'),
      paidNote: readOptionalString(json, 'paidNote'),
      cancelReason: readOptionalString(json, 'cancelReason'),
      missionMessage: readOptionalString(json, 'missionMessage'),
    );
    if (order.id.isEmpty ||
        order.items.isEmpty ||
        order.total < 0 ||
        order.goodsSubtotal < 0 ||
        order.shippingFee < 0 ||
        order.voucherAmount < 0 ||
        order.kelopakUsed < 0 ||
        order.kelopakValue < 0) {
      throw const FormatException('Pesanan tidak sah');
    }
    return order;
  }

  /// Nomor pesanan `BP-YYMMDD-NNNN`.
  final String id;
  final OrderStatus status;
  final List<OrderItem> items;
  final List<OrderGift> gifts;
  final OrderAddress address;
  final String courierId;
  final String courierName;
  final String courierEta;

  /// Null bila total Rp0 (tidak perlu cara bayar).
  final String? paymentMethodId;
  final String? paymentMethodName;
  final int goodsSubtotal;
  final int shippingFee;
  final String? voucherId;
  final String? voucherTitle;
  final int voucherAmount;
  final int kelopakUsed;
  final int kelopakValue;

  /// Jumlah yang dibayar: barang − voucher − Kelopak + ongkir.
  final int total;
  final int placedAtMs;

  /// Batas bayar; hanya ada selama menunggu pembayaran.
  final int? payByMs;
  final int? paidAtMs;
  final int? shippedAtMs;
  final int? completedAtMs;
  final int? cancelledAtMs;

  /// Keterangan lunas tanpa pembayaran, contoh "Lunas dengan Kelopak".
  final String? paidNote;
  final String? cancelReason;

  /// Kabar misi setelah pesanan selesai, bila ada.
  final String? missionMessage;

  /// Jumlah barang berbayar.
  int get itemCount {
    var count = 0;
    for (final item in items) {
      count += item.qty;
    }
    return count;
  }

  /// Total potongan (voucher + Kelopak).
  int get savings => voucherAmount + kelopakValue;

  /// Bayar di tempat.
  bool get isCod => paymentMethodId == 'cod';

  /// Waktu pesanan dibuat.
  DateTime get placedAt => _at(placedAtMs);

  /// Batas bayar, atau null.
  DateTime? get payBy => payByMs == null ? null : _at(payByMs!);

  /// Waktu masuk [status], atau null bila belum pernah.
  DateTime? timeOf(OrderStatus status) {
    final ms = switch (status) {
      OrderStatus.awaitingPayment => paidNote == null && !isCod
          ? placedAtMs
          : null,
      OrderStatus.packing => paidAtMs,
      OrderStatus.shipped => shippedAtMs,
      OrderStatus.completed => completedAtMs,
      OrderStatus.cancelled => cancelledAtMs,
    };
    return ms == null ? null : _at(ms);
  }

  /// Salinan dengan status dan cap waktu baru.
  Order copyWith({
    required OrderStatus status,
    int? paidAtMs,
    int? shippedAtMs,
    int? completedAtMs,
    int? cancelledAtMs,
    String? cancelReason,
    String? missionMessage,
  }) => Order(
    id: id,
    status: status,
    items: items,
    gifts: gifts,
    address: address,
    courierId: courierId,
    courierName: courierName,
    courierEta: courierEta,
    paymentMethodId: paymentMethodId,
    paymentMethodName: paymentMethodName,
    goodsSubtotal: goodsSubtotal,
    shippingFee: shippingFee,
    voucherId: voucherId,
    voucherTitle: voucherTitle,
    voucherAmount: voucherAmount,
    kelopakUsed: kelopakUsed,
    kelopakValue: kelopakValue,
    total: total,
    placedAtMs: placedAtMs,
    payByMs: status == OrderStatus.awaitingPayment ? payByMs : null,
    paidAtMs: paidAtMs ?? this.paidAtMs,
    shippedAtMs: shippedAtMs ?? this.shippedAtMs,
    completedAtMs: completedAtMs ?? this.completedAtMs,
    cancelledAtMs: cancelledAtMs ?? this.cancelledAtMs,
    paidNote: paidNote,
    cancelReason: cancelReason ?? this.cancelReason,
    missionMessage: missionMessage ?? this.missionMessage,
  );

  /// Bentuk JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'status': status.param,
    'items': <Object?>[for (final item in items) item.toJson()],
    'gifts': <Object?>[for (final gift in gifts) gift.toJson()],
    'address': address.toJson(),
    'courierId': courierId,
    'courierName': courierName,
    'courierEta': courierEta,
    'paymentMethodId': paymentMethodId,
    'paymentMethodName': paymentMethodName,
    'goodsSubtotal': goodsSubtotal,
    'shippingFee': shippingFee,
    'voucherId': voucherId,
    'voucherTitle': voucherTitle,
    'voucherAmount': voucherAmount,
    'kelopakUsed': kelopakUsed,
    'kelopakValue': kelopakValue,
    'total': total,
    'placedAtMs': placedAtMs,
    'payByMs': payByMs,
    'paidAtMs': paidAtMs,
    'shippedAtMs': shippedAtMs,
    'completedAtMs': completedAtMs,
    'cancelledAtMs': cancelledAtMs,
    'paidNote': paidNote,
    'cancelReason': cancelReason,
    'missionMessage': missionMessage,
  };

  static DateTime _at(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}
