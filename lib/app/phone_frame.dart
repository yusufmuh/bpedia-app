/// Kolom ponsel di layar lebar (SPEC §3): web dan tablet menampilkan app
/// sebagai kolom 430 px di tengah latar bermerek; ponsel tampil penuh.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/design.dart';

/// Membungkus seluruh app (dipasang di `MaterialApp.builder`).
///
/// Di lebar lebih dari [breakpoint], [child] dirender dalam kolom selebar
/// [columnWidth] dengan `MediaQuery` yang sudah disesuaikan, sehingga halaman,
/// lembar bawah, dan dialog tetap berukuran ponsel. Tidak ada tata letak
/// desktop.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({required this.child, super.key});

  /// Lebar layar terbesar yang masih tampil penuh.
  static const double breakpoint = 520;

  /// Lebar kolom ponsel.
  static const double columnWidth = 430;

  /// Tinggi kolom terbesar; layar yang lebih tinggi menampilkan kolom
  /// melayang bersudut bulat.
  static const double maxColumnHeight = 932;

  /// Lebar layar terkecil yang menampilkan panel merek di kiri dan Bipy di
  /// kanan kolom.
  static const double sidePanelsFrom = 1080;

  static const double _floatMargin = 24;
  static const double _floatRadius = 32;

  final Widget child;

  /// Apakah layar selebar [width] menampilkan kolom ponsel.
  static bool isFramed(double width) => width > breakpoint;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    if (!isFramed(size.width)) return child;

    final c = context.bp;
    final safeHeight = size.height - media.padding.vertical;
    final floating = safeHeight >= maxColumnHeight + _floatMargin * 2;
    final columnHeight = floating ? maxColumnHeight : size.height;
    final gapBelow = floating ? (size.height - columnHeight) / 2 : 0.0;
    final radius = floating
        ? const BorderRadius.all(Radius.circular(_floatRadius))
        : BorderRadius.zero;

    final framed = media.copyWith(
      size: Size(columnWidth, columnHeight),
      padding: floating
          ? EdgeInsets.zero
          : media.padding.copyWith(left: 0, right: 0),
      viewPadding: floating
          ? EdgeInsets.zero
          : media.viewPadding.copyWith(left: 0, right: 0),
      viewInsets: media.viewInsets.copyWith(
        left: 0,
        right: 0,
        bottom: math.max(0, media.viewInsets.bottom - gapBelow),
      ),
    );

    final sideWidth = (size.width - columnWidth) / 2;
    final showPanels = size.width >= sidePanelsFrom && size.height >= 560;

    return ColoredBox(
      color: c.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PetalBackdropPainter(
                  petal: c.brand,
                  glow: c.brandTint,
                  dark: c.isDark,
                ),
              ),
            ),
          ),
          if (showPanels) ...<Widget>[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: sideWidth,
              child: const _BrandPanel(),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: sideWidth,
              child: const _MascotPanel(),
            ),
          ],
          Center(
            child: Container(
              key: const ValueKey<String>('phone-frame-column'),
              width: columnWidth,
              height: columnHeight,
              clipBehavior: Clip.antiAlias,
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: floating
                    ? Border.all(color: c.line)
                    : Border.symmetric(vertical: BorderSide(color: c.line)),
              ),
              decoration: BoxDecoration(
                color: c.canvas,
                borderRadius: radius,
                boxShadow: c.isDark
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x66000000),
                          offset: Offset(0, 18),
                          blurRadius: 48,
                        ),
                      ]
                    : const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x1F6B1439),
                          offset: Offset(0, 18),
                          blurRadius: 48,
                        ),
                        BoxShadow(
                          color: Color(0x0F000000),
                          offset: Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: MediaQuery(data: framed, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel kiri: logo dan satu kalimat pengantar.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Align(
      alignment: const Alignment(0, -0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  image: true,
                  label: 'Bpedia',
                  child: AssetPicture(
                    c.isDark
                        ? 'assets/images/logo_horizontal_reverse.webp'
                        : 'assets/images/logo_horizontal.webp',
                    width: 188,
                    height: 80,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    showSkeleton: false,
                  ),
                ),
                const SizedBox(height: BpSpace.x5),
                Text(
                  'Belanja kecantikan sambil kumpulkan Kelopak',
                  style: BpText.display.copyWith(
                    color: c.text,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: BpSpace.x3),
                Text(
                  'Bpedia Demo dirancang untuk ponsel. Di layar lebar, '
                  'aplikasi tampil sebagai kolom ponsel di tengah.',
                  style: BpText.body.copyWith(
                    color: c.textMuted,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: BpSpace.x5),
                const Wrap(
                  spacing: BpSpace.x2,
                  runSpacing: BpSpace.x2,
                  children: <Widget>[
                    _PanelTag(
                      icon: BrandGlyph.reward,
                      label: 'Check-in Harian',
                    ),
                    _PanelTag(icon: BrandGlyph.flash, label: 'Roda Sabtu'),
                    _PanelTag(icon: BrandGlyph.bag, label: 'Misi Belanja'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelTag extends StatelessWidget {
  const _PanelTag({required this.icon, required this.label});

  final BrandGlyph icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BpRadius.pillAll,
        border: Border.all(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BrandIcon(icon, size: 18, style: BrandIconStyle.color),
            const SizedBox(width: 6),
            Text(
              label,
              style: BpText.caption.copyWith(
                color: c.text,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel kanan: Bipy menyambut dengan balon sapaan.
class _MascotPanel extends StatelessWidget {
  const _MascotPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return ExcludeSemantics(
      child: Align(
        alignment: const Alignment(0, 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(color: c.line),
                  boxShadow: BpShadows.floating(c),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    'Hai, Babes!',
                    textScaler: TextScaler.noScaling,
                    style: BpText.subtitle.copyWith(
                      color: c.brandStrong,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: BpSpace.x2),
              const BipyPose(
                'assets/bipy/bipy_pose_host.webp',
                width: 190,
                height: 320,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pose diam Bipy yang digerakkan dengan kode: masuk dengan pegas, lalu
/// idle tiga-sinus (naik-turun, condong, napas) di atas bayangan lantai.
///
/// Gerak berhenti saat tak terlihat (`TickerMode`) dan saat gerak dikurangi.
class BipyPose extends StatefulWidget {
  const BipyPose(
    this.asset, {
    required this.height,
    this.width,
    this.shadow = true,
    this.semanticLabel,
    super.key,
  });

  /// Jalur aset pose, mis. `assets/bipy/bipy_pose_host.webp`.
  final String asset;
  final double height;

  /// Bawaan: 0,62 × [height].
  final double? width;

  /// Bayangan elips di kaki.
  final bool shadow;

  /// `null` = dekoratif.
  final String? semanticLabel;

  @override
  State<BipyPose> createState() => _BipyPoseState();
}

class _BipyPoseState extends State<BipyPose> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final Animation<double> _spring = CurvedAnimation(
    parent: _enter,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.35, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (BpMotion.reduced(context)) {
      _idle.stop();
      _enter.value = 1;
      return;
    }
    if (!_idle.isAnimating) _idle.repeat();
    if (_enter.status == AnimationStatus.dismissed) _enter.forward();
  }

  @override
  void dispose() {
    _idle.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final width = widget.width ?? widget.height * 0.62;
    final label = widget.semanticLabel;
    final art = AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_idle, _enter]),
      builder: (context, child) {
        final t = _idle.value * 2 * math.pi;
        final amplitude = widget.height / 64;
        // Tiga sinus berbeda periode supaya gerak tidak terasa berulang.
        final dy =
            math.sin(t * 3) * amplitude + math.sin(t * 7) * 0.3 * amplitude;
        final tilt = math.sin(t * 2) * 0.02;
        final breathe = 1 + math.sin(t * 5) * 0.008;
        final enter = _spring.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Opacity(
              opacity: _fade.value,
              child: Transform.translate(
                offset: Offset(0, dy + (1 - enter) * widget.height * 0.12),
                child: Transform.rotate(
                  angle: tilt,
                  alignment: Alignment.bottomCenter,
                  child: Transform.scale(
                    scaleX: 0.7 + 0.3 * enter,
                    scaleY: (0.7 + 0.3 * enter) * breathe,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
              ),
            ),
            if (widget.shadow)
              Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scaleX: 1 - dy / (amplitude * 14),
                  child: Container(
                    width: width * 0.62,
                    height: math.max(6, widget.height * 0.04),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(width * 0.31, widget.height * 0.02),
                      ),
                      color: (c.isDark ? Colors.black : BpFest.festDeep)
                          .withValues(alpha: c.isDark ? 0.45 : 0.1),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: AssetPicture(
        widget.asset,
        width: width,
        height: widget.height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        showSkeleton: false,
      ),
    );
    if (label == null) return ExcludeSemantics(child: art);
    return Semantics(image: true, label: label, child: art);
  }
}

/// Latar bermerek: dua pendar lembut dan kelopak samar yang tersebar tetap.
class _PetalBackdropPainter extends CustomPainter {
  const _PetalBackdropPainter({
    required this.petal,
    required this.glow,
    required this.dark,
  });

  final Color petal;
  final Color glow;
  final bool dark;

  /// (x, y) ternormalisasi, panjang kelopak, sudut (radian), kepekatan.
  static const List<(double, double, double, double, double)> _petals =
      <(double, double, double, double, double)>[
        (0.045, 0.12, 46, 0.6, 0.9),
        (0.16, 0.30, 28, -0.5, 0.6),
        (0.075, 0.55, 60, 2.2, 0.7),
        (0.22, 0.78, 36, 1.1, 0.9),
        (0.035, 0.90, 30, -1.2, 0.6),
        (0.30, 0.08, 24, 2.6, 0.5),
        (0.27, 0.50, 20, 0.2, 0.45),
        (0.955, 0.10, 34, -0.7, 0.7),
        (0.84, 0.22, 54, 0.9, 0.85),
        (0.93, 0.46, 26, 2.4, 0.6),
        (0.78, 0.60, 22, -1.9, 0.45),
        (0.90, 0.80, 62, -0.3, 0.8),
        (0.74, 0.93, 30, 1.6, 0.6),
        (0.70, 0.12, 20, 0.4, 0.45),
        (0.50, 0.03, 26, 1.3, 0.5),
        (0.52, 0.97, 32, -2.3, 0.5),
      ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    void glowAt(Alignment center, double radius, double alpha) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: center,
            radius: radius,
            colors: <Color>[
              glow.withValues(alpha: alpha),
              glow.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    glowAt(const Alignment(-0.85, -0.7), 0.75, dark ? 0.55 : 0.9);
    glowAt(const Alignment(0.9, 0.75), 0.8, dark ? 0.45 : 0.8);

    final base = dark ? 0.16 : 0.13;
    for (final (x, y, length, angle, strength) in _petals) {
      canvas
        ..save()
        ..translate(x * size.width, y * size.height)
        ..rotate(angle);
      final half = length / 2;
      final width = length * 0.36;
      final shape = Path()
        ..moveTo(0, -half)
        ..cubicTo(width, -half * 0.35, width * 0.9, half * 0.7, 0, half)
        ..cubicTo(-width * 0.9, half * 0.7, -width, -half * 0.35, 0, -half)
        ..close();
      canvas
        ..drawPath(
          shape,
          Paint()..color = petal.withValues(alpha: base * strength),
        )
        ..drawPath(
          Path()
            ..moveTo(0, -half * 0.55)
            ..quadraticBezierTo(width * 0.18, 0, 0, half * 0.7),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round
            ..color = petal.withValues(alpha: base * strength * 0.9),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_PetalBackdropPainter oldDelegate) =>
      oldDelegate.petal != petal ||
      oldDelegate.glow != glow ||
      oldDelegate.dark != dark;
}
