import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import '../tokens.dart';
import 'tappable.dart';

/// Pengatur jumlah `−  2  +` dengan tombol 48 × 48.
///
/// Bila [onRemove] diisi dan nilai sudah di batas bawah, tombol kurang
/// berubah menjadi tong sampah (seperti keranjang app Bpedia).
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.onRemove,
  });

  final int value;

  /// `null` menonaktifkan seluruh pengatur.
  final ValueChanged<int>? onChanged;
  final int min;

  /// Batas atas (stok atau batas per pesanan).
  final int max;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final change = onChanged;
    final remove = onRemove;
    final atMin = value <= min;
    final showRemove = atMin && remove != null;
    final canDecrease = change != null && !atMin;
    final canIncrease = change != null && value < max;

    Widget glyph(IconData icon, bool enabled) {
      return Icon(
        icon,
        size: 16,
        color: enabled ? c.text : c.textFaint.withValues(alpha: 0.5),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: c.surface,
                shape: StadiumBorder(side: BorderSide(color: c.line)),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BpTappable(
              onTap: showRemove
                  ? remove
                  : (canDecrease ? () => change(value - 1) : null),
              semanticLabel: showRemove
                  ? 'Hapus dari keranjang'
                  : 'Kurangi jumlah',
              tooltip: showRemove ? 'Hapus dari keranjang' : 'Kurangi jumlah',
              builder: (context, states) => glyph(
                showRemove ? LucideIcons.trash2 : LucideIcons.minus,
                showRemove || canDecrease,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 28),
              child: Semantics(
                container: true,
                label: 'Jumlah',
                value: '$value',
                liveRegion: true,
                excludeSemantics: true,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: BpText.subtitle.copyWith(
                    color: change == null ? c.textFaint : c.text,
                    fontFeatures: BpText.tabular,
                  ),
                ),
              ),
            ),
            BpTappable(
              onTap: canIncrease ? () => change(value + 1) : null,
              semanticLabel: 'Tambah jumlah',
              tooltip: 'Tambah jumlah',
              builder: (context, states) =>
                  glyph(LucideIcons.plus, canIncrease),
            ),
          ],
        ),
      ],
    );
  }
}
