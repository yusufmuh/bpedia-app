/// Pesanan (demo): buat, bayar, kirim, selesai, batal. Tiap transisi
/// memanggil [RewardsGateway] dan menulis notifikasi ke [InboxRepository].
library;

import 'dart:async';

import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

import '../../services/analytics/analytics.dart';
import '../address/address_repository.dart';
import '../auth/auth_repository.dart';
import '../cart/cart_repository.dart';
import '../catalog/catalog_repository.dart';
import '../inbox/inbox_repository.dart';
import '../payment/payment_catalog.dart';
import '../rewards/rewards_gateway.dart';
import '../shipping/shipping_repository.dart';
import '../storage/document_repository.dart';
import '../wib_dates.dart';
import 'order.dart';

export 'order.dart';

/// Bahan pesanan dari layar checkout.
final class OrderDraft {
  const OrderDraft({
    required this.items,
    required this.address,
    required this.shipping,
    required this.payment,
    required this.quote,
  });

  /// Barang berbayar yang dicentang di keranjang.
  final List<CartItem> items;

  /// Alamat kirim; null = belum dipilih.
  final Address? address;

  /// Kurir terpilih; null = belum dipilih.
  final ShippingOption? shipping;

  /// Cara bayar; boleh null hanya bila total Rp0.
  final PaymentMethod? payment;

  /// Kutipan terakhir dari [RewardsGateway.quote].
  final CheckoutQuote quote;
}

/// Mengapa sebuah aksi pesanan ditolak.
enum OrderProblem {
  notLoggedIn('Masuk dulu untuk melanjutkan, Babes.'),
  emptyCart('Pilih minimal 1 produk untuk checkout.'),
  missingAddress('Tambah alamat pengiriman dulu.'),
  missingShipping('Pilih kurir pengiriman dulu.'),
  missingPayment('Pilih metode pembayaran dulu.'),
  unavailableItem('Ada produk yang stoknya berubah. Periksa keranjangmu.'),
  staleQuote('Rincian harga berubah. Periksa lagi sebelum membuat pesanan.'),
  rewardsRejected('Hadiah atau Kelopak tidak bisa dipakai. Coba lagi.'),
  notFound('Pesanan tidak ditemukan.'),
  wrongStatus('Aksi ini tidak tersedia untuk status pesanan sekarang.'),
  expired('Batas waktu pembayaran habis. Pesanan dibatalkan.'),
  busy('Pesanan sedang diproses. Tunggu sebentar.');

  const OrderProblem(this.message);

  /// Pesan bawaan untuk pengguna.
  final String message;
}

/// Hasil aksi pesanan.
final class OrderResult {
  const OrderResult.ok(Order this.order, {this.completion})
    : problem = null,
      _message = null;

  const OrderResult.failed(OrderProblem this.problem, {String? message})
    : order = null,
      completion = null,
      _message = message;

  /// Pesanan setelah aksi; null bila gagal.
  final Order? order;

  /// Alasan gagal; null bila berhasil.
  final OrderProblem? problem;

  final String? _message;

  /// Pesan untuk pengguna saat gagal; null bila berhasil.
  String? get message => _message ?? problem?.message;

  /// Hasil hadiah saat pesanan selesai (kabar misi dan perayaan).
  final CompletionResult? completion;

  /// Apakah aksi berhasil.
  bool get ok => order != null;
}

/// Pesanan tersimpan milik profil lokal.
class OrderRepository extends DocumentRepository {
  OrderRepository({
    required WibClock clock,
    required RewardsGateway rewards,
    required InboxRepository inbox,
    required CartRepository cart,
    required CatalogRepository catalog,
    required AuthRepository auth,
    Analytics? analytics,
  }) : _clock = clock,
       _rewards = rewards,
       _inbox = inbox,
       _cart = cart,
       _catalog = catalog,
       _auth = auth,
       _analytics = analytics;

  /// Batas bayar setelah pesanan dibuat (demo).
  static const Duration paymentWindow = Duration(hours: 24);

  /// Keterangan pesanan yang lunas tanpa pembayaran.
  static const String paidWithKelopakNote = 'Lunas dengan Kelopak';

  /// Alasan batal karena lewat batas bayar.
  static const String expiredReason = 'Batas waktu pembayaran habis';

