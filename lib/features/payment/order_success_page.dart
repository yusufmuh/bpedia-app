import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show ConfettiBurst, ConfettiController;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../data/orders/order_repository.dart';
import '../../design/design.dart';
import '../cart/widgets/line_parts.dart';
import '../cart/widgets/recommendations.dart';
import '../orders/order_format.dart';

/// `/pesanan/:id/sukses`: centang beranimasi, konfeti ringan, ringkasan
/// (Kelopak dipakai, hadiah ikut dikirim, catatan misi), "Lihat pesanan" dan
/// "Belanja lagi".
class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with SingleTickerProviderStateMixin {
  final ConfettiController _confetti = ConfettiController();
  late final AnimationController _check = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (BpMotion.reduced(context)) {
        _check.value = 1;
      } else {
        _check.forward();
      }
      _confetti.fire(origin: const Alignment(0, -0.75), power: 0.7, count: 60);
    });
  }

  @override
  void dispose() {
    _check.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final order = services.orders.byId(widget.orderId);
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: BpAppBar(
        title: 'Pesanan berhasil',
        leading: IconButton(
          tooltip: 'Tutup',
          icon: const Icon(LucideIcons.x),
          onPressed: () => services.router.goHome(context),
        ),
      ),
      body: order == null
          ? Center(
              child: EmptyState(
                illustration: const FloatingBipy(pose: 'pose_semangat'),
                title: 'Pesanan tidak ditemukan',
                message: 'Cek daftar transaksimu, Babes.',
                actionLabel: 'Lihat transaksi',
                onAction: () =>
                    services.router.go(context, const OrdersRoute()),
              ),
            )
          : ConfettiBurst(
              controller: _confetti,
              particleCount: 60,
              child: ListView(
                children: <Widget>[
                  _Hero(order: order, check: _check),
                  _Summary(order: order, services: services),
                  Section(
                    inset: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        PillButton(
                          label: 'Lihat pesanan',
                          expand: true,
                          onPressed: () => services.router.replace(
                            context,
                            OrderDetailRoute(order.id),
                          ),
                        ),
                        const SizedBox(height: BpSpace.x2),
                        PillButton(
                          label: 'Belanja lagi',
                          variant: PillButtonVariant.outline,
                          expand: true,
                          onPressed: () => services.router.goHome(context),
                        ),
                      ],
                    ),
                  ),
                  RecommendationSection(
                    title: 'Belanja lagi, yuk',
                    exclude: <String>[
                      for (final item in order.items) item.productCode,
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.order, required this.check});

  final Order order;
  final Animation<double> check;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final paid = order.paidNote == null && !order.isCod;
    final title = paid ? 'Pembayaran berhasil' : 'Pesanan berhasil dibuat';
    final message = order.paidNote != null
        ? 'Lunas dengan Kelopak. Pesananmu sedang dikemas, Babes.'
        : order.isCod
        ? 'Siapkan ${formatRupiah(order.total)} saat kurir tiba. Pesananmu sedang dikemas.'
        : 'Terima kasih, Babes. Pesananmu sedang dikemas.';
    return Section(
      inset: true,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.brandTint,
                  ),
                ),
                const FloatingBipy(
                  pose: 'pose_lompat_bintang',
                  height: 150,
                  semanticLabel: 'Bipy melompat gembira',
                ),
                Positioned(
                  bottom: 6,
                  child: Transform.translate(
                    offset: const Offset(58, 0),
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: check,
                        curve: Curves.elasticOut,
                      ),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 4),
                        ),
                        child: Icon(
                          LucideIcons.check,
                          color: c.surface,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BpSpace.x3),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: BpText.titleL.copyWith(color: c.text),
            ),
          ),
          const SizedBox(height: BpSpace.x1),
          Text(
            message,
            textAlign: TextAlign.center,
            style: BpText.body.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.order, required this.services});

  final Order order;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final rewards = services.rewards.available;
    return Section(
      header: const SectionHeader(title: 'Ringkasan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InfoRow(label: 'Nomor pesanan', value: order.id),
          InfoRow(
            label: order.isCod ? 'Bayar di tempat' : 'Total dibayar',
            value: formatRupiah(order.total),
          ),
          if (order.kelopakUsed > 0)
            InfoRow(
              label: 'Kelopak dipakai',
              value:
                  '${kelopakAmountLabel(order.kelopakUsed)} (-${formatRupiah(order.kelopakValue)})',
              valueColor: c.success,
            ),
          if (order.voucherAmount > 0)
            InfoRow(
              label: 'Voucher',
              value: '-${formatRupiah(order.voucherAmount)}',
              valueColor: c.success,
            ),
          if (order.gifts.isNotEmpty)
            _Highlight(
              icon3d: 'hadiah',
              text:
                  '${order.gifts.length} hadiah gratis ikut dikirim bersama pesanan ini.',
              background: c.goldTint,
              foreground: c.onGoldTint,
            ),
          if (rewards)
            _Highlight(
              icon3d: 'misi',
              text:
                  'Misi Belanja dihitung saat pesanan selesai. Tekan "Pesanan diterima" setelah paket tiba.',
              background: c.surfaceMuted,
              foreground: c.text,
            ),
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon3d,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String icon3d;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        BpSpace.x2,
        BpSpace.screen,
        0,
      ),
      padding: const EdgeInsets.all(BpSpace.x3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BpRadius.cardAll,
      ),
      child: Row(
        children: <Widget>[
          AssetPicture(
            'assets/icons3d/$icon3d.webp',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            showSkeleton: false,
          ),
          const SizedBox(width: BpSpace.x3),
          Expanded(
            child: Text(text, style: BpText.bodyS.copyWith(color: foreground)),
          ),
        ],
      ),
    );
  }
}
