/// Halaman Hot Item (`/hot-item`, FITUR #10): daftar produk sale dengan
/// gambar highlight asli, filter tema promo, dan cari.
library;

import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;

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

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(
        titleWidget: HotItemTitle(size: 18),
        actions: <Widget>[CartButton()],
      ),
      body: ListenableBuilder(
        listenable: services.catalog,
        builder: (context, _) {
          final state = catalogStateView(context);
          if (state != null) return state;
          final all = services.catalog.hotItems;
          final themes = <String>{
            for (final product in all) product.hot!.theme,
          }.toList();
          final results = services.catalog
              .search(CatalogQuery(text: _text, hotOnly: true))
              .where(
                (product) => _theme == null || product.hot!.theme == _theme,
              )
              .toList();
          final soonest = soonestRunning(all, services.clock.today);
          return CustomScrollView(
            slivers: <Widget>[
              PinnedHeaderSliver(
                child: ColoredBox(
                  color: c.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          BpSpace.screen,
                          BpSpace.x2,
                          BpSpace.screen,
                          BpSpace.x1,
                        ),
                        child: SearchField(
                          key: const ValueKey<String>('hot-cari'),
                          controller: _search,
                          hint: 'Cari di Hot Item',
                          onChanged: (value) => setState(() => _text = value),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                          BpSpace.screen,
                          BpSpace.x1,
                          BpSpace.screen,
                          BpSpace.x2,
                        ),
                        child: Row(
                          children: <Widget>[
                            BpChip(
                              label: 'Semua (${all.length})',
                              selected: _theme == null,
                              onTap: () => setState(() => _theme = null),
                            ),
                            for (final theme in themes) ...<Widget>[
                              const SizedBox(width: BpSpace.x2),
                              BpChip(
                                label: theme,
                                selected: _theme == theme,
                                onTap: () => setState(() => _theme = theme),
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
              SliverToBoxAdapter(
                child: _HotIntro(soonest: soonest, count: results.length),
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
              else ...<Widget>[
                SliverProductGrid(
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      HotItemCard(product: results[index], showAddButton: true),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: BpSpace.x4)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HotIntro extends StatelessWidget {
  const _HotIntro({required this.soonest, required this.count});

  final HotDeal? soonest;
  final int count;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final deal = soonest;
    final limits = <int>{
      for (final product in services.catalog.hotItems) product.hot!.maxPerOrder,
    };
    final perOrder = limits.length == 1 ? limits.first : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        BpSpace.x3,
        BpSpace.screen,
        BpSpace.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: BpSpace.x2,
            runSpacing: BpSpace.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '$count produk harga spesial',
                style: BpText.subtitle.copyWith(color: c.text),
              ),
              if (deal != null)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      'Berakhir dalam ',
                      style: BpText.caption.copyWith(color: c.textMuted),
                    ),
                    HotCountdown(deal: deal),
                  ],
                ),
            ],
          ),
          const SizedBox(height: BpSpace.x1),
          Text(
            'Harga dan kuota sesuai bpedia.id '
            '(${snapshotDateLabel(services.catalog.snapshotWib)}).'
            '${perOrder == null ? '' : ' Maksimal $perOrder per pesanan.'}',
            style: BpText.caption.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
