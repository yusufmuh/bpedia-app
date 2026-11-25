import 'package:bpedia_app/app/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalog/shop_test_support.dart';

void main() {
  testWidgets('kolom kosong: riwayat, kategori populer, brand pilihan', (
    tester,
  ) async {
    final services = shopServices();
    services.searchHistory
      ..record('sunscreen')
      ..record('serum');
    await pumpShop(tester, services, '/cari');
    expect(find.text('Riwayat pencarian'), findsOneWidget);
    expect(find.text('serum'), findsOneWidget);
    expect(find.text('Kategori populer'), findsOneWidget);
    expect(find.text('Brand pilihan'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus "serum" dari riwayat'));
    await tester.pump();
    expect(services.searchHistory.terms, <String>['sunscreen']);
    await tester.tap(find.text('Hapus semua'));
    await tester.pump();
    expect(services.searchHistory.terms, isEmpty);
    expect(find.text('Riwayat pencarian'), findsNothing);
  });

  testWidgets('mengetik menampilkan saran, kirim membuka katalog', (
    tester,
  ) async {
    final services = shopServices();
    await pumpShop(tester, services, '/cari');
    await tester.enterText(
      find.byKey(const ValueKey<String>('cari-kolom')).first,
      'acne',
    );
    await tester.pump();
    expect(find.text('Cari "acne"'), findsOneWidget);
    expect(find.text('Produk'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('cari-semua')));
    await settle(tester);
    final route = services.router.tabRoute.value;
    expect(route, isA<CatalogRoute>());
    expect((route as CatalogRoute).query, 'acne');
    expect(services.searchHistory.terms.first, 'acne');
    expect(services.analyticsLog.records.first.name, 'af_search');
  });

  testWidgets('saran brand membuka katalog berfilter brand', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/cari?q=wardah');
    await tester.tap(find.text('Wardah').first);
    await settle(tester);
    final route = services.router.tabRoute.value as CatalogRoute;
    expect(route.brands, <String>['Wardah']);
  });

  testWidgets('saran produk membuka detail produk', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/cari?q=Mugwort Daily Sunscreen');
    await tester.tap(find.textContaining('ACNAWAY Mugwort').first);
    await settle(tester);
    expect(find.text('Pengiriman'), findsOneWidget);
  });

  testWidgets('kata tanpa hasil memberi petunjuk', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/cari?q=zzzz');
    expect(find.textContaining('Belum ada produk yang cocok'), findsOneWidget);
  });

  testWidgets('teks 200% pada lebar 360 tanpa luapan', (tester) async {
    final services = shopServices();
    services.searchHistory.record('lip cream matte tahan lama');
    await pumpShop(tester, services, '/cari', size: narrowPhone, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey<String>('cari-kolom')).first,
      'serum',
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
