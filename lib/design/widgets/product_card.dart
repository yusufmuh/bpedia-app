import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens.dart';
import 'asset_picture.dart';
import 'discount_badge.dart';
import 'price_text.dart';
import 'skeleton.dart';
import 'tappable.dart';

/// Model tampilan kartu produk. Dibuat layar dari data katalog; widget
/// desain tidak mengenal repositori.
@immutable
class ProductCardData {
  const ProductCardData({
    required this.id,
    required this.name,
    required this.price,
    this.imageAsset,
    this.image,
    this.strikePrice,
    this.discountPercent,
    this.rating,
    this.brand,
    this.ribbon,
    this.inStock = true,
  }) : assert(
         imageAsset == null || image == null,
         'Isi imageAsset atau image, bukan keduanya.',
       );

  /// Kode produk.
  final String id;
  final String name;

  /// Harga akhir dalam rupiah.
  final int price;

  /// Jalur aset gambar, mis. `assets/catalog/img/P39A06S01000021-1.webp`.
  final String? imageAsset;
  final ImageProvider? image;

  /// Harga sebelum diskon; tampil dicoret bila lebih besar dari [price].
  final int? strikePrice;

  /// Persen diskon untuk lencana pojok kanan atas.
  final int? discountPercent;

  /// Rating dari katalog. `null` = baris rating dikosongkan (tidak dikarang).
  final double? rating;

  /// Nama brand, tampil kecil di atas nama produk.
  final String? brand;

  /// Pita kecil menempel kiri bawah gambar, mis. "Produk misi".
  final String? ribbon;
  final bool inStock;

  bool get hasDiscount {
    final strike = strikePrice;
    return strike != null && strike > price;
  }
}

/// Aksi tambah ke keranjang pada kartu.
enum ProductCardAction {
  /// Tanpa tombol (rel Hot Item, produk serupa).
  none,

  /// Tombol bulat 32 berisi plus di kanan bawah.
  quickAdd,

  /// Tombol berbingkai "+ Keranjang" selebar kartu.
  addButton,
}

/// Kartu produk bergaya marketplace: gambar 1:1 penuh tepi, lencana diskon
/// di pojok kanan atas, nama dua baris, baris rating setinggi tetap, lalu
/// harga tebal dan harga coret.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.data,
    this.onTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.wishlisted = false,
    this.action = ProductCardAction.quickAdd,
    this.imageAspectRatio = 1,
    this.imageFit = BoxFit.cover,
    this.reserveRatingRow = true,
  });

  final ProductCardData data;
  final VoidCallback? onTap;

  /// `null` menyembunyikan tombol tambah.
  final VoidCallback? onAddToCart;

  /// `null` menyembunyikan tombol hati.
  final VoidCallback? onToggleWishlist;
  final bool wishlisted;
  final ProductCardAction action;

  /// Lebar : tinggi gambar. Rel Hot Item memakai rasio asli gambar highlight.
  final double imageAspectRatio;
  final BoxFit imageFit;

  /// Baris rating tetap dicadangkan walau kosong supaya harga sejajar
  /// antarkartu pada grid. Matikan pada rel yang tidak menampilkan rating.
  final bool reserveRatingRow;

  String _semanticLabel() {
    final buffer = StringBuffer(data.name);
    final brand = data.brand;
    if (brand != null) buffer.write(', $brand');
    buffer.write(', harga ${formatRupiah(data.price)}');
    final strike = data.strikePrice;
    if (data.hasDiscount && strike != null) {
      buffer.write(', harga sebelumnya ${formatRupiah(strike)}');
    }
    final percent = data.discountPercent;
    if (percent != null && percent > 0) {
      buffer.write(', diskon $percent persen');
    }
    final rating = data.rating;
    if (rating != null) buffer.write(', rating ${formatRating(rating)}');
    final ribbon = data.ribbon;
    if (ribbon != null) buffer.write(', $ribbon');
    if (!data.inStock) buffer.write(', stok habis');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final scaler = MediaQuery.textScalerOf(context);
    final add = data.inStock ? onAddToCart : null;
    final showQuickAdd =
        action == ProductCardAction.quickAdd && onAddToCart != null;
    final showAddButton =
        action == ProductCardAction.addButton && onAddToCart != null;
    final brand = data.brand;
    final rating = data.rating;
    final percent = data.discountPercent;
    final ribbon = data.ribbon;
    final wishlist = onToggleWishlist;

    final image = AspectRatio(
      aspectRatio: imageAspectRatio,
      child: ColoredBox(
        color: c.surfaceMuted,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Opacity(
              opacity: data.inStock ? 1 : 0.55,
              child: _ProductImage(data: data, fit: imageFit),
            ),
            if (!data.inStock)
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.scrim,
                    borderRadius: BpRadius.pillAll,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: Text(
                      'Stok habis',
                      style: BpText.label.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (percent != null && percent > 0)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: DiscountBadge(percent: percent, corner: true),
              ),
            if (ribbon != null)
              PositionedDirectional(
                start: 0,
                bottom: 0,
                child: _Ribbon(label: ribbon),
              ),
          ],
        ),
      ),
    );

    final info = Padding(
      padding: EdgeInsetsDirectional.only(
        start: BpSpace.cardDense,
        top: BpSpace.cardDense,
        end: showQuickAdd ? 0 : BpSpace.cardDense,
        bottom: showQuickAdd || showAddButton ? 0 : BpSpace.cardDense,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: showQuickAdd ? BpSpace.cardDense : 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (brand != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BpText.label.copyWith(color: c.textMuted),
                      ),
                    ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: scaler.scale(18) * 2,
                    ),
                    child: Text(
                      data.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BpText.bodyS.copyWith(color: c.text),
                    ),
                  ),
                  if (rating != null || reserveRatingRow) ...<Widget>[
                    const SizedBox(height: BpSpace.x1),
                    SizedBox(
                      height: scaler.scale(16),
                      child: rating == null ? null : _Rating(rating: rating),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 2,
                    bottom: showQuickAdd ? BpSpace.cardDense : 0,
                  ),
                  child: ExcludeSemantics(
                    child: PriceText(
                      data.price,
                      strikePrice: data.strikePrice,
                      stacked: true,
                    ),
                  ),
                ),
              ),
              if (showQuickAdd) _QuickAddButton(onPressed: add),
            ],
          ),
          if (showAddButton) _AddButton(onPressed: add),
        ],
      ),
    );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BpRadius.cardAll,
        border: Border.all(color: c.line),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(BpRadius.card - 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                ExcludeSemantics(child: image),
                if (wishlist != null)
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: _WishlistButton(
                      active: wishlisted,
                      onPressed: wishlist,
                    ),
                  ),
              ],
            ),
            info,
          ],
        ),
      ),
    );

    final tap = onTap;
    return Semantics(
      container: true,
      button: tap != null,
      label: _semanticLabel(),
      onTap: tap,
      child: _CardPress(onTap: tap, child: card),
    );
  }
}

