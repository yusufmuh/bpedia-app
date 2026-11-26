/// Kepala Beranda yang menempel (SPEC §4.1 butir 1): baris logo dengan
/// tombol Masuk tamu [K10], sakelar tema [K9], lonceng, dan keranjang yang
/// menyusut saat digulir, lalu kolom cari selebar penuh yang tetap tampil.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/shell.dart' show CartButton, ThemeToggleButton;
import '../../design/design.dart';
import '../catalog/shop_common.dart';

/// Tinggi baris logo.
const double _brandRowHeight = 52;

/// Delegasi kepala Beranda.
class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  HomeHeaderDelegate({
    required this.topPadding,
    required this.searchRowHeight,
    required this.hints,
  });

  /// Tinggi bilah status.
  final double topPadding;

  /// Tinggi baris cari (mengikuti skala huruf).
  final double searchRowHeight;

  /// Petunjuk kolom cari yang bergantian.
  final List<String> hints;

  @override
  double get maxExtent => topPadding + _brandRowHeight + searchRowHeight;

  @override
  double get minExtent => topPadding + searchRowHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final c = context.bp;
    final collapse = (shrinkOffset / _brandRowHeight).clamp(0.0, 1.0);
    final brandHeight = _brandRowHeight * (1 - collapse);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(
            color: c.line.withValues(alpha: math.max(collapse, 0.0)),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: brandHeight,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minHeight: _brandRowHeight,
                  maxHeight: _brandRowHeight,
                  child: Opacity(
                    opacity: (1 - collapse * 1.6).clamp(0.0, 1.0),
                    child: const _BrandRow(),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: searchRowHeight,
              child: _SearchRow(hints: hints),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(HomeHeaderDelegate oldDelegate) =>
      oldDelegate.topPadding != topPadding ||
      oldDelegate.searchRowHeight != searchRowHeight ||
      oldDelegate.hints.length != hints.length;
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    final dark = context.bp.isDark;
    return Padding(
      padding: const EdgeInsets.only(left: BpSpace.screen, right: BpSpace.x1),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                label: 'Bpedia',
                header: true,
                child: AssetPicture(
                  dark
                      ? 'assets/images/logo_horizontal_reverse.webp'
                      : 'assets/images/logo_horizontal.webp',
                  height: 36,
                  width: 84,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  showSkeleton: false,
                ),
              ),
            ),
          ),
          const _GuestLogin(),
          const ThemeToggleButton(),
          const InboxButton(),
          const CartButton(),
        ],
      ),
    );
  }
}

/// Tombol Masuk pil tint untuk tamu; hilang setelah masuk (akun lewat tab
/// Akun).
class _GuestLogin extends StatelessWidget {
  const _GuestLogin();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.auth,
      builder: (context, _) {
        if (services.auth.isLoggedIn) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: BpSpace.x1),
          child: PillButton(
            key: const ValueKey<String>('beranda-kepala-masuk'),
            label: 'Masuk',
            size: PillButtonSize.small,
            variant: PillButtonVariant.tonal,
            onPressed: () => services.router.go(context, const LoginRoute()),
          ),
        );
      },
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.hints});

  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
      child: Center(
        child: SearchField.button(
          key: const ValueKey<String>('beranda-cari'),
          hints: hints,
          onTap: () => services.router.go(context, const SearchRoute()),
        ),
      ),
    );
  }
}
