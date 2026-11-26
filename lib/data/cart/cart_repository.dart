/// Keranjang belanja: baris `{productCode, qty, selected}` dengan batas stok
/// dan batas Hot Item per pesanan.
library;

import 'dart:async';

import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

import '../../services/analytics/analytics.dart';
import '../catalog/catalog_repository.dart';
import '../rewards/rewards_gateway.dart' show PricedLine;
import '../storage/document_repository.dart';

/// Satu baris keranjang.
final class CartLine {
  const CartLine({
    required this.productCode,
    required this.qty,
    this.selected = true,
  });

  /// Membaca baris tersimpan; `qty` harus minimal 1.
  factory CartLine.fromJson(Object? source) {
    final json = asJsonMap(source, 'baris keranjang');
    final line = CartLine(
      productCode: readString(json, 'productCode'),
      qty: readInt(json, 'qty'),
      selected: readBool(json, 'selected', fallback: true),
    );
    if (line.qty < 1) throw const FormatException('Jumlah keranjang tidak sah');
    return line;
  }

  /// Kode produk katalog.
  final String productCode;

  /// Jumlah, minimal 1.
  final int qty;

  /// Dicentang untuk checkout.
  final bool selected;

  /// Salinan dengan bidang diganti.
  CartLine copyWith({int? qty, bool? selected}) => CartLine(
    productCode: productCode,
    qty: qty ?? this.qty,
    selected: selected ?? this.selected,
  );

  /// Bentuk JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'productCode': productCode,
    'qty': qty,
    'selected': selected,
  };

  @override
  bool operator ==(Object other) =>
      other is CartLine &&
      other.productCode == productCode &&
      other.qty == qty &&
      other.selected == selected;

  @override
  int get hashCode => Object.hash(productCode, qty, selected);
}

/// Baris keranjang beserta produknya.
final class CartItem {
  const CartItem({required this.line, required this.product});

  /// Baris keranjang.
  final CartLine line;

  /// Produk katalog.
  final Product product;

  /// Jumlah.
  int get qty => line.qty;

  /// Dicentang untuk checkout.
  bool get selected => line.selected;

  /// `harga × jumlah`.
  int get lineTotal => product.price * line.qty;

  /// Apakah jumlah sudah di batas (stok atau batas per pesanan).
  bool get atMax => line.qty >= product.maxQty;
}

/// Baris yang dihapus beserta posisinya, untuk "Urungkan".
final class RemovedCartLine {
  const RemovedCartLine({required this.line, required this.index});

  /// Baris yang dihapus.
  final CartLine line;

  /// Posisi baris sebelum dihapus.
  final int index;
}

/// Mengapa jumlah yang diminta tidak dipenuhi seluruhnya.
enum CartLimit {
  /// Stok habis.
  outOfStock('Stok produk ini habis.'),

  /// Terbatas stok.
  stock('Jumlah disesuaikan dengan stok yang tersedia.'),

  /// Terbatas batas Hot Item per pesanan.
  perOrder('Hot Item ini dibatasi per pesanan.'),

  /// Produk tidak ada di katalog.
  unknownProduct('Produk tidak ditemukan.');

  const CartLimit(this.message);

  /// Pesan untuk pengguna.
  final String message;
}

/// Hasil menambah atau mengubah jumlah.
final class CartChange {
  const CartChange({required this.qty, required this.added, this.limit});

  /// Jumlah produk itu di keranjang sekarang.
  final int qty;

  /// Berapa yang benar-benar bertambah (0 bila tidak berubah).
  final int added;

  /// Batas yang kena, atau null bila permintaan dipenuhi seluruhnya.
  final CartLimit? limit;

  /// Apakah keranjang berubah.
  bool get changed => added != 0;
}

/// Keranjang belanja tersimpan.
class CartRepository extends DocumentRepository {
  CartRepository({required CatalogRepository catalog, Analytics? analytics})
    : _catalog = catalog,
      _analytics = analytics;

  final CatalogRepository _catalog;
  final Analytics? _analytics;
  List<CartLine> _lines = const <CartLine>[];

  @override
  String get sectionKey => 'cart';

  // ------------------------------------------------------------------- baca

  /// Baris keranjang, urut ditambahkan.
  List<CartLine> get lines => _lines;

  /// Baris beserta produknya, urut ditambahkan.
  List<CartItem> get items => <CartItem>[
    for (final line in _lines)
      CartItem(line: line, product: _catalog.byCode(line.productCode)!),
  ];

  /// Apakah keranjang kosong.
  bool get isEmpty => _lines.isEmpty;

  /// Jumlah baris (judul "Keranjang (3)").
  int get lineCount => _lines.length;

  /// Jumlah barang (lencana ikon keranjang).
  int get count {
    var total = 0;
    for (final line in _lines) {
      total += line.qty;
    }
    return total;
  }

  /// Jumlah [productCode] di keranjang (0 bila tidak ada).
  int quantityOf(String productCode) {
    for (final line in _lines) {
      if (line.productCode == productCode) return line.qty;
    }
    return 0;
  }

