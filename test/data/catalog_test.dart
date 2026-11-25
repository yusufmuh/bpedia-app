import 'dart:io';

import 'package:bpedia_app/data/catalog/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late CatalogRepository catalog;

  setUp(() => catalog = loadCatalog());

  test('82 produk asli dengan kode unik dan gambar yang ada', () {
    expect(catalog.isLoaded, isTrue);
    expect(catalog.loadError, isNull);
    expect(catalog.products.length, 82);
    expect(catalog.products.map((p) => p.code).toSet().length, 82);
    expect(catalog.snapshotWib, isNotEmpty);
    expect(catalog.siteBadges, contains('BPOM Verified'));
    for (final product in catalog.products) {
      expect(product.images, isNotEmpty, reason: product.code);
      expect(product.price, greaterThan(0), reason: product.code);
      for (final image in product.images) {
        expect(image, startsWith(catalogAssetRoot), reason: product.code);
        expect(File(image).existsSync(), isTrue, reason: image);
      }
    }
  });

  test('6 kategori berikon brand dan 26 brand, semuanya punya produk', () {
    expect(catalog.categories.length, 6);
    expect(catalog.brands.length, 26);
    for (final category in catalog.categories) {
      expect(
        File('assets/icons/bpedia-ikon-${category.icon}.svg').existsSync(),
        isTrue,
        reason: category.icon,
      );
      expect(
        catalog.search(CatalogQuery(categoryId: category.id)),
        isNotEmpty,
        reason: category.id,
      );
      expect(catalog.categoryById(category.id), same(category));
    }
    for (final brand in catalog.brands) {
      expect(
        catalog.search(CatalogQuery(brands: <String>[brand])),
        isNotEmpty,
        reason: brand,
      );
    }
    expect(catalog.categoryById('tidak-ada'), isNull);
  });

  test('5 Hot Item: harga jual = harga hot, gambar highlight asli', () {
    expect(catalog.hotItems.length, 5);
    for (final product in catalog.hotItems) {
      final hot = product.hot!;
      expect(product.price, hot.price, reason: product.code);
      expect(hot.normalPrice, greaterThan(hot.price));
      expect(File(hot.image).existsSync(), isTrue, reason: hot.image);
      expect(product.maxQty, lessThanOrEqualTo(hot.maxPerOrder));
    }
    expect(
      catalog.search(CatalogQuery(hotOnly: true)).map((p) => p.code).toSet(),
      catalog.hotItems.map((p) => p.code).toSet(),
    );
  });

  test('mencari nama dan brand tanpa peduli huruf besar', () {
    expect(catalog.byCode(codeB)!.brand, 'Animate');
    expect(catalog.byCode('TIDAK-ADA'), isNull);
    expect(catalog.byCodes(<String>[codeB, 'X', codeA]).length, 2);

    final animate = catalog.search(CatalogQuery(text: '  ANIMATE '));
    expect(animate, isNotEmpty);
    expect(animate.every((p) => p.brand == 'Animate'), isTrue);
    expect(catalog.search(CatalogQuery(text: 'zzzz-tidak-ada')), isEmpty);
    expect(catalog.search(CatalogQuery()).length, 82);

    final name = catalog.byCode(codeA)!.name.split(' ').take(2).join(' ');
    expect(
      catalog.search(CatalogQuery(text: name.toLowerCase())).first.name,
      startsWith(name.split(' ').first),
    );
  });

  test('filter kategori, brand jamak, dan rentang harga', () {
    final query = CatalogQuery(
      categoryId: 'skincare',
      brands: <String>['Animate', 'Acnaway'],
      minPrice: 20000,
      maxPrice: 30000,
    );
    final found = catalog.search(query);
    expect(found, isNotEmpty);
    for (final product in found) {
      expect(product.categoryId, 'skincare');
      expect(<String>['Animate', 'Acnaway'], contains(product.brand));
      expect(product.price, inInclusiveRange(20000, 30000));
    }
    expect(query.activeFilterCount, 4);
    expect(query.isEmpty, isFalse);
    expect(query.withoutFilters().isEmpty, isTrue);
    expect(query.copyWith(clearCategory: true).categoryId, isNull);
    expect(query.copyWith(clearPrice: true).minPrice, isNull);
    expect(query.copyWith(), query);
    expect(query.copyWith().hashCode, query.hashCode);
  });

  test('enam urutan', () {
    List<T> sorted<T>(CatalogSort sort, T Function(Product p) pick) => <T>[
      for (final product in catalog.search(CatalogQuery(sort: sort)))
        pick(product),
    ];

    final cheapest = sorted<int>(CatalogSort.cheapest, (p) => p.price);
    expect(cheapest, List<int>.of(cheapest)..sort());
    expect(cheapest.first, 3600);

    final priciest = sorted<int>(CatalogSort.priciest, (p) => p.price);
    expect(priciest, cheapest.reversed.toList());
    expect(priciest.first, 178800);

    final discounts = sorted<int>(
      CatalogSort.biggestDiscount,
      (p) => p.discountPercent ?? 0,
    );
    expect(discounts, (List<int>.of(discounts)..sort()).reversed.toList());

    final az = sorted<String>(
      CatalogSort.nameAsc,
      (p) => p.name.toLowerCase(),
    );
    expect(az, List<String>.of(az)..sort());
    final za = sorted<String>(
      CatalogSort.nameDesc,
      (p) => p.name.toLowerCase(),
    );
    expect(za, az.reversed.toList());

    expect(
      catalog.search(CatalogQuery()).map((p) => p.code).toList(),
      catalog.products.map((p) => p.code).toList(),
    );
    expect(CatalogSort.fromParam('termurah'), CatalogSort.cheapest);
    expect(CatalogSort.fromParam('entah'), CatalogSort.relevance);
    expect(CatalogSort.fromParam(null), CatalogSort.relevance);
    expect(
      <String>[for (final sort in CatalogSort.values) sort.label],
      <String>[
        'Paling Sesuai',
        'Termurah',
        'Termahal',
        'Diskon Terbesar',
        'Nama A–Z',
        'Nama Z–A',
      ],
    );
  });

  test('produk serupa: kategori sama, brand sama lebih dulu', () {
    final product = catalog.byCode(codeB)!;
    final similar = catalog.similarTo(codeB, limit: 6);
    expect(similar.length, 6);
    expect(similar.any((p) => p.code == codeB), isFalse);
    expect(similar.every((p) => p.categoryId == product.categoryId), isTrue);
    expect(similar.first.brand, product.brand);
    expect(catalog.similarTo('TIDAK-ADA'), isEmpty);
  });

  test('cari brand untuk lembar filter', () {
    expect(catalog.brandsMatching(''), catalog.brands);
    expect(catalog.brandsMatching('anim'), <String>['Animate']);
    expect(catalog.brandsMatching('zzz'), isEmpty);
  });

  test('JSON katalog rusak tidak membuat crash', () {
    final broken = CatalogRepository();
    var notified = 0;
    broken.addListener(() => notified++);
    expect(broken.isLoaded, isFalse);
    broken.loadFromJson('{bukan json');
    expect(broken.isLoaded, isTrue);
    expect(broken.loadError, isNotNull);
    expect(broken.products, isEmpty);
    broken.loadFromJson('{"products": [{"code": 1}]}');
    expect(broken.products, isEmpty);
    expect(notified, greaterThan(0));
    broken.loadFromJson(readCatalogJson());
    expect(broken.loadError, isNull);
    expect(broken.products.length, 82);
  });
}
