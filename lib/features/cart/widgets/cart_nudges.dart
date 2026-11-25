/// Strip dan kartu dorongan di keranjang: alamat kirim, ambang gratis
/// ongkir, Kelopak, dan Misi Belanja.
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

/// Strip ambang gratis ongkir kurir pertama (nilai demo).
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
    final progress = (subtotal / freeFrom).clamp(0.0, 1.0);
    final fg = reached ? c.success : c.text;
    return ColoredBox(
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BpSpace.screen,
          0,
          BpSpace.screen,
          BpSpace.x3,
        ),
        child: Container(
          padding: const EdgeInsets.all(BpSpace.x3),
          decoration: BoxDecoration(
            color: reached ? c.successTint : c.surface,
            borderRadius: BpRadius.cardAll,
            border: Border.all(
              color: reached ? c.success.withValues(alpha: 0.35) : c.line,
            ),
          ),
          child: Row(
            children: <Widget>[
              const BrandIcon(
                BrandGlyph.ongkir,
                size: 28,
                style: BrandIconStyle.color,
              ),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                      reached
                          ? TextSpan(
                              text: 'Yay, gratis ongkir $courierName ',
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
                                TextSpan(
                                  text: ' untuk gratis ongkir $courierName ',
                                ),
                                TextSpan(
                                  text: ShippingRepository.demoTag,
                                  style: TextStyle(color: c.textMuted),
                                ),
                              ],
                            ),
                      style: BpText.bodyS.copyWith(color: fg),
                    ),
                    if (!reached) ...<Widget>[
                      const SizedBox(height: 6),
                      _ProgressBar(value: progress, color: c.brand),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu dorongan berikon 3D: judul, isi, bar progres opsional, aksi.
class NudgeCard extends StatelessWidget {
  const NudgeCard({
    super.key,
    required this.icon3d,
    required this.title,
    this.message,
    this.progress,
    this.actionLabel,
    this.onAction,
    this.tinted = false,
  });

  /// Nama ikon 3D di `assets/icons3d/<icon3d>.webp`.
  final String icon3d;
  final String title;
  final String? message;

  /// 0..1; null tanpa bar.
  final double? progress;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Latar `goldTint` (Kelopak) alih-alih `surface`.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final body = message;
    final bar = progress;
    final action = actionLabel;
    final fg = tinted ? c.onGoldTint : c.text;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
      padding: const EdgeInsets.all(BpSpace.x3),
      decoration: BoxDecoration(
        color: tinted ? c.goldTint : c.surface,
        borderRadius: BpRadius.cardAll,
        border: Border.all(color: tinted ? c.goldTint : c.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AssetPicture(
            'assets/icons3d/$icon3d.webp',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            showSkeleton: false,
          ),
          const SizedBox(width: BpSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: BpText.subtitle.copyWith(color: fg)),
                if (body != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      body,
                      style: BpText.caption.copyWith(
                        color: tinted ? c.onGoldTint : c.textMuted,
                      ),
                    ),
                  ),
                if (bar != null) ...<Widget>[
                  const SizedBox(height: BpSpace.x2),
                  _ProgressBar(value: bar, color: c.gold),
                ],
                if (action != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: PillButton(
                      label: action,
                      onPressed: onAction,
                      variant: PillButtonVariant.text,
                      size: PillButtonSize.small,
                      trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu Kelopak: "Pakai 128 Kelopak, hemat Rp12.800 di checkout".
class KelopakNudge extends StatelessWidget {
  const KelopakNudge({super.key, required this.balance, required this.saving});

  final int balance;

  /// Potongan rupiah bila semua barang terpilih di-checkout.
  final int saving;

  @override
  Widget build(BuildContext context) {
    return NudgeCard(
      icon3d: 'kelopak',
      tinted: true,
      title: saving > 0
          ? 'Pakai ${kelopakAmountLabel(balance)}, hemat ${formatRupiah(saving)} di checkout'
          : 'Kamu punya ${kelopakAmountLabel(balance)}',
      message: saving > 0
          ? 'Sakelar Pakai Kelopak sudah menyala di checkout.'
          : 'Centang produk untuk memakai Kelopak di checkout.',
    );
  }
}

/// Kartu Misi Belanja dari [MissionHint].
class MissionNudge extends StatelessWidget {
  const MissionNudge({super.key, required this.hint, required this.onOpen});

  final MissionHint hint;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final target = hint.target <= 0 ? 1 : hint.target;
    return NudgeCard(
      icon3d: 'misi',
      title: hint.reached ? 'Target misi tercapai' : 'Misi Belanja',
      message: hint.message,
      progress: (hint.current / target).clamp(0.0, 1.0),
      actionLabel: 'Lihat misi',
      onAction: onOpen,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      value: '${(value * 100).round()} persen',
      child: ClipRRect(
        borderRadius: BpRadius.pillAll,
        child: SizedBox(
          height: 6,
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: ColoredBox(color: c.surfaceMuted)),
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
