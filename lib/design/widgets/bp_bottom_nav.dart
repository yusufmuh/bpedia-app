import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'asset_picture.dart';
import 'brand_icon.dart';
import 'cart_badge_icon.dart';

/// Satu tab biasa pada [BpBottomNav].
@immutable
class BpNavItem {
  const BpNavItem({
    required this.label,
    required this.glyph,
    this.badgeCount = 0,
    this.showDot = false,
  });

  final String label;
  final BrandGlyph glyph;

  /// Lencana angka merah di kanan atas ikon.
  final int badgeCount;

  /// Titik merah tanpa angka.
  final bool showDot;

  BpNavItem copyWith({int? badgeCount, bool? showDot}) {
    return BpNavItem(
      label: label,
      glyph: glyph,
      badgeCount: badgeCount ?? this.badgeCount,
      showDot: showDot ?? this.showDot,
    );
  }
}

/// Bottom nav lima tab: dua tab kiri, tombol Hadiah bulat yang menonjol di
/// tengah, dua tab kanan.
///
/// Indeks: 0–1 = [leading], 2 = Hadiah, 3–4 = [trailing]. Tab aktif memakai
/// ikon brand berisi dan label tebal berwarna merek; tanpa pil latar.
class BpBottomNav extends StatelessWidget {
  const BpBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    this.leading = defaultLeading,
    this.trailing = defaultTrailing,
    this.rewardLabel = 'Hadiah',
    this.rewardImageAsset = 'assets/icons3d/kelopak.webp',
    this.rewardImagePackage,
    this.rewardDot = false,
  }) : assert(leading.length == 2 && trailing.length == 2),
       assert(currentIndex >= 0 && currentIndex < 5);

  static const int rewardIndex = 2;

  static const List<BpNavItem> defaultLeading = <BpNavItem>[
    BpNavItem(label: 'Beranda', glyph: BrandGlyph.home),
    BpNavItem(label: 'Katalog', glyph: BrandGlyph.bag),
  ];

  static const List<BpNavItem> defaultTrailing = <BpNavItem>[
    BpNavItem(label: 'Transaksi', glyph: BrandGlyph.transaksi),
    BpNavItem(label: 'Akun', glyph: BrandGlyph.akun),
  ];

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<BpNavItem> leading;
  final List<BpNavItem> trailing;
  final String rewardLabel;

  /// Gambar koin Kelopak 3D di dalam tombol Hadiah.
  final String rewardImageAsset;
  final String? rewardImagePackage;

  /// Titik merah pada tombol Hadiah bila ada yang bisa diklaim.
  final bool rewardDot;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    Widget tab(BpNavItem item, int index) {
      return Expanded(
        child: _NavTab(
          item: item,
          selected: currentIndex == index,
          position: index + 1,
          onTap: () => onSelected(index),
        ),
      );
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
          boxShadow: BpShadows.stickyBar(c),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: BpSize.bottomNav),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  tab(leading[0], 0),
                  tab(leading[1], 1),
                  Expanded(
                    child: _RewardTab(
                      label: rewardLabel,
                      imageAsset: rewardImageAsset,
                      imagePackage: rewardImagePackage,
                      selected: currentIndex == rewardIndex,
                      showDot: rewardDot,
                      onTap: () => onSelected(rewardIndex),
                    ),
                  ),
                  tab(trailing[0], 3),
                  tab(trailing[1], 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.position,
    required this.onTap,
  });

  final BpNavItem item;
  final bool selected;
  final int position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final reduce = BpMotion.reduced(context);
    final badge = item.badgeCount;
    final suffix = badge > 0 ? ', $badge baru' : (item.showDot ? ', baru' : '');
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${item.label}, tab $position dari 5$suffix',
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        excludeFromSemantics: true,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        splashFactory: NoSplash.splashFactory,
        highlightColor: c.surfaceMuted,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 26,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    AnimatedScale(
                      scale: selected ? 1.08 : 1,
                      duration: reduce ? Duration.zero : BpMotion.emphasis,
                      curve: selected
                          ? BpMotion.emphasisCurve
                          : BpMotion.microCurve,
                      child: BrandIcon(
                        item.glyph,
                        style: selected
                            ? BrandIconStyle.color
                            : BrandIconStyle.mono,
                        color: c.textMuted,
                      ),
                    ),
                    if (badge > 0)
                      PositionedDirectional(
                        top: -3,
                        start: 22,
                        child: CountBadge(count: badge),
                      )
                    else if (item.showDot)
                      const PositionedDirectional(
                        top: -1,
                        end: 4,
                        child: DotBadge(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: BpText.label.copyWith(
                    color: selected ? c.brandStrong : c.textMuted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _RewardTab extends StatelessWidget {
  const _RewardTab({
    required this.label,
    required this.imageAsset,
    required this.imagePackage,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final String? imagePackage;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    const size = BpSize.rewardButton;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '$label, tab 3 dari 5${showDot ? ', ada yang bisa diklaim' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Positioned(
              top: -BpSize.rewardLift,
              child: SizedBox.square(
                dimension: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: BpFest.candy,
                        border: Border.all(
                          color: c.surface,
                          width: BpSize.rewardRing,
                        ),
                        boxShadow: BpShadows.candy,
                      ),
                      child: Center(
                        child: AssetPicture(
                          imageAsset,
                          package: imagePackage,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          showSkeleton: false,
                        ),
                      ),
                    ),
                    if (showDot)
                      const PositionedDirectional(
                        top: 1,
                        end: 1,
                        child: DotBadge(size: 12),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: BpText.label.copyWith(
                    color: selected ? c.brandStrong : c.text,
                    fontWeight: FontWeight.w700,
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
