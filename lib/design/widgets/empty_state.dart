import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'asset_picture.dart';
import 'pill_button.dart';

/// Keadaan kosong: ilustrasi (Bipy), judul, penjelasan, dan satu aksi.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.imageAsset,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.imageSize = 132,
    this.compact = false,
  }) : assert(
         imageAsset == null || illustration == null,
         'Isi imageAsset atau illustration, bukan keduanya.',
       );

  final String title;
  final String? message;

  /// Jalur aset ilustrasi beralfa, mis. `assets/bipy/bipy_ngintip.webp`.
  final String? imageAsset;

  /// Mengganti gambar (mis. sprite Bipy atau ikon).
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final double imageSize;

  /// Versi pendek untuk di dalam seksi (padding lebih kecil).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final asset = imageAsset;
    final art = illustration;
    final body = message;
    final action = actionLabel;
    final secondary = secondaryLabel;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: BpSpace.x8,
        vertical: compact ? BpSpace.x5 : BpSpace.x8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (art != null)
            art
          else if (asset != null)
            AssetPicture(
              asset,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
              showSkeleton: false,
            ),
          if (art != null || asset != null) const SizedBox(height: BpSpace.x4),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: BpText.title.copyWith(color: c.text),
            ),
          ),
          if (body != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: BpText.body.copyWith(color: c.textMuted),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: BpSpace.x5),
            PillButton(label: action, onPressed: onAction),
          ],
          if (secondary != null) ...<Widget>[
            const SizedBox(height: BpSpace.x1),
            PillButton(
              label: secondary,
              onPressed: onSecondary,
              variant: PillButtonVariant.text,
              size: PillButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}
