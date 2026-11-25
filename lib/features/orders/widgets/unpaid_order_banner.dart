import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_router.dart';
import '../../../app/app_scope.dart';
import '../../../data/orders/order_repository.dart';
import '../../../data/wib_dates.dart';
import '../../../design/design.dart';

/// Pengingat bayar untuk Beranda (SPEC §4.1 butir 6): baris `warningTint`
/// "Selesaikan pembayaran pesanan #BP-…" + "Bayar". Tidak tampil untuk tamu
/// atau bila tidak ada pesanan yang menunggu pembayaran.
class UnpaidOrderBanner extends StatelessWidget {
  const UnpaidOrderBanner({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(
      BpSpace.screen,
      BpSpace.x2,
      BpSpace.screen,
      BpSpace.x2,
    ),
  });

  final EdgeInsetsGeometry margin;

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
}
