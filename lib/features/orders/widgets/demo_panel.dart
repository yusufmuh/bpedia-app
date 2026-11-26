import 'package:flutter/material.dart';

import '../../../design/design.dart';

/// Kotak simulasi bergaya Mode Demo: latar `goldTint`, garis putus emas 1 dp,
/// lencana DEMO, judul, keterangan, dan aksi opsional.
class DemoPanel extends StatelessWidget {
  const DemoPanel({
    super.key,
    required this.title,
    required this.message,
    this.actions = const <Widget>[],
  });

  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: c.gold,
        radius: BpRadius.card,
      ),
      child: Container(
        padding: const EdgeInsets.all(BpSpace.x3),
        decoration: BoxDecoration(
          color: c.goldTint,
          borderRadius: BpRadius.cardAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const DemoBadge(),
                const SizedBox(width: BpSpace.x2),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: BpText.subtitle.copyWith(color: c.text),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BpSpace.x1),
            Text(message, style: BpText.bodyS.copyWith(color: c.textMuted)),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: BpSpace.x3),
              Row(
                children: <Widget>[
                  for (final (index, action) in actions.indexed) ...<Widget>[
                    if (index > 0) const SizedBox(width: BpSpace.x2),
                    Expanded(child: action),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lencana kecil "DEMO".
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.gold.withValues(alpha: 0.22),
        borderRadius: BpRadius.badgeAll,
      ),
      child: Text(
        'DEMO',
        style: BpText.label.copyWith(
          color: c.onGoldTint,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          Radius.circular(radius),
        ),
      );
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