  final WibClock _clock;
  final RewardsGateway _rewards;
  final InboxRepository _inbox;
  final CartRepository _cart;
  final CatalogRepository _catalog;
  final AuthRepository _auth;
  final Analytics? _analytics;
  final Set<String> _busy = <String>{};
  List<Order> _orders = const <Order>[];
  int _seq = 0;
  bool _placing = false;

  @override
  String get sectionKey => 'orders';

  /// Lokasi rute detail pesanan [id].
  static String routeOf(String id) => '/pesanan/$id';

  // ------------------------------------------------------------------- baca

  /// Semua pesanan, terbaru di atas.
  List<Order> get orders => _orders;

  /// Apakah belum ada pesanan.
  bool get isEmpty => _orders.isEmpty;

  /// Pesanan bernomor [id], atau null.
  Order? byId(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  /// Pesanan berstatus [status] (null = semua), terbaru di atas.
  List<Order> byStatus(OrderStatus? status) => status == null
      ? _orders
      : _orders.where((order) => order.status == status).toList(growable: false);

  /// Jumlah pesanan berstatus [status] (lencana tab dan strip Akun).
  int countOf(OrderStatus status) =>
      _orders.where((order) => order.status == status).length;

  /// Pesanan yang menunggu pembayaran (pengingat di Beranda).
  List<Order> get unpaid => byStatus(OrderStatus.awaitingPayment);

  /// Apakah [orderId] sedang diproses (tombol menampilkan status sibuk).
  bool isBusy(String orderId) => _busy.contains(orderId);

  // ------------------------------------------------------------------- buat

  /// Membuat pesanan dari [draft]. Kutipan diikat ke pesanan lewat
  /// [RewardsGateway.commit]; total Rp0 dan COD langsung dikemas.
  Future<OrderResult> place(OrderDraft draft) async {
    final problem = _check(draft);
    if (problem != null) return OrderResult.failed(problem);
    if (_placing) return const OrderResult.failed(OrderProblem.busy);
    _placing = true;
    try {
      final quote = draft.quote;
      final now = _clock.instant.toUtc();
      final id = _numberFor(_seq + 1, now);
      final voucherTitle = _voucherTitle(quote);
      final commit = await _rewards.commit(id, quote);
      if (!commit.ok) {
        return OrderResult.failed(
          OrderProblem.rewardsRejected,
          message: commit.message,
        );
      }
      _seq++;
      final nowMs = now.millisecondsSinceEpoch;
      final payment = quote.total == 0 ? null : draft.payment;
      final packsNow = payment == null || payment.isCod;
      final address = draft.address!;
      final shipping = draft.shipping!;
      final order = Order(
        id: id,
        status: packsNow ? OrderStatus.packing : OrderStatus.awaitingPayment,
        items: List<OrderItem>.unmodifiable(<OrderItem>[
          for (final item in draft.items)
            OrderItem(
              productCode: item.product.code,
              name: item.product.name,
              image: item.product.primaryImage,
              unitPrice: item.product.price,
              qty: item.qty,
            ),
        ]),
        gifts: List<OrderGift>.unmodifiable(<OrderGift>[
          for (final gift in quote.gifts)
            OrderGift(
              id: gift.id,
              productCode: gift.productCode,
              name: gift.name,
              sourceLabel: gift.sourceLabel,
              image: _catalog.byCode(gift.productCode)?.primaryImage,
            ),
        ]),
        address: OrderAddress(
          label: address.label,
          recipient: address.recipient,
          phone: address.phoneLabel,
          fullAddress: address.fullAddress,
          note: address.note,
        ),
        courierId: shipping.id,
        courierName: shipping.name,
        courierEta: shipping.etaLabel,
        paymentMethodId: payment?.id,
        paymentMethodName: payment?.name,
        goodsSubtotal: quote.goodsSubtotal,
        shippingFee: quote.shippingFee,
        voucherId: quote.voucherId,
        voucherTitle: voucherTitle,
        voucherAmount: quote.voucherAmount,
        kelopakUsed: quote.kelopakUsed,
        kelopakValue: quote.kelopakValue,
        total: quote.total,
        placedAtMs: nowMs,
        payByMs: packsNow ? null : nowMs + paymentWindow.inMilliseconds,
        paidAtMs: packsNow ? nowMs : null,
        paidNote: payment == null ? paidWithKelopakNote : null,
      );
      _orders = List<Order>.unmodifiable(<Order>[order, ..._orders]);
      _cart.removePurchased(order.items.map((item) => item.productCode));
      _notifyPlaced(order);
      _logPlaced(order);
      changed();
      return OrderResult.ok(order);
    } finally {
      _placing = false;
    }
  }

  // --------------------------------------------------------------- transisi

  /// Menandai pesanan dibayar (simulasi): menunggu pembayaran → dikemas.
  /// Pesanan yang lewat batas bayar dibatalkan.
  Future<OrderResult> pay(String orderId) => _transition(orderId, (order) async {
    if (order.status != OrderStatus.awaitingPayment) {
      return const OrderResult.failed(OrderProblem.wrongStatus);
    }
    if (_isOverdue(order)) {
      await _cancelNow(order, reason: expiredReason);
      return const OrderResult.failed(OrderProblem.expired);
    }
    final paid = _replace(
      order.copyWith(status: OrderStatus.packing, paidAtMs: _nowMs()),
    );
    _inbox.add(
      kind: InboxKind.order,
      title: 'Pembayaran diterima',
      body:
          'Pembayaran ${rupiah(paid.total)} untuk pesanan #${paid.id} '
          'diterima. Pesananmu sedang dikemas.',
      route: routeOf(paid.id),
    );
    _logPurchase(paid);
    return OrderResult.ok(paid);
  });

  /// Menandai pesanan dikirim (simulasi): dikemas → dikirim.
  Future<OrderResult> ship(String orderId) => _transition(orderId, (order) async {
    if (order.status != OrderStatus.packing) {
      return const OrderResult.failed(OrderProblem.wrongStatus);
    }
    await _rewards.ship(order.id);
    final shipped = _replace(
      order.copyWith(status: OrderStatus.shipped, shippedAtMs: _nowMs()),
    );
    _inbox.add(
      kind: InboxKind.order,
      title: 'Pesanan dikirim',
      body:
          'Pesanan #${shipped.id} dikirim dengan ${shipped.courierName}.'
          '${shipped.gifts.isEmpty ? '' : ' Hadiah gratismu ikut dikirim.'}',
      route: routeOf(shipped.id),
    );
    return OrderResult.ok(shipped);
  });

  /// "Pesanan diterima": dikirim → selesai. Hadiah diterima dan misi
  /// dievaluasi; hasilnya ada di [OrderResult.completion].
  Future<OrderResult> complete(String orderId) =>
      _transition(orderId, (order) async {
        if (order.status != OrderStatus.shipped) {
          return const OrderResult.failed(OrderProblem.wrongStatus);
        }
        final completion = await _rewards.complete(order.id);
        final done = _replace(
          order.copyWith(
            status: OrderStatus.completed,
            completedAtMs: _nowMs(),
            missionMessage: completion.missionMessage,
          ),
        );
        _inbox.add(
          kind: InboxKind.order,
          title: 'Pesanan selesai',
          body:
              'Terima kasih, Babes. Pesanan #${done.id} sudah kamu terima.',
          route: routeOf(done.id),
        );
        final mission = completion.missionMessage;
        if (mission != null && mission.isNotEmpty) {
          _inbox.add(
            kind: InboxKind.reward,
            title: 'Misi Belanja',
            body: mission,
            route: '/hadiah/misi',
          );
        }
        return OrderResult.ok(done, completion: completion);
      });

  /// Membatalkan pesanan yang masih menunggu pembayaran atau dikemas.
  /// Kelopak, voucher, dan hadiah gratis dikembalikan lewat gateway.
  Future<OrderResult> cancel(String orderId, {String? reason}) =>
      _transition(orderId, (order) async {
        if (!order.status.canCancel) {
          return const OrderResult.failed(OrderProblem.wrongStatus);
        }
        return OrderResult.ok(await _cancelNow(order, reason: reason));
      });

  /// Membatalkan semua pesanan yang lewat batas bayar. Mengembalikan nomor
  /// pesanan yang dibatalkan. Dipanggil saat app dibuka dan saat daftar
  /// pesanan ditampilkan.
  Future<List<String>> cancelOverdue() async {
    final cancelled = <String>[];
    for (final order in List<Order>.of(_orders)) {
      if (order.status != OrderStatus.awaitingPayment || !_isOverdue(order)) {
        continue;
      }
      final result = await cancel(order.id, reason: expiredReason);
      if (result.ok) cancelled.add(order.id);
    }
    return cancelled;
  }

  /// "Beli lagi": memasukkan barang pesanan [orderId] ke keranjang.
  /// Mengembalikan jumlah produk yang berhasil masuk.
  int buyAgain(String orderId) {
    final order = byId(orderId);
    if (order == null) return 0;
    var added = 0;
    for (final item in order.items) {
      if (_cart.add(item.productCode, qty: item.qty).qty > 0) added++;
    }
    return added;
  }

  /// Teks konfirmasi batal: menyebut apa saja yang dikembalikan.
  String cancelSummary(Order order) {
    final parts = <String>[
      if (order.kelopakUsed > 0) kelopakLabel(order.kelopakUsed),
      if (order.voucherAmount > 0) 'voucher ${rupiah(order.voucherAmount)}',
      if (order.gifts.isNotEmpty) '${order.gifts.length} hadiah gratis',
    ];
    if (parts.isEmpty) return 'Pesanan #${order.id} akan dibatalkan.';
    return 'Pesanan #${order.id} akan dibatalkan. '
        '${_joinList(parts)} dikembalikan ke akunmu.';
  }

  // ---------------------------------------------------------------- simpan

  @override
  Object? toJson() => <String, Object?>{
    'seq': _seq,
    'items': <Object?>[for (final order in _orders) order.toJson()],
  };

  @override
  void restoreState(Object? json) {
    if (json == null) {
      _orders = const <Order>[];
      _seq = 0;
      return;
    }
    final map = asJsonMap(json, 'pesanan');
    final items = readList(map, 'items', Order.fromJson);
    final seq = readInt(map, 'seq', fallback: items.length);
    final ids = <String>{for (final order in items) order.id};
    if (seq < items.length || ids.length != items.length) {
      throw const FormatException('Daftar pesanan tidak sah');
    }
    _orders = List<Order>.unmodifiable(items);
    _seq = seq;
  }

  // --------------------------------------------------------------- bantuan

  OrderProblem? _check(OrderDraft draft) {
    if (!_auth.isLoggedIn) return OrderProblem.notLoggedIn;
    if (draft.items.isEmpty) return OrderProblem.emptyCart;
    if (draft.address == null) return OrderProblem.missingAddress;
    final shipping = draft.shipping;
    if (shipping == null) return OrderProblem.missingShipping;
    var subtotal = 0;
    for (final item in draft.items) {
      final product = _catalog.byCode(item.product.code);
      if (product == null || item.qty < 1 || item.qty > product.maxQty) {
        return OrderProblem.unavailableItem;
      }
      subtotal += product.price * item.qty;
    }
    final quote = draft.quote;
    final expected =
        quote.goodsSubtotal -
        quote.voucherAmount -
        quote.kelopakValue +
        quote.shippingFee;
    if (quote.goodsSubtotal != subtotal ||
        quote.shippingFee != shipping.fee ||
        quote.voucherAmount < 0 ||
        quote.kelopakValue < 0 ||
        quote.total < 0 ||
        quote.total != expected) {
      return OrderProblem.staleQuote;
    }
    if (quote.total > 0 && draft.payment == null) {
      return OrderProblem.missingPayment;
    }
    return null;
  }

  Future<OrderResult> _transition(
    String orderId,
    Future<OrderResult> Function(Order order) action,
  ) async {
    final order = byId(orderId);
    if (order == null) return const OrderResult.failed(OrderProblem.notFound);
    if (!_busy.add(orderId)) return const OrderResult.failed(OrderProblem.busy);
    if (!isDisposed) notifyListeners();
    try {
      return await action(order);
    } finally {
      _busy.remove(orderId);
      changed();
    }
  }

  Future<Order> _cancelNow(Order order, {String? reason}) async {
    await _rewards.cancel(order.id);
    final cancelled = _replace(
      order.copyWith(
        status: OrderStatus.cancelled,
        cancelledAtMs: _nowMs(),
        cancelReason: reason,
      ),
    );
    final returned = <String>[
      if (cancelled.kelopakUsed > 0) kelopakLabel(cancelled.kelopakUsed),
      if (cancelled.voucherAmount > 0) 'voucher',
      if (cancelled.gifts.isNotEmpty) 'hadiah gratis',
    ];
    final lead = reason == null
        ? 'Pesanan #${cancelled.id} dibatalkan.'
        : 'Pesanan #${cancelled.id} dibatalkan: $reason.';
    _inbox.add(
      kind: InboxKind.order,
      title: 'Pesanan dibatalkan',
      body: returned.isEmpty
          ? lead
          : '$lead ${_joinList(returned)} sudah dikembalikan.',
      route: routeOf(cancelled.id),
    );
    return cancelled;
  }

  Order _replace(Order next) {
    _orders = List<Order>.unmodifiable(<Order>[
      for (final order in _orders) order.id == next.id ? next : order,
    ]);
    return next;
  }

  void _notifyPlaced(Order order) {
    final gifts = order.gifts.isEmpty ? '' : ' Hadiah gratismu ikut dikirim.';
    final String title;
    final String body;
    if (order.status == OrderStatus.awaitingPayment) {
      title = 'Menunggu pembayaran';
      body =
          'Bayar ${rupiah(order.total)} untuk pesanan #${order.id} sebelum '
          '${wibDateTimeLabel(order.payBy!)}.';
    } else if (order.paidNote != null) {
      title = 'Pesanan dikemas';
      body =
          'Pesanan #${order.id} lunas dengan Kelopak dan sedang dikemas.$gifts';
    } else {
      title = 'Pesanan dikemas';
      body =
          'Pesanan #${order.id} dengan bayar di tempat sedang dikemas. '
          'Siapkan ${rupiah(order.total)} saat kurir tiba.$gifts';
    }
    _inbox.add(
      kind: InboxKind.order,
      title: title,
      body: body,
      route: routeOf(order.id),
    );
  }

  void _logPlaced(Order order) {
    final analytics = _analytics;
    if (analytics == null) return;
    if (order.kelopakUsed > 0) {
      unawaited(
        analytics.logEvent(BpEvent.kelopakRedeem, <String, Object?>{
          AfParam.orderId: order.id,
          AfParam.kelopak: order.kelopakUsed,
          AfParam.price: order.kelopakValue,
        }),
      );
    }
    final voucherId = order.voucherId;
    if (voucherId != null) {
      unawaited(
        analytics.logEvent(BpEvent.voucherRedeem, <String, Object?>{
          AfParam.orderId: order.id,
          AfParam.voucherId: voucherId,
          AfParam.price: order.voucherAmount,
        }),
      );
    }
    if (order.gifts.isNotEmpty) {
      unawaited(
        analytics.logEvent(BpEvent.giftAttached, <String, Object?>{
          AfParam.orderId: order.id,
          AfParam.giftCount: order.gifts.length,
          AfParam.contentList: <String>[
            for (final gift in order.gifts) gift.productCode,
          ],
        }),
      );
    }
    if (order.status == OrderStatus.packing) _logPurchase(order);
  }

  void _logPurchase(Order order) {
    unawaited(
      _analytics?.logPurchase(
        orderId: order.id,
        paid: order.total,
        productCodes: <String>[
          for (final item in order.items) item.productCode,
        ],
        itemCount: order.itemCount,
      ),
    );
  }

  String? _voucherTitle(CheckoutQuote quote) {
    final id = quote.voucherId;
    if (id == null) return null;
    for (final voucher in _rewards.vouchersFor(quote.goodsSubtotal)) {
      if (voucher.id == id) return voucher.title;
    }
    return null;
  }

  bool _isOverdue(Order order) {
    final payBy = order.payByMs;
    return payBy != null && _nowMs() > payBy;
  }

  int _nowMs() => _clock.instant.toUtc().millisecondsSinceEpoch;

  static String _numberFor(int seq, DateTime now) =>
      'BP-${compactWibDate(wibDayOfInstant(now))}-'
      '${seq.toString().padLeft(4, '0')}';

  static String _joinList(List<String> parts) {
    final text = parts.length == 1
        ? parts.single
        : '${parts.sublist(0, parts.length - 1).join(', ')} dan ${parts.last}';
    return text[0].toUpperCase() + text.substring(1);
  }
}
