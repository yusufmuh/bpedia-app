/// Strip dan kartu dorongan di keranjang: alamat kirim, Misi Belanja, ambang
/// gratis ongkir, dan ringkasan hemat voucher + Kelopak di bilah bawah.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/rewards/rewards_gateway.dart';
import '../../../data/shipping/shipping_repository.dart';
import '../../../design/design.dart';
import '../../orders/order_format.dart';

/// Pil "Kirim ke" di atas keranjang.
class ShipToBar extends StatelessWidget {
  const ShipToBar({super.key, required this.label, required this.onTap});

  /// Mis. "Rumah · Sinta Dewi", atau null bila belum ada alamat.
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final text = label;
    return ColoredBox(
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BpSpace.screen,
          BpSpace.x2,
          BpSpace.screen,
          BpSpace.x2,
        ),
        child: BpTappable(
          onTap: onTap,
          alignment: Alignment.centerLeft,
          pressScale: false,
          semanticLabel: text == null
              ? 'Tambah alamat pengiriman'
              : 'Kirim ke $text. Ubah alamat',
          builder: (context, states) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BpSpace.x3,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BpRadius.pillAll,
            ),
            child: Row(
              children: <Widget>[
                Icon(LucideIcons.mapPin, size: 18, color: c.brandStrong),
                const SizedBox(width: BpSpace.x2),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: text == null
                              ? 'Belum ada alamat. '
                              : 'Kirim ke ',
                          style: TextStyle(color: c.textMuted),
                        ),
                        TextSpan(
                          text: text ?? 'Tambah alamat',
                          style: TextStyle(
                            color: c.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BpText.bodyS,
                  ),
                ),
                Icon(LucideIcons.chevronDown, size: 18, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Teks dengan setiap nominal "RpX" ditebalkan.
TextSpan boldRupiahSpan(String text, {required TextStyle bold}) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in RegExp(r'Rp[0-9.]*[0-9]').allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    spans.add(TextSpan(text: match.group(0), style: bold));
    cursor = match.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return TextSpan(children: spans);
}

/// Strip Misi Belanja tepat di bawah "Kirim ke" [K4]: pesan misi dengan
/// nominal tebal, bilah progres 4 dp, "Di keranjang RpX dari RpY", chevron.
class MissionStrip extends StatelessWidget {
  const MissionStrip({super.key, required this.hint, required this.onOpen});

  final MissionHint hint;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final target = hint.target <= 0 ? 1 : hint.target;
    final progress = (hint.current / target).clamp(0.0, 1.0);
    final shown = hint.current > hint.target ? hint.target : hint.current;
    final progressLabel =
        'Di keranjang ${formatRupiah(shown)} dari ${formatRupiah(hint.target)}';
    return ColoredBox(
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BpSpace.screen,
          0,
          BpSpace.screen,
          BpSpace.x2,
        ),
        child: BpTappable(
          onTap: onOpen,
          pressScale: false,
          alignment: Alignment.centerLeft,
          focusRadius: BpRadius.cardAll,
          semanticLabel: 'Misi Belanja. ${hint.message}. $progressLabel',
          builder: (context, states) => Container(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.x3,
              BpSpace.x2,
              BpSpace.x2,
              BpSpace.x2,
            ),
            decoration: BoxDecoration(
              color: c.goldTint,
              borderRadius: BpRadius.cardAll,
              border: Border.all(color: c.gold.withValues(alpha: 0.45)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text.rich(
                        boldRupiahSpan(
                          hint.message,
                          bold: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: BpText.bodyS.copyWith(color: c.onGoldTint),
                      ),
                      const SizedBox(height: 6),
                      CartProgressBar(
                        value: progress,
                        color: hint.reached ? c.success : c.gold,
                        height: 4,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progressLabel,
                        style: BpText.caption.copyWith(
                          color: c.onGoldTint,
                          fontFeatures: BpText.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BpSpace.x1),
                Icon(LucideIcons.chevronRight, size: 20, color: c.onGoldTint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris tipis ambang gratis ongkir kurir pertama (nilai demo).
class FreeShippingStrip extends StatelessWidget {
  const FreeShippingStrip({
    super.key,
    required this.courierName,
    required this.freeFrom,
    required this.subtotal,
  });

  final String courierName;
  final int freeFrom;
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final reached = subtotal >= freeFrom;
    final left = freeFrom - subtotal;
    return ColoredBox(
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BpSpace.screen,
          0,
          BpSpace.screen,
          BpSpace.x2,
        ),
        child: Row(
          children: <Widget>[
            const BrandIcon(
              BrandGlyph.ongkir,
              size: 20,
              style: BrandIconStyle.color,
            ),
            const SizedBox(width: BpSpace.x2),
            Expanded(
              child: Text.rich(
                reached
                    ? TextSpan(
                        text: 'Yay, gratis ongkir $courierName ',
                        style: TextStyle(color: c.success),
                        children: <InlineSpan>[
                          TextSpan(
                            text: ShippingRepository.demoTag,
                            style: TextStyle(color: c.textMuted),
                          ),
                        ],
                      )
                    : TextSpan(
                        text: 'Belanja ',
                        children: <InlineSpan>[
                          TextSpan(
                            text: '${formatRupiah(left)} lagi',
                            style: TextStyle(
                              color: c.brandStrong,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' untuk gratis ongkir $courierName '),
                          TextSpan(
                            text: ShippingRepository.demoTag,
                            style: TextStyle(color: c.textMuted),
                          ),
                        ],
                      ),
                style: BpText.caption.copyWith(color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu hemat di atas bilah lekat keranjang [K16]: "Hemat RpX di checkout"
/// dengan chip voucher dan Kelopak dari kutipan yang sama dengan total.
class CartSavingsCard extends StatelessWidget {
  const CartSavingsCard({
    super.key,
    required this.voucherAmount,
    required this.kelopakUsed,
    required this.kelopakValue,
    required this.onTap,
  });

  final int voucherAmount;
  final int kelopakUsed;
  final int kelopakValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final total = voucherAmount + kelopakValue;
    final parts = <String>[
      if (voucherAmount > 0) 'voucher ${formatRupiah(voucherAmount)}',
      if (kelopakValue > 0)
        '${kelopakAmountLabel(kelopakUsed)} ${formatRupiah(kelopakValue)}',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        BpSpace.x2,
        BpSpace.screen,
        0,
      ),
      child: BpTappable(
        onTap: onTap,
        pressScale: false,
        alignment: Alignment.centerLeft,
        focusRadius: BpRadius.cardAll,
        semanticLabel:
            'Hemat ${formatRupiah(total)} di checkout: ${parts.join(', ')}. '
            'Lihat rincian',
        builder: (context, states) => Container(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.x3,
            BpSpace.x2,
            BpSpace.x2,
            BpSpace.x2,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BpRadius.cardAll,
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.successTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.badgeCheck, size: 18, color: c.success),
              ),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hemat ${formatRupiah(total)} di checkout',
                      style: BpText.bodyS.copyWith(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: <Widget>[
                        if (voucherAmount > 0)
                          SavingChip(
                            icon: BrandIcon(
                              BrandGlyph.voucher,
                              size: 14,
                              color: c.info,
                            ),
                            label: 'Voucher -${formatRupiah(voucherAmount)}',
                            color: c.info,
                            background: c.infoTint,
                          ),
                        if (kelopakValue > 0)
                          SavingChip(
                            label:
                                '${kelopakAmountLabel(kelopakUsed)} '
                                '-${formatRupiah(kelopakValue)}',
                            color: c.onGoldTint,
                            background: c.goldTint,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 20, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip kecil berwarna untuk potongan (voucher, Kelopak).
class SavingChip extends StatelessWidget {
  const SavingChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final lead = icon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BpRadius.badgeAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (lead != null) ...<Widget>[lead, const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              style: BpText.label.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: BpText.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bilah progres membulat.
class CartProgressBar extends StatelessWidget {
  const CartProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      value: '${(value * 100).round()} persen',
      child: ClipRRect(
        borderRadius: BpRadius.pillAll,
        child: SizedBox(
          height: height,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: ColoredBox(color: c.surface.withValues(alpha: 0.7)),
              ),
              FractionallySizedBox(
                widthFactor: value,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BpRadius.pillAll,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
