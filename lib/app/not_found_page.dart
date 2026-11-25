/// Halaman untuk tujuan yang tidak ada (SPEC §3): "Waduh, tujuanmu nggak
/// ada!" dengan Bipy mengintip dan tombol "Ke Beranda".
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import 'app_router.dart';
import 'app_scope.dart';

/// Halaman 404 berdesain. Dipasang kerangka app sebagai
/// `AppRouter.notFoundBuilder`.
///
/// [route] berupa [NotFoundRoute] untuk lokasi yang tidak dikenal, atau rute
/// yang dikenal tetapi belum punya halaman di build ini.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.route, super.key});

  /// Rute yang diminta.
  final AppRoute route;

  /// Judul untuk lokasi yang tidak dikenal.
  static const String unknownTitle = 'Waduh, tujuanmu nggak ada!';

  /// Judul untuk rute yang dikenal tetapi belum punya halaman.
  static const String unavailableTitle = 'Halaman ini belum tersedia';

  bool get _unknown => route is NotFoundRoute;

  void _goHome(BuildContext context) {
    final router = AppScope.maybeOf(context)?.router;
    if (router != null) {
      router.goHome(context);
    } else {
      Navigator.of(context).popUntil((entry) => entry.isFirst);
    }
  }

  void _openCatalog(BuildContext context) {
    final router = AppScope.maybeOf(context)?.router;
    if (router != null) router.go(context, const CatalogRoute());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final hasRouter = AppScope.maybeOf(context) != null;
    final location = route.location.isEmpty ? '/' : route.location;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: BpSize.appBar,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: BpSpace.x1),
                  if (canPop) const BpBackButton(),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    BpSpace.screen,
                    0,
                    BpSpace.screen,
                    BpSpace.x8,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0,
                        constraints.maxHeight - BpSpace.x8,
                      ),
                    ),
                    child: Align(
                      alignment: const Alignment(0, -0.35),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _PeekCard(
                          title: _unknown ? unknownTitle : unavailableTitle,
                          message: _unknown
                              ? 'Halaman yang kamu cari tidak ditemukan atau '
                                    'sudah pindah. Yuk, balik ke Beranda, '
                                    'Babes.'
                              : 'Bagian ini belum dibuka di versi demo. Yuk, '
                                    'lanjut jelajah dari Beranda, Babes.',
                          location: location,
                          onHome: () => _goHome(context),
                          onCatalog: hasRouter
                              ? () => _openCatalog(context)
                              : null,
                          onBack: canPop
                              ? () => Navigator.of(context).maybePop()
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu isi dengan seni "4 Bipy 4" yang mengintip dari tepi atasnya.
class _PeekCard extends StatelessWidget {
  const _PeekCard({
    required this.title,
    required this.message,
    required this.location,
    required this.onHome,
    required this.onCatalog,
    required this.onBack,
  });

  final String title;
  final String message;
  final String location;
  final VoidCallback onHome;
  final VoidCallback? onCatalog;
  final VoidCallback? onBack;

  static const double _artHeight = 138;
  static const double _overlap = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final back = onBack;
    final catalog = onCatalog;
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: _artHeight - _overlap),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(BpRadius.dialog),
              ),
              border: Border.all(color: c.line),
              boxShadow: BpShadows.floating(c),
            ),
            padding: const EdgeInsets.fromLTRB(
              BpSpace.x5,
              BpSpace.x8,
              BpSpace.x5,
              BpSpace.x3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: BpText.titleL.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: BpSpace.x2),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: BpText.body.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: BpSpace.x4),
                _LocationPill(location: location),
                const SizedBox(height: BpSpace.x5),
                PillButton(
                  label: 'Ke Beranda',
                  icon: const Icon(LucideIcons.house),
                  expand: true,
                  onPressed: onHome,
                ),
                const SizedBox(height: BpSpace.x1),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: BpSpace.x2,
                  children: <Widget>[
                    if (back != null)
                      PillButton(
                        label: 'Kembali',
                        variant: PillButtonVariant.text,
                        size: PillButtonSize.small,
                        onPressed: back,
                      ),
                    if (catalog != null)
                      PillButton(
                        label: 'Lihat katalog',
                        variant: PillButtonVariant.text,
                        size: PillButtonSize.small,
                        onPressed: catalog,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: _artHeight,
          child: ExcludeSemantics(child: _PeekArt()),
        ),
      ],
    );
  }
}

/// Lokasi yang diminta, satu baris, supaya pengguna tahu apa yang salah.
class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      label: 'Alamat yang dibuka: $location',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BpRadius.pillAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(LucideIcons.link2, size: 14, color: c.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BpText.caption.copyWith(
                    color: c.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Angka "404" dengan wajah Bipy sebagai angka nol. Bipy naik dari balik
/// tepi kartu lalu bergoyang pelan.
class _PeekArt extends StatefulWidget {
  const _PeekArt();

  @override
  State<_PeekArt> createState() => _PeekArtState();
}

class _PeekArtState extends State<_PeekArt> with TickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  late final Animation<double> _riseCurve = CurvedAnimation(
    parent: _rise,
    curve: Curves.easeOutBack,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (BpMotion.reduced(context)) {
      _idle.stop();
      _rise.value = 1;
      return;
    }
    if (!_idle.isAnimating) _idle.repeat();
    if (_rise.status == AnimationStatus.dismissed) _rise.forward();
  }

  @override
  void dispose() {
    _rise.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const digit = _Digit();
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: _PeekCard._artHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Transform.rotate(angle: -0.1, child: digit),
            ClipRect(
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[_rise, _idle]),
                builder: (context, child) {
                  final t = _idle.value * 2 * math.pi;
                  final dy =
                      (1 - _riseCurve.value) * _PeekCard._artHeight +
                      2 +
                      math.sin(t * 2) * 2 +
                      math.sin(t * 5) * 0.8;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.rotate(
                      angle: math.sin(t * 3) * 0.035,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  );
                },
                child: const AssetPicture(
                  'assets/bipy/bipy_ngintip.webp',
                  width: 146,
                  height: 134,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  showSkeleton: false,
                ),
              ),
            ),
            Transform.rotate(angle: 0.1, child: digit),
          ],
        ),
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[BpFest.festTop, BpFest.candyBottom],
        ).createShader(bounds),
        child: const Text(
          '4',
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: BpText.family,
            fontSize: 112,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
