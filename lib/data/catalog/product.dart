/// Model katalog: produk asli Bpedia, kategori, dan data Hot Item.
///
/// Semua angka (harga, stok, rating, kuota) berasal dari
/// `assets/catalog/catalog.json`; tidak ada nilai karangan.
library;

import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

import '../wib_dates.dart';

/// Folder aset katalog; jalur gambar di JSON relatif terhadap folder ini.
const String catalogAssetRoot = 'assets/catalog/';

/// Jumlah tertinggi satu produk di keranjang.
const int cartMaxQty = 99;

/// Kategori produk.
final class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  /// Membaca kategori dari JSON katalog.
  factory ProductCategory.fromJson(Object? source) {
    final json = asJsonMap(source, 'kategori');
    return ProductCategory(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      icon: readString(json, 'icon'),
    );
  }

  /// ID kategori (dipakai di rute dan filter).
  final String id;

  /// Nama tampil.
  final String name;

  /// Nama ikon brand (`assets/icons/bpedia-ikon-<icon>.svg`).
  final String icon;
}

/// Data Hot Item sebuah produk (potret; tanpa logika kedaluwarsa).
final class HotDeal {
  const HotDeal({
    required this.saleId,
    required this.theme,
    required this.price,
    required this.normalPrice,
    required this.discountPercent,
    required this.quota,
    required this.sold,
    required this.maxPerOrder,
    required this.startDay,
    required this.endDay,
    required this.image,
  });

  /// Membaca data Hot Item dari JSON katalog.
  factory HotDeal.fromJson(Object? source) {
    final json = asJsonMap(source, 'hot item');
    final deal = HotDeal(
      saleId: readInt(json, 'saleId'),
      theme: readString(json, 'theme'),
      price: readInt(json, 'price'),
      normalPrice: readInt(json, 'normalPrice'),
      discountPercent: readInt(json, 'discountPercent'),
      quota: readInt(json, 'quota'),
      sold: readInt(json, 'sold'),
      maxPerOrder: readInt(json, 'maxPerOrder'),
      startDay: parseWibDay(readString(json, 'start')),
      endDay: parseWibDay(readString(json, 'end')),
      image: '$catalogAssetRoot${readString(json, 'image')}',
    );
    if (deal.price < 0 || deal.maxPerOrder < 1) {
      throw const FormatException('Data Hot Item tidak sah');
    }
    return deal;
  }

  /// ID promo di Bpedia.
  final int saleId;

  /// Tema promo ("Wednesday Bye-Bye Acne").
  final String theme;

  /// Harga Hot Item (rupiah).
  final int price;

  /// Harga normal (rupiah).
  final int normalPrice;

  /// Persen diskon.
  final int discountPercent;

  /// Kuota promo pada saat potret.
  final int quota;

  /// Terjual pada saat potret.
  final int sold;

  /// Batas jumlah per pesanan.
  final int maxPerOrder;

  /// Hari WIB promo mulai.
  final int startDay;

  /// Hari WIB promo berakhir.
  final int endDay;

  /// Gambar highlight asli (jalur aset lengkap).
  final String image;
}

/// Satu produk katalog.
final class Product {
  const Product({
    required this.code,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.price,
    required this.description,
    required this.stock,
    required this.weightGrams,
    required this.images,
    required this.sourceUrl,
    this.strikePrice,
    this.discountPercent,
    this.rating,
    this.hot,
  });

  /// Membaca produk dari JSON katalog.
  factory Product.fromJson(Object? source) {
    final json = asJsonMap(source, 'produk');
    final weight = json['weightKg'];
    if (weight is! num || weight < 0) {
      throw const FormatException('Berat produk tidak sah');
    }
    final rating = json['rating'];
    if (rating != null && rating is! num) {
      throw const FormatException('Rating produk tidak sah');
    }
    final product = Product(
      code: readString(json, 'code'),
      name: readString(json, 'name'),
      brand: readString(json, 'brand'),
      categoryId: readString(json, 'category'),
      price: readInt(json, 'price'),
      strikePrice: readOptionalInt(json, 'strikePrice'),
      discountPercent: readOptionalInt(json, 'discountPercent'),
      description: readString(json, 'description', fallback: ''),
      rating: (rating as num?)?.toDouble(),
      stock: readInt(json, 'stock'),
      weightGrams: (weight * 1000).round(),
      images: List<String>.unmodifiable(
        readStringList(json, 'images').map((path) => '$catalogAssetRoot$path'),
      ),
      sourceUrl: readString(json, 'sourceUrl', fallback: ''),
      hot: json['hot'] == null ? null : HotDeal.fromJson(json['hot']),
    );
    if (product.code.isEmpty ||
        product.price < 0 ||
        product.stock < 0 ||
        product.images.isEmpty) {
      throw const FormatException('Produk tidak sah');
    }
    return product;
  }

