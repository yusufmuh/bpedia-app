/// Tab Katalog (SPEC §4.3): kolom cari, kategori, bar alat menempel (Filter
/// berlencana + chip urutan), chip filter aktif, dan grid dua kolom.
library;

import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/shell.dart' show CartButton;
import '../../data/catalog/catalog_repository.dart';
import '../../design/design.dart';
import 'catalog_query_route.dart';
import 'filter_sheet.dart';
import 'shop_common.dart';

/// Isi tab Katalog. Parameter kueri dibaca dari `router.tabRoute`.
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ValueListenableBuilder<AppRoute>(
      valueListenable: services.router.tabRoute,
      builder: (context, route, _) {
        final query = route is CatalogRoute
            ? queryOfRoute(route)
            : CatalogQuery();
        return CatalogView(query: query);
      },
    );
  }
}

/// Tampilan katalog untuk [query].
class CatalogView extends StatelessWidget {
  const CatalogView({required this.query, super.key});

  final CatalogQuery query;

  void _apply(BuildContext context, CatalogQuery next) {
    AppScope.of(context).router.go(context, routeOfQuery(next));
  }

  Future<void> _openFilter(BuildContext context) async {
    final next = await showCatalogFilterSheet(context, query);
    if (next != null && context.mounted) _apply(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: <Widget>[
          _CatalogHeader(
            query: query,
            onClearText: () => _apply(context, query.copyWith(text: '')),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: services.catalog,
              builder: (context, _) {
                final state = catalogStateView(context, sliver: true);
                final results = services.catalog.search(query);
                final suggestions = results.isEmpty
                    ? services.catalog
                          .search(
                            CatalogQuery(sort: CatalogSort.biggestDiscount),
                          )
                          .take(6)
                          .toList()
                    : const <Product>[];
                return CustomScrollView(
                  primary: true,
                  slivers: <Widget>[
                    if (query.isEmpty)
                      SliverToBoxAdapter(
                        child: _CategoryStrip(
                          onSelected: (id) =>
                              _apply(context, query.copyWith(categoryId: id)),
                        ),
                      ),
                    PinnedHeaderSliver(
                      child: _Toolbar(
                        query: query,
                        onFilter: () => _openFilter(context),
                        onSort: (sort) =>
                            _apply(context, query.copyWith(sort: sort)),
                        onChanged: (next) => _apply(context, next),
                      ),
                    ),
                    if (state != null)
                      state
                    else if (results.isEmpty) ...<Widget>[
                      SliverToBoxAdapter(
                        child: _EmptyResults(
                          query: query,
                          onClear: () => _apply(
                            context,
                            query.activeFilterCount > 0
                                ? query.withoutFilters()
                                : CatalogQuery(sort: query.sort),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Section(
                          gap: false,
                          padding: EdgeInsets.only(top: BpSpace.x1),
                          header: SectionHeader(title: 'Mungkin kamu suka'),
                          child: SizedBox.shrink(),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(top: BpSpace.x2),
                        sliver: SliverProductGrid(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) =>
                              ShopProductCard(product: suggestions[index]),
                        ),
                      ),
                    ] else ...<Widget>[
                      SliverToBoxAdapter(
                        child: _ResultCount(
                          query: query,
                          count: results.length,
                        ),
                      ),
                      SliverProductGrid(
                        itemCount: results.length,
                        itemBuilder: (context, index) =>
                            ShopProductCard(product: results[index]),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: BpSpace.x4),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.query, required this.onClearText});

  final CatalogQuery query;
  final VoidCallback onClearText;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final text = query.text;
    return Material(
      color: c.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.screen,
            BpSpace.x2,
            BpSpace.x1,
            BpSpace.x2,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SearchField.button(
                  key: const ValueKey<String>('katalog-cari'),
                  hint: text.isEmpty ? 'Cari di katalog Bpedia' : text,
                  onTap: () => services.router.go(
                    context,
                    SearchRoute(query: text.isEmpty ? null : text),
                  ),
                  trailing: text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus kata kunci',
                          onPressed: onClearText,
                          icon: const Icon(LucideIcons.x, size: 18),
                        ),
                ),
              ),
              const SizedBox(width: BpSpace.x1),
              const InboxButton(),
              const CartButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Container(
      color: c.surface,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: BpSpace.x3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final category in services.catalog.categories)
              CategoryTile(
                label: category.name,
                icon: category.icon,
                onTap: () => onSelected(category.id),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ubin kategori: ikon brand berwarna dalam lingkaran `brandTint` + label.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final glyph = BrandGlyph.tryParse(icon) ?? BrandGlyph.bag;
    return BpTappable(
      onTap: onTap,
      semanticLabel: 'Kategori $label',
      focusRadius: BpRadius.tileAll,
      builder: (context, states) => SizedBox(
        width: 76,
        child: Column(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.brandTint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: BrandIcon(glyph, size: 28, style: BrandIconStyle.color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: BpText.caption.copyWith(color: c.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.query,
    required this.onFilter,
    required this.onSort,
    required this.onChanged,
  });

  final CatalogQuery query;
  final VoidCallback onFilter;
  final ValueChanged<CatalogSort> onSort;
  final ValueChanged<CatalogQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final count = query.activeFilterCount;
    final categoryId = query.categoryId;
    final min = query.minPrice;
    final max = query.maxPrice;
    final active = <Widget>[
      if (categoryId != null)
        BpChip(
          label: categoryNameOf(services, categoryId),
          onDeleted: () => onChanged(query.copyWith(clearCategory: true)),
        ),
      for (final brand in query.brands.toList()..sort())
        BpChip(
          label: brand,
          onDeleted: () => onChanged(
            query.copyWith(
              brands: query.brands.where((other) => other != brand),
            ),
          ),
        ),
      if (min != null || max != null)
        BpChip(
          label: priceRangeLabel(min, max),
          onDeleted: () => onChanged(query.copyWith(clearPrice: true)),
        ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BpSpace.screen,
              vertical: BpSpace.x1,
            ),
            child: Row(
              children: <Widget>[
                BpChip(
                  key: const ValueKey<String>('katalog-filter'),
                  label: 'Filter',
                  selected: count > 0,
                  leading: const Icon(LucideIcons.slidersHorizontal),
                  trailing: count == 0 ? null : CountBadge(count: count),
                  onTap: onFilter,
                ),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
                  color: c.line,
                ),
                for (final sort in CatalogSort.values) ...<Widget>[
                  BpChip(
                    label: sort.label,
                    selected: query.sort == sort,
                    onTap: () => onSort(sort),
                  ),
                  const SizedBox(width: BpSpace.x2),
                ],
              ],
            ),
          ),
          if (active.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                BpSpace.screen,
                0,
                BpSpace.screen,
                BpSpace.x1,
              ),
              child: Row(
                children: <Widget>[
                  for (final chip in active) ...<Widget>[
                    chip,
                    const SizedBox(width: BpSpace.x2),
                  ],
                  PillButton(
                    label: 'Hapus semua',
                    variant: PillButtonVariant.text,
                    size: PillButtonSize.small,
                    onPressed: () => onChanged(query.withoutFilters()),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Rp25.000 sampai Rp50.000", "Mulai Rp100.001", "Sampai Rp24.999".
String priceRangeLabel(int? min, int? max) {
  if (min != null && max != null) {
    return '${formatRupiah(min)} sampai ${formatRupiah(max)}';
  }
  if (min != null) return 'Mulai ${formatRupiah(min)}';
  return 'Sampai ${formatRupiah(max ?? 0)}';
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.query, required this.count});

  final CatalogQuery query;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final text = query.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        BpSpace.x3,
        BpSpace.screen,
        BpSpace.x2,
      ),
      child: Semantics(
        liveRegion: true,
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '$count produk',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (text.isNotEmpty) TextSpan(text: ' untuk "$text"'),
            ],
          ),
          style: BpText.bodyS.copyWith(color: c.textMuted),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query, required this.onClear});

  final CatalogQuery query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilter = query.activeFilterCount > 0;
    final text = query.text;
    return EmptyState(
      illustration: const BipySprite(
        BipySprites.peek,
        height: 140,
        semanticLabel: 'Bipy mengintip dari tas',
      ),
      title: 'Belum ketemu, Babes',
      message: text.isEmpty
          ? 'Belum ada produk yang cocok dengan filter ini.'
          : 'Belum ada produk untuk "$text". Coba kata lain atau longgarkan filter.',
      actionLabel: hasFilter ? 'Hapus filter' : 'Lihat semua produk',
      onAction: onClear,
    );
  }
}
