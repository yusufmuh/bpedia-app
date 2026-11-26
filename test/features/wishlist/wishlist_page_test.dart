import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalog/shop_test_support.dart';

void main() {
  testWidgets('wishlist kosong mengajak belanja', (tester) async {
    final services = shopServices(loggedIn: true);
    await pumpShop(tester, services, '/wishlist');
    expect(find.text('Wishlist masih kosong'), findsOneWidget);
    await tester.tap(find.text('Mulai belanja'));
    await settle(tester);
    expect(services.router.currentTab.name, 'catalog');
  });

  testWidgets('tamu melihat produk favorit dan ajakan masuk', (tester) async {
    final services = shopServices();
    services.wishlist
      ..toggle(plainCode)
      ..toggle(hotCode);
    await pumpShop(tester, services, '/wishlist');
    expect(find.text('2 produk tersimpan'), findsOneWidget);
    expect(find.text('Semua (2)'), findsOneWidget);
    expect(
      find.textContaining('Wishlist tersimpan di perangkat ini'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('produk-$hotCode')),
      findsOneWidget,
    );
  });

  testWidgets('sudah masuk: tambah ke keranjang dan hapus dari wishlist', (
    tester,
  ) async {
    final services = shopServices(loggedIn: true);
    services.wishlist.toggle(plainCode);
    await pumpShop(tester, services, '/wishlist');
    expect(find.textContaining('Wishlist tersimpan'), findsNothing);
    final card = find.byKey(const ValueKey<String>('produk-$plainCode'));
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
    await settle(tester);
    expect(services.wishlist.count, 0);
    expect(find.text('Wishlist masih kosong'), findsOneWidget);
  });

  testWidgets('chip kategori berjumlah menyaring wishlist', (tester) async {
    final services = shopServices(loggedIn: true);
    services.wishlist
      ..toggle(plainCode)
      ..toggle(hotCode)
      ..toggle('P11B11B01000004');
    await pumpShop(tester, services, '/wishlist');
    final bodycare = services.wishlist.products
        .where((product) => product.categoryId == 'bodycare')
        .length;
    expect(find.text('Semua (3)'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('wishlist-kategori-bodycare')),
    );
    await tester.pump();
    expect(find.text('$bodycare produk tersimpan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('produk-P11B11B01000004')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('produk-$hotCode')), findsNothing);
  });

  testWidgets('Atur: pilih lalu hapus massal', (tester) async {
    final services = shopServices(loggedIn: true);
    services.wishlist
      ..toggle(plainCode)
      ..toggle(hotCode);
    await pumpShop(tester, services, '/wishlist');
    await tester.tap(find.byKey(const ValueKey<String>('wishlist-atur')));
    await tester.pump();
    expect(find.text('Pilih produk untuk dihapus'), findsOneWidget);
    final product = services.catalog.byCode(hotCode)!;
    await tester.tap(find.bySemanticsLabel(product.name).last);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('wishlist-hapus')));
    await settle(tester);
    expect(services.wishlist.contains(hotCode), isFalse);
    expect(services.wishlist.contains(plainCode), isTrue);
    expect(find.text('1 produk dihapus dari wishlist.'), findsOneWidget);
  });

  testWidgets('ikon cari membuka pencarian', (tester) async {
    final services = shopServices(loggedIn: true);
    services.wishlist.toggle(plainCode);
    await pumpShop(tester, services, '/wishlist');
    await tester.tap(find.byKey(const ValueKey<String>('wishlist-cari')));
    await settle(tester);
    expect(find.text('Wishlist'), findsNothing);
  });

  testWidgets('teks 200% pada lebar 360 tanpa luapan', (tester) async {
    final services = shopServices();
    services.wishlist
      ..toggle(plainCode)
      ..toggle('P39A06S01000007');
    await pumpShop(
      tester,
      services,
      '/wishlist',
      size: narrowPhone,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