  /// Kode produk Bpedia (kunci unik).
  final String code;

  /// Nama produk.
  final String name;

  /// Brand.
  final String brand;

  /// ID kategori.
  final String categoryId;

  /// Harga jual (rupiah). Untuk Hot Item ini sudah harga hot.
  final int price;

  /// Harga coret, bila ada.
  final int? strikePrice;

  /// Persen diskon, bila ada.
  final int? discountPercent;

  /// Deskripsi dari Bpedia.
  final String description;

  /// Rating, bila ada di sumber.
  final double? rating;

  /// Stok pada saat potret.
  final int stock;

  /// Berat kirim dalam gram.
  final int weightGrams;

  /// Jalur aset gambar (minimal satu).
  final List<String> images;

  /// Halaman produk di bpedia.id.
  final String sourceUrl;

  /// Data Hot Item, bila produk sedang jadi Hot Item pada saat potret.
  final HotDeal? hot;

  /// Gambar utama.
  String get primaryImage => images.first;

  /// Apakah produk Hot Item.
  bool get isHot => hot != null;

  /// Apakah stok masih ada.
  bool get inStock => stock > 0;

  /// Apakah punya harga coret yang lebih tinggi dari harga jual.
  bool get hasDiscount {
    final strike = strikePrice;
    return strike != null && strike > price;
  }

  /// Jumlah tertinggi yang boleh ada di keranjang: stok, batas Hot Item per
  /// pesanan, dan [cartMaxQty].
  int get maxQty {
    var limit = stock < cartMaxQty ? stock : cartMaxQty;
    final perOrder = hot?.maxPerOrder;
    if (perOrder != null && perOrder < limit) limit = perOrder;
    return limit;
  }
}

/// Isi `assets/catalog/catalog.json`.
final class Catalog {
  Catalog({
    required this.snapshotWib,
    required this.source,
    required List<String> siteBadges,
    required List<ProductCategory> categories,
    required List<String> brands,
    required List<Product> products,
  }) : siteBadges = List<String>.unmodifiable(siteBadges),
       categories = List<ProductCategory>.unmodifiable(categories),
       brands = List<String>.unmodifiable(brands),
       products = List<Product>.unmodifiable(products);

  /// Katalog kosong (sebelum dimuat atau saat aset gagal dibaca).
  factory Catalog.empty() => Catalog(
    snapshotWib: '',
    source: '',
    siteBadges: const <String>[],
    categories: const <ProductCategory>[],
    brands: const <String>[],
    products: const <Product>[],
  );

  /// Membaca katalog; melempar [FormatException] bila bentuknya salah atau ada
  /// kode produk ganda.
  factory Catalog.fromJson(Object? source) {
    final json = asJsonMap(source, 'katalog');
    final catalog = Catalog(
      snapshotWib: readString(json, 'snapshotWib', fallback: ''),
      source: readString(json, 'source', fallback: ''),
      siteBadges: readStringList(json, 'siteBadges'),
      categories: readList(json, 'categories', ProductCategory.fromJson),
      brands: readStringList(json, 'brands'),
      products: readList(json, 'products', Product.fromJson),
    );
    final codes = <String>{};
    for (final product in catalog.products) {
      if (!codes.add(product.code)) {
        throw FormatException('Kode produk ganda: ${product.code}');
      }
    }
    return catalog;
  }

  /// Waktu potret data (ISO 8601, WIB).
  final String snapshotWib;

  /// Keterangan sumber data.
  final String source;

  /// Lencana situs ("100% Original", ...).
  final List<String> siteBadges;

  /// Kategori, urut tampil.
  final List<ProductCategory> categories;

  /// Brand, urut abjad.
  final List<String> brands;

  /// Produk, urut sumber.
  final List<Product> products;
}
