/// Potongan baris yang dipakai bersama keranjang, checkout, dan pesanan:
/// gambar barang, baris hadiah gratis (Rp0), kepala seksi hadiah, dan pose
/// Bipy yang melayang.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';

/// Gambar barang persegi beradius 10 dengan border tipis.
class LineThumb extends StatelessWidget {
  const LineThumb({super.key, required this.asset, this.size = 72});

  /// Jalur aset gambar; null menampilkan ikon tas pudar.
  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final path = asset;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BpRadius.tileAll,
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? Center(
              child: BrandIcon(
                BrandGlyph.bag,
                size: size * 0.4,
                color: c.textFaint,
              ),
            )
          : AssetPicture(path, width: size, height: size),
    );
  }
}

/// Kepala seksi "Hadiah gratis" beraksen `goldTint`.
class GiftSectionHeader extends StatelessWidget {
  const GiftSectionHeader({super.key, required this.count, this.subtitle});

  final int count;

  /// Keterangan di bawah judul, mis. "Ikut dikirim, tanpa ongkir tambahan".
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final sub = subtitle;
    return Semantics(
      header: true,
      child: Container(
        color: c.goldTint,
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.screen,
          vertical: BpSpace.x3,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const AssetPicture(
                'assets/icons3d/hadiah.webp',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                showSkeleton: false,
              ),
            ),
            const SizedBox(width: BpSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Hadiah gratis ($count)',
                    style: BpText.subtitle.copyWith(color: c.onGoldTint),
                  ),
                  if (sub != null)
                    Text(
                      sub,
                      style: BpText.caption.copyWith(color: c.onGoldTint),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu hadiah produk gratis: tanpa centang dan tanpa stepper, lencana
/// "Gratis", harga Rp0, dan asal hadiah.
class GiftTile extends StatelessWidget {
  const GiftTile({
    super.key,
    required this.name,
    required this.sourceLabel,
    this.imageAsset,
    this.normalPrice,
    this.status,
    this.onTap,
    this.thumbSize = 64,
  });

  final String name;

  /// Asal hadiah, mis. "Roda Sabtu, 22 Nov".
  final String sourceLabel;
  final String? imageAsset;

  /// Harga normal produk untuk harga coret; null bila tidak diketahui.
  final int? normalPrice;

  /// Chip status di kanan atas (detail pesanan), mis. "Ikut dikirim".
  final Widget? status;
  final VoidCallback? onTap;
  final double thumbSize;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final chip = status;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BpSpace.screen,
        vertical: BpSpace.x3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LineThumb(asset: imageAsset, size: thumbSize),
          const SizedBox(width: BpSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BpText.bodyS.copyWith(color: c.text),
                ),
                const SizedBox(height: BpSpace.x1),
                Text(
                  sourceLabel,
                  style: BpText.caption.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: BpSpace.x1),
                Wrap(
                  spacing: BpSpace.x2,
                  runSpacing: BpSpace.x1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    const StatusChip(label: 'Gratis', tone: StatusTone.gold),
                    PriceText(0, strikePrice: normalPrice),
                    ?chip,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final tap = onTap;
    return MergeSemantics(
      child: Semantics(
        label: 'Hadiah gratis',
        child: tap == null ? row : InkWell(onTap: tap, child: row),
      ),
    );
  }
}

/// Pose diam Bipy yang melayang pelan (gabungan tiga gelombang sinus) dan
/// masuk dengan pegas. Berhenti di tempat saat gerak dikurangi.
class FloatingBipy extends StatefulWidget {
  const FloatingBipy({
    super.key,
    required this.pose,
    this.height = 140,
    this.semanticLabel,
  });

  /// Nama pose di `assets/bipy/bipy_<pose>.webp`, mis. `pose_belanja`.
  final String pose;
  final double height;
  final String? semanticLabel;

  @override
  State<FloatingBipy> createState() => _FloatingBipyState();
}

class _FloatingBipyState extends State<FloatingBipy>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool? _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = BpMotion.reduced(context);
    if (reduced == _reduced) return;
    _reduced = reduced;
    if (reduced) {
      _idle.stop();
      _enter.value = 1;
    } else {
      _idle.repeat();
      if (_enter.value == 0) _enter.forward();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = AssetPicture(
      'assets/bipy/bipy_${widget.pose}.webp',
      height: widget.height,
      fit: BoxFit.contain,
      showSkeleton: false,
      semanticLabel: widget.semanticLabel,
    );
    return SizedBox(
      height: widget.height + 12,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_idle, _enter]),
        builder: (context, child) {
          final t = _idle.value * 2 * math.pi;
          final dy =
              math.sin(t) * 4 +
              math.sin(t * 2 + 1.3) * 1.5 +
              math.sin(t * 3) * 0.8;
          final tilt = math.sin(t + 0.6) * 0.025;
          final enter = Curves.elasticOut.transform(_enter.value);
          return Transform.translate(
            offset: Offset(0, dy + (1 - enter) * 24),
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(
                scale: 0.85 + 0.15 * enter,
                child: Opacity(
                  opacity: _enter.value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: image,
      ),
    );
  }
}

/// Chip "Produk misi" berikon bendera.
class MissionChip extends StatelessWidget {
  const MissionChip({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: 'Produk misi',
      tone: StatusTone.gold,
      icon: Icon(LucideIcons.flag, size: 12, color: context.bp.onGoldTint),
    );
  }
}