  /// Baris yang dicentang beserta produknya.
  List<CartItem> get selectedItems =>
      items.where((item) => item.selected).toList(growable: false);

  /// Jumlah baris yang dicentang (tombol "Checkout (2)").
  int get selectedLineCount => _lines.where((line) => line.selected).length;

  /// Subtotal barang yang dicentang (rupiah).
  int get selectedSubtotal {
    var total = 0;
    for (final item in selectedItems) {
      total += item.lineTotal;
    }
    return total;
  }

  /// Berat kirim barang yang dicentang (gram).
  int get selectedWeightGrams {
    var total = 0;
    for (final item in selectedItems) {
      total += item.product.weightGrams * item.qty;
    }
    return total;
  }

  /// Apakah semua baris dicentang (false untuk keranjang kosong).
  bool get allSelected =>
      _lines.isNotEmpty && _lines.every((line) => line.selected);

  /// Apakah ada minimal satu barang berbayar yang dicentang (syarat Checkout
  /// dan syarat hadiah gratis ikut dikirim).
  bool get hasSelection => _lines.any((line) => line.selected);

  /// Baris yang dicentang sebagai [PricedLine] untuk kutipan checkout.
  List<PricedLine> get linesForCheckout => <PricedLine>[
    for (final item in selectedItems)
      PricedLine(
        productCode: item.product.code,
        unitPrice: item.product.price,
        quantity: item.qty,
      ),
  ];

  /// Baris yang dihitung dorongan misi di keranjang: sama dengan
  /// [linesForCheckout]. Misi menilai subtotal produk misi dalam satu pesanan
  /// (KEPUTUSAN §3), jadi barang yang tidak dicentang tidak ikut dihitung.
  List<PricedLine> get pricedLines => linesForCheckout;

  // ------------------------------------------------------------------- ubah

  /// Menambah [qty] buah [productCode] (dicentang). Jumlah dibatasi stok dan
  /// batas Hot Item per pesanan; hasilnya menyebut batas yang kena.
  CartChange add(String productCode, {int qty = 1}) {
    if (qty < 1) throw ArgumentError.value(qty, 'qty', 'minimal 1');
    final product = _catalog.byCode(productCode);
    if (product == null) {
      return const CartChange(
        qty: 0,
        added: 0,
        limit: CartLimit.unknownProduct,
      );
    }
    final current = quantityOf(productCode);
    final target = _clamp(product, current + qty);
    final limit = target < current + qty ? _limitOf(product) : null;
    if (target == current) {
      return CartChange(qty: current, added: 0, limit: limit);
    }
    final index = _indexOf(productCode);
    final lines = <CartLine>[..._lines];
    if (index < 0) {
      lines.add(CartLine(productCode: productCode, qty: target));
    } else {
      lines[index] = lines[index].copyWith(qty: target, selected: true);
    }
    _lines = List<CartLine>.unmodifiable(lines);
    unawaited(
      _analytics?.logAddToCart(
        productCode: product.code,
        category: product.categoryId,
        price: product.price,
        quantity: target - current,
      ),
    );
    changed();
    return CartChange(qty: target, added: target - current, limit: limit);
  }

  /// "Beli sekarang": memastikan [productCode] ada di keranjang dengan jumlah
  /// minimal [qty], lalu hanya baris itu yang dicentang.
  CartChange buyNow(String productCode, {int qty = 1}) {
    final current = quantityOf(productCode);
    final change = current >= qty
        ? CartChange(qty: current, added: 0)
        : add(productCode, qty: qty - current);
    if (change.qty > 0) selectOnly(productCode);
    return change;
  }

  /// Mengatur jumlah: di bawah 1 menghapus baris, di atas batas disesuaikan.
  CartChange setQty(String productCode, int qty) {
    final index = _indexOf(productCode);
    if (index < 0) {
      return qty < 1
          ? const CartChange(qty: 0, added: 0)
          : add(productCode, qty: qty);
    }
    final current = _lines[index].qty;
    if (qty < 1) {
      remove(productCode);
      return CartChange(qty: 0, added: -current);
    }
    final product = _catalog.byCode(productCode)!;
    final target = _clamp(product, qty);
    final limit = target < qty ? _limitOf(product) : null;
    if (target < 1) {
      remove(productCode);
      return CartChange(qty: 0, added: -current, limit: limit);
    }
    if (target != current) {
      final lines = <CartLine>[..._lines];
      lines[index] = lines[index].copyWith(qty: target);
      _lines = List<CartLine>.unmodifiable(lines);
      changed();
    }
    return CartChange(qty: target, added: target - current, limit: limit);
  }

  /// Menghapus baris; simpan hasilnya untuk [undoRemove] ("Urungkan").
  RemovedCartLine? remove(String productCode) {
    final index = _indexOf(productCode);
    if (index < 0) return null;
    final lines = <CartLine>[..._lines];
    final line = lines.removeAt(index);
    _lines = List<CartLine>.unmodifiable(lines);
    changed();
    return RemovedCartLine(line: line, index: index);
  }

