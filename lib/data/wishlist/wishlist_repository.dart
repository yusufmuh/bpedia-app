/// Wishlist: kode produk favorit, terbaru lebih dulu.
library;

import 'dart:async';

import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

import '../../services/analytics/analytics.dart';
import '../catalog/catalog_repository.dart';
import '../storage/document_repository.dart';

/// Produk favorit yang tersimpan.
class WishlistRepository extends DocumentRepository {
  WishlistRepository({required CatalogRepository catalog, Analytics? analytics})
    : _catalog = catalog,
      _analytics = analytics;

  final CatalogRepository _catalog;
  final Analytics? _analytics;
  List<String> _codes = const <String>[];

  @override
  String get sectionKey => 'wishlist';

  /// Kode produk favorit, terbaru lebih dulu.
  List<String> get codes => _codes;

  /// Jumlah favorit.
  int get count => _codes.length;

  /// Produk favorit yang masih ada di katalog, terbaru lebih dulu.
  List<Product> get products => _catalog.byCodes(_codes);

  /// Apakah [code] ada di wishlist.
  bool contains(String code) => _codes.contains(code);

  /// Menambah atau menghapus [code]; mengembalikan apakah sekarang favorit.
  /// Kode di luar katalog diabaikan (false).
  bool toggle(String code) {
    if (contains(code)) {
      remove(code);
      return false;
    }
    final product = _catalog.byCode(code);
    if (product == null) return false;
    _codes = List<String>.unmodifiable(<String>[code, ..._codes]);
    unawaited(
      _analytics?.logAddToWishlist(
        productCode: product.code,
        category: product.categoryId,
        price: product.price,
      ),
    );
    changed();
    return true;
  }

  /// Menghapus [code] dari wishlist.
  void remove(String code) {
    if (!contains(code)) return;
    _codes = List<String>.unmodifiable(_codes.where((other) => other != code));
    changed();
  }

  @override
  Object? toJson() => <String, Object?>{'codes': _codes};

  @override
  void restoreState(Object? json) {
    if (json == null) {
      _codes = const <String>[];
      return;
    }
    final codes = readStringList(asJsonMap(json, 'wishlist'), 'codes');
    _codes = List<String>.unmodifiable(<String>{...codes});
  }
}
