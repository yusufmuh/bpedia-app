/// Gambar mini produk terbang ke ikon keranjang setelah tambah cepat
/// (SPEC §4.2): 300 ms, lintasan melengkung, mengecil dan memudar.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../design/design.dart';

/// Lama penerbangan.
const Duration cartFlightDuration = Duration(milliseconds: 300);

/// Menerbangkan [image] dari kotak [context] ke ikon keranjang terdekat
/// pada Scaffold yang sama. Tidak melakukan apa pun bila gerak dikurangi,
/// bila ikon keranjang tidak terlihat, atau bila tidak ada Overlay.
void flyToCart(BuildContext context, String image) {
  if (BpMotion.reduced(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final source = context.findRenderObject();
  final scaffold = Scaffold.maybeOf(context)?.context;
  if (overlay == null || scaffold == null) return;
  if (source is! RenderBox || !source.hasSize || !source.attached) return;
  final target = _findCartIcon(scaffold);
  if (target == null) return;
  final overlayBox = overlay.context.findRenderObject();
  if (overlayBox is! RenderBox) return;
  final from = overlayBox.globalToLocal(
    source.localToGlobal(source.size.center(Offset.zero)),
  );
  final to = overlayBox.globalToLocal(
    target.localToGlobal(target.size.center(Offset.zero)),
  );
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _CartFlight(
      key: const ValueKey<String>('terbang-keranjang'),
      image: image,
      from: from,
      to: to,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

RenderBox? _findCartIcon(BuildContext root) {
  RenderBox? found;
  void visit(Element element) {
    if (found != null) return;
    if (element.widget is CartBadgeIcon) {
      final box = element.findRenderObject();
      if (box is RenderBox && box.hasSize && box.attached) {
        found = box;
        return;
      }
    }
    element.visitChildElements(visit);
  }

  root.visitChildElements(visit);
  return found;
}

class _CartFlight extends StatefulWidget {
  const _CartFlight({
    required this.image,
    super.key,
    required this.from,
    required this.to,
    required this.onDone,
  });

  final String image;
  final Offset from;
  final Offset to;
  final VoidCallback onDone;

  @override
  State<_CartFlight> createState() => _CartFlightState();
}

class _CartFlightState extends State<_CartFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: cartFlightDuration,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenCompleteOrCancel(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = Curves.easeInCubic.transform(_controller.value);
                final x = lerpDouble(widget.from.dx, widget.to.dx, t)!;
                final lift = 4 * t * (1 - t) * 80;
                final y = lerpDouble(widget.from.dy, widget.to.dy, t)! - lift;
                return Positioned(
                  left: x - size / 2,
                  top: y - size / 2,
                  child: Opacity(
                    opacity: lerpDouble(1, 0.6, t)!,
                    child: Transform.scale(
                      scale: lerpDouble(1, 0.35, t)!,
                      child: child,
                    ),
                  ),
                );
              },
              child: ClipOval(
                child: AssetPicture(
                  widget.image,
                  width: size,
                  height: size,
                  showSkeleton: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
