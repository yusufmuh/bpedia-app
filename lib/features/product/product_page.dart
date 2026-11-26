/// Detail produk (SPEC §4.4, FITUR #13, PERBAIKAN produk): galeri geser +
/// baris thumbnail, pita Hot Item merah dengan segmen hitung mundur, blok
/// harga dengan "Hemat", lencana kepercayaan satu baris, pita produk misi,
/// pengiriman (demo), deskripsi, info produk, produk serupa, dan bilah
/// menempel bawah (Chat, Wishlist, "Beli sekarang", "+ Keranjang").
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/shell.dart' show CartButton;
import '../../data/catalog/catalog_repository.dart';
import '../../data/shipping/shipping_repository.dart';
import '../../design/design.dart';
import '../../services/analytics/analytics.dart';
import '../catalog/shop_common.dart';
import '../hot/hot_deal_view.dart';
import 'add_to_cart_sheet.dart';

/// Halaman detail produk berkode [code].
class ProductPage extends StatefulWidget {
  const ProductPage({required this.code, super.key});

  final String code;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ScrollController _scroll = ScrollController();
  bool _logged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logged) return;
    final services = AppScope.of(context);
    final product = services.catalog.byCode(widget.code);
    if (product == null) return;
    _logged = true;
    unawaited(
      services.analytics.logContentView(
        productCode: product.code,
        category: product.categoryId,
        price: product.price,
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.catalog,
      builder: (context, _) {
        final state = catalogStateView(context);
        final product = services.catalog.byCode(widget.code);
        if (state != null || product == null) {
          return Scaffold(
            appBar: const BpAppBar(
              title: 'Detail produk',
              actions: <Widget>[CartButton()],
            ),
            body:
                state ??
                Center(
                  child: SingleChildScrollView(
                    child: EmptyState(
                      imageAsset: 'assets/bipy/bipy_ngintip.webp',
                      title: 'Produk tidak ditemukan',
                      message:
                          'Produk ini sudah tidak ada di katalog atau tautannya '
                          'salah, Babes.',
                      actionLabel: 'Lihat katalog',
                      onAction: () =>
                          services.router.go(context, const CatalogRoute()),
                    ),
                  ),
                ),
          );
        }
        return _ProductView(product: product, scroll: _scroll);
      },
    );
  }
}

class _ProductView extends StatelessWidget {
  const _ProductView({required this.product, required this.scroll});

