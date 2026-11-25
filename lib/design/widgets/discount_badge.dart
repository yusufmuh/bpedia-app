import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Lencana diskon `-39%`.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent, this.corner = false});

  final int percent;

  /// Menempel di pojok kanan atas gambar kartu (pola marketplace): pojok
  /// luar mengikuti radius kartu, hanya pojok kiri bawah yang membulat.
  final bool corner;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      label: 'Diskon $percent persen',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.sale,
          borderRadius: corner
              ? const BorderRadius.only(
                  topRight: Radius.circular(BpRadius.card - 1),
                  bottomLeft: Radius.circular(BpRadius.tile),
                )
              : BpRadius.badgeAll,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: corner ? 8 : 6,
            vertical: corner ? 4 : 3,
          ),
          child: Text(
            '-$percent%',
            style: BpText.label.copyWith(
              color: c.onSale,
              fontSize: corner ? 12 : null,
              fontWeight: FontWeight.w700,
              fontFeatures: BpText.tabular,
            ),
          ),
        ),
      ),
    );
  }
}
