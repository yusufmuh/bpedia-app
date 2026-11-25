/// Kueri katalog: teks, kategori, brand, rentang harga, dan urutan (Dart murni).
library;

/// Enam urutan katalog (SPEC §4.3).
enum CatalogSort {
  /// Paling Sesuai.
  relevance('sesuai', 'Paling Sesuai'),

  /// Termurah.
  cheapest('termurah', 'Termurah'),

  /// Termahal.
  priciest('termahal', 'Termahal'),

  /// Diskon Terbesar.
  biggestDiscount('diskon', 'Diskon Terbesar'),

  /// Nama A–Z.
  nameAsc('nama-az', 'Nama A–Z'),

  /// Nama Z–A.
  nameDesc('nama-za', 'Nama Z–A');

  const CatalogSort(this.param, this.label);

  /// Nilai parameter `urut` di rute.
  final String param;

  /// Teks chip urutan.
  final String label;

  /// Urutan untuk nilai parameter [param]; tak dikenal → [relevance].
  static CatalogSort fromParam(String? param) {
    for (final sort in values) {
      if (sort.param == param) return sort;
    }
    return relevance;
  }
}

/// Kueri katalog tak-berubah.
final class CatalogQuery {
  CatalogQuery({
    String text = '',
    this.categoryId,
    Iterable<String> brands = const <String>[],
    this.minPrice,
    this.maxPrice,
    this.sort = CatalogSort.relevance,
    this.hotOnly = false,
  }) : text = text.trim(),
       brands = Set<String>.unmodifiable(brands);

  /// Teks cari (nama, brand, kategori, deskripsi).
  final String text;

  /// Batasi ke satu kategori.
  final String? categoryId;

  /// Batasi ke brand ini (kosong = semua).
  final Set<String> brands;

  /// Harga terendah (rupiah, inklusif).
  final int? minPrice;

  /// Harga tertinggi (rupiah, inklusif).
  final int? maxPrice;

  /// Urutan hasil.
  final CatalogSort sort;

  /// Hanya produk Hot Item.
  final bool hotOnly;

  /// Jumlah filter aktif (kategori, tiap brand, rentang harga) untuk lencana
  /// tombol Filter. Teks cari dan urutan tidak dihitung.
  int get activeFilterCount =>
      (categoryId == null ? 0 : 1) +
      brands.length +
      (minPrice == null && maxPrice == null ? 0 : 1);

  /// Apakah tidak ada teks maupun filter.
  bool get isEmpty => text.isEmpty && activeFilterCount == 0 && !hotOnly;

  /// Salinan dengan bidang diganti. Pakai `clear*` untuk mengosongkan bidang
  /// yang boleh null.
  CatalogQuery copyWith({
    String? text,
    String? categoryId,
    Iterable<String>? brands,
    int? minPrice,
    int? maxPrice,
    CatalogSort? sort,
    bool? hotOnly,
    bool clearCategory = false,
    bool clearPrice = false,
  }) => CatalogQuery(
    text: text ?? this.text,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    brands: brands ?? this.brands,
    minPrice: clearPrice ? null : minPrice ?? this.minPrice,
    maxPrice: clearPrice ? null : maxPrice ?? this.maxPrice,
    sort: sort ?? this.sort,
    hotOnly: hotOnly ?? this.hotOnly,
  );

  /// Kueri yang sama tanpa filter (teks, urutan, dan [hotOnly] dipertahankan).
  CatalogQuery withoutFilters() =>
      CatalogQuery(text: text, sort: sort, hotOnly: hotOnly);

  @override
  bool operator ==(Object other) =>
      other is CatalogQuery &&
      other.text == text &&
      other.categoryId == categoryId &&
      other.brands.length == brands.length &&
      other.brands.containsAll(brands) &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.sort == sort &&
      other.hotOnly == hotOnly;

  @override
  int get hashCode => Object.hash(
    text,
    categoryId,
    Object.hashAllUnordered(brands),
    minPrice,
    maxPrice,
    sort,
    hotOnly,
  );
}
