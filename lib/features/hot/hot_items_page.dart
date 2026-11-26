/// Halaman Hot Item (`/hot-item`, FITUR #10, PERBAIKAN hot_item): kepala
/// kembali + cari + keranjang, judul dengan hitung mundur sebaris, chip tema,
/// lalu kartu dikelompokkan per kampanye. Kampanye yang sudah lewat
/// diringkas menjadi rel mini berlabel "Berakhir" tanpa tombol beli.
library;

import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/shell.dart' show CartButton;
import '../../data/catalog/catalog_repository.dart';
import '../../design/design.dart';
import '../catalog/shop_common.dart';
import 'hot_deal_view.dart';

/// Daftar Hot Item.
class HotItemsPage extends StatefulWidget {
  const HotItemsPage({super.key});

  @override
  State<HotItemsPage> createState() => _HotItemsPageState();
}

/// Satu kampanye Hot Item beserta produknya pada hasil saat ini.
class _Campaign {
  _Campaign(this.theme, this.deal);

  final String theme;

  /// Deal pertama kampanye; periode sama untuk satu tema.
  final HotDeal deal;
  final List<Product> products = <Product>[];
}

class _HotItemsPageState extends State<HotItemsPage> {
  final TextEditingController _search = TextEditingController();
  String _text = '';
  String? _theme;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    setState(() {
      _text = '';
      _theme = null;
    });
  }

  List<_Campaign> _group(List<Product> results, int today) {
    final byTheme = <String, _Campaign>{};
    for (final product in results) {
      final deal = product.hot!;
      byTheme
          .putIfAbsent(deal.theme, () => _Campaign(deal.theme, deal))
          .products
          .add(product);
    }
    int rank(_Campaign campaign) => switch (hotPhaseOf(campaign.deal, today)) {
      HotPhase.running => 0,
      HotPhase.upcoming => 1,
      HotPhase.ended => 2,
    };
    return byTheme.values.toList()..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.deal.endDay.compareTo(b.deal.endDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: BpAppBar(
        titleWidget: Padding(
          padding: const EdgeInsets.only(right: BpSpace.x1),
          child: SearchField(
            key: const ValueKey<String>('hot-cari'),
            controller: _search,
            hint: 'Cari di Hot Item',
            onChanged: (value) => setState(() => _text = value),
          ),
        ),
        actions: const <Widget>[CartButton()],
        divider: false,
      ),
      body: ListenableBuilder(
        listenable: services.catalog,
        builder: (context, _) {
          final state = catalogStateView(context);
          if (state != null) return state;
          final today = services.clock.today;
          final all = services.catalog.hotItems;
          final themeCounts = <String, int>{};
          final ordered = <Product>[...all]
            ..sort((a, b) {
              int ended(Product p) =>
                  hotPhaseOf(p.hot!, today) == HotPhase.ended ? 1 : 0;
              final byEnd = ended(a).compareTo(ended(b));
              return byEnd != 0
                  ? byEnd
                  : a.hot!.endDay.compareTo(b.hot!.endDay);
            });
          for (final product in ordered) {
            final theme = product.hot!.theme;
            themeCounts[theme] = (themeCounts[theme] ?? 0) + 1;
          }
          final results = services.catalog
              .search(CatalogQuery(text: _text, hotOnly: true))
              .where(
                (product) => _theme == null || product.hot!.theme == _theme,
              )
              .toList();
          final campaigns = _group(results, today);
          final soonest = soonestRunning(all, today);
          return CustomScrollView(
            slivers: <Widget>[
              PinnedHeaderSliver(
                child: ColoredBox(
                  color: c.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _TitleRow(soonest: soonest),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                          BpSpace.screen,
                          BpSpace.x1,
                          BpSpace.screen,
                          BpSpace.x3,
                        ),
                        child: Row(
                          children: <Widget>[
                            BpChip(
                              label: 'Semua (${all.length})',
                              selected: _theme == null,
                              onTap: () => setState(() => _theme = null),
                            ),
                            for (final entry
                                in themeCounts.entries) ...<Widget>[
                              const SizedBox(width: BpSpace.x2),
                              BpChip(
                                key: ValueKey<String>('hot-tema-${entry.key}'),
                                label: '${entry.key} (${entry.value})',
                                selected: _theme == entry.key,
                                onTap: () => setState(() => _theme = entry.key),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: c.line),
                    ],
                  ),
                ),
              ),
              if (results.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    illustration: const BipySprite(
                      BipySprites.peek,
                      height: 132,
                      semanticLabel: 'Bipy mengintip dari tas',
                    ),
                    title: 'Hot Item tidak ditemukan',
                    message: _text.isEmpty
                        ? 'Belum ada Hot Item untuk tema ini.'
                        : 'Belum ada Hot Item untuk "$_text".',
                    actionLabel: 'Tampilkan semua Hot Item',
                    onAction: _clear,
                  ),
                )
              else
                for (final campaign in campaigns)
                  if (hotPhaseOf(campaign.deal, today) == HotPhase.ended)
                    SliverToBoxAdapter(
                      child: _EndedCampaign(campaign: campaign),
                    )
                  else ...<Widget>[
                    SliverToBoxAdapter(
                      child: _CampaignHeader(campaign: campaign, today: today),
                    ),
                    SliverProductGrid(
                      itemCount: campaign.products.length,
                      itemBuilder: (context, index) => HotItemCard(
                        product: campaign.products[index],
                        showBuyButton:
                            hotPhaseOf(campaign.deal, today) ==
                            HotPhase.running,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: BpSpace.sectionGap),
                    ),
                  ],
              const SliverToBoxAdapter(child: _Disclaimer()),
            ],
          );
        },
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.soonest});

  final HotDeal? soonest;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final deal = soonest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        BpSpace.x2,
        BpSpace.screen,
        BpSpace.x2,
      ),
      child: Row(
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.5,
            ),
            child: const HotItemTitle(size: 22),
          ),
          const SizedBox(width: BpSpace.x2),
          Expanded(
            child: deal == null
                ? const SizedBox.shrink()
                : Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: BpSpace.x2,
                    runSpacing: BpSpace.x1,
                    children: <Widget>[
                      Text(
                        'Berakhir dalam',
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                      HotCountdown(deal: deal),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader({required this.campaign, required this.today});

  final _Campaign campaign;
  final int today;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final deal = campaign.deal;
    final upcoming = hotPhaseOf(deal, today) == HotPhase.upcoming;
    final when = upcoming
        ? 'Mulai ${wibDayName(deal.startDay)}, ${wibShortDate(deal.startDay)}'
        : 's.d. ${wibDayName(deal.endDay)}, ${wibShortDate(deal.endDay)}';
    return ColoredBox(
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BpSpace.screen,
          BpSpace.x4,
          BpSpace.screen,
          BpSpace.x1,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: BpSpace.x2,
          runSpacing: BpSpace.x1,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                campaign.theme,
                style: BpText.subtitle.copyWith(color: c.text),
              ),
            ),
            Text(
              when,
              style: BpText.bodyS.copyWith(
                color: upcoming ? c.textMuted : c.sale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kampanye yang sudah lewat: judul, tanggal berakhir, lencana "Berakhir",
/// dan rel mini tiga kolom tanpa tombol beli.
class _EndedCampaign extends StatelessWidget {
  const _EndedCampaign({required this.campaign});

  final _Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final deal = campaign.deal;
    final width = MediaQuery.sizeOf(context).width;
    final tile = (width - BpSpace.screen * 2 - BpSpace.grid * 2) / 3;
    return Container(
      key: ValueKey<String>('hot-berakhir-${campaign.theme}'),
      color: c.surface,
      margin: const EdgeInsets.only(bottom: BpSpace.sectionGap),
      padding: const EdgeInsets.only(top: BpSpace.x4, bottom: BpSpace.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          campaign.theme,
                          style: BpText.subtitle.copyWith(color: c.text),
                        ),
                      ),
                      Text(
                        'Berakhir ${wibDayName(deal.endDay)}, '
                        '${wibLongDate(deal.endDay)} · '
                        '${campaign.products.length} produk',
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BpSpace.x2),
                const StatusChip(label: 'Berakhir'),
              ],
            ),
          ),
          const SizedBox(height: BpSpace.x3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final product in campaign.products) ...<Widget>[
                  if (product != campaign.products.first)
                    const SizedBox(width: BpSpace.grid),
                  SizedBox(
                    width: tile,
                    child: BpTappable(
                      onTap: () => services.router.go(
                        context,
                        ProductRoute(product.code),
                      ),
                      semanticLabel: '${product.name}, Hot Item berakhir',
                      minWidth: 0,
                      minHeight: 0,
                      focusRadius: BpRadius.tileAll,
                      builder: (context, states) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BpRadius.tileAll,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: AssetPicture(product.hot!.image),
                            ),
                          ),
                          const SizedBox(height: BpSpace.x1),
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BpText.caption.copyWith(color: c.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final limits = <int>{
      for (final product in services.catalog.hotItems) product.hot!.maxPerOrder,
    };
    final perOrder = limits.length == 1 ? limits.first : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.x6,
        BpSpace.x3,
        BpSpace.x6,
        BpSpace.x6,
      ),
      child: Text(
        'Harga, kuota, dan tanggal mengikuti kampanye Bpedia '
        '(${snapshotDateLabel(services.catalog.snapshotWib)}), selama kuota '
        'tersedia.${perOrder == null ? '' : ' Maksimal $perOrder per pesanan.'}',
        textAlign: TextAlign.center,
        style: BpText.caption.copyWith(color: c.textMuted),
      ),
    );
  }
}
