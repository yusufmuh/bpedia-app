/// Wishlist (`/wishlist`, PERBAIKAN wishlist): produk favorit tersimpan di
/// perangkat, chip kategori berjumlah, "N produk tersimpan" + "Atur" untuk
/// hapus massal, grid dua kolom dengan tombol keranjang, dan keadaan kosong
/// dengan Bipy.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/shell.dart' show CartButton;
import '../../data/catalog/catalog_repository.dart';
import '../../design/design.dart';
import '../catalog/shop_common.dart';

/// Daftar produk favorit.
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  String? _category;
  bool _editing = false;
  final Set<String> _selected = <String>{};

  void _toggleEditing() => setState(() {
    _editing = !_editing;
    _selected.clear();
  });

  void _toggleSelected(String code) => setState(() {
    if (!_selected.remove(code)) _selected.add(code);
  });

  void _removeSelected() {
    final services = AppScope.of(context);
    final count = _selected.length;
    for (final code in _selected) {
      services.wishlist.remove(code);
    }
    services.haptics.selection();
    setState(() {
      _selected.clear();
      _editing = false;
    });
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$count produk dihapus dari wishlist.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.wishlist,
        services.catalog,
        services.auth,
      ]),
      builder: (context, _) {
        final state = catalogStateView(context);
        final all = state == null ? services.wishlist.products : <Product>[];
        final counts = <String, int>{};
        for (final product in all) {
          counts[product.categoryId] = (counts[product.categoryId] ?? 0) + 1;
        }
        final category = counts.containsKey(_category) ? _category : null;
        final products = category == null
            ? all
            : all.where((p) => p.categoryId == category).toList();
        final editing = _editing && all.isNotEmpty;
        return Scaffold(
          backgroundColor: c.canvas,
          appBar: BpAppBar(
            title: 'Wishlist',
            actions: <Widget>[
              IconButton(
                key: const ValueKey<String>('wishlist-cari'),
                tooltip: 'Cari produk',
                onPressed: () =>
                    services.router.go(context, const SearchRoute()),
                icon: Icon(LucideIcons.search, color: c.text),
              ),
              const CartButton(),
            ],
          ),
          bottomNavigationBar: editing
              ? StickyBottomBar(
                  child: PillButton(
                    key: const ValueKey<String>('wishlist-hapus'),
                    label: _selected.isEmpty
                        ? 'Pilih produk untuk dihapus'
                        : 'Hapus dari wishlist (${_selected.length})',
                    expand: true,
                    onPressed: _selected.isEmpty ? null : _removeSelected,
                  ),
                )
              : null,
          body:
              state ??
              (all.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: EmptyState(
                          imageAsset: 'assets/bipy/bipy_pose_belanja.webp',
                          imageSize: 150,
                          title: 'Wishlist masih kosong',
                          message:
                              'Ketuk ikon hati di produk yang kamu suka, nanti '
                              'tersimpan di sini.',
                          actionLabel: 'Mulai belanja',
                          onAction: () =>
                              services.router.go(context, const CatalogRoute()),
                        ),
                      ),
                    )
                  : CustomScrollView(
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: _CategoryChips(
                            total: all.length,
                            counts: counts,
                            selected: category,
                            onSelected: (id) => setState(() => _category = id),
                          ),
                        ),
                        if (!services.auth.isLoggedIn)
                          const SliverToBoxAdapter(child: _GuestNote()),
                        SliverToBoxAdapter(
                          child: _CountRow(
                            products: products,
                            editing: editing,
                            onEdit: _toggleEditing,
                          ),
                        ),
                        SliverProductGrid(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final card = ShopProductCard(
                              product: product,
                              action: ProductCardAction.addButton,
                            );
                            if (!editing) return card;
                            return _SelectableCard(
                              selected: _selected.contains(product.code),
                              label: product.name,
                              onTap: () => _toggleSelected(product.code),
                              child: card,
                            );
                          },
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: BpSpace.x4),
                        ),
                      ],
                    )),
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.total,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final int total;
  final Map<String, int> counts;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.screen,
          vertical: BpSpace.x2,
        ),
        child: Row(
          children: <Widget>[
            BpChip(
              key: const ValueKey<String>('wishlist-semua'),
              label: 'Semua ($total)',
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final category in services.catalog.categories)
              if (counts.containsKey(category.id)) ...<Widget>[
                const SizedBox(width: BpSpace.x2),
                BpChip(
                  key: ValueKey<String>('wishlist-kategori-${category.id}'),
                  label: '${category.name} (${counts[category.id]})',
                  selected: selected == category.id,
                  onTap: () => onSelected(category.id),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _GuestNote extends StatelessWidget {
  const _GuestNote();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Container(
      color: c.brandTint,
      padding: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        BpSpace.x2,
        BpSpace.x2,
        BpSpace.x2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Wishlist tersimpan di perangkat ini. Masuk supaya gampang '
              'checkout.',
              style: BpText.caption.copyWith(color: c.text),
            ),
          ),
          PillButton(
            label: 'Masuk',
            size: PillButtonSize.small,
            variant: PillButtonVariant.tonal,
            onPressed: () => services.router.go(
              context,
              const LoginRoute(next: '/wishlist'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.products,
    required this.editing,
    required this.onEdit,
  });

  final List<Product> products;
  final bool editing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final soldOut = products.where((product) => !product.inStock).length;
    final muted = BpText.bodyS.copyWith(color: c.textMuted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        BpSpace.x2,
        BpSpace.x1,
        BpSpace.x1,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '${products.length}',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' produk tersimpan'),
                  if (soldOut > 0) TextSpan(text: ' · $soldOut stok habis'),
                ],
              ),
              style: muted,
            ),
          ),
          PillButton(
            key: const ValueKey<String>('wishlist-atur'),
            label: editing ? 'Selesai' : 'Atur',
            variant: PillButtonVariant.text,
            size: PillButtonSize.small,
            icon: editing ? null : const Icon(LucideIcons.pencil, size: 16),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Kartu dalam mode Atur: ketuk memilih, lingkaran centang di kiri atas.
class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Stack(
      children: <Widget>[
        ExcludeSemantics(child: child),
        Positioned.fill(
          child: BpTappable(
            onTap: onTap,
            selected: selected,
            semanticLabel: selected ? '$label, dipilih' : label,
            pressScale: false,
            focusRadius: BpRadius.cardAll,
            builder: (context, states) => DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? c.brand.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BpRadius.cardAll,
                border: Border.all(
                  color: selected ? c.brand : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(BpSpace.x2),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? c.brand : c.surface,
                    border: Border.all(
                      color: selected ? c.brand : c.textFaint,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? Icon(LucideIcons.check, size: 16, color: c.onBrand)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
