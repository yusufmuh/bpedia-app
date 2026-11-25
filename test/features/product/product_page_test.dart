import 'package:bpedia_app/features/product/add_to_cart_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalog/shop_test_support.dart';

void main() {
  testWidgets('detail menampilkan harga, brand, lencana, dan mencatat view', (
    tester,
  ) async {
    final services = shopServices();
    final product = services.catalog.byCode(plainCode)!;
    await pumpShop(tester, services, '/produk/$plainCode');
    expect(find.text(product.name), findsWidgets);
    expect(find.text(product.brand), findsWidgets);
    expect(find.text('100% Original'), findsOneWidget);
    expect(find.text('BPOM terverifikasi'), findsOneWidget);
    expect(find.text('Pengiriman'), findsOneWidget);
    expect(find.text('1/${product.images.length}'), findsOneWidget);
    expect(
      services.analyticsLog.records.any(
        (record) =>
            record.name == 'af_content_view' &&
            record.values.values.contains(plainCode),
      ),
      isTrue,
    );
    expect(find.byKey(const ValueKey<String>('detail-misi')), findsNothing);
  });

  testWidgets('produk misi menampilkan pita Misi Belanja', (tester) async {
    final services = shopServices(
      rewards: FakeShopRewards(missionCodes: <String>{plainCode}),
    );
    await pumpShop(tester, services, '/produk/$plainCode');
    expect(find.byKey(const ValueKey<String>('detail-misi')), findsOneWidget);
  });

  testWidgets('lembar jumlah menambah ke keranjang', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/produk/$plainCode');
    await tester.tap(find.byKey(const ValueKey<String>('detail-tambah')));
    await settle(tester);
    expect(find.byType(AddToCartSheet), findsOneWidget);
    await tester.tap(find.byTooltip('Tambah jumlah').first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('lembar-tambah')));
    await settle(tester);
    expect(services.cart.quantityOf(plainCode), 2);
    expect(find.text('Masuk keranjang, Babes.'), findsOneWidget);
  });

  testWidgets('Hot Item dibatasi 1 per pesanan', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/produk/$hotCode');
    expect(find.textContaining('maks. 1 per pesanan'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('detail-tambah')));
    await settle(tester);
    expect(find.text('Hot Item: maksimal 1 per pesanan.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('lembar-tambah')));
    await settle(tester);
    expect(services.cart.quantityOf(hotCode), 1);
    await tester.tap(find.byKey(const ValueKey<String>('detail-tambah')));
    await settle(tester);
    expect(find.textContaining('sudah batas maksimal'), findsOneWidget);
  });

  testWidgets('Beli sekarang memilih hanya produk itu lalu ke checkout', (
    tester,
  ) async {
    final services = shopServices(loggedIn: true);
    services.cart.add(hotCode);
    await pumpShop(tester, services, '/produk/$plainCode');
    await tester.tap(find.byKey(const ValueKey<String>('detail-beli')));
    await settle(tester);
    expect(services.cart.quantityOf(plainCode), 1);
    expect(
      services.cart.selectedItems.map((item) => item.product.code),
      <String>[plainCode],
    );
    expect(services.router.navigatorKey.currentState!.canPop(), isTrue);
  });

  testWidgets('hati menyimpan ke wishlist', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/produk/$plainCode');
    await tester.tap(find.byKey(const ValueKey<String>('detail-wishlist')));
    await tester.pump();
    expect(services.wishlist.contains(plainCode), isTrue);
    expect(find.text('Disimpan ke wishlist.'), findsOneWidget);
  });

  testWidgets('kode tidak dikenal menampilkan keadaan kosong', (tester) async {
    final services = shopServices();
    await pumpShop(tester, services, '/produk/TIDAKADA');
    expect(find.text('Produk tidak ditemukan'), findsOneWidget);
    await tester.tap(find.text('Lihat katalog'));
    await settle(tester);
    expect(services.router.currentTab.name, 'catalog');
  });

  testWidgets('teks 200% pada lebar 360 tanpa luapan', (tester) async {
    final services = shopServices(
      rewards: FakeShopRewards(missionCodes: <String>{hotCode}),
    );
    await pumpShop(
      tester,
      services,
      '/produk/$hotCode',
      size: narrowPhone,
      textScale: 2,
    );
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
  });
}
