/// Katalog produk asli Bpedia dari `assets/catalog/catalog.json`.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle;

import 'catalog_query.dart';
import 'product.dart';

export 'catalog_query.dart';
export 'product.dart';

/// Jalur aset katalog.
const String catalogAsset = 'assets/catalog/catalog.json';

/// Katalog hanya-baca: cari, filter, urut, Hot Item, dan produk serupa.
class CatalogRepository extends ChangeNotifier {
  /// Katalog kosong; isi dengan [load] atau [loadFromJson].
  CatalogRepository() : _catalog = Catalog.empty();

  /// Katalog yang sudah berisi [catalog].
  CatalogRepository.of(Catalog catalog) : _catalog = catalog, _loaded = true {
    _index();
  }

  Catalog _catalog;
  bool _loaded = false;
  Object? _loadError;
  Map<String, Product> _byCode = const <String, Product>{};
  Map<String, ProductCategory> _categoryById =
      const <String, ProductCategory>{};
  Map<String, String> _haystack = const <String, String>{};
  List<Product> _hotItems = const <Product>[];

  /// Apakah katalog sudah dimuat.
  bool get isLoaded => _loaded;

  /// Galat pemuatan terakhir; null bila berhasil.
  Object? get loadError => _loadError;

  /// Waktu potret data (ISO 8601, WIB).
  String get snapshotWib => _catalog.snapshotWib;

  /// Keterangan sumber data.
  String get source => _catalog.source;

  /// Lencana situs ("100% Original", "BPOM Verified", "Gratis Ongkir").
  List<String> get siteBadges => _catalog.siteBadges;

  /// Semua produk, urut sumber.
  List<Product> get products => _catalog.products;

  /// Kategori, urut tampil.
  List<ProductCategory> get categories => _catalog.categories;

  /// Brand, urut abjad.
  List<String> get brands => _catalog.brands;

  /// Produk Hot Item, urut sumber.
  List<Product> get hotItems => _hotItems;

  /// Memuat katalog dari [bundle]. Tidak melempar: kegagalan tercatat di
  /// [loadError] dan katalog tetap kosong.
  Future<void> load(AssetBundle bundle) async {
    try {
      loadFromJson(await bundle.loadString(catalogAsset));
    } on Object catch (error) {
      _fail(error);
    }
  }

  /// Memuat katalog dari teks JSON. Tidak melempar (lihat [load]).
  void loadFromJson(String source) {
    try {
      _catalog = Catalog.fromJson(jsonDecode(source));
      _loadError = null;
      _loaded = true;
      _index();
      notifyListeners();
    } on FormatException catch (error) {
      _fail(error);
    }
  }

  /// Produk berkode [code], atau null.
  Product? byCode(String code) => _byCode[code];

  /// Kategori ber-ID [id], atau null.
  ProductCategory? categoryById(String id) => _categoryById[id];

  /// Produk dari [codes] yang ada di katalog, urut sesuai [codes].
  List<Product> byCodes(Iterable<String> codes) => <Product>[
    for (final code in codes)
      if (_byCode[code] case final Product product) product,
  ];

  /// Brand yang namanya memuat [text] (tanpa beda huruf besar/kecil).
  List<String> brandsMatching(String text) {
    final needle = text.trim().toLowerCase();
    if (needle.isEmpty) return brands;
    return brands
        .where((brand) => brand.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  /// Produk yang cocok dengan [query], terurut menurut [CatalogQuery.sort].
  ///
  /// Teks dipecah per kata; semua kata harus ada di nama, brand, kategori, atau
  /// deskripsi. "Paling Sesuai" mengutamakan kecocokan di nama, lalu brand,
  /// lalu urutan sumber.
  List<Product> search(CatalogQuery query) {
    final tokens = query.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    final scored = <({Product product, int score, int index})>[];
    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      if (query.hotOnly && !product.isHot) continue;
      if (query.categoryId != null && product.categoryId != query.categoryId) {
        continue;
      }
      if (query.brands.isNotEmpty && !query.brands.contains(product.brand)) {
        continue;
      }
      final min = query.minPrice;
      final max = query.maxPrice;
      if (min != null && product.price < min) continue;
      if (max != null && product.price > max) continue;
      final score = _score(product, tokens);
      if (score < 0) continue;
      scored.add((product: product, score: score, index: i));
    }
    scored.sort((a, b) {
      final order = switch (query.sort) {
        CatalogSort.relevance => b.score.compareTo(a.score),
        CatalogSort.cheapest => a.product.price.compareTo(b.product.price),
        CatalogSort.priciest => b.product.price.compareTo(a.product.price),
        CatalogSort.biggestDiscount => (b.product.discountPercent ?? 0)
            .compareTo(a.product.discountPercent ?? 0),
        CatalogSort.nameAsc => _compareNames(a.product, b.product),
        CatalogSort.nameDesc => _compareNames(b.product, a.product),
      };
      return order != 0 ? order : a.index.compareTo(b.index);
    });
    return <Product>[for (final entry in scored) entry.product];
  }

  /// Produk lain di kategori yang sama dengan [code]; brand yang sama lebih
  /// dulu. Paling banyak [limit].
  List<Product> similarTo(String code, {int limit = 8}) {
    final product = _byCode[code];
    if (product == null) return const <Product>[];
    final sameBrand = <Product>[];
    final sameCategory = <Product>[];
    for (final other in products) {
      if (other.code == code || other.categoryId != product.categoryId) {
        continue;
      }
      (other.brand == product.brand ? sameBrand : sameCategory).add(other);
    }
    return <Product>[...sameBrand, ...sameCategory].take(limit).toList();
  }

  int _score(Product product, List<String> tokens) {
    if (tokens.isEmpty) return 0;
    final name = product.name.toLowerCase();
    final brand = product.brand.toLowerCase();
    final all = _haystack[product.code]!;
    var score = 0;
    for (final token in tokens) {
      if (!all.contains(token)) return -1;
      if (name.startsWith(token)) {
        score += 8;
      } else if (name.contains(token)) {
        score += 4;
      } else if (brand.contains(token)) {
        score += 2;
      } else {
        score += 1;
      }
    }
    return score;
  }

  static int _compareNames(Product a, Product b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  void _index() {
    _byCode = <String, Product>{
      for (final product in _catalog.products) product.code: product,
    };
    _categoryById = <String, ProductCategory>{
      for (final category in _catalog.categories) category.id: category,
    };
    _haystack = <String, String>{
      for (final product in _catalog.products)
        product.code: <String>[
          product.name,
          product.brand,
          _categoryById[product.categoryId]?.name ?? product.categoryId,
          product.description,
        ].join(' ').toLowerCase(),
    };
    _hotItems = List<Product>.unmodifiable(
      _catalog.products.where((product) => product.isHot),
    );
  }

  void _fail(Object error) {
    _loadError = error;
    _catalog = Catalog.empty();
    _loaded = true;
    _index();
    notifyListeners();
  }
}
