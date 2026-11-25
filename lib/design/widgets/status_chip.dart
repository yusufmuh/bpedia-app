import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

enum StatusTone { neutral, brand, success, warning, danger, info, gold }

/// Label status kecil berlatar lembut (status pesanan, "Gratis", "Original").
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;

  /// Ikon kecil di kiri label (14 px), mengikuti warna teks.
  final Widget? icon;

  static (Color background, Color foreground) colorsOf(
    BpColors c,
    StatusTone tone,
  ) {
    return switch (tone) {
      StatusTone.neutral => (c.surfaceMuted, c.textMuted),
      StatusTone.brand => (c.brandTint, c.brandStrong),
      StatusTone.success => (c.successTint, c.success),
      StatusTone.warning => (c.warningTint, c.warning),
      StatusTone.danger => (c.dangerTint, c.danger),
      StatusTone.info => (c.infoTint, c.info),
      StatusTone.gold => (c.goldTint, c.onGoldTint),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = colorsOf(context.bp, tone);
    final leading = icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BpRadius.badgeAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (leading != null) ...<Widget>[
              IconTheme.merge(
                data: IconThemeData(color: foreground, size: 14),
                child: leading,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: BpText.label.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
