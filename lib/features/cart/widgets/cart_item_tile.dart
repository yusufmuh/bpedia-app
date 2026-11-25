import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/cart/cart_repository.dart';
import '../../../design/design.dart';
import 'line_parts.dart';

/// Satu baris keranjang: centang, gambar 72, nama 2 baris, lencana (Hot
/// Item, produk misi), harga, dan stepper. Geser ke kiri untuk menghapus.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.missionProduct,
    required this.onSelected,
    required this.onQtyChanged,
    required this.onRemove,
    required this.onOpen,
  });

  final CartItem item;

  /// Produk ini termasuk produk misi tahap aktif.
  final bool missionProduct;
  final ValueChanged<bool> onSelected;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final product = item.product;
    final perOrder = product.hot?.maxPerOrder;
    final limitNote = perOrder != null && perOrder <= product.stock
        ? 'Maks. $perOrder per pesanan'
        : (product.stock <= 5 ? 'Stok tinggal ${product.stock}' : null);
    return Dismissible(
      key: ValueKey<String>('cart-${product.code}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: c.danger,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.only(right: BpSpace.x6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(LucideIcons.trash2, color: c.surface, size: BpSize.iconDense),
            const SizedBox(width: BpSpace.x2),
            Text('Hapus', style: BpText.subtitle.copyWith(color: c.surface)),
          ],
        ),
      ),
      child: ColoredBox(
        color: c.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.x1,
            BpSpace.x3,
            BpSpace.screen,
            BpSpace.x3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Checkbox(
                  value: item.selected,
                  onChanged: (value) => onSelected(value ?? false),
                  semanticLabel: 'Pilih ${product.name}',
                ),
              ),
              Semantics(
                button: true,
                label: 'Buka ${product.name}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onOpen,
                  child: LineThumb(asset: product.primaryImage),
                ),
              ),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: onOpen,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BpText.bodyS.copyWith(color: c.text),
                      ),
                    ),
                    if (product.isHot || missionProduct || limitNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: BpSpace.x1),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: <Widget>[
                            if (product.isHot)
                              const StatusChip(
                                label: 'Hot Item',
                                tone: StatusTone.danger,
                              ),
                            if (missionProduct)
                              const StatusChip(
                                label: 'Produk misi',
                                tone: StatusTone.gold,
                              ),
                            if (limitNote != null)
                              Text(
                                limitNote,
                                style: BpText.caption.copyWith(
                                  color: c.warning,
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: BpSpace.x2),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: BpSpace.x1,
                        spacing: BpSpace.x2,
                        children: <Widget>[
                          PriceText(
                            product.price,
                            strikePrice: product.strikePrice,
                            discountPercent: product.discountPercent,
                            stacked: true,
                          ),
                          QtyStepper(
                            value: item.qty,
                            max: product.maxQty,
                            onChanged: onQtyChanged,
                            onRemove: onRemove,
                          ),
                        ],
                      ),
                    ),
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
