/// Kepala Beranda yang menempel (SPEC §4.1 butir 1): baris logo dengan
/// sakelar tema [K9] dan tombol Masuk atau avatar [K10] yang menyusut saat
/// digulir, lalu baris cari dengan lonceng dan keranjang yang tetap tampil.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/shell.dart' show CartButton, LoginButton, ThemeToggleButton;
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
      padding: const EdgeInsets.only(left: BpSpace.screen, right: BpSpace.x2),
      child: Row(
        children: <Widget>[
          Semantics(
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
          const Spacer(),
          const ThemeToggleButton(),
          const SizedBox(width: BpSpace.x1),
          const _AccountAction(),
        ],
      ),
    );
  }
}

/// Tombol Masuk untuk tamu, avatar inisial setelah masuk.
class _AccountAction extends StatelessWidget {
  const _AccountAction();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return ListenableBuilder(
      listenable: services.auth,
      builder: (context, _) {
        final profile = services.auth.profile;
        if (!services.auth.isLoggedIn || profile == null) {
          return const LoginButton();
        }
        return BpTappable(
          key: const ValueKey<String>('beranda-avatar'),
          onTap: () => services.router.go(context, const AccountRoute()),
          semanticLabel: 'Akun ${profile.name}',
          tooltip: 'Akun',
          builder: (context, states) => Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brandTint,
              shape: BoxShape.circle,
              border: Border.all(color: c.brandLine),
            ),
            child: Text(
              profile.initials,
              textScaler: TextScaler.noScaling,
              style: BpText.subtitle.copyWith(color: c.brandStrong),
            ),
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
      padding: const EdgeInsets.only(left: BpSpace.screen, right: BpSpace.x1),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SearchField.button(
              key: const ValueKey<String>('beranda-cari'),
              hints: hints,
              onTap: () => services.router.go(context, const SearchRoute()),
            ),
          ),
          const SizedBox(width: BpSpace.x1),
          const InboxButton(),
          const CartButton(),
        ],
      ),
    );
  }
}
