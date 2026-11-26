import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/catalog/catalog_repository.dart';
import 'package:bpedia_app/features/catalog/catalog_query_route.dart';
import 'package:bpedia_app/features/catalog/filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shop_test_support.dart';

CatalogRoute _route(AppServices services) {
  final route = services.router.tabRoute.value;
  expect(route, isA<CatalogRoute>());
  return route as CatalogRoute;
}

void main() {
  test('kueri dan rute katalog saling bolak-balik', () {
    final query = CatalogQuery(
      text: 'serum',
      categoryId: 'skincare',
      brands: <String>['Wardah', 'Animate'],
      minPrice: 10000,
      maxPrice: 50000,
      sort: CatalogSort.cheapest,
    );
    final route = routeOfQuery(query);
    expect(route.brands, <String>['Animate', 'Wardah']);
    expect(route.sort, 'termurah');
    expect(queryOfRoute(route), query);
    expect(routeOfQuery(CatalogQuery()).location, '/katalog');
  });

  testWidgets('katalog menampilkan semua produk dan kategori', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/katalog');
    expect(
      find.text('${services.catalog.products.length} produk'),
      findsOneWidget,
    );
    expect(find.text('Skincare'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('katalog-filter')),
      findsOneWidget,
    );
  });

  testWidgets('rel kategori tetap tampil dan ubin terpilih bisa dilepas', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/katalog?kategori=skincare');
    expect(
      find.byKey(const ValueKey<String>('katalog-kategori')),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Kategori Makeup'));
    await settle(tester);
    expect(_route(services).category, 'makeup');
    await tester.tap(find.bySemanticsLabel('Kategori Makeup, terpilih'));
    await settle(tester);
    expect(_route(services).category, isNull);
  });

  testWidgets('chip urutan mengubah parameter rute', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/katalog');
    await tester.tap(find.text('Termurah'));
    await settle(tester);
    expect(_route(services).sort, 'termurah');
    expect(find.text('Termurah'), findsOneWidget);
  });

  testWidgets('filter aktif tampil sebagai chip dan bisa dihapus', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(
      tester,
      services,
      '/katalog?kategori=skincare&brand=Animate',
    );
    final expected = services.catalog
        .search(
          CatalogQuery(categoryId: 'skincare', brands: <String>['Animate']),
        )
        .length;
    expect(find.text('$expected produk'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Hapus filter Animate'));
    await settle(tester);
    expect(_route(services).brands, isEmpty);
    expect(_route(services).category, 'skincare');
    expect(
      find.bySemanticsLabel('Kategori Skincare, terpilih'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('katalog-hapus-filter')),
    );
    await settle(tester);
    expect(_route(services).category, isNull);
  });

  testWidgets('lembar Filter: pilih brand dan harga lalu Terapkan', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/katalog');
    await tester.tap(find.byKey(const ValueKey<String>('katalog-filter')));
    await settle(tester);
    expect(find.byType(CatalogFilterSheet), findsOneWidget);
    await tester.enterText(
      find
          .descendant(
            of: find.byType(CatalogFilterSheet),
            matching: find.byType(TextField),
          )
          .first,
      'ward',
    );
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Wardah'));
    await tester.pump();
    await tester.tap(find.text(priceRanges[1].label));
    await tester.pump();
    final expected = services.catalog
        .search(
          CatalogQuery(
            brands: <String>['Wardah'],
            minPrice: priceRanges[1].min,
            maxPrice: priceRanges[1].max,
          ),
        )
        .length;
    final apply = find.text('Terapkan ($expected produk)');
    expect(apply, findsOneWidget);
    await tester.tap(apply);
    await settle(tester);
    final route = _route(services);
    expect(route.brands, <String>['Wardah']);
    expect(route.minPrice, 25000);
    expect(route.maxPrice, 50000);
  });

  testWidgets('lembar Filter: 4 brand terbanyak berjumlah, Lihat semua', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/katalog?kategori=skincare');
    await tester.tap(find.byKey(const ValueKey<String>('katalog-filter')));
    await settle(tester);
    final counts = <String, int>{};
    for (final product in services.catalog.search(
      CatalogQuery(categoryId: 'skincare'),
    )) {
      counts[product.brand] = (counts[product.brand] ?? 0) + 1;
    }
    final top = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final sheet = find.byType(CatalogFilterSheet);
    expect(
      find.descendant(of: sheet, matching: find.text(top.first.key)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('${top.first.value}')),
      findsWidgets,
    );
    expect(
      find.descendant(of: sheet, matching: find.text(top[4].key)),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey<String>('filter-brand-semua')));
    await tester.pump();
    expect(
      find.descendant(of: sheet, matching: find.text(top[4].key)),
      findsOneWidget,
    );
  });

  testWidgets('rentang harga terbalik menonaktifkan Terapkan', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/katalog');
    await tester.tap(find.byKey(const ValueKey<String>('katalog-filter')));
    await settle(tester);
    final fields = find.descendant(
      of: find.byType(CatalogFilterSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(1), '90000');
    await tester.enterText(fields.at(2), '10000');
    await tester.pump();
    expect(find.text('Cek rentang harga'), findsOneWidget);
  });

  testWidgets('hasil kosong menampilkan Bipy dan saran produk', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/katalog?q=sepatu');
    expect(find.text('Belum ketemu, Babes'), findsOneWidget);
    expect(find.text('Mungkin kamu suka'), findsOneWidget);
    await tester.tap(find.text('Lihat semua produk'));
    await settle(tester);
    expect(_route(services).query, isNull);
  });

  testWidgets('kartu: tambah cepat dan wishlist', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/katalog?q=Mugwort Daily Sunscreen');
    final card = find.byKey(const ValueKey<String>('produk-$plainCode'));
    expect(card, findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: card,
            matching: find.bySemanticsLabel(
              RegExp('wishlist', caseSensitive: false),
            ),
          )
          .first,
    );
    await tester.pump();
    expect(services.wishlist.contains(plainCode), isTrue);
    await tester.tap(
      find
          .descendant(
            of: card,
            matching: find.bySemanticsLabel(
              RegExp('keranjang', caseSensitive: false),
            ),
          )
          .first,
    );
    await tester.pump();
    expect(services.cart.quantityOf(plainCode), 1);
    expect(find.text('Masuk keranjang, Babes.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const ValueKey<String>('terbang-keranjang')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey<String>('terbang-keranjang')),
      findsNothing,
    );
    await tester.tap(card);
    await settle(tester);
    expect(find.text('Info produk'), findsNothing);
    expect(find.text('Pengiriman'), findsOneWidget);
  });

  testWidgets('teks 200% pada lebar 360 tanpa luapan', (tester) async {
    final services = shopServices();
    await pumpShop(
      tester,
      services,
      '/katalog?kategori=makeup&brand=Focallure&maks=50000',
      size: narrowPhone,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey<String>('katalog-filter')));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
