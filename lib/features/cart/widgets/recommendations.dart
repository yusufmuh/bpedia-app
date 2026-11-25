/// Grid "Kamu mungkin suka" di bawah keranjang dan layar sukses, supaya
/// layar pendek tidak berakhir di ruang kosong.
library;

import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../app/app_scope.dart';
import '../../../data/cart/cart_repository.dart';
import '../../../data/catalog/catalog_repository.dart';
import '../../../design/design.dart';

/// Model kartu dari produk katalog.
ProductCardData productCardDataOf(Product product) => ProductCardData(
  id: product.code,
  name: product.name,
  price: product.price,
  imageAsset: product.primaryImage,
  strikePrice: product.strikePrice,
  discountPercent: product.discountPercent,
  rating: product.rating,
  brand: product.brand,
  inStock: product.inStock,
);

/// Produk rekomendasi: mirip barang pertama di [exclude], lalu Hot Item,
/// lalu urutan katalog; tanpa produk yang sudah ada di [exclude].
List<Product> recommendedProducts(
  CatalogRepository catalog, {
  required List<String> exclude,
  int limit = 6,
}) {
  final skip = exclude.toSet();
  final picked = <Product>[];
  void take(Iterable<Product> source) {
    for (final product in source) {
      if (picked.length >= limit) return;
      if (skip.contains(product.code) || !product.inStock) continue;
      if (picked.any((p) => p.code == product.code)) continue;
      picked.add(product);
    }
  }

  if (exclude.isNotEmpty) take(catalog.similarTo(exclude.first, limit: limit));
  take(catalog.hotItems);
  take(catalog.products);
  return picked;
}

/// Seksi grid produk rekomendasi dengan tombol tambah cepat.
class RecommendationSection extends StatelessWidget {
  const RecommendationSection({
    super.key,
    required this.exclude,
    this.title = 'Kamu mungkin suka',
  });

  /// Kode produk yang tidak ditampilkan (sudah di keranjang).
  final List<String> exclude;
  final String title;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final products = recommendedProducts(services.catalog, exclude: exclude);
    if (products.isEmpty) return const SizedBox.shrink();
    return Section(
      gap: false,
      header: SectionHeader(
        title: title,
        onAction: () => services.router.go(context, const CatalogRoute()),
      ),
      child: ListenableBuilder(
        listenable: services.wishlist,
        builder: (context, _) => ProductGrid(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              data: productCardDataOf(product),
              wishlisted: services.wishlist.contains(product.code),
              onToggleWishlist: () => services.wishlist.toggle(product.code),
              onTap: () =>
                  services.router.go(context, ProductRoute(product.code)),
              onAddToCart: () => _add(context, product),
            );
          },
        ),
      ),
    );
  }

  void _add(BuildContext context, Product product) {
    final services = AppScope.of(context);
    final change = services.cart.add(product.code);
    services.haptics.light();
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final limit = change.limit;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          change.changed
              ? 'Masuk keranjang: ${product.name}'
              : (limit?.message ?? CartLimit.stock.message),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
