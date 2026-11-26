/// Lembar Filter katalog (SPEC §4.3, PERBAIKAN katalog_filter): chip
/// kategori satu baris gulir, brand terbanyak dengan jumlah produk dan
/// "Lihat semua", rentang harga dengan chip cepat, "Atur ulang", dan
/// "Terapkan (N produk)".
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_scope.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../design/design.dart';

/// Rentang harga cepat.
const List<({String label, int? min, int? max})> priceRanges =
    <({String label, int? min, int? max})>[
      (label: 'Di bawah Rp25.000', min: null, max: 24999),
      (label: 'Rp25.000 sampai Rp50.000', min: 25000, max: 50000),
      (label: 'Rp50.000 sampai Rp100.000', min: 50000, max: 100000),
      (label: 'Di atas Rp100.000', min: 100001, max: null),
    ];

/// Membuka lembar Filter untuk [initial]. Mengembalikan kueri baru bila
/// "Terapkan" ditekan, atau null bila ditutup.
Future<CatalogQuery?> showCatalogFilterSheet(
  BuildContext context,
  CatalogQuery initial,
) {
  return showBpSheet<CatalogQuery>(
    context: context,
    useRootNavigator: true,
    builder: (context) => CatalogFilterSheet(initial: initial),
  );
}

/// Isi lembar Filter.
class CatalogFilterSheet extends StatefulWidget {
  const CatalogFilterSheet({required this.initial, super.key});

  final CatalogQuery initial;

  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  late CatalogQuery _draft = widget.initial;
  final TextEditingController _brandSearch = TextEditingController();
  late final TextEditingController _min = TextEditingController(
    text: widget.initial.minPrice?.toString() ?? '',
  );
  late final TextEditingController _max = TextEditingController(
    text: widget.initial.maxPrice?.toString() ?? '',
  );
  String _brandNeedle = '';
  bool _allBrands = false;

  /// Jumlah brand yang tampil sebelum "Lihat semua".
  static const int _topBrands = 4;

