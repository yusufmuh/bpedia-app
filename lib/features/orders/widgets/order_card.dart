import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_router.dart';
import '../../../app/app_scope.dart';
import '../../../data/orders/order_repository.dart';
import '../../../data/wib_dates.dart';
import '../../../design/design.dart';
import '../../cart/widgets/line_parts.dart';
import '../order_actions.dart';
import '../order_format.dart';

/// Kartu pesanan di daftar Transaksi: nomor, tanggal, chip status, barang
/// pertama + "+2 produk lain", hadiah, total, dan aksi utama sesuai status.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.busy = false});

  final Order order;

  /// Pesanan sedang diproses (tombol menampilkan pemutar).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final services = AppScope.of(context);
    final first = order.items.first;
    final others = order.items.length - 1;
    final payBy = order.payBy;
    return Padding(
      padding: const EdgeInsets.only(bottom: BpSpace.sectionGap),
      child: Material(
        color: c.surface,
        child: InkWell(
          onTap: () => services.router.go(context, OrderDetailRoute(order.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x3,
              BpSpace.screen,
              BpSpace.x3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: BpSpace.x2,
                  runSpacing: BpSpace.x2,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        BrandIcon(
                          BrandGlyph.transaksi,
                          size: BpSize.iconDense,
                          color: c.textMuted,
                        ),
                        const SizedBox(width: BpSpace.x2),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              order.id,
                              style: BpText.subtitle.copyWith(color: c.text),
                            ),
                            Text(
                              wibDateTimeLabel(order.placedAt),
                              style: BpText.caption.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    StatusChip(
                      label: order.status.label,
                      tone: orderStatusTone(order.status),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: BpSpace.x3),
                  child: Divider(height: 1, thickness: 1, color: c.line),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LineThumb(asset: first.image, size: 64),
                    const SizedBox(width: BpSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            first.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BpText.bodyS.copyWith(color: c.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${first.qty} x ${formatRupiah(first.unitPrice)}',
                            style: BpText.caption.copyWith(color: c.textMuted),
                          ),
                          if (others > 0 || order.gifts.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: BpSpace.x1),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: <Widget>[
                                  if (others > 0)
                                    StatusChip(label: '+$others produk lain'),
                                  if (order.gifts.isNotEmpty)
                                    StatusChip(
                                      label:
                                          '+${order.gifts.length} hadiah gratis',
                                      tone: StatusTone.gold,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (order.status == OrderStatus.awaitingPayment &&
                    payBy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BpSpace.x3),
                    child: Row(
                      children: <Widget>[
                        Icon(LucideIcons.clock, size: 16, color: c.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Bayar sebelum ${wibDateTimeLabel(payBy)}',
                            style: BpText.caption.copyWith(
                              color: c.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: BpSpace.x3),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: BpSpace.x3,
                  runSpacing: BpSpace.x2,
                  children: <Widget>[
                    MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Total ${order.itemCount} produk',
                            style: BpText.caption.copyWith(color: c.textMuted),
                          ),
                          Text(
                            formatRupiah(order.total),
                            style: BpText.title.copyWith(
                              color: c.text,
                              fontFeatures: BpText.tabular,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PrimaryAction(order: order, busy: busy),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.order, required this.busy});

  final Order order;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return switch (order.status) {
      OrderStatus.awaitingPayment => PillButton(
        label: 'Bayar',
        size: PillButtonSize.small,
        busy: busy,
        onPressed: () => services.router.go(context, PaymentRoute(order.id)),
      ),
      OrderStatus.packing => PillButton(
        label: 'Lacak',
        size: PillButtonSize.small,
        variant: PillButtonVariant.outline,
        onPressed: () =>
            services.router.go(context, OrderDetailRoute(order.id)),
      ),
      OrderStatus.shipped => PillButton(
        label: 'Pesanan diterima',
        size: PillButtonSize.small,
        busy: busy,
        onPressed: () => completeOrder(context, order),
      ),
      OrderStatus.completed || OrderStatus.cancelled => PillButton(
        label: 'Beli lagi',
        size: PillButtonSize.small,
        variant: PillButtonVariant.outline,
        onPressed: () => buyAgain(context, order),
      ),
    };
  }
}
