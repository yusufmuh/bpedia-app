/// Bagian bersama layar jelajah: data kartu produk, kartu yang sudah
/// tersambung ke wishlist dan keranjang, tambah ke keranjang dengan umpan
/// balik, tombol notifikasi, dan label tanggal WIB.
library;

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../data/wib_dates.dart';
import '../../design/design.dart';

const List<String> _monthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// "25 Nov" untuk nomor hari WIB [wibDay].
String wibShortDate(int wibDay) {
  final date = dateOfWibDay(wibDay);
  return '${date.day} ${_monthsShort[date.month - 1]}';
}

const List<String> _weekdays = <String>[
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// "Sabtu" untuk nomor hari WIB [wibDay].
String wibDayName(int wibDay) => _weekdays[dateOfWibDay(wibDay).weekday - 1];

/// "25 Nov 2026" untuk nomor hari WIB [wibDay].
String wibLongDate(int wibDay) =>
    '${wibShortDate(wibDay)} ${dateOfWibDay(wibDay).year}';

/// "potret 25 Nov 2026" dari waktu potret ISO katalog.
String snapshotDateLabel(String iso) {
  final day = iso.length >= 10 ? tryParseWibDay(iso.substring(0, 10)) : null;
  return day == null ? 'potret terakhir' : 'potret ${wibLongDate(day)}';
}

/// Saat 24.00 WIB pada akhir hari WIB [wibDay] (UTC).
DateTime wibEndOfDay(int wibDay) => DateTime.utc(
  1970,
).add(Duration(days: wibDay + 1)).subtract(const Duration(hours: 7));

/// "13:59:08" untuk sisa waktu [remaining]; jam bisa lebih dari 24.
String countdownText(Duration remaining) {
  final safe = remaining.isNegative ? Duration.zero : remaining;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(safe.inHours)}:${two(safe.inMinutes % 60)}:'
      '${two(safe.inSeconds % 60)}';
}

/// Nama kategori produk untuk tampilan.
String categoryNameOf(AppServices services, String categoryId) =>
    services.catalog.categoryById(categoryId)?.name ?? categoryId;

/// Brand dengan produk terbanyak di katalog, lalu abjad.
List<String> popularBrands(AppServices services, {int limit = 10}) {
  final counts = <String, int>{};
  for (final product in services.catalog.products) {
    counts[product.brand] = (counts[product.brand] ?? 0) + 1;
  }
  final brands = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return brands.take(limit).toList(growable: false);
}

/// Apakah [product] termasuk produk Misi Belanja tahap aktif.
bool isMissionProduct(AppServices services, Product product) =>
    services.rewards.available &&
    services.rewards.missionProductCodes.contains(product.code);

/// Data tampilan kartu dari produk katalog.
ProductCardData productCardData(Product product, {bool mission = false}) {
  final percent = product.discountPercent;
  return ProductCardData(
    id: product.code,
    name: product.name,
    price: product.price,
    imageAsset: product.primaryImage,
    strikePrice: product.strikePrice,
    discountPercent: product.hasDiscount ? percent : null,
    rating: product.rating,
    brand: product.brand,
    ribbon: mission
        ? 'Produk misi'
        : product.isHot
        ? 'Hot Item'
        : null,
    inStock: product.inStock,
  );
}

/// Membuka [location] dari data (promo, notifikasi) lewat router app.
void openAppLocation(BuildContext context, String location) {
  AppScope.of(context).router.go(context, parseAppRoute(location));
}

/// Menambah [product] ke keranjang lalu memberi tahu hasilnya: getar ringan
/// dan pesan singkat dengan tautan ke keranjang.
void addProductToCart(BuildContext context, Product product, {int qty = 1}) {
  final services = AppScope.of(context);
  final change = services.cart.add(product.code, qty: qty);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (change.changed) {
    services.haptics.light();
  } else {
    services.haptics.medium();
  }
  if (messenger == null) return;
  final limit = change.limit;
  final text = change.changed
      ? limit == null
            ? 'Masuk keranjang, Babes.'
            : 'Masuk keranjang. ${limit.message}'
      : limit?.message ?? 'Jumlah di keranjang sudah maksimal.';
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: change.changed
            ? SnackBarAction(
                label: 'Lihat',
                onPressed: () => services.router.go(context, const CartRoute()),
              )
            : null,
      ),
    );
}

/// Menambah atau menghapus [product] dari wishlist dengan pesan singkat.
void toggleWishlist(BuildContext context, Product product) {
  final services = AppScope.of(context);
  final added = services.wishlist.toggle(product.code);
  services.haptics.selection();
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Disimpan ke wishlist.' : 'Dihapus dari wishlist.',
        ),
        action: added
            ? SnackBarAction(
                label: 'Lihat',
                onPressed: () =>
                    services.router.go(context, const WishlistRoute()),
              )
            : null,
      ),
    );
}

/// Kartu produk yang tersambung: ketuk membuka detail, hati mengubah
/// wishlist, tombol tambah memasukkan ke keranjang.
class ShopProductCard extends StatelessWidget {
  const ShopProductCard({
    required this.product,
    this.action = ProductCardAction.quickAdd,
    super.key,
  });

  final Product product;
  final ProductCardAction action;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.wishlist,
        services.rewards,
      ]),
      builder: (context, _) => ProductCard(
        key: ValueKey<String>('produk-${product.code}'),
        data: productCardData(
          product,
          mission: isMissionProduct(services, product),
        ),
        action: action,
        wishlisted: services.wishlist.contains(product.code),
        onTap: () => services.router.go(context, ProductRoute(product.code)),
        onToggleWishlist: () => toggleWishlist(context, product),
        onAddToCart: action == ProductCardAction.none
            ? null
            : () => addProductToCart(context, product),
      ),
    );
  }
}

/// Lonceng notifikasi berlencana jumlah belum dibaca (hanya setelah masuk).
class InboxButton extends StatelessWidget {
  const InboxButton({super.key, this.color});

  /// Warna ikon; bawaan `text`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[services.inbox, services.auth]),
      builder: (context, _) => BadgeIcon(
        icon: BrandIcon(BrandGlyph.notif, color: color ?? context.bp.text),
        label: 'Notifikasi',
        count: services.auth.isLoggedIn ? services.inbox.unreadCount : 0,
        countNoun: 'belum dibaca',
        onPressed: () => services.router.go(context, const InboxRoute()),
      ),
    );
  }
}

/// Isi area produk saat katalog belum siap atau gagal dimuat. Mengembalikan
/// null bila katalog siap.
Widget? catalogStateView(BuildContext context, {bool sliver = false}) {
  final services = AppScope.of(context);
  final catalog = services.catalog;
  Widget? view;
  if (!catalog.isLoaded) {
    view = const _GridSkeleton();
  } else if (catalog.loadError != null) {
    view = EmptyState(
      title: 'Katalog belum bisa dimuat',
      message: 'Periksa ruang penyimpanan perangkat lalu coba lagi, Babes.',
      imageAsset: 'assets/bipy/bipy_pose_semangat.webp',
      actionLabel: 'Coba lagi',
      onAction: () => catalog.load(DefaultAssetBundle.of(context)),
    );
  }
  if (view == null) return null;
  return sliver ? SliverToBoxAdapter(child: view) : view;
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BpSpace.x2),
      child: ProductGrid(
        itemCount: 4,
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      ),
    );
  }
}