  /// Mengembalikan baris yang dihapus ke posisi lamanya (digabung bila produk
  /// itu sudah ditambahkan lagi).
  void undoRemove(RemovedCartLine removed) =>
      restoreAll(<RemovedCartLine>[removed]);

  /// Mengembalikan beberapa baris yang dihapus [removeSelected].
  void restoreAll(List<RemovedCartLine> removed) {
    if (removed.isEmpty) return;
    final lines = <CartLine>[..._lines];
    final ordered = <RemovedCartLine>[...removed]
      ..sort((a, b) => a.index.compareTo(b.index));
    for (final entry in ordered) {
      final product = _catalog.byCode(entry.line.productCode);
      if (product == null) continue;
      final existing = lines.indexWhere(
        (line) => line.productCode == entry.line.productCode,
      );
      if (existing >= 0) {
        lines[existing] = lines[existing].copyWith(
          qty: _clamp(product, lines[existing].qty + entry.line.qty),
        );
      } else {
        final index = entry.index.clamp(0, lines.length);
        lines.insert(index, entry.line);
      }
    }
    _lines = List<CartLine>.unmodifiable(lines);
    changed();
  }

  /// Mencentang atau melepas centang satu baris.
  void setSelected(String productCode, bool selected) {
    final index = _indexOf(productCode);
    if (index < 0 || _lines[index].selected == selected) return;
    final lines = <CartLine>[..._lines];
    lines[index] = lines[index].copyWith(selected: selected);
    _lines = List<CartLine>.unmodifiable(lines);
    changed();
  }

  /// "Pilih semua": mencentang atau melepas centang semua baris.
  void selectAll(bool selected) {
    if (_lines.every((line) => line.selected == selected)) return;
    _lines = List<CartLine>.unmodifiable(<CartLine>[
      for (final line in _lines) line.copyWith(selected: selected),
    ]);
    changed();
  }

  /// Hanya [productCode] yang dicentang.
  void selectOnly(String productCode) {
    final next = <CartLine>[
      for (final line in _lines)
        line.copyWith(selected: line.productCode == productCode),
    ];
    if (_sameLines(next, _lines)) return;
    _lines = List<CartLine>.unmodifiable(next);
    changed();
  }

  /// "Hapus" untuk yang dicentang; hasilnya bisa dikembalikan dengan
  /// [restoreAll].
  List<RemovedCartLine> removeSelected() {
    final removed = <RemovedCartLine>[
      for (var i = 0; i < _lines.length; i++)
        if (_lines[i].selected) RemovedCartLine(line: _lines[i], index: i),
    ];
    if (removed.isEmpty) return removed;
    _lines = List<CartLine>.unmodifiable(
      _lines.where((line) => !line.selected),
    );
    changed();
    return removed;
  }

  /// Mengeluarkan [productCodes] setelah pesanan dibuat.
  void removePurchased(Iterable<String> productCodes) {
    final codes = productCodes.toSet();
    if (!_lines.any((line) => codes.contains(line.productCode))) return;
    _lines = List<CartLine>.unmodifiable(
      _lines.where((line) => !codes.contains(line.productCode)),
    );
    changed();
  }

  /// Mengosongkan keranjang.
  void clear() {
    if (_lines.isEmpty) return;
    _lines = const <CartLine>[];
    changed();
  }

  // ---------------------------------------------------------------- simpan

  @override
  Object? toJson() => <String, Object?>{
    'lines': <Object?>[for (final line in _lines) line.toJson()],
  };

  /// Baris yang produknya sudah tidak ada di katalog atau stoknya habis
  /// dibuang; baris ganda digabung; jumlah disesuaikan dengan batas.
  @override
  void restoreState(Object? json) {
    if (json == null) {
      _lines = const <CartLine>[];
      return;
    }
    final stored = readList(
      asJsonMap(json, 'keranjang'),
      'lines',
      CartLine.fromJson,
    );
    final merged = <String, CartLine>{};
    for (final line in stored) {
      final product = _catalog.byCode(line.productCode);
      if (product == null) continue;
      final previous = merged[line.productCode];
      final qty = _clamp(product, (previous?.qty ?? 0) + line.qty);
      if (qty < 1) continue;
      merged[line.productCode] = CartLine(
        productCode: line.productCode,
        qty: qty,
        selected: line.selected || (previous?.selected ?? false),
      );
    }
    _lines = List<CartLine>.unmodifiable(merged.values);
  }

  // --------------------------------------------------------------- bantuan

  int _indexOf(String productCode) =>
      _lines.indexWhere((line) => line.productCode == productCode);

  static int _clamp(Product product, int qty) =>
      qty > product.maxQty ? product.maxQty : qty;

  static CartLimit _limitOf(Product product) {
    if (!product.inStock) return CartLimit.outOfStock;
    final perOrder = product.hot?.maxPerOrder;
    if (perOrder != null &&
        perOrder <= product.stock &&
        perOrder < cartMaxQty) {
      return CartLimit.perOrder;
    }
    return CartLimit.stock;
  }

  static bool _sameLines(List<CartLine> a, List<CartLine> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