  final Product product;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final width = MediaQuery.sizeOf(context).width;
    final similar = services.catalog.similarTo(product.code);
    return Scaffold(
      backgroundColor: c.canvas,
      body: Stack(
        children: <Widget>[
          CustomScrollView(
            controller: scroll,
            slivers: <Widget>[
              SliverToBoxAdapter(child: _Gallery(product: product)),
              SliverToBoxAdapter(child: _PriceBlock(product: product)),
              const SliverToBoxAdapter(child: _BadgeRow()),
              SliverToBoxAdapter(child: _ShippingSection(product: product)),
              SliverToBoxAdapter(child: _DescriptionSection(product: product)),
              SliverToBoxAdapter(child: _InfoSection(product: product)),
              if (similar.isNotEmpty)
                SliverToBoxAdapter(
                  child: Section(
                    header: SectionHeader(
                      title: 'Produk serupa',
                      onAction: () => services.router.go(
                        context,
                        CatalogRoute(category: product.categoryId),
                      ),
                    ),
                    child: ProductRail(
                      itemCount: similar.length,
                      itemWidth: 148,
                      itemBuilder: (context, index) => ShopProductCard(
                        product: similar[index],
                        action: ProductCardAction.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _FadingAppBar(product: product, scroll: scroll, galleryHeight: width),
        ],
      ),
      bottomNavigationBar: _BottomBar(product: product),
    );
  }
}

class _FadingAppBar extends StatelessWidget {
  const _FadingAppBar({
    required this.product,
    required this.scroll,
    required this.galleryHeight,
  });

  final Product product;
  final ScrollController scroll;
  final double galleryHeight;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedBuilder(
      animation: scroll,
      builder: (context, _) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        final span = (galleryHeight - BpSize.appBar - top).clamp(1.0, 2000.0);
        final t = (offset / span).clamp(0.0, 1.0);
        Widget circle(Widget child) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surface.withValues(alpha: 0.86 * (1 - t)),
          ),
          child: child,
        );
        return Container(
          height: top + BpSize.appBar,
          padding: EdgeInsets.only(
            top: top,
            left: BpSpace.x1,
            right: BpSpace.x1,
          ),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: t),
            border: Border(
              bottom: BorderSide(color: c.line.withValues(alpha: t)),
            ),
          ),
          child: Row(
            children: <Widget>[
              circle(const BpBackButton()),
              const SizedBox(width: BpSpace.x1),
              Expanded(
                child: Opacity(
                  opacity: t,
                  child: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BpText.appBarTitle.copyWith(color: c.text),
                  ),
                ),
              ),
              circle(
                IconButton(
                  tooltip: 'Bagikan',
                  onPressed: () => _share(context, services, product),
                  icon: Icon(LucideIcons.share2, color: c.text),
                ),
              ),
              const SizedBox(width: BpSpace.x1),
              circle(const CartButton()),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _share(
  BuildContext context,
  AppServices services,
  Product product,
) async {
  final link = product.sourceUrl.isEmpty
      ? 'https://bpedia.id${ProductRoute(product.code).location}'
      : product.sourceUrl;
  await Clipboard.setData(ClipboardData(text: link));
  services.haptics.selection();
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Tautan produk disalin. Tinggal tempel, Babes.'),
      ),
    );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});

  final Product product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _show(int index) {
    if (!_pages.hasClients) return;
    if (BpMotion.reduced(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: BpMotion.standard,
        curve: BpMotion.standardCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final product = widget.product;
    final deal = product.hot;
    final services = AppScope.of(context);
    final images = <String>[
      if (deal != null &&
          hotPhaseOf(deal, services.clock.today) == HotPhase.running)
        deal.image,
      ...product.images,
    ];
    final count = images.length;
    final gallery = AspectRatio(
      aspectRatio: 1,
      child: ColoredBox(
        color: c.surfaceMuted,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Semantics(
              label: 'Foto produk ${_index + 1} dari $count',
              child: PageView.builder(
                controller: _pages,
                itemCount: count,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => AssetPicture(
                  images[index],
                  fit: BoxFit.cover,
                  semanticLabel: index == 0 ? widget.product.name : null,
                ),
              ),
            ),
            if (count > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: BpSpace.x3,
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (var i = 0; i < count; i++)
                        AnimatedContainer(
                          duration: BpMotion.micro,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? c.brand
                                : c.surface.withValues(alpha: 0.9),
                            borderRadius: BpRadius.pillAll,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: BpSpace.x3,
              bottom: BpSpace.x3,
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.x2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.scrim,
                    borderRadius: BpRadius.pillAll,
                  ),
                  child: Text(
                    '${_index + 1}/$count',
                    style: BpText.label.copyWith(
                      color: Colors.white,
                      fontFeatures: BpText.tabular,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (count < 2) return gallery;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        gallery,
        ColoredBox(
          color: c.surface,
          child: SingleChildScrollView(
            key: const ValueKey<String>('detail-thumbnail'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x2,
              BpSpace.screen,
              BpSpace.x2,
            ),
            child: Row(
              children: <Widget>[
                for (var i = 0; i < count; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: BpSpace.x2),
                  BpTappable(
                    onTap: () => _show(i),
                    semanticLabel: 'Foto ${i + 1}',
                    selected: i == _index,
                    minWidth: 48,
                    minHeight: 48,
                    focusRadius: const BorderRadius.all(Radius.circular(8)),
                    builder: (context, states) => AnimatedContainer(
                      duration: BpMotion.micro,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        border: Border.all(
                          color: i == _index ? c.brand : c.line,
                          width: i == _index ? 2 : 1,
                        ),
                      ),
                      child: AssetPicture(
                        images[i],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final deal = product.hot;
    final rating = product.rating;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.wishlist,
        services.rewards,
      ]),
      builder: (context, _) {
        final mission = isMissionProduct(services, product);
        return Section(
          padding: const EdgeInsets.only(bottom: BpSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (deal != null &&
                  hotPhaseOf(deal, services.clock.today) != HotPhase.ended)
                _HotStrip(deal: deal),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BpSpace.screen,
                  BpSpace.x3,
                  BpSpace.screen,
                  0,
                ),
                child: _PriceLines(product: product),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BpSpace.screen,
                  BpSpace.x2,
                  BpSpace.screen,
                  0,
                ),
                child: Text(
                  product.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: BpText.title.copyWith(color: c.text),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BpSpace.screen,
                  BpSpace.x2,
                  BpSpace.screen,
                  0,
                ),
                child: Wrap(
                  spacing: BpSpace.x3,
                  runSpacing: BpSpace.x1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    BpChip(
                      label: product.brand,
                      leading: const Icon(LucideIcons.store),
                      onTap: () => services.router.go(
                        context,
                        CatalogRoute(brands: <String>[product.brand]),
                      ),
                    ),
                    if (rating != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(LucideIcons.star, size: 16, color: c.gold),
                          const SizedBox(width: 4),
                          Text(
                            formatRating(rating),
                            style: BpText.bodyS.copyWith(
                              color: c.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      product.inStock ? 'Stok ${product.stock}' : 'Stok habis',
                      style: BpText.bodyS.copyWith(
                        color: product.inStock
                            ? (product.stock <= 5 ? c.warning : c.textMuted)
                            : c.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (mission)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BpSpace.screen,
                    BpSpace.x3,
                    BpSpace.screen,
                    0,
                  ),
                  child: _MissionRibbon(
                    onTap: () =>
                        services.router.go(context, const MissionRoute()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Lima digit harga dengan harga coret, lencana diskon, dan "Hemat".
class _PriceLines extends StatelessWidget {
  const _PriceLines({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final strike = product.strikePrice;
    final hasStrike = strike != null && strike > product.price;
    final percent = product.discountPercent;
    final semantics = StringBuffer('Harga ${formatRupiah(product.price)}');
    if (hasStrike) {
      semantics.write(
        ', harga sebelumnya ${formatRupiah(strike)}, '
        'hemat ${formatRupiah(strike - product.price)}',
      );
    }
    return Semantics(
      label: semantics.toString(),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: BpSpace.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              PriceText(product.price, size: PriceTextSize.detail),
              if (hasStrike && percent != null && percent > 0)
                DiscountBadge(percent: percent),
            ],
          ),
          if (hasStrike)
            Wrap(
              spacing: BpSpace.x2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  formatRupiah(strike),
                  style: BpText.bodyS.copyWith(
                    color: c.textFaint,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: c.textFaint,
                    fontFeatures: BpText.tabular,
                  ),
                ),
                Text(
                  'Hemat ${formatRupiah(strike - product.price)}',
                  key: const ValueKey<String>('detail-hemat'),
                  style: BpText.bodyS.copyWith(
                    color: c.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Pita Hot Item merah penuh: judul + kampanye di kiri, "Berakhir dalam"
/// dengan segmen hari/jam/menit/detik di kanan (berdetik).
class _HotStrip extends StatefulWidget {
  const _HotStrip({required this.deal});

  final HotDeal deal;

  @override
  State<_HotStrip> createState() => _HotStripState();
}

class _HotStripState extends State<_HotStrip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final deal = widget.deal;
    final running = hotPhaseOf(deal, services.clock.today) == HotPhase.running;
    const white = Colors.white;
    final Widget right;
    if (running) {
      final left = wibEndOfDay(
        deal.endDay,
      ).difference(services.clock.instant.toUtc());
      final safe = left.isNegative ? Duration.zero : left;
      String two(int value) => value.toString().padLeft(2, '0');
      Widget segment(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: white.withValues(alpha: 0.22),
          borderRadius: BpRadius.badgeAll,
        ),
        child: Text(
          text,
          style: BpText.label.copyWith(
            color: white,
            fontWeight: FontWeight.w700,
            fontFeatures: BpText.tabular,
          ),
        ),
      );
      Widget colon() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          ':',
          style: BpText.label.copyWith(
            color: white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      right = Semantics(
        label:
            'Berakhir dalam ${safe.inDays} hari ${safe.inHours % 24} jam '
            '${safe.inMinutes % 60} menit',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Berakhir dalam', style: BpText.label.copyWith(color: white)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (safe.inDays > 0) ...<Widget>[
                  segment('${safe.inDays} hari'),
                  const SizedBox(width: 4),
                ],
                segment(two(safe.inHours % 24)),
                colon(),
                segment(two(safe.inMinutes % 60)),
                colon(),
                segment(two(safe.inSeconds % 60)),
              ],
            ),
          ],
        ),
      );
    } else {
      right = Text(
        'Mulai ${wibShortDate(deal.startDay)}',
        style: BpText.caption.copyWith(
          color: white,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Container(
      key: const ValueKey<String>('detail-hot'),
      color: c.sale,
      padding: const EdgeInsets.symmetric(
        horizontal: BpSpace.screen,
        vertical: BpSpace.x2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(LucideIcons.flame, size: 16, color: white),
                    const SizedBox(width: 4),
                    Text(
                      'HOT ITEM',
                      style: BpText.bodyS.copyWith(
                        color: white,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${deal.theme} · maks. ${deal.maxPerOrder} per pesanan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BpText.label.copyWith(color: white),
                ),
              ],
            ),
          ),
          const SizedBox(width: BpSpace.x2),
          Flexible(child: right),
        ],
      ),
    );
  }
}

class _MissionRibbon extends StatelessWidget {
  const _MissionRibbon({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      key: const ValueKey<String>('detail-misi'),
      onTap: onTap,
      semanticLabel: 'Produk Misi Belanja, bantu selesaikan misi',
      pressScale: false,
      focusRadius: BpRadius.tileAll,
      builder: (context, states) => Container(
        padding: const EdgeInsets.fromLTRB(
          BpSpace.x2,
          BpSpace.x2,
          BpSpace.x3,
          BpSpace.x2,
        ),
        decoration: BoxDecoration(
          color: c.goldTint,
          borderRadius: BpRadius.tileAll,
        ),
        child: Row(
          children: <Widget>[
            const AssetPicture(
              'assets/icons3d/misi.webp',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              showSkeleton: false,
            ),
            const SizedBox(width: BpSpace.x2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    const TextSpan(
                      text: 'Produk Misi Belanja',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' · bantu selesaikan misi',
                      style: TextStyle(color: c.onGoldTint),
                    ),
                  ],
                ),
                style: BpText.bodyS.copyWith(color: c.onGoldTint),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: c.onGoldTint),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow();

  @override
  Widget build(BuildContext context) {
    return const Section(
      padding: EdgeInsets.symmetric(vertical: BpSpace.x3),
      child: TrustBadgeRow(),
    );
  }
}

class _ShippingSection extends StatelessWidget {
  const _ShippingSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final options = services.shipping.options(
      weightGrams: product.weightGrams,
      goodsSubtotal: product.price,
    );
    return Section(
      header: const SectionHeader(
        title: 'Pengiriman',
        subtitle: 'Ongkir dan estimasi tiba ${ShippingRepository.demoTag}',
      ),
      child: Column(
        children: <Widget>[
          for (final option in options)
            InfoRow(
              leading: Icon(LucideIcons.truck, color: c.textMuted),
              label: option.name,
              helper: '${option.etaLabel} ${ShippingRepository.demoTag}',
              valueWidget: Text(
                option.isFree ? 'Gratis ongkir' : formatRupiah(option.fee),
                style: BpText.body.copyWith(
                  color: option.isFree ? c.success : c.text,
                  fontWeight: FontWeight.w600,
                  fontFeatures: BpText.tabular,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection({required this.product});

  final Product product;

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final text = widget.product.description.trim();
    final long = text.length > 220;
    return Section(
      header: const SectionHeader(title: 'Deskripsi'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedSize(
              duration: BpMotion.reduced(context)
                  ? Duration.zero
                  : BpMotion.standard,
              curve: BpMotion.standardCurve,
              alignment: Alignment.topCenter,
              child: Text(
                text.isEmpty ? 'Deskripsi produk belum tersedia.' : text,
                maxLines: _open || !long ? null : 5,
                overflow: _open || !long ? null : TextOverflow.ellipsis,
                style: BpText.body.copyWith(color: c.text),
              ),
            ),
            if (long)
              PillButton(
                key: const ValueKey<String>('detail-deskripsi'),
                label: _open ? 'Tutup deskripsi' : 'Baca selengkapnya',
                variant: PillButtonVariant.text,
                size: PillButtonSize.small,
                trailing: Icon(
                  _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                ),
                onPressed: () => setState(() => _open = !_open),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final weight = product.weightGrams >= 1000
        ? '${(product.weightGrams / 1000).toStringAsFixed(1).replaceAll('.', ',')} kg'
        : '${product.weightGrams} g';
    return Section(
      header: const SectionHeader(title: 'Info produk'),
      child: Column(
        children: <Widget>[
          InfoRow(label: 'Kode produk', value: product.code),
          InfoRow(
            label: 'Kategori',
            value: categoryNameOf(services, product.categoryId),
          ),
          InfoRow(label: 'Brand', value: product.brand),
          InfoRow(
            label: 'Stok',
            value: product.inStock ? '${product.stock}' : 'Habis',
          ),
          InfoRow(label: 'Berat kirim', value: weight),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final available = product.inStock;
    Widget labeled({
      required Key key,
      required String label,
      required String tooltip,
      required Widget icon,
      required VoidCallback onTap,
      bool selected = false,
    }) => BpTappable(
      key: key,
      onTap: onTap,
      semanticLabel: tooltip,
      tooltip: tooltip,
      selected: selected,
      minWidth: 48,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            const SizedBox(height: 2),
            Text(
              label,
              style: BpText.label.copyWith(fontSize: 10, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
    return StickyBottomBar(
      child: Row(
        children: <Widget>[
          labeled(
            key: const ValueKey<String>('detail-chat'),
            label: 'Chat',
            tooltip: 'Tanya Bpedia Care lewat WhatsApp',
            icon: BrandIcon(BrandGlyph.chat, size: 22, color: c.text),
            onTap: () => services.links.openWhatsAppCare(
              'Halo Bpedia Care, saya mau tanya produk ${product.name} '
              '(${product.code}).',
            ),
          ),
          ListenableBuilder(
            listenable: services.wishlist,
            builder: (context, _) {
              final wished = services.wishlist.contains(product.code);
              return labeled(
                key: const ValueKey<String>('detail-wishlist'),
                label: 'Wishlist',
                tooltip: wished ? 'Hapus dari wishlist' : 'Simpan ke wishlist',
                selected: wished,
                icon: AnimatedScale(
                  scale: wished ? 1.12 : 1,
                  duration: BpMotion.reduced(context)
                      ? Duration.zero
                      : BpMotion.emphasis,
                  curve: BpMotion.emphasisCurve,
                  child: BrandIcon(
                    BrandGlyph.wishlist,
                    size: 22,
                    style: wished ? BrandIconStyle.color : BrandIconStyle.mono,
                    color: wished ? null : c.text,
                  ),
                ),
                onTap: () => toggleWishlist(context, product),
              );
            },
          ),
          const SizedBox(width: BpSpace.x1),
          Expanded(
            child: PillButton(
              key: const ValueKey<String>('detail-beli'),
              label: 'Beli sekarang',
              variant: PillButtonVariant.outline,
              size: PillButtonSize.small,
              onPressed: available
                  ? () => buyProductNow(context, product)
                  : null,
            ),
          ),
          const SizedBox(width: BpSpace.x2),
          Expanded(
            child: PillButton(
              key: const ValueKey<String>('detail-tambah'),
              label: available ? '+ Keranjang' : 'Stok habis',
              size: PillButtonSize.small,
              onPressed: available
                  ? () => showAddToCartSheet(context, product)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
