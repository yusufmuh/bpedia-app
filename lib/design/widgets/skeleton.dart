import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Kerangka muat berkilau. Diam saat gerak dikurangi.
///
/// Tanpa [width] dan [height] kerangka mengisi induknya (induk harus
/// berukuran terbatas).
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = BpRadius.tile,
  });

  const Skeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = BpRadius.pill;

  /// Satu baris teks setinggi [height].
  const Skeleton.line({super.key, this.width, this.height = 12})
    : radius = BpRadius.badge;

  final double? width;
  final double? height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (BpMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final box = ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ShimmerPainter(
            progress: _controller,
            base: c.isDark ? c.surfaceMuted : c.line,
            glow: c.isDark ? c.line : const Color(0xFFF8F8FA),
            radius: widget.radius,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
    if (widget.width == null && widget.height == null) return box;
    return SizedBox(width: widget.width, height: widget.height, child: box);
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.progress,
    required this.base,
    required this.glow,
    required this.radius,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color base;
  final Color glow;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius.clamp(0, size.shortestSide / 2)),
    );
    canvas.drawRRect(shape, Paint()..color = base);

    final band = size.width * 0.9 + 80;
    final start = -band + (size.width + band) * progress.value;
    final bandRect = Rect.fromLTWH(start, 0, band, size.height);
    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[base, glow, base],
      ).createShader(bandRect);
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(bandRect, glowPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.base != base ||
      oldDelegate.glow != glow ||
      oldDelegate.radius != radius;
}
