import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import '../tokens.dart';
import 'tappable.dart';

/// Baris label–nilai.
///
/// Dua pemakaian:
/// - ringkasan ("Subtotal produk" · "Rp120.000"): tanpa [onTap], tinggi rapat;
/// - baris menu atau pilihan ("Voucher" · "2 tersedia" · chevron): dengan
///   [onTap], tinggi minimal 48.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.helper,
    this.leading,
    this.trailing,
    this.onTap,
    this.emphasized = false,
    this.valueColor,
    this.padding,
  }) : assert(
         value == null || valueWidget == null,
         'Isi value atau valueWidget, bukan keduanya.',
       );

  final String label;
  final String? value;

  /// Mengganti teks nilai (mis. `StatusChip` atau `PriceText`).
  final Widget? valueWidget;

  /// Keterangan kecil di bawah label.
  final String? helper;

  /// Ikon 20–24 px di kiri label.
  final Widget? leading;

  /// Mengganti chevron pada baris yang bisa diketuk.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Baris total: label dan nilai tebal, nilai memakai gaya `titleL`.
  final bool emphasized;
  final Color? valueColor;

  /// Bawaan: margin layar kiri-kanan; 6 atas-bawah (ringkasan) atau 12
  /// (baris menu).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final tap = onTap;
    final lead = leading;
    final help = helper;
    final text = value;
    final custom = valueWidget;
    final interactive = tap != null;
    // Pada huruf sangat besar nilai pindah ke bawah label supaya keduanya
    // tidak berebut lebar dan terpenggal di tengah kata.
    final stackValue =
        (text != null || custom != null) &&
        MediaQuery.textScalerOf(context).scale(10) > 15;

    final labelStyle = emphasized
        ? BpText.subtitle.copyWith(color: c.text)
        : BpText.body.copyWith(color: interactive ? c.text : c.textMuted);
    final valueStyle = emphasized
        ? BpText.titleL.copyWith(
            color: valueColor ?? c.text,
            fontFeatures: BpText.tabular,
          )
        : BpText.body.copyWith(
            color: valueColor ?? (interactive ? c.textMuted : c.text),
            fontWeight: interactive ? FontWeight.w400 : FontWeight.w500,
            fontFeatures: BpText.tabular,
          );

    final row = Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: BpSpace.screen,
            vertical: interactive ? BpSpace.x3 : 6,
          ),
      child: Row(
        crossAxisAlignment: help == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: <Widget>[
          if (lead != null) ...<Widget>[
            IconTheme.merge(
              data: IconThemeData(color: c.text, size: BpSize.icon),
              child: lead,
            ),
            const SizedBox(width: BpSpace.x3),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: labelStyle),
                if (help != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      help,
                      style: BpText.caption.copyWith(color: c.textMuted),
                    ),
                  ),
                if (stackValue)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: custom ?? Text(text!, style: valueStyle),
                  ),
              ],
            ),
          ),
          if (!stackValue && (text != null || custom != null)) ...<Widget>[
            const SizedBox(width: BpSpace.x3),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.5,
              ),
              child:
                  custom ??
                  Text(text!, textAlign: TextAlign.end, style: valueStyle),
            ),
          ],
          if (interactive) ...<Widget>[
            const SizedBox(width: BpSpace.x1),
            trailing ??
                Icon(
                  LucideIcons.chevronRight,
                  size: BpSize.iconDense,
                  color: c.textFaint,
                ),
          ],
        ],
      ),
    );

    if (!interactive) {
      return MergeSemantics(child: row);
    }
    return BpTappable(
      onTap: tap,
      alignment: Alignment.centerLeft,
      focusRadius: BorderRadius.zero,
      pressScale: false,
      builder: (context, states) {
        final active =
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered);
        return AnimatedContainer(
          duration: BpMotion.micro,
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: BpSize.touch),
          alignment: Alignment.centerLeft,
          color: active ? c.surfaceMuted : c.surfaceMuted.withValues(alpha: 0),
          child: row,
        );
      },
    );
  }
}