  @override
  void dispose() {
    _brandSearch.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _setPrice(int? min, int? max, {bool syncFields = true}) {
    setState(() {
      _draft = min == null && max == null
          ? _draft.copyWith(clearPrice: true)
          : CatalogQuery(
              text: _draft.text,
              categoryId: _draft.categoryId,
              brands: _draft.brands,
              minPrice: min,
              maxPrice: max,
              sort: _draft.sort,
              hotOnly: _draft.hotOnly,
            );
      if (syncFields) {
        _min.text = min?.toString() ?? '';
        _max.text = max?.toString() ?? '';
      }
    });
  }

  void _onPriceTyped() {
    _setPrice(
      int.tryParse(_min.text),
      int.tryParse(_max.text),
      syncFields: false,
    );
  }

  void _reset() {
    _brandSearch.clear();
    setState(() {
      _brandNeedle = '';
      _draft = _draft.withoutFilters();
      _min.clear();
      _max.clear();
    });
  }

  void _toggleBrand(String brand) {
    final brands = <String>{..._draft.brands};
    if (!brands.remove(brand)) brands.add(brand);
    setState(() => _draft = _draft.copyWith(brands: brands));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final catalog = services.catalog;
    final c = context.bp;
    final count = catalog.search(_draft).length;
    final min = _draft.minPrice;
    final max = _draft.maxPrice;
    final invalidRange = min != null && max != null && min > max;
    final counts = <String, int>{};
    for (final product in catalog.search(
      CatalogQuery(
        text: _draft.text,
        categoryId: _draft.categoryId,
        minPrice: min,
        maxPrice: max,
        hotOnly: _draft.hotOnly,
      ),
    )) {
      counts[product.brand] = (counts[product.brand] ?? 0) + 1;
    }
    final matching = catalog.brandsMatching(_brandNeedle).toList()
      ..sort((a, b) {
        final byCount = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    final collapsed = !_allBrands && _brandNeedle.trim().isEmpty;
    final brands = collapsed
        ? <String>[
            ...matching.take(_topBrands),
            for (final brand in matching.skip(_topBrands))
              if (_draft.brands.contains(brand)) brand,
          ]
        : matching;
    return BpSheet(
      title: 'Filter',
      footer: Row(
        children: <Widget>[
          Expanded(
            child: PillButton(
              label: 'Atur ulang',
              variant: PillButtonVariant.neutral,
              onPressed: _draft.activeFilterCount == 0 ? null : _reset,
            ),
          ),
          const SizedBox(width: BpSpace.x3),
          Expanded(
            flex: 2,
            child: PillButton(
              label: invalidRange
                  ? 'Cek rentang harga'
                  : 'Terapkan ($count produk)',
              onPressed: invalidRange
                  ? null
                  : () => Navigator.of(context).pop(_draft),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _GroupTitle('Kategori'),
          SingleChildScrollView(
            key: const ValueKey<String>('filter-kategori'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final category in catalog.categories) ...<Widget>[
                  BpChip(
                    label: category.name,
                    selected: _draft.categoryId == category.id,
                    leading: _draft.categoryId == category.id
                        ? const Icon(LucideIcons.check)
                        : null,
                    onTap: () => setState(
                      () => _draft = _draft.categoryId == category.id
                          ? _draft.copyWith(clearCategory: true)
                          : _draft.copyWith(categoryId: category.id),
                    ),
                  ),
                  const SizedBox(width: BpSpace.x2),
                ],
              ],
            ),
          ),
          const _SectionDivider(),
          _GroupTitle(
            'Brand',
            trailing: _draft.brands.isEmpty
                ? null
                : '${_draft.brands.length} dipilih',
            action:
                _brandNeedle.trim().isNotEmpty || matching.length <= _topBrands
                ? null
                : (
                    label: _allBrands ? 'Lebih sedikit' : 'Lihat semua',
                    onTap: () => setState(() => _allBrands = !_allBrands),
                  ),
          ),
          SearchField(
            controller: _brandSearch,
            hint: 'Cari brand',
            onChanged: (value) => setState(() => _brandNeedle = value),
          ),
          const SizedBox(height: BpSpace.x2),
          if (brands.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: BpSpace.x3),
              child: Text(
                'Brand "$_brandNeedle" belum ada di katalog.',
                style: BpText.bodyS.copyWith(color: c.textMuted),
              ),
            )
          else
            for (final brand in brands)
              _BrandRow(
                brand: brand,
                count: counts[brand] ?? 0,
                selected: _draft.brands.contains(brand),
                onTap: () => _toggleBrand(brand),
              ),
          const _SectionDivider(),
          const _GroupTitle('Harga'),
          Row(
            children: <Widget>[
              Expanded(
                child: _PriceField(
                  controller: _min,
                  label: 'Minimum',
                  onChanged: _onPriceTyped,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
                child: Text(
                  '-',
                  style: BpText.body.copyWith(color: c.textMuted),
                ),
              ),
              Expanded(
                child: _PriceField(
                  controller: _max,
                  label: 'Maksimum',
                  onChanged: _onPriceTyped,
                ),
              ),
            ],
          ),
          if (invalidRange)
            Padding(
              padding: const EdgeInsets.only(top: BpSpace.x2),
              child: Text(
                'Harga minimum lebih besar dari maksimum. Tukar angkanya, ya.',
                style: BpText.caption.copyWith(color: c.danger),
              ),
            ),
          const SizedBox(height: BpSpace.x3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final range in priceRanges) ...<Widget>[
                  BpChip(
                    label: range.label,
                    selected: min == range.min && max == range.max,
                    onTap: () => min == range.min && max == range.max
                        ? _setPrice(null, null)
                        : _setPrice(range.min, range.max),
                  ),
                  const SizedBox(width: BpSpace.x2),
                ],
              ],
            ),
          ),
          const SizedBox(height: BpSpace.x4),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: BpSpace.x3),
    child: Divider(height: 1, thickness: 1, color: context.bp.line),
  );
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title, {this.trailing, this.action});

  final String title;
  final String? trailing;
  final ({String label, VoidCallback onTap})? action;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final note = trailing;
    final link = action;
    return Padding(
      padding: const EdgeInsets.only(bottom: BpSpace.x2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: BpText.subtitle.copyWith(color: c.text),
              ),
            ),
          ),
          if (note != null)
            Text(note, style: BpText.caption.copyWith(color: c.brandStrong)),
          if (link != null)
            PillButton(
              key: const ValueKey<String>('filter-brand-semua'),
              label: link.label,
              variant: PillButtonVariant.text,
              size: PillButtonSize.small,
              onPressed: link.onTap,
            ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.brand,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String brand;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return MergeSemantics(
      child: BpTappable(
        onTap: onTap,
        selected: selected,
        semanticLabel: brand,
        pressScale: false,
        alignment: Alignment.centerLeft,
        focusRadius: BpRadius.tileAll,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.symmetric(vertical: BpSpace.x1),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: BpMotion.micro,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? c.brand : c.surface,
                  borderRadius: BpRadius.badgeAll,
                  border: Border.all(
                    color: selected ? c.brand : c.textFaint,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(LucideIcons.check, size: 16, color: c.onBrand)
                    : null,
              ),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Text(
                  brand,
                  style: BpText.body.copyWith(
                    color: c.text,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: BpSpace.x2),
              ExcludeSemantics(
                child: Text(
                  '$count',
                  style: BpText.caption.copyWith(
                    fontSize: 12,
                    color: c.textMuted,
                    fontFeatures: BpText.tabular,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      onChanged: (_) => onChanged(),
      style: BpText.body.copyWith(fontFeatures: BpText.tabular),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp',
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}
