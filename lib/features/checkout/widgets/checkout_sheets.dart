/// Lembar pilih voucher dan lembar pilih metode pembayaran.
library;

import 'package:flutter/material.dart';

import '../../../data/payment/payment_catalog.dart';
import '../../../data/rewards/rewards_gateway.dart';
import '../../../design/design.dart';
import 'payment_summary.dart';

/// Hasil lembar voucher: [voucherId] null = tanpa voucher.
final class VoucherChoice {
  const VoucherChoice(this.voucherId);

  final String? voucherId;
}

/// Lembar pilih voucher. Voucher yang belum memenuhi syarat tampil redup
/// beserta alasannya. Null bila lembar ditutup tanpa memilih.
Future<VoucherChoice?> showVoucherSheet(
  BuildContext context, {
  required List<VoucherOption> vouchers,
  required String? selectedId,
}) {
  return showBpSheet<VoucherChoice>(
    context: context,
    builder: (context) {
      final c = context.bp;
      final usable = vouchers.where((v) => v.usable).toList();
      final locked = vouchers.where((v) => !v.usable).toList();
      return BpSheet(
        title: 'Pilih voucher',
        footer: PillButton(
          label: 'Tanpa voucher',
          variant: PillButtonVariant.neutral,
          expand: true,
          onPressed: () => Navigator.of(context).pop(const VoucherChoice(null)),
        ),
        child: vouchers.isEmpty
            ? const EmptyState(
                compact: true,
                imageAsset: 'assets/icons3d/voucher.webp',
                imageSize: 88,
                title: 'Belum ada voucher',
                message:
                    'Selesaikan Misi Belanja atau klaim voucher di Event Promo.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final voucher in <VoucherOption>[...usable, ...locked])
                    Padding(
                      padding: const EdgeInsets.only(bottom: BpSpace.x2),
                      child: VoucherTicket(
                        valueLabel: formatRupiah(voucher.amount),
                        title: voucher.title,
                        condition:
                            'Min. belanja ${formatRupiah(voucher.minSpend)}',
                        expiry: voucher.expiresLabel,
                        muted: !voucher.usable,
                        reason: voucher.reason,
                        selected: voucher.id == selectedId,
                        actionLabel: voucher.usable
                            ? (voucher.id == selectedId ? 'Dipakai' : 'Pakai')
                            : null,
                        onAction: voucher.usable
                            ? () => Navigator.of(
                                context,
                              ).pop(VoucherChoice(voucher.id))
                            : null,
                      ),
                    ),
                  Text(
                    'Satu voucher per pesanan. Syarat minimum dihitung dari '
                    'subtotal produk sebelum potongan Kelopak.',
                    style: BpText.caption.copyWith(color: c.textMuted),
                  ),
                ],
              ),
      );
    },
  );
}

/// Lembar pilih metode pembayaran (semua simulasi), dikelompokkan per jenis.
Future<String?> showPaymentMethodSheet(
  BuildContext context, {
  required String selectedId,
}) {
  return showBpSheet<String>(
    context: context,
    builder: (context) {
      final c = context.bp;
      return BpSheet(
        title: 'Metode pembayaran',
        padding: const EdgeInsets.only(bottom: BpSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BpSpace.screen,
                0,
                BpSpace.screen,
                BpSpace.x2,
              ),
              child: Text(
                PaymentCatalog.demoNote,
                style: BpText.caption.copyWith(color: c.textMuted),
              ),
            ),
            for (final entry in PaymentCatalog.grouped.entries) ...<Widget>[
              if (entry.value.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BpSpace.screen,
                    BpSpace.x3,
                    BpSpace.screen,
                    BpSpace.x1,
                  ),
                  child: Text(
                    entry.key.title,
                    style: BpText.label.copyWith(color: c.textMuted),
                  ),
                ),
              for (final method in entry.value)
                ChoiceTile(
                  title: method.name,
                  selected: method.id == selectedId,
                  leading: PaymentMethodBadge(kind: method.kind),
                  onTap: () => Navigator.of(context).pop(method.id),
                ),
            ],
          ],
        ),
      );
    },
  );
}

/// Lencana jenis pembayaran: kotak kecil berisi singkatan.
class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({super.key, required this.kind});

  final PaymentKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final text = switch (kind) {
      PaymentKind.qris => 'QRIS',
      PaymentKind.virtualAccount => 'VA',
      PaymentKind.retail => 'Gerai',
      PaymentKind.ewallet => 'Dompet',
      PaymentKind.cod => 'COD',
    };
    return Container(
      width: 52,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BpRadius.badgeAll,
        border: Border.all(color: c.line),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            text,
            style: BpText.label.copyWith(
              color: c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
