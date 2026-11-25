/// Layar Cari (SPEC §4.3): kolom cari fokus otomatis, riwayat pencarian
/// lokal, saran kategori dan brand saat kolom kosong, dan saran langsung
/// (produk, brand, kategori) saat mengetik.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../design/design.dart';
import '../catalog/shop_common.dart';

/// Halaman cari dengan teks awal [initialQuery].
class SearchPage extends StatefulWidget {
  const SearchPage({this.initialQuery, super.key});

  final String? initialQuery;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller =
      TextEditingController.fromValue(
        TextEditingValue(
          text: widget.initialQuery ?? '',
          selection: TextSelection.collapsed(
            offset: (widget.initialQuery ?? '').length,
          ),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    final services = AppScope.of(context);
    services.searchHistory.record(text);
    services.router.go(context, CatalogRoute(query: text));
  }

  void _openCatalog(CatalogRoute route) {
    AppScope.of(context).router.go(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final text = _controller.text.trim();
    return Scaffold(
      backgroundColor: c.surface,
      appBar: BpAppBar(
        titleWidget: SearchField(
          key: const ValueKey<String>('cari-kolom'),
          controller: _controller,
          autofocus: true,
          hint: 'Cari produk, brand, atau kategori',
          onChanged: (_) => setState(() {}),
          onSubmitted: _submit,
        ),
        actions: <Widget>[
          PillButton(
            label: 'Cari',
            variant: PillButtonVariant.text,
            size: PillButtonSize.small,
            onPressed: text.isEmpty ? null : () => _submit(text),
          ),
        ],
      ),
      body: text.isEmpty
          ? _SearchHome(onSearch: _submit, onCatalog: _openCatalog)
          : _Suggestions(
              text: text,
              onSearch: _submit,
              onCatalog: _openCatalog,
            ),
    );
  }
}

class _SearchHome extends StatelessWidget {
  const _SearchHome({required this.onSearch, required this.onCatalog});

  final ValueChanged<String> onSearch;
  final ValueChanged<CatalogRoute> onCatalog;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return ListenableBuilder(
      listenable: services.searchHistory,
      builder: (context, _) {
        final terms = services.searchHistory.terms;
        return ListView(
          padding: const EdgeInsets.only(bottom: BpSpace.x6),
          children: <Widget>[
            if (terms.isNotEmpty) ...<Widget>[
              SectionHeader(
                title: 'Riwayat pencarian',
                trailing: PillButton(
                  label: 'Hapus semua',
                  variant: PillButtonVariant.text,
                  size: PillButtonSize.small,
                  onPressed: services.searchHistory.clear,
                ),
              ),
              for (final term in terms)
                _HistoryRow(
                  term: term,
                  onTap: () => onSearch(term),
                  onRemove: () => services.searchHistory.remove(term),
                ),
              const SizedBox(height: BpSpace.x2),
            ],
            const SectionHeader(title: 'Kategori populer'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
              child: Wrap(
                spacing: BpSpace.x2,
                runSpacing: BpSpace.x2,
                children: <Widget>[
                  for (final category in services.catalog.categories)
                    BpChip(
                      label: category.name,
                      leading: switch (BrandGlyph.tryParse(category.icon)) {
                        final BrandGlyph glyph => BrandIcon(glyph, size: 16),
                        null => null,
                      },
                      onTap: () =>
                          onCatalog(CatalogRoute(category: category.id)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: BpSpace.x3),
            const SectionHeader(title: 'Brand pilihan'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
              child: Wrap(
                spacing: BpSpace.x2,
                runSpacing: BpSpace.x2,
                children: <Widget>[
                  for (final brand in popularBrands(services, limit: 12))
                    BpChip(
                      label: brand,
                      onTap: () =>
                          onCatalog(CatalogRoute(brands: <String>[brand])),
                    ),
                ],
              ),
            ),
            const SizedBox(height: BpSpace.x3),
            if (services.catalog.hotItems.isNotEmpty)
              InfoRow(
                label: 'Lagi Hot Item',
                helper:
                    '${services.catalog.hotItems.length} produk harga spesial',
                leading: Icon(LucideIcons.flame, color: c.sale),
                trailing: Icon(LucideIcons.chevronRight, color: c.textMuted),
                onTap: () => services.router.go(context, const HotItemsRoute()),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return InfoRow(
      label: term,
      leading: Icon(LucideIcons.history, size: 20, color: c.textMuted),
      onTap: onTap,
      trailing: IconButton(
        tooltip: 'Hapus "$term" dari riwayat',
        onPressed: onRemove,
        icon: Icon(LucideIcons.x, size: 18, color: c.textMuted),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.text,
    required this.onSearch,
    required this.onCatalog,
  });

  final String text;
  final ValueChanged<String> onSearch;
  final ValueChanged<CatalogRoute> onCatalog;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final needle = text.toLowerCase();
    final brands = services.catalog.brandsMatching(text).take(3).toList();
    final categories = services.catalog.categories
        .where((category) => category.name.toLowerCase().contains(needle))
        .toList();
    final products = services.catalog
        .search(CatalogQuery(text: text))
        .take(6)
        .toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: BpSpace.x6),
      children: <Widget>[
        InfoRow(
          key: const ValueKey<String>('cari-semua'),
          label: 'Cari "$text"',
          leading: Icon(LucideIcons.search, size: 20, color: c.brandStrong),
          trailing: Icon(LucideIcons.arrowUpLeft, size: 18, color: c.textMuted),
          onTap: () => onSearch(text),
        ),
        for (final brand in brands)
          InfoRow(
            label: brand,
            helper: 'Brand',
            leading: Icon(LucideIcons.store, size: 20, color: c.textMuted),
            onTap: () => onCatalog(CatalogRoute(brands: <String>[brand])),
          ),
        for (final category in categories)
          InfoRow(
            label: category.name,
            helper: 'Kategori',
            leading: BrandIcon(
              BrandGlyph.tryParse(category.icon) ?? BrandGlyph.bag,
              size: 20,
              color: c.textMuted,
            ),
            onTap: () => onCatalog(CatalogRoute(category: category.id)),
          ),
        if (products.isNotEmpty) ...<Widget>[
          Container(height: BpSpace.sectionGap, color: c.canvas),
          const SectionHeader(title: 'Produk'),
          for (final product in products)
            _ProductSuggestion(
              product: product,
              onTap: () =>
                  services.router.go(context, ProductRoute(product.code)),
            ),
        ] else if (brands.isEmpty && categories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(BpSpace.screen),
            child: Text(
              'Belum ada produk yang cocok. Tekan Cari untuk melihat hasil '
              'lengkap dan atur filter.',
              style: BpText.bodyS.copyWith(color: c.textMuted),
            ),
          ),
      ],
    );
  }
}

class _ProductSuggestion extends StatelessWidget {
  const _ProductSuggestion({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      onTap: onTap,
      semanticLabel: '${product.name}, ${formatRupiah(product.price)}',
      pressScale: false,
      alignment: Alignment.centerLeft,
      focusRadius: BpRadius.tileAll,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.screen,
          vertical: BpSpace.x2,
        ),
        child: Row(
          children: <Widget>[
            AssetPicture(
              product.primaryImage,
              width: 48,
              height: 48,
              borderRadius: BpRadius.tileAll,
            ),
            const SizedBox(width: BpSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BpText.bodyS.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(product.price),
                    style: BpText.subtitle.copyWith(
                      color: c.brandStrong,
                      fontFeatures: BpText.tabular,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
