import 'package:flutter/material.dart';
import 'package:kelopak_hub/kelopak_hub.dart' show shortDateLabel;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_router.dart';
import '../../../app/app_scope.dart';
import '../../../data/orders/order_repository.dart';
import '../../../data/wib_dates.dart';
import '../../../design/design.dart';
import '../../cart/widgets/line_parts.dart';
import '../order_actions.dart';
import '../order_format.dart';

/// Kartu pesanan di daftar Transaksi: "Belanja · tanggal" + nomor, chip
/// status, barang pertama + "+2 produk lain", hadiah yang ikut, baris status,
/// "Total n barang", dan aksi sesuai status.
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
    final gift = order.gifts.isEmpty ? null : order.gifts.first;
    final status = orderCardStatusLine(order);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        0,
        BpSpace.screen,
        BpSpace.x3,
      ),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BpRadius.cardAll,
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => services.router.go(context, OrderDetailRoute(order.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.x4,
              BpSpace.x3,
              BpSpace.x4,
              BpSpace.x3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: BrandIcon(
                        BrandGlyph.bag,
                        size: BpSize.iconDense,
                        color: c.brandStrong,
                      ),
                    ),
                    const SizedBox(width: BpSpace.x3),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        spacing: BpSpace.x2,
                        runSpacing: 4,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Belanja · ${orderDateLabel(order.placedAt)}',
                                style: BpText.subtitle.copyWith(color: c.text),
                              ),
                              Text(
                                '#${order.id}',
                                style: BpText.caption.copyWith(
                                  color: c.textMuted,
                                  fontFeatures: BpText.tabular,
                                ),
                              ),
                            ],
                          ),
                          StatusChip(
                            label: order.status.label,
                            tone: orderStatusTone(order.status),
                          ),
                        ],
                      ),
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
                            '${first.qty} barang x '
                            '${formatRupiah(first.unitPrice)}',
                            style: BpText.caption.copyWith(color: c.textMuted),
                          ),
                          if (others > 0)
                            Text(
                              '+$others produk lain',
                              style: BpText.caption.copyWith(
                                color: c.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (gift != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BpSpace.x3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BpSpace.x3,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.goldTint,
                        borderRadius: BpRadius.pillAll,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(LucideIcons.gift, size: 14, color: c.onGoldTint),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hadiah gratis ikut: ${gift.name}'
                              '${order.gifts.length > 1 ? ' +${order.gifts.length - 1}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BpText.caption.copyWith(
                                color: c.onGoldTint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (status != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BpSpace.x3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          status.icon,
                          size: 16,
                          color: _toneColor(c, status.tone),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            status.text,
                            style: BpText.caption.copyWith(
                              color: status.tone == StatusTone.warning
                                  ? c.warning
                                  : c.text,
                              fontWeight: status.tone == StatusTone.warning
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: BpSpace.x3),
                  child: Divider(height: 1, thickness: 1, color: c.line),
                ),
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
                            'Total ${order.itemCount} barang',
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
                    _Actions(order: order, busy: busy),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _toneColor(BpColors c, StatusTone tone) => switch (tone) {
    StatusTone.warning => c.warning,
    StatusTone.success => c.success,
    StatusTone.info => c.info,
    StatusTone.brand => c.brandStrong,
    _ => c.textMuted,
  };
}

/// "28 Nov 2026" (tanggal WIB).
String orderDateLabel(DateTime instant) {
  final day = wibDayOfInstant(instant);
  return '${shortDateLabel(day)} ${dateOfWibDay(day).year}';
}

/// Baris status di kartu pesanan.
final class OrderStatusLine {
  const OrderStatusLine(this.icon, this.text, this.tone);

  final IconData icon;
  final String text;
  final StatusTone tone;
}

/// Keterangan status di kartu: batas bayar, lunas/dikemas, dalam perjalanan,
/// diterima, atau dibatalkan.
OrderStatusLine? orderCardStatusLine(Order order) {
  switch (order.status) {
    case OrderStatus.awaitingPayment:
      final payBy = order.payBy;
      if (payBy == null) return null;
      final day = wibDayOfInstant(payBy);
      return OrderStatusLine(
        LucideIcons.clock,
        'Bayar sebelum ${shortDateLabel(day)}, ${wibClockLabel(payBy)} WIB',
        StatusTone.warning,
      );
    case OrderStatus.packing:
      final paid =
          order.paidNote ??
          (order.isCod
              ? 'Bayar di tempat'
              : 'Lunas · ${order.paymentMethodName ?? 'simulasi'}');
      return OrderStatusLine(
        LucideIcons.package,
        '$paid. Pesanan sedang dikemas.',
        StatusTone.info,
      );
    case OrderStatus.shipped:
      return OrderStatusLine(
        LucideIcons.truck,
        'Dalam perjalanan bersama ${order.courierName}',
        StatusTone.brand,
      );
    case OrderStatus.completed:
      final at = order.timeOf(OrderStatus.completed);
      return OrderStatusLine(
        LucideIcons.circleCheck,
        at == null ? 'Pesanan diterima' : 'Diterima ${orderDateLabel(at)}',
        StatusTone.success,
      );
    case OrderStatus.cancelled:
      return OrderStatusLine(
        LucideIcons.rotateCcw,
        order.paidAtMs != null && !order.isCod && order.total > 0
            ? 'Dibatalkan. Dana dikembalikan (simulasi).'
            : 'Dibatalkan.',
        StatusTone.neutral,
      );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.busy});

  final Order order;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    void open() => services.router.go(context, OrderDetailRoute(order.id));
    return switch (order.status) {
      OrderStatus.awaitingPayment => PillButton(
        label: 'Bayar sekarang',
        size: PillButtonSize.small,
        busy: busy,
        onPressed: () => services.router.go(context, PaymentRoute(order.id)),
      ),
      OrderStatus.packing => PillButton(
        label: 'Lihat detail',
        size: PillButtonSize.small,
        variant: PillButtonVariant.outline,
        onPressed: open,
      ),
      OrderStatus.shipped => Wrap(
        spacing: BpSpace.x2,
        runSpacing: BpSpace.x2,
        children: <Widget>[
          PillButton(
            label: 'Lacak',
            size: PillButtonSize.small,
            variant: PillButtonVariant.outline,
            onPressed: open,
          ),
          PillButton(
            label: 'Pesanan diterima',
            size: PillButtonSize.small,
            busy: busy,
            onPressed: () => completeOrder(context, order),
          ),
        ],
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