/// Umpan balik tekan kartu (skala 0,97) tanpa menelan ketukan tombol di
/// dalamnya.
class _CardPress extends StatefulWidget {
  const _CardPress({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_CardPress> createState() => _CardPressState();
}

class _CardPressState extends State<_CardPress> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tap = widget.onTap;
    if (tap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: tap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed && !BpMotion.reduced(context) ? BpMotion.pressScale : 1,
        duration: BpMotion.micro,
        curve: BpMotion.microCurve,
        child: widget.child,
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.data, required this.fit});

  final ProductCardData data;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = data.imageAsset;
    final provider = data.image;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 180.0;
        final cacheWidth = AssetPicture.bucket(
          width * MediaQuery.devicePixelRatioOf(context),
        );
        if (asset != null) {
          return AssetPicture(asset, fit: fit, cacheWidth: cacheWidth);
        }
        if (provider != null) {
          return AssetPicture.provider(
            provider,
            fit: fit,
            cacheWidth: cacheWidth,
          );
        }
        return Center(
          child: Icon(
            LucideIcons.shoppingBag,
            size: 32,
            color: context.bp.textFaint.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.brand,
        borderRadius: const BorderRadiusDirectional.only(
          topEnd: Radius.circular(BpRadius.badge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          maxLines: 1,
          style: BpText.label.copyWith(fontSize: 10, color: c.onBrand),
        ),
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final scaler = MediaQuery.textScalerOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.star_rounded, size: scaler.scale(14), color: c.gold),
        const SizedBox(width: 2),
        Text(
          formatRating(rating),
          maxLines: 1,
          style: BpText.caption.copyWith(
            color: c.textMuted,
            fontFeatures: BpText.tabular,
          ),
        ),
      ],
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final reduce = BpMotion.reduced(context);
    return BpTappable(
      onTap: onPressed,
      semanticLabel: active ? 'Hapus dari wishlist' : 'Simpan ke wishlist',
      tooltip: active ? 'Hapus dari wishlist' : 'Simpan ke wishlist',
      selected: active,
      builder: (context, states) {
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            border: Border.all(color: c.line),
          ),
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: active ? 1 : 0.9,
            duration: reduce ? Duration.zero : BpMotion.emphasis,
            curve: active ? BpMotion.emphasisCurve : BpMotion.microCurve,
            child: Icon(
              active ? Icons.favorite_rounded : LucideIcons.heart,
              size: active ? 18 : 16,
              color: active ? c.brand : c.textMuted,
            ),
          ),
        );
      },
    );
  }
}

/// Tombol tambah cepat: bulat 32 dalam area sentuh 48. Berubah menjadi
/// centang sesaat setelah diketuk.
class _QuickAddButton extends StatefulWidget {
  const _QuickAddButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  static const Duration _confirmFor = Duration(milliseconds: 900);

