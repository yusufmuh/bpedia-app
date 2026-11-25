import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../data/orders/order_repository.dart';
import '../../data/shipping/shipping_repository.dart';
import '../../design/design.dart';
import '../cart/widgets/line_parts.dart';
import '../checkout/widgets/payment_summary.dart';
import 'order_actions.dart';
import 'order_format.dart';
import 'widgets/order_timeline.dart';

/// `/pesanan/:id`: kepala status, garis waktu, alamat, kurir, barang,
/// hadiah gratis, rincian bayar (voucher dan Kelopak), kontrol simulasi
/// (DEMO), dan batal dengan konfirmasi pengembalian.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.orders,
      builder: (context, _) {
        final c = context.bp;
        final order = services.orders.byId(orderId);
        return Scaffold(
          backgroundColor: c.canvas,
          appBar: const BpAppBar(title: 'Detail pesanan'),
          body: order == null
              ? Center(
                  child: SingleChildScrollView(
                    child: EmptyState(
                      illustration: const FloatingBipy(pose: 'pose_semangat'),
                      title: 'Pesanan tidak ditemukan',
                      message: 'Nomor pesanan $orderId tidak ada di akun ini.',
                      actionLabel: 'Lihat transaksi',
                      onAction: () =>
                          services.router.go(context, const OrdersRoute()),
                    ),
                  ),
                )
              : _DetailBody(order: order, services: services),
          bottomNavigationBar: order == null
              ? null
              : _DetailBar(
                  order: order,
                  busy: services.orders.isBusy(order.id),
                ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.order, required this.services});

  final Order order;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final left = remainingPayLabel(order, services.clock.instant);
    final mission = order.missionMessage;
    return ListView(
      padding: const EdgeInsets.only(top: BpSpace.sectionGap),
      children: <Widget>[
        Section(
          inset: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  StatusChip(
                    label: order.status.label,
                    tone: orderStatusTone(order.status),
                  ),
                  if (left != null) ...<Widget>[
                    const SizedBox(width: BpSpace.x2),
                    Flexible(
                      child: Text(
                        left,
                        style: BpText.caption.copyWith(
                          color: c.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: BpSpace.x2),
              Text(
                orderStatusDescription(order),
                style: BpText.body.copyWith(color: c.text),
              ),
              const SizedBox(height: BpSpace.x2),
              Text(
                'No. pesanan ${order.id}',
                style: BpText.caption.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ),
        if (mission != null && mission.isNotEmpty)
          Section(
            inset: true,
            child: Container(
              padding: const EdgeInsets.all(BpSpace.x3),
              decoration: BoxDecoration(
                color: c.goldTint,
                borderRadius: BpRadius.cardAll,
              ),
              child: Row(
                children: <Widget>[
                  const AssetPicture(
                    'assets/icons3d/misi.webp',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    showSkeleton: false,
                  ),
                  const SizedBox(width: BpSpace.x3),
                  Expanded(
                    child: Text(
                      mission,
                      style: BpText.bodyS.copyWith(color: c.onGoldTint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Section(
          header: const SectionHeader(title: 'Status pesanan'),
          inset: true,
          child: OrderTimeline(steps: timelineOf(order)),
        ),
        if (order.status.isActive) _DemoControls(order: order),
        Section(
          header: const SectionHeader(title: 'Alamat pengiriman'),
          inset: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(LucideIcons.mapPin, size: 20, color: c.brandStrong),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${order.address.recipient} · ${order.address.phone}',
                      style: BpText.subtitle.copyWith(color: c.text),
                    ),
                    Text(
                      order.address.fullAddress,
                      style: BpText.bodyS.copyWith(color: c.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Section(
          padding: const EdgeInsets.symmetric(vertical: BpSpace.x1),
          child: InfoRow(
            label: 'Pengiriman',
            leading: const BrandIcon(
              BrandGlyph.ongkir,
              style: BrandIconStyle.color,
            ),
            value: order.courierName,
            helper: '${order.courierEta} ${ShippingRepository.demoTag}',
          ),
        ),
        Section(
          header: SectionHeader(title: 'Produk (${order.itemCount})'),
          child: Column(
            children: <Widget>[
              for (final item in order.items)
                InkWell(
                  onTap: () => services.router.go(
                    context,
                    ProductRoute(item.productCode),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BpSpace.screen,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        LineThumb(asset: item.image, size: 56),
                        const SizedBox(width: BpSpace.x3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: BpText.bodyS.copyWith(color: c.text),
                              ),
                              Text(
                                '${item.qty} x ${formatRupiah(item.unitPrice)}',
                                style: BpText.caption.copyWith(
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: BpSpace.x2),
                        Text(
                          formatRupiah(item.lineTotal),
                          style: BpText.subtitle.copyWith(
                            color: c.text,
                            fontFeatures: BpText.tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (order.gifts.isNotEmpty)
          Section(
            padding: const EdgeInsets.only(bottom: BpSpace.x1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GiftSectionHeader(
                  count: order.gifts.length,
                  subtitle: _giftSubtitle(order.status),
                ),
                for (final gift in order.gifts)
                  GiftTile(
                    name: gift.name,
                    sourceLabel: gift.sourceLabel,
                    imageAsset: gift.image,
                    thumbSize: 56,
                    normalPrice: services.catalog
                        .byCode(gift.productCode)
                        ?.price,
                    status: StatusChip(
                      label: _giftStatus(order.status),
                      tone: order.status == OrderStatus.cancelled
                          ? StatusTone.neutral
                          : StatusTone.success,
                    ),
                  ),
              ],
            ),
          ),
        Section(
          header: const SectionHeader(title: 'Rincian pembayaran'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InfoRow(
                label: 'Metode pembayaran',
                value:
                    order.paymentMethodName ??
                    order.paidNote ??
                    'Lunas dengan Kelopak',
              ),
              PaymentSummary(
                goodsSubtotal: order.goodsSubtotal,
                itemCount: order.itemCount,
                shippingFee: order.shippingFee,
                voucherAmount: order.voucherAmount,
                voucherTitle: order.voucherTitle,
                kelopakUsed: order.kelopakUsed,
                kelopakValue: order.kelopakValue,
                total: order.total,
                totalLabel: order.isCod
                    ? 'Bayar di tempat'
                    : 'Total pembayaran',
              ),
            ],
          ),
        ),
        const SizedBox(height: BpSpace.x6),
      ],
    );
  }

  static String _giftSubtitle(OrderStatus status) => switch (status) {
    OrderStatus.cancelled =>
      'Pesanan batal: hadiah kembali menunggu pesanan berikutnya',
    OrderStatus.completed => 'Hadiah sudah diterima bersama pesanan ini',
    _ => 'Ikut dikirim, tanpa ongkir tambahan',
  };

  static String _giftStatus(OrderStatus status) => switch (status) {
    OrderStatus.awaitingPayment || OrderStatus.packing => 'Ikut pesanan',
    OrderStatus.shipped => 'Dikirim',
    OrderStatus.completed => 'Diterima',
    OrderStatus.cancelled => 'Kembali ke Hadiahku',
  };
}

class _DemoControls extends StatelessWidget {
  const _DemoControls({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final (label, help, action) = switch (order.status) {
      OrderStatus.awaitingPayment => (
        'Simulasikan pembayaran',
        'Tandai pesanan sudah dibayar tanpa uang sungguhan.',
        () => simulatePayment(context, order),
      ),
      OrderStatus.packing => (
        'Kirim pesanan',
        'Tandai paket sudah diserahkan ke kurir.',
        () => simulateShipping(context, order),
      ),
      _ => (
        'Pesanan diterima',
        'Tandai paket sudah tiba. Misi Belanja dievaluasi setelah ini.',
        () => completeOrder(context, order),
      ),
    };
    return Section(
      inset: true,
      child: Container(
        padding: const EdgeInsets.all(BpSpace.x3),
        decoration: BoxDecoration(
          color: c.infoTint,
          borderRadius: BpRadius.cardAll,
          border: Border.all(color: c.info.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(LucideIcons.flaskConical, size: 18, color: c.info),
                const SizedBox(width: BpSpace.x2),
                Expanded(
                  child: Text(
                    'Kontrol simulasi (DEMO)',
                    style: BpText.subtitle.copyWith(color: c.info),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BpSpace.x1),
            Text(help, style: BpText.caption.copyWith(color: c.text)),
            const SizedBox(height: BpSpace.x2),
            PillButton(
              label: label,
              size: PillButtonSize.small,
              variant: PillButtonVariant.neutral,
              busy: AppScope.of(context).orders.isBusy(order.id),
              onPressed: action,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBar extends StatelessWidget {
  const _DetailBar({required this.order, required this.busy});

  final Order order;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final Widget? primary = switch (order.status) {
      OrderStatus.awaitingPayment => PillButton(
        label: 'Bayar sekarang',
        expand: true,
        onPressed: () => services.router.go(context, PaymentRoute(order.id)),
      ),
      OrderStatus.packing => null,
      OrderStatus.shipped => PillButton(
        label: 'Pesanan diterima',
        expand: true,
        busy: busy,
        onPressed: () => completeOrder(context, order),
      ),
      OrderStatus.completed || OrderStatus.cancelled => PillButton(
        label: 'Beli lagi',
        expand: true,
        onPressed: () => buyAgain(context, order),
      ),
    };
    final cancel = order.status.canCancel
        ? PillButton(
            label: 'Batalkan pesanan',
            variant: PillButtonVariant.neutral,
            expand: true,
            busy: busy && primary == null,
            onPressed: () => confirmCancelOrder(context, order),
          )
        : null;
    return StickyBottomBar(
      child: Row(
        children: <Widget>[
          if (cancel != null) Expanded(child: cancel),
          if (cancel != null && primary != null)
            const SizedBox(width: BpSpace.x3),
          if (primary != null) Expanded(child: primary),
        ],
      ),
    );
  }
}
