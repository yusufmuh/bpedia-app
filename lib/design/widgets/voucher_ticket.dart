import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'pill_button.dart';

/// Tiket voucher lebar: potongan kiri berisi nilai, garis putus dengan lubang
/// setengah lingkaran, lalu syarat, masa berlaku, dan satu tombol kecil.
class VoucherTicket extends StatelessWidget {
  const VoucherTicket({
    super.key,
    required this.valueLabel,
    required this.title,
    this.valueCaption = 'Diskon',
    this.condition,
    this.expiry,
    this.actionLabel,
    this.onAction,
    this.muted = false,
    this.reason,
    this.selected = false,
  });

  /// Nilai besar di potongan kiri, mis. `Rp10.000` atau `10%`.
  final String valueLabel;

  /// Label kecil di atas nilai, mis. "Diskon" atau "Gratis ongkir".
  final String valueCaption;
  final String title;

  /// Syarat satu baris, mis. "Min. belanja Rp100.000".
  final String? condition;

  /// Masa berlaku, mis. "Berlaku s.d. 25 Des 2026".
  final String? expiry;

  /// Teks tombol ("Klaim", "Pakai"). `null` = tanpa tombol.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Voucher terpakai, kedaluwarsa, atau belum memenuhi syarat: tampil
  /// redup.
  final bool muted;

  /// Alasan voucher belum bisa dipakai, mis. "Tambah Rp25.000 lagi".
  final String? reason;

  /// Voucher sedang dipilih di checkout: bingkai `brand` 1,5 px.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final large = MediaQuery.textScalerOf(context).scale(10) > 13;
    final accent = muted ? c.textMuted : c.brandStrong;
    final fill = muted ? c.surfaceMuted : c.brandTint;
    final border = selected ? c.brand : (muted ? c.line : c.brandLine);
    final cond = condition;
    final exp = expiry;
    final why = reason;
    final action = actionLabel;

    final stub = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          valueCaption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BpText.label.copyWith(color: accent),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valueLabel,
            maxLines: 1,
            style: BpText.titleL.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              fontFeatures: BpText.tabular,
            ),
          ),
        ),
      ],
    );

    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: BpText.subtitle.copyWith(color: muted ? c.textMuted : c.text),
        ),
        if (cond != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              cond,
              style: BpText.caption.copyWith(color: c.textMuted),
            ),
          ),
        if (why != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              why,
              style: BpText.caption.copyWith(
                color: c.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else if (exp != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              exp,
              style: BpText.label.copyWith(
                color: c.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );

    final button = action == null
        ? null
        : PillButton(
            label: action,
            onPressed: muted ? null : onAction,
            size: PillButtonSize.small,
          );

    final semantics = StringBuffer('Voucher $valueCaption $valueLabel, $title');
    if (cond != null) semantics.write(', $cond');
    if (why != null) {
      semantics.write(', $why');
    } else if (exp != null) {
      semantics.write(', $exp');
    }
    if (selected) semantics.write(', dipilih');

    return Semantics(
      container: true,
      label: semantics.toString(),
      child: CustomPaint(
        painter: _TicketPainter(
          fill: fill,
          border: border,
          borderWidth: selected ? 1.5 : 1,
          dash: muted ? c.line : c.brandLine,
          stubFraction: _stubFraction,
          textDirection: Directionality.of(context),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: (_stubFraction * 100).round(),
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BpSpace.x2,
                        vertical: BpSpace.x3,
                      ),
                      child: stub,
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (_stubFraction * 100).round(),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: BpSpace.x4,
                      end: BpSpace.x2,
                      top: BpSpace.x2,
                      bottom: BpSpace.x2,
                    ),
                    child: large || button == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ExcludeSemantics(child: details),
                              if (button != null)
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: button,
                                ),
                            ],
                          )
                        : Row(
                            children: <Widget>[
                              Expanded(child: ExcludeSemantics(child: details)),
                              const SizedBox(width: BpSpace.x1),
                              button,
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _stubFraction = 0.3;
}

class _TicketPainter extends CustomPainter {
  const _TicketPainter({
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.dash,
    required this.stubFraction,
    required this.textDirection,
  });

  final Color fill;
  final Color border;
  final double borderWidth;
  final Color dash;
  final double stubFraction;
  final TextDirection textDirection;

  static const double _notch = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final seam = textDirection == TextDirection.ltr
        ? size.width * stubFraction
        : size.width * (1 - stubFraction);
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(BpRadius.tile),
    );
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(seam, 0), radius: _notch))
      ..addOval(
        Rect.fromCircle(center: Offset(seam, size.height), radius: _notch),
      );
    final shape = Path.combine(
      PathOperation.difference,
      Path()..addRRect(body),
      holes,
    );

    canvas
      ..drawPath(shape, Paint()..color = fill)
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = border,
      );

    final dashPaint = Paint()
      ..color = dash
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashLength = 4.0;
    const gap = 4.0;
    var y = _notch + 5;
    final end = size.height - _notch - 5;
    while (y < end) {
      final stop = (y + dashLength).clamp(0.0, end);
      canvas.drawLine(Offset(seam, y), Offset(seam, stop), dashPaint);
      y += dashLength + gap;
    }
  }

  @override
  bool shouldRepaint(_TicketPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.border != border ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.dash != dash ||
      oldDelegate.stubFraction != stubFraction ||
      oldDelegate.textDirection != textDirection;
}
