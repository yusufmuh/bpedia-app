import 'package:flutter/material.dart';
import 'package:kelopak_hub/kelopak_hub.dart' show shortDateLabel;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_router.dart';
import '../../../app/app_scope.dart';
import '../../../data/orders/order_repository.dart';
import '../../../data/wib_dates.dart';
import '../../../design/design.dart';

/// Pengingat bayar (SPEC §4.1 butir 6), baris `warningTint`. Tidak tampil
/// untuk tamu atau bila tidak ada pesanan yang menunggu pembayaran.
///
/// Bawaan (Beranda): "Selesaikan pembayaran pesanan #BP-…" + "Bayar".
/// [UnpaidOrderBanner.summary] (daftar Transaksi): "n pesanan menunggu
/// pembayaran · #BP-… · batas …" + chevron; ketuk membuka pembayaran pesanan
/// dengan batas paling dekat.
class UnpaidOrderBanner extends StatelessWidget {
  const UnpaidOrderBanner({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(
      BpSpace.screen,
      BpSpace.x2,
      BpSpace.screen,
      BpSpace.x2,
    ),
  }) : summary = false;

  /// Versi ringkas untuk kepala daftar Transaksi.
  const UnpaidOrderBanner.summary({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(
      BpSpace.screen,
      0,
      BpSpace.screen,
      BpSpace.x3,
    ),
  }) : summary = true;

  final EdgeInsetsGeometry margin;
  final bool summary;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.orders,
        services.auth,
      ]),
      builder: (context, _) {
        final unpaid = services.auth.isLoggedIn
            ? services.orders.unpaid
            : const <Order>[];
        if (unpaid.isEmpty) return const SizedBox.shrink();
        if (summary) return _summary(context, unpaid);
        final order = services.orders.unpaid.first;
        final c = context.bp;
        final payBy = order.payBy;
        final more = unpaid.length - 1;
        return Padding(
          padding: margin,
          child: Semantics(
            container: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                BpSpace.x3,
                BpSpace.x2,
                BpSpace.x2,
                BpSpace.x2,
              ),
              decoration: BoxDecoration(
                color: c.warningTint,
                borderRadius: BpRadius.cardAll,
              ),
              child: Row(
                children: <Widget>[
                  Icon(LucideIcons.clock, color: c.warning, size: 22),
                  const SizedBox(width: BpSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Selesaikan pembayaran pesanan #${order.id}',
                          style: BpText.bodyS.copyWith(
                            color: c.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          <String>[
                            formatRupiah(order.total),
                            if (payBy != null)
                              'sebelum ${wibDateTimeLabel(payBy)}',
                            if (more > 0) '+$more pesanan lain',
                          ].join(' · '),
                          style: BpText.caption.copyWith(color: c.warning),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BpSpace.x2),
                  PillButton(
                    label: 'Bayar',
                    size: PillButtonSize.small,
                    onPressed: () =>
                        services.router.go(context, PaymentRoute(order.id)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summary(BuildContext context, List<Order> unpaid) {
    final services = AppScope.of(context);
    final c = context.bp;
    var urgent = unpaid.first;
    for (final order in unpaid) {
      final by = order.payByMs ?? order.placedAtMs;
      if (by < (urgent.payByMs ?? urgent.placedAtMs)) urgent = order;
    }
    final payBy = urgent.payBy;
    final detail = <String>[
      '#${urgent.id}',
      if (payBy != null)
        'batas ${shortDateLabel(wibDayOfInstant(payBy))}, '
            '${wibClockLabel(payBy)} WIB',
    ].join(' · ');
    final title = '${unpaid.length} pesanan menunggu pembayaran';
    return Padding(
      padding: margin,
      child: BpTappable(
        key: const ValueKey<String>('transaksi-menunggu-bayar'),
        onTap: () => services.router.go(context, PaymentRoute(urgent.id)),
        pressScale: false,
        alignment: Alignment.centerLeft,
        focusRadius: BpRadius.cardAll,
        semanticLabel: '$title. $detail. Bayar',
        builder: (context, states) => Container(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.x3,
            BpSpace.x2,
            BpSpace.x2,
            BpSpace.x2,
          ),
          decoration: BoxDecoration(
            color: c.warningTint,
            borderRadius: BpRadius.cardAll,
          ),
          child: Row(
            children: <Widget>[
              Icon(LucideIcons.clock, color: c.warning, size: 22),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: BpText.subtitle.copyWith(color: c.text)),
                    Text(
                      detail,
                      style: BpText.caption.copyWith(
                        color: c.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 20, color: c.warning),
            ],
          ),
        ),
      ),
    );
  }
}
