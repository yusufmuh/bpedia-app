/// Beranda (SPEC §4.1, PERBAIKAN home): kepala menempel, strip akun/dompet,
/// carousel Event Promo + baris kepercayaan, pintasan 3D, strip game,
/// pengingat bayar, Hot Item berjalan, brand, rekomendasi bertab, dan App
/// Flyer harian.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../design/design.dart';
import '../catalog/shop_common.dart';
import '../orders/widgets/unpaid_order_banner.dart';
import 'app_flyer.dart';
import 'home_header.dart';
import 'home_sections.dart';

/// Isi tab Beranda.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// Jumlah produk rekomendasi per langkah muat.
  static const int pageSize = 12;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _visible = HomePage.pageSize;
  String? _tab;
  bool _loadingMore = false;
  bool _flyerChecked = false;
  Timer? _loadTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flyerChecked) return;
    _flyerChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      unawaited(maybeShowDailyFlyer(context));
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification, int total) {
    if (notification.depth != 0) return false;
    if (_loadingMore || _visible >= total) return false;
    if (notification.metrics.extentAfter > 480) return false;
    setState(() => _loadingMore = true);
    _loadTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _visible = (_visible + HomePage.pageSize).clamp(0, total);
        _loadingMore = false;
      });
    });
    return false;
  }

  List<String> _hints(CatalogRepository catalog) => <String>[
    for (final category in catalog.categories)
      'Cari ${category.name.toLowerCase()} di Bpedia',
    'Cari serum di Bpedia',
  ];

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final media = MediaQuery.of(context);
    final searchRowHeight = (media.textScaler.scale(20) + 36).clamp(56.0, 96.0);
    return Scaffold(
      backgroundColor: c.canvas,
      body: ListenableBuilder(
        listenable: services.catalog,
        builder: (context, _) {
          final tab = _tab;
          final products = tab == null
              ? services.catalog.products
              : services.catalog.products
                    .where((product) => product.categoryId == tab)
                    .toList(growable: false);
          final total = products.length;
          final shown = _visible.clamp(0, total);
          final state = catalogStateView(context, sliver: true);
          final banners = services.promo.banners;
          final game = services.rewards.available
              ? services.rewards.buildGameStrip(context)
              : null;
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) => _onScroll(notification, total),
            child: CustomScrollView(
              primary: true,
              slivers: <Widget>[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeHeaderDelegate(
                    topPadding: media.padding.top,
                    searchRowHeight: searchRowHeight,
                    hints: _hints(services.catalog),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Section(
                    padding: const EdgeInsets.only(
                      top: BpSpace.x3,
                      bottom: BpSpace.x3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const HomeAccountStrip(),
                        if (banners.isNotEmpty) ...<Widget>[
                          const SizedBox(height: BpSpace.x3),
                          BannerCarousel(
                            key: const ValueKey<String>('beranda-banner'),
                            items: <BannerItem>[
                              for (final banner in banners)
                                BannerItem(
                                  asset: banner.image,
                                  semanticLabel: banner.title,
                                  onTap: () =>
                                      openAppLocation(context, banner.route),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: BpSpace.x3),
                        const HomeTrustRow(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Section(
                    padding: EdgeInsets.only(
                      top: BpSpace.x3,
                      bottom: BpSpace.x3,
                    ),
                    child: HomeShortcutGrid(),
                  ),
                ),
                if (game != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: BpSpace.sectionGap,
                      ),
                      child: game,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: UnpaidOrderBanner(
                    key: ValueKey<String>('beranda-bayar'),
                    margin: EdgeInsets.fromLTRB(
                      BpSpace.screen,
                      0,
                      BpSpace.screen,
                      BpSpace.sectionGap,
                    ),
                  ),
                ),
                if (state != null)
                  state
                else ...<Widget>[
                  const SliverToBoxAdapter(child: HomeHotSection()),
                  const SliverToBoxAdapter(child: HomeBrandSection()),
                  SliverToBoxAdapter(
                    child: Section(
                      gap: false,
                      padding: const EdgeInsets.only(top: BpSpace.x1),
                      header: const SectionHeader(title: 'Rekomendasi untukmu'),
                      child: HomeRecommendTabs(
                        selected: _tab,
                        onSelected: (id) => setState(() {
                          _tab = id;
                          _visible = HomePage.pageSize;
                          _loadTimer?.cancel();
                          _loadingMore = false;
                        }),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: BpSpace.x2),
                    sliver: SliverProductGrid(
                      itemCount: shown + (_loadingMore ? 2 : 0),
                      itemBuilder: (context, index) => index < shown
                          ? ShopProductCard(product: products[index])
                          : const ProductCardSkeleton(),
                    ),
                  ),
                  if (shown >= total && total > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: BpSpace.x3),
                        child: Center(
                          child: PillButton(
                            label: 'Lihat semua di Katalog',
                            variant: PillButtonVariant.outline,
                            size: PillButtonSize.small,
                            onPressed: () => services.router.go(
                              context,
                              const CatalogRoute(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 72)),
              ],
            ),
          );
        },
      ),
    );
  }
}
