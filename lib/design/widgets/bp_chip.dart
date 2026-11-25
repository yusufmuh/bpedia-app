import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import '../tokens.dart';
import 'tappable.dart';

/// Chip pil untuk urutan, filter, kategori, dan brand.
///
/// - [onTap] saja: chip pilihan (lihat [selected]).
/// - [onDeleted] saja: chip filter aktif; ketuk di mana pun untuk menghapus.
/// - Keduanya `null`: label statis.
class BpChip extends StatelessWidget {
  const BpChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.leading,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  /// Ikon atau gambar kecil di kiri (16 px).
  final Widget? leading;

  /// Ikon kecil di kanan, mis. chevron untuk chip yang membuka lembar.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final active = selected || (onDeleted != null && onTap == null);
    final foreground = active ? c.brandStrong : c.text;
    final leadingWidget = leading;
    final trailingWidget = trailing;

    Widget pill(Set<WidgetState> states) {
      final pressed = states.contains(WidgetState.pressed);
      final hovered = states.contains(WidgetState.hovered);
      final base = active ? c.brandTint : c.surface;
      final fill = pressed || hovered
          ? Color.alphaBlend(
              foreground.withValues(alpha: pressed ? 0.10 : 0.05),
              base,
            )
          : base;
      return AnimatedContainer(
        duration: BpMotion.micro,
        curve: BpMotion.microCurve,
        constraints: const BoxConstraints(minHeight: 36),
        padding: EdgeInsets.only(
          left: leadingWidget == null ? 14 : 10,
          right: onDeleted != null || trailingWidget != null ? 10 : 14,
          top: 6,
          bottom: 6,
        ),
        decoration: ShapeDecoration(
          color: fill,
          shape: StadiumBorder(
            side: BorderSide(color: active ? c.brandLine : c.line),
          ),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (leadingWidget != null) ...<Widget>[
                leadingWidget,
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BpText.bodyS.copyWith(
                    color: foreground,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (trailingWidget != null) ...<Widget>[
                const SizedBox(width: 4),
                trailingWidget,
              ],
              if (onDeleted != null) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(LucideIcons.x, size: 14),
              ],
            ],
          ),
        ),
      );
    }

    final action = onTap ?? onDeleted;
    if (action == null) return pill(const <WidgetState>{});
    return BpTappable(
      onTap: action,
      selected: onTap == null ? null : selected,
      semanticLabel: onTap == null ? 'Hapus filter $label' : label,
      minWidth: 0,
      builder: (context, states) => pill(states),
    );
  }
}
