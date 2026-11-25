import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'brand_icon.dart';
import 'skeleton.dart';

/// Gambar aset yang didekode seukuran tampil, dengan kerangka saat memuat
/// dan ikon tas pudar saat gagal.
class AssetPicture extends StatelessWidget {
  const AssetPicture(
    String this.asset, {
    super.key,
    this.package,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheWidth,
    this.borderRadius,
    this.semanticLabel,
    this.showSkeleton = true,
  }) : image = null;

  const AssetPicture.provider(
    ImageProvider this.image, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheWidth,
    this.borderRadius,
    this.semanticLabel,
    this.showSkeleton = true,
  }) : asset = null,
       package = null;

  /// Jalur aset, mis. `assets/catalog/img/P39A06S01000021-1.webp`.
  final String? asset;
  final String? package;
  final ImageProvider? image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  /// Lebar dekode dalam piksel fisik. Bawaan: [width] × rasio piksel, atau
  /// lebar layar bila [width] tidak diberi.
  final int? cacheWidth;
  final BorderRadius? borderRadius;

  /// `null` = dekoratif.
  final String? semanticLabel;

  /// Matikan untuk gambar beralfa (maskot, logo) supaya tidak ada kotak abu.
  final bool showSkeleton;

  /// Membulatkan ke kelipatan 64 supaya ukuran berdekatan berbagi cache.
  static int bucket(double physicalWidth) =>
      ((physicalWidth / 64).ceil() * 64).clamp(64, 2048);

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final logicalWidth = width ?? MediaQuery.sizeOf(context).width;
    final decodeWidth = cacheWidth ?? bucket(logicalWidth * ratio);
    final source = image ?? AssetImage(asset!, package: package);
    final reduce = BpMotion.reduced(context);

    Widget picture = Image(
      image: ResizeImage.resizeIfNeeded(decodeWidth, null, source),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      excludeFromSemantics: true,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        final loaded = frame != null;
        return Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            if (!loaded && showSkeleton)
              const Positioned.fill(child: Skeleton(radius: 0)),
            AnimatedOpacity(
              opacity: loaded ? 1 : 0,
              duration: reduce ? Duration.zero : BpMotion.standard,
              curve: BpMotion.standardCurve,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: c.surfaceMuted,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(BpSpace.x2),
                  child: BrandIcon(
                    BrandGlyph.bag,
                    size: 32,
                    color: c.textFaint.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final radius = borderRadius;
    if (radius != null) {
      picture = ClipRRect(borderRadius: radius, child: picture);
    }
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: picture);
    return Semantics(image: true, label: label, child: picture);
  }
}
