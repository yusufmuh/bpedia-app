import 'package:bpedia_app/data/cart/cart_repository.dart';
import 'package:bpedia_app/data/catalog/catalog_repository.dart';
import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late CatalogRepository catalog;
  late LocalAnalytics analytics;
  late CartRepository cart;

  setUp(() {
    catalog = loadCatalog();
    analytics = LocalAnalytics();
    cart = CartRepository(catalog: catalog, analytics: analytics);
  });

  test('menambah, membatasi 99, mengubah, dan menghapus dengan urung', () {
    expect(cart.isEmpty, isTrue);
    expect(cart.allSelected, isFalse);

    final added = cart.add(codeMany, qty: 2);
    expect(added.added, 2);
    expect(added.limit, isNull);
    cart.add(codeMany);
    expect(cart.quantityOf(codeMany), 3);
    expect(cart.lineCount, 1);
    expect(cart.count, 3);

    final product = catalog.byCode(codeMany)!;
    expect(product.maxQty, 95);
    final capped = cart.setQty(codeMany, 500);
    expect(capped.qty, 95);
    expect(capped.limit, CartLimit.stock);
    expect(cart.items.single.atMax, isTrue);

    cart.add(codeB);
    final removed = cart.remove(codeMany)!;
    expect(removed.index, 0);
    expect(cart.lines.single.productCode, codeB);
    cart.undoRemove(removed);
    expect(cart.lines.first.productCode, codeMany);
    expect(cart.quantityOf(codeMany), 95);

    expect(cart.setQty(codeB, 0).qty, 0);
    expect(cart.quantityOf(codeB), 0);
    expect(cart.remove(codeB), isNull);
  });

  test('batas stok: tidak bisa melebihi stok yang ada', () {
    expect(cart.add(codeLastOne).added, 1);
    final again = cart.add(codeLastOne);
    expect(again.added, 0);
    expect(again.changed, isFalse);
    expect(again.limit, CartLimit.stock);
    expect(again.limit!.message, contains('stok'));
    expect(cart.quantityOf(codeLastOne), 1);
  });

  test('Hot Item mengikuti batas per pesanan', () {
    final hot = catalog.byCode(hotCode)!;
    expect(hot.hot!.maxPerOrder, 1);
    expect(hot.price, hot.hot!.price);

    final change = cart.add(hotCode, qty: 3);
    expect(change.qty, 1);
    expect(change.limit, CartLimit.perOrder);
    expect(cart.setQty(hotCode, 2).limit, CartLimit.perOrder);
    expect(cart.quantityOf(hotCode), 1);
  });

  test('produk tak dikenal dan jumlah tidak sah', () {
    final unknown = cart.add('TIDAK-ADA');
    expect(unknown.limit, CartLimit.unknownProduct);
    expect(cart.isEmpty, isTrue);
    expect(() => cart.add(codeB, qty: 0), throwsArgumentError);
    expect(cart.setQty('TIDAK-ADA', 0).qty, 0);
  });

  test('centang, pilih semua, subtotal terpilih, dan baris checkout', () {
    cart
      ..add(codeA)
      ..add(codeB, qty: 2)
      ..add(codeMany);
    expect(cart.allSelected, isTrue);
    expect(cart.selectedSubtotal, 46196 + 41000 + 26000);

    cart.setSelected(codeA, false);
    expect(cart.allSelected, isFalse);
    expect(cart.selectedLineCount, 2);
    expect(cart.selectedSubtotal, 67000);
    expect(cart.hasSelection, isTrue);
    expect(
      <String>[for (final line in cart.linesForCheckout) line.productCode],
      <String>[codeB, codeMany],
    );
    expect(cart.linesForCheckout.first.lineTotal, 41000);
    expect(
      <String>[for (final line in cart.pricedLines) line.productCode],
      <String>[codeB, codeMany],
      reason: 'dorongan misi hanya menghitung barang yang dicentang',
    );
    expect(
      cart.selectedWeightGrams,
      catalog.byCode(codeB)!.weightGrams * 2 +
          catalog.byCode(codeMany)!.weightGrams,
    );

    cart.selectAll(false);
    expect(cart.hasSelection, isFalse);
    expect(cart.selectedSubtotal, 0);
    cart.selectAll(true);
    expect(cart.allSelected, isTrue);

    cart.selectOnly(codeB);
    expect(cart.selectedItems.single.product.code, codeB);
  });

  test('menambah lagi produk yang tidak dicentang mencentangnya kembali', () {
    cart
      ..add(codeB)
      ..setSelected(codeB, false)
      ..add(codeB);
    expect(cart.lines.single.selected, isTrue);
    expect(cart.lines.single.qty, 2);
  });

  test('hapus yang dicentang bisa diurungkan ke posisi semula', () {
    cart
      ..add(codeA)
      ..add(codeB)
      ..add(codeMany)
      ..setSelected(codeB, false);

    final removed = cart.removeSelected();
    expect(removed.length, 2);
    expect(cart.lines.single.productCode, codeB);

    cart.restoreAll(removed);
    expect(
      <String>[for (final line in cart.lines) line.productCode],
      <String>[codeA, codeB, codeMany],
    );
    expect(cart.removeSelected().length, 2);
    cart.selectAll(false);
    expect(cart.removeSelected(), isEmpty);
  });

  test('urung menggabungkan jumlah bila produk sudah ditambahkan lagi', () {
    cart.add(codeB, qty: 2);
    final removed = cart.remove(codeB)!;
    cart.add(codeB, qty: 11);
    cart.undoRemove(removed);
    expect(cart.quantityOf(codeB), 12);
    expect(cart.lineCount, 1);
  });

  test('beli sekarang hanya mencentang produk itu', () {
    cart
      ..add(codeA)
      ..add(codeB, qty: 3);
    final change = cart.buyNow(codeB);
    expect(change.added, 0);
    expect(cart.quantityOf(codeB), 3);
    expect(cart.selectedItems.single.product.code, codeB);

    cart.buyNow(codeMany, qty: 2);
    expect(cart.quantityOf(codeMany), 2);
    expect(cart.selectedItems.single.product.code, codeMany);
  });

  test('removePurchased dan clear', () {
    cart
      ..add(codeA)
      ..add(codeB);
    cart.removePurchased(<String>[codeA, 'TIDAK-ADA']);
    expect(cart.lines.single.productCode, codeB);
    cart.clear();
    expect(cart.isEmpty, isTrue);
  });

  test('memberi tahu pendengar hanya saat berubah', () {
    var notified = 0;
    cart.addListener(() => notified++);
    cart.add(codeB);
    cart.setSelected(codeB, true);
    cart.selectAll(true);
    cart.setQty(codeB, 1);
    cart.clear();
    cart.clear();
    expect(notified, 2);
  });

  test('mencatat af_add_to_cart dengan jumlah yang benar-benar bertambah', () {
    cart.add(codeLastOne, qty: 5);
    cart.add(codeLastOne);
    final records = analytics.records
        .where((record) => record.name == AfEvent.addToCart)
        .toList();
    expect(records.length, 1);
    expect(records.single.values[AfParam.contentId], codeLastOne);
    expect(records.single.values[AfParam.quantity], 1);
    expect(records.single.values[AfParam.price], 20500);
  });

  group('persistensi', () {
    test('bolak-balik JSON', () {
      cart
        ..add(codeA, qty: 2)
        ..add(codeB)
        ..setSelected(codeB, false);
      final copy = CartRepository(catalog: catalog)..restore(cart.toJson());
      expect(copy.lines, cart.lines);
    });

    test('membuang baris yang produknya hilang dan menyesuaikan batas', () {
      cart.restore(<String, Object?>{
        'lines': <Object?>[
          <String, Object?>{'productCode': 'SUDAH-HILANG', 'qty': 2},
          <String, Object?>{'productCode': codeLastOne, 'qty': 7},
          <String, Object?>{'productCode': codeB, 'qty': 1, 'selected': false},
          <String, Object?>{'productCode': codeB, 'qty': 2, 'selected': true},
          <String, Object?>{'productCode': hotCode, 'qty': 4},
        ],
      });
      expect(cart.lineCount, 3);
      expect(cart.quantityOf(codeLastOne), 1);
      expect(cart.quantityOf(codeB), 3);
      expect(cart.lines[1].selected, isTrue);
      expect(cart.quantityOf(hotCode), 1);
    });

    test('JSON tidak sah ditolak dan keadaan lama utuh', () {
      cart.add(codeA);
      expect(
        () => cart.restore(<String, Object?>{
          'lines': <Object?>[
            <String, Object?>{'productCode': codeB, 'qty': 0},
          ],
        }),
        throwsFormatException,
      );
      expect(() => cart.restore('rusak'), throwsFormatException);
      expect(cart.quantityOf(codeA), 1);
      cart.restore(null);
      expect(cart.isEmpty, isTrue);
    });
  });
}
