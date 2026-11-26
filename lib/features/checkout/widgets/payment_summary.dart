/// Rincian harga (checkout dan detail pesanan) dan baris pilihan bergaya
/// radio yang dipakai lembar kurir dan metode bayar.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/shipping/shipping_repository.dart';
import '../../../design/design.dart';
import '../../orders/order_format.dart';

/// Rupiah yang berhitung naik/turun saat nilainya berubah.
class AnimatedRupiah extends StatelessWidget {
  const AnimatedRupiah(
    this.value, {
    super.key,
    this.style,
    this.negative = false,
    this.textAlign,
  });

  final int value;
  final TextStyle? style;

  /// Tampil dengan tanda minus (potongan).
  final bool negative;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final reduced = BpMotion.reduced(context);
    String label(int amount) => negative && amount > 0
        ? '-${formatRupiah(amount)}'
        : formatRupiah(amount);
    return Semantics(
      label: label(value),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value.toDouble()),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 450),
        curve: BpMotion.standardCurve,
        builder: (context, shown, _) => Text(
          label(shown.round()),
          textAlign: textAlign,
          maxLines: 1,
          style: (style ?? BpText.body).copyWith(fontFeatures: BpText.tabular),
        ),
      ),
    );
  }
}

/// Rincian: subtotal → voucher → Kelopak → ongkir → hadiah Rp0 → total
/// (KEPUTUSAN §1, K17), lalu pita hemat bila ada potongan.
class PaymentSummary extends StatelessWidget {
  const PaymentSummary({
    super.key,
    required this.goodsSubtotal,
    required this.itemCount,
    required this.shippingFee,
    required this.voucherAmount,
    required this.kelopakUsed,
    required this.kelopakValue,
    required this.total,
    this.voucherTitle,
    this.giftCount = 0,
    this.totalLabel = 'Total pembayaran',
    this.showSavingsNote = true,
  });

  final int goodsSubtotal;
  final int itemCount;
  final int shippingFee;
  final int voucherAmount;
  final String? voucherTitle;
  final int kelopakUsed;
  final int kelopakValue;
  final int total;

  /// Jumlah hadiah gratis yang ikut pesanan; tampil sebagai baris Rp0.
  final int giftCount;
  final String totalLabel;

  /// Pita hijau "Kamu hemat RpX" di bawah total bila ada potongan.
  final bool showSavingsNote;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final reduced = BpMotion.reduced(context);
    final positive = BpText.body.copyWith(
      color: c.text,
      fontWeight: FontWeight.w500,
    );
    final saving = BpText.body.copyWith(
      color: c.success,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Line(
          label: 'Subtotal produk ($itemCount barang)',
          value: AnimatedRupiah(goodsSubtotal, style: positive),
        ),
        if (voucherAmount > 0)
          _Line(
            label: voucherTitle == null ? 'Voucher' : 'Voucher · $voucherTitle',
            value: AnimatedRupiah(voucherAmount, style: saving, negative: true),
          ),
        AnimatedSize(
          duration: reduced ? Duration.zero : BpMotion.standard,
          curve: BpMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: kelopakUsed > 0
              ? _Line(
                  label: 'Kelopak dipakai · ${kelopakAmountLabel(kelopakUsed)}',
                  value: AnimatedRupiah(
                    kelopakValue,
                    style: saving,
                    negative: true,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        _Line(
          label: 'Ongkos kirim ${ShippingRepository.demoTag}',
          value: shippingFee == 0
              ? Text('Gratis', style: saving)
              : AnimatedRupiah(shippingFee, style: positive),
        ),
        if (giftCount > 0)
          _Line(
            label: 'Hadiah gratis ($giftCount barang)',
            value: Text('Rp0', style: positive),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BpSpace.screen,
            vertical: BpSpace.x2,
          ),
          child: Divider(height: 1, thickness: 1, color: c.line),
        ),
        _Line(
          label: totalLabel,
          emphasized: true,
          value: AnimatedRupiah(
            total,
            style: BpText.title.copyWith(color: c.brandStrong),
          ),
        ),
        if (showSavingsNote && voucherAmount + kelopakValue > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x2,
              BpSpace.screen,
              0,
            ),
            child: SavingsNote(
              text:
                  'Kamu hemat ${formatRupiah(voucherAmount + kelopakValue)}.'
                  '${kelopakUsed > 0 ? ' Kelopak hanya memotong harga barang, bukan ongkir.' : ''}',
            ),
          ),
      ],
    );
  }
}

/// Pita hijau berikon centang untuk catatan penghematan.
class SavingsNote extends StatelessWidget {
  const SavingsNote({super.key, required this.text, this.leading});

  final String text;

  /// Ikon pengganti centang (mis. Kelopak 3D).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BpSpace.x3,
        vertical: BpSpace.x2,
      ),
      decoration: BoxDecoration(
        color: c.successTint,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: <Widget>[
          leading ?? Icon(LucideIcons.circleCheck, size: 18, color: c.success),
          const SizedBox(width: BpSpace.x2),
          Expanded(
            child: Text(
              text,
              style: BpText.bodyS.copyWith(
                color: c.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final Widget value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.screen,
          vertical: 5,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: BpSpace.x3,
          children: <Widget>[
            Text(
              label,
              style: emphasized
                  ? BpText.subtitle.copyWith(color: c.text)
                  : BpText.body.copyWith(color: c.textMuted),
            ),
            value,
          ],
        ),
      ),
    );
  }
}

/// Baris pilihan tunggal (kurir, metode bayar) dengan lingkaran radio.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Nilai di kanan, mis. ongkir.
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final sub = subtitle;
    final end = trailing;
    final lead = leading;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: BpTappable(
        onTap: onTap,
        selected: selected,
        alignment: Alignment.centerLeft,
        pressScale: false,
        focusRadius: BpRadius.cardAll,
        builder: (context, states) => AnimatedContainer(
          duration: BpMotion.micro,
          margin: const EdgeInsets.symmetric(
            horizontal: BpSpace.screen,
            vertical: BpSpace.x1,
          ),
          padding: const EdgeInsets.all(BpSpace.x3),
          decoration: BoxDecoration(
            color: selected ? c.brandTint : c.surface,
            borderRadius: BpRadius.cardAll,
            border: Border.all(
              color: selected ? c.brand : c.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              RadioDot(selected: selected),
              const SizedBox(width: BpSpace.x3),
              if (lead != null) ...<Widget>[
                lead,
                const SizedBox(width: BpSpace.x3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: BpText.subtitle.copyWith(color: c.text)),
                    if (sub != null)
                      Text(
                        sub,
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                  ],
                ),
              ),
              if (end != null) ...<Widget>[
                const SizedBox(width: BpSpace.x2),
                end,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lingkaran radio 20 dp.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return AnimatedContainer(
      duration: BpMotion.micro,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? c.brand : c.textFaint,
          width: selected ? 6 : 2,
        ),
      ),
    );
  }
}
