/// Tampilan Hot Item [K8]: kartu gambar highlight asli, hitung mundur ke akhir
/// periode promo (data katalog), dan bilah kuota dari potret katalog.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../design/design.dart';
import '../catalog/shop_common.dart';

/// Keadaan periode Hot Item terhadap hari WIB ini.
enum HotPhase { upcoming, running, ended }

/// Fase [deal] pada hari WIB [today].
HotPhase hotPhaseOf(HotDeal deal, int today) {
  if (today < deal.startDay) return HotPhase.upcoming;
  if (today > deal.endDay) return HotPhase.ended;
  return HotPhase.running;
}

/// "12 Nov sampai 29 Nov" atau "25 Nov" bila satu hari.
String hotPeriodLabel(HotDeal deal) => deal.startDay == deal.endDay
    ? wibShortDate(deal.startDay)
    : '${wibShortDate(deal.startDay)} sampai ${wibShortDate(deal.endDay)}';

/// Hot Item yang periodenya paling cepat berakhir di antara yang berjalan.
HotDeal? soonestRunning(Iterable<Product> products, int today) {
  HotDeal? best;
  for (final product in products) {
    final deal = product.hot;
    if (deal == null || hotPhaseOf(deal, today) != HotPhase.running) continue;
    if (best == null || deal.endDay < best.endDay) best = deal;
  }
  return best;
}

/// Pil hitung mundur ke 24.00 WIB hari terakhir [deal]. Di luar periode
/// menampilkan tanggal mulai atau periode, bukan hitung mundur.
class HotCountdown extends StatefulWidget {
  const HotCountdown({required this.deal, this.dense = false, super.key});

  final HotDeal deal;

  /// Versi kecil untuk kartu.
  final bool dense;

  @override
  State<HotCountdown> createState() => _HotCountdownState();
}

class _HotCountdownState extends State<HotCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final deal = widget.deal;
    final phase = hotPhaseOf(deal, services.clock.today);
    final String text;
    final String semantics;
    switch (phase) {
      case HotPhase.running:
        final left = wibEndOfDay(
          deal.endDay,
        ).difference(services.clock.instant.toUtc());
        text = left.inHours >= 24
            ? 'Berakhir ${left.inDays} hari lagi'
            : countdownText(left);
        semantics =
            'Berakhir dalam ${left.inHours} jam ${left.inMinutes % 60} menit';
      case HotPhase.upcoming:
        text = 'Mulai ${wibShortDate(deal.startDay)}';
        semantics = text;
      case HotPhase.ended:
        text = hotPeriodLabel(deal);
        semantics = 'Periode $text';
    }
    final running = phase == HotPhase.running;
    final dense = widget.dense;
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : BpSpace.x2,
          vertical: dense ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: running ? c.sale : c.surfaceMuted,
          borderRadius: BpRadius.badgeAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              running ? LucideIcons.timer : LucideIcons.calendar,
              size: dense ? 12 : 14,
              color: running ? c.onSale : c.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (dense ? BpText.label : BpText.caption).copyWith(
                  color: running ? c.onSale : c.textMuted,
                  fontWeight: FontWeight.w700,
                  fontFeatures: BpText.tabular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilah kuota Hot Item: isi = bagian terjual dari kuota potret katalog.
class HotQuotaBar extends StatelessWidget {
  const HotQuotaBar({required this.deal, super.key});

  final HotDeal deal;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final quota = deal.quota;
    final sold = deal.sold.clamp(0, quota);
    final fraction = quota == 0 ? 1.0 : sold / quota;
    final left = quota - sold;
    final label = left <= 0
        ? 'Kuota habis'
        : sold == 0
        ? 'Kuota $quota'
        : 'Terjual $sold, sisa $left';
    return Semantics(
      label: '$label dari kuota $quota',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: BpRadius.pillAll,
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: c.dangerTint),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction == 0 ? 0.04 : fraction,
                    child: ColoredBox(color: c.sale),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BpText.label.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Kartu Hot Item: gambar highlight asli 1:1, lencana diskon, nama, harga
/// Hot Item, harga normal, hitung mundur, bilah kuota.
class HotItemCard extends StatelessWidget {
  const HotItemCard({
    required this.product,
    this.showAddButton = false,
    super.key,
  });

  final Product product;

  /// Tombol "+ Keranjang" di bawah kartu (halaman Hot Item).
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final deal = product.hot!;
    return Semantics(
      container: true,
      child: BpTappable(
        onTap: () => services.router.go(context, ProductRoute(product.code)),
        semanticLabel:
            'Hot Item ${product.name}, ${formatRupiah(deal.price)}, '
            'harga normal ${formatRupiah(deal.normalPrice)}, '
            'diskon ${deal.discountPercent} persen',
        minWidth: 0,
        minHeight: 0,
        focusRadius: BpRadius.cardAll,
        builder: (context, states) => DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BpRadius.cardAll,
            border: Border.all(color: c.line),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(BpRadius.card - 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      AssetPicture(deal.image),
                      if (deal.discountPercent > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: DiscountBadge(
                            percent: deal.discountPercent,
                            corner: true,
                          ),
                        ),
                      Positioned(
                        left: 6,
                        bottom: 6,
                        right: 6,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: HotCountdown(deal: deal, dense: true),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BpSpace.cardDense,
                    BpSpace.cardDense,
                    BpSpace.cardDense,
                    BpSpace.cardDense,
                  ),
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
                      PriceText(
                        deal.price,
                        strikePrice: deal.normalPrice,
                        stacked: true,
                      ),
                      const SizedBox(height: 6),
                      HotQuotaBar(deal: deal),
                      if (showAddButton) ...<Widget>[
                        const SizedBox(height: BpSpace.x2),
                        PillButton(
                          label: product.inStock ? '+ Keranjang' : 'Stok habis',
                          variant: PillButtonVariant.outline,
                          size: PillButtonSize.small,
                          expand: true,
                          onPressed: product.inStock
                              ? () => addProductToCart(context, product)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seni judul "HOT ITEM": ikon api 3D + huruf tebal miring.
class HotItemTitle extends StatelessWidget {
  const HotItemTitle({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AssetPicture(
          'assets/icons3d/hot.webp',
          width: size + 10,
          height: size + 10,
          fit: BoxFit.contain,
          showSkeleton: false,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'HOT ITEM',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: BpText.family,
              fontSize: size,
              height: 1.1,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
              color: c.sale,
            ),
          ),
        ),
      ],
    );
  }
}
