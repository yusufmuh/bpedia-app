import 'package:flutter/material.dart';

import '../../../design/design.dart';

/// Gambar QR contoh untuk pembayaran simulasi: pola modul tetap per [seed]
/// dengan tiga penanda sudut dan label DEMO di tengah. Bukan kode QR yang
/// bisa dipindai.
class QrDemo extends StatelessWidget {
  const QrDemo({super.key, required this.seed, this.size = 184});

  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kode QR contoh, pembayaran simulasi',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              size: Size.square(size),
              painter: _QrPainter(seed: seed),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BpRadius.badgeAll,
                border: Border.all(color: BpColors.light.brand, width: 1.5),
              ),
              child: Text(
                'DEMO',
                style: BpText.label.copyWith(
                  color: BpColors.light.brandStrong,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter({required this.seed});

  static const int _modules = 25;

  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final ink = Paint()..color = const Color(0xFF1F1A1D);
    var state = 0x9E3779B9;
    for (final unit in seed.codeUnits) {
      state = (state ^ unit) * 0x01000193 & 0x7FFFFFFF;
    }
    bool next() {
      state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
      return (state >> 16) & 1 == 1;
    }

    bool inFinder(int x, int y) {
      bool near(int ox, int oy) =>
          x >= ox && x < ox + 8 && y >= oy && y < oy + 8;
      return near(0, 0) || near(_modules - 8, 0) || near(0, _modules - 8);
    }

    for (var y = 0; y < _modules; y++) {
      for (var x = 0; x < _modules; x++) {
        final filled = next();
        if (inFinder(x, y)) continue;
        if (filled) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell + 0.4, cell + 0.4),
            ink,
          );
        }
      }
    }
    for (final origin in <Offset>[
      Offset.zero,
      Offset((_modules - 7) * cell, 0),
      Offset(0, (_modules - 7) * cell),
    ]) {
      _finder(canvas, origin, cell, ink);
    }
  }

  void _finder(Canvas canvas, Offset origin, double cell, Paint ink) {
    final outer = Rect.fromLTWH(origin.dx, origin.dy, cell * 7, cell * 7);
    canvas
      ..drawRect(outer, ink)
      ..drawRect(outer.deflate(cell), Paint()..color = Colors.white)
      ..drawRect(outer.deflate(cell * 2), ink);
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.seed != seed;
}
