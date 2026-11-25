/// Lembar kecil "Tambah ke keranjang" dengan pengatur jumlah (SPEC §4.4).
library;

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../design/design.dart';
import '../catalog/shop_common.dart';

/// Membuka lembar jumlah untuk [product]; menambah ke keranjang saat
/// dikonfirmasi.
Future<void> showAddToCartSheet(BuildContext context, Product product) async {
  final qty = await showBpSheet<int>(
    context: context,
    useRootNavigator: true,
    maxHeightFactor: 0.7,
    builder: (context) => AddToCartSheet(product: product),
  );
  if (qty != null && context.mounted) {
    addProductToCart(context, product, qty: qty);
  }
}

/// Isi lembar jumlah.
class AddToCartSheet extends StatefulWidget {
  const AddToCartSheet({required this.product, super.key});

  final Product product;

  @override
  State<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends State<AddToCartSheet> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final product = widget.product;
    final inCart = services.cart.quantityOf(product.code);
    final room = (product.maxQty - inCart).clamp(0, product.maxQty);
    final perOrder = product.hot?.maxPerOrder;
    final String note;
    if (room == 0) {
      note = inCart > 0
          ? 'Jumlah di keranjang sudah batas maksimal ($inCart).'
          : 'Stok produk ini habis.';
    } else if (perOrder != null) {
      note = 'Hot Item: maksimal $perOrder per pesanan.';
    } else {
      note =
          'Stok ${product.stock}${inCart > 0 ? ' · $inCart di keranjang' : ''}';
    }
    return BpSheet(
      title: 'Tambah ke keranjang',
      footer: PillButton(
        key: const ValueKey<String>('lembar-tambah'),
        label: 'Masukkan keranjang',
        expand: true,
        onPressed: room == 0 ? null : () => Navigator.of(context).pop(_qty),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AssetPicture(
                product.primaryImage,
                width: 72,
                height: 72,
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
                    const SizedBox(height: BpSpace.x1),
                    PriceText(product.price, strikePrice: product.strikePrice),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BpSpace.x4),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Jumlah',
                      style: BpText.subtitle.copyWith(color: c.text),
                    ),
                    Text(
                      note,
                      style: BpText.caption.copyWith(
                        color: room == 0 ? c.danger : c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BpSpace.x3),
              QtyStepper(
                value: room == 0 ? 0 : _qty,
                min: room == 0 ? 0 : 1,
                max: room == 0 ? 0 : room,
                onChanged: room == 0
                    ? null
                    : (value) => setState(() => _qty = value),
              ),
            ],
          ),
          const SizedBox(height: BpSpace.x2),
        ],
      ),
    );
  }
}