  Timer? _timer;
  bool _confirmed = false;

  void _tap() {
    widget.onPressed?.call();
    _timer?.cancel();
    setState(() => _confirmed = true);
    _timer = Timer(_confirmFor, () {
      if (mounted) setState(() => _confirmed = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final enabled = widget.onPressed != null;
    return BpTappable(
      onTap: enabled ? _tap : null,
      semanticLabel: 'Tambah ke keranjang',
      tooltip: 'Tambah ke keranjang',
      builder: (context, states) {
        return AnimatedContainer(
          duration: BpMotion.micro,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled
                ? (_confirmed ? c.success : c.brand)
                : (c.isDark ? c.surfaceMuted : c.line),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            _confirmed ? LucideIcons.check : LucideIcons.plus,
            size: 18,
            color: enabled ? (_confirmed ? c.surface : c.onBrand) : c.textFaint,
          ),
        );
      },
    );
  }
}

/// Tombol berbingkai "+ Keranjang" selebar kartu (pola Tokopedia).
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final enabled = onPressed != null;
    final foreground = enabled ? c.brandStrong : c.textFaint;
    return BpTappable(
      onTap: onPressed,
      minWidth: double.infinity,
      semanticLabel: 'Tambah ke keranjang',
      focusRadius: BpRadius.tileAll,
      builder: (context, states) {
        final pressed = states.contains(WidgetState.pressed);
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: pressed ? c.brandTint : c.surface,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(color: enabled ? c.brand : c.line),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(LucideIcons.plus, size: 14, color: foreground),
                const SizedBox(width: 4),
                Text(
                  'Keranjang',
                  maxLines: 1,
                  softWrap: false,
                  style: BpText.button.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Kerangka muat seukuran [ProductCard].
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      label: 'Memuat produk',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BpRadius.cardAll,
          border: Border.all(color: c.line),
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(BpRadius.card - 1)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AspectRatio(aspectRatio: 1, child: Skeleton(radius: 0)),
              Padding(
                padding: EdgeInsets.all(BpSpace.cardDense),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Skeleton.line(height: 12),
                    SizedBox(height: 6),
                    Skeleton.line(width: 96, height: 12),
                    SizedBox(height: 22),
                    Skeleton.line(width: 84, height: 16),
                    SizedBox(height: 6),
                    Skeleton.line(width: 60, height: 10),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pembangun satu kartu pada grid.
typedef ProductCardBuilder = Widget Function(BuildContext context, int index);

/// Satu baris grid dua kolom; kedua kartu sama tinggi.
class _GridRow extends StatelessWidget {
  const _GridRow({required this.left, required this.right});

  final Widget left;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BpSpace.grid),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: left),
            const SizedBox(width: BpSpace.grid),
            Expanded(child: right ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

/// Grid produk dua kolom yang tidak menggulir sendiri (untuk jumlah kecil di
/// dalam halaman). Tinggi kartu mengikuti isi, jadi aman pada skala teks
/// besar.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: BpSpace.gridMargin),
  });

  final int itemCount;
  final ProductCardBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final rows = (itemCount / 2).ceil();
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var row = 0; row < rows; row++)
            _GridRow(
              left: itemBuilder(context, row * 2),
              right: row * 2 + 1 < itemCount
                  ? itemBuilder(context, row * 2 + 1)
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Grid produk dua kolom malas untuk `CustomScrollView` (katalog, beranda).
class SliverProductGrid extends StatelessWidget {
  const SliverProductGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: BpSpace.gridMargin),
  });

  final int itemCount;
  final ProductCardBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final rows = (itemCount / 2).ceil();
    return SliverPadding(
      padding: padding,
      sliver: SliverList.builder(
        itemCount: rows,
        itemBuilder: (context, row) {
          return _GridRow(
            left: itemBuilder(context, row * 2),
            right: row * 2 + 1 < itemCount
                ? itemBuilder(context, row * 2 + 1)
                : null,
          );
        },
      ),
    );
  }
}

/// Rel kartu produk gulir horizontal (Hot Item, produk serupa). Semua kartu
/// sama tinggi dan tinggi rel mengikuti isi, jadi aman pada skala teks besar.
///
/// Kartu dibangun sekaligus; pakai untuk daftar pendek (sampai ±20 kartu).
class ProductRail extends StatelessWidget {
  const ProductRail({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemWidth = 148,
    this.padding = const EdgeInsets.symmetric(horizontal: BpSpace.screen),
    this.controller,
  });

  final int itemCount;
  final ProductCardBuilder itemBuilder;
  final double itemWidth;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var i = 0; i < itemCount; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: BpSpace.grid),
              SizedBox(width: itemWidth, child: itemBuilder(context, i)),
            ],
          ],
        ),
      ),
    );
  }
}
