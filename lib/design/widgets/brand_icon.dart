import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';
import '../tokens.dart';

/// 25 bentuk set ikon brand (`assets/icons/bpedia-ikon-<id>.svg`).
enum BrandGlyph {
  akun('akun'),
  bag('bag'),
  best('best'),
  bodycare('bodycare'),
  chat('chat'),
  cod('cod'),
  flash('flash'),
  fragrance('fragrance'),
  haircare('haircare'),
  home('home'),
  lashes('lashes'),
  makeup('makeup'),
  newItem('new'),
  notif('notif'),
  ongkir('ongkir'),
  original('original'),
  promo('promo'),
  reward('reward'),
  search('search'),
  skincare('skincare'),
  tips('tips'),
  tools('tools'),
  transaksi('transaksi'),
  voucher('voucher'),
  wishlist('wishlist');

  const BrandGlyph(this.id);

  /// Nama pada berkas dan pada `icon` kategori di katalog.
  final String id;

  String get colorAsset => 'assets/icons/bpedia-ikon-$id.svg';
  String get monoAsset => 'assets/icons/bpedia-ikon-$id-mono.svg';

  /// Mencari bentuk dari nama katalog, mis. `skincare`; `null` bila tidak ada.
  static BrandGlyph? tryParse(String id) {
    for (final glyph in values) {
      if (glyph.id == id) return glyph;
    }
    return null;
  }
}

enum BrandIconStyle {
  /// Garis satu warna, mengikuti [BrandIcon.color] atau `IconTheme`.
  mono,

  /// Garis berry + isi pink lembut; di tema gelap dipetakan ke padanan gelap.
  color,
}

/// Ikon dari set brand Bpedia.
class BrandIcon extends StatelessWidget {
  const BrandIcon(
    this.glyph, {
    super.key,
    this.size = BpSize.icon,
    this.style = BrandIconStyle.mono,
    this.color,
    this.semanticLabel,
  });

  final BrandGlyph glyph;
  final double size;
  final BrandIconStyle style;

  /// Warna garis untuk gaya mono. Diabaikan pada gaya warna.
  final Color? color;

  /// `null` = dekoratif.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final mono = style == BrandIconStyle.mono;
    final tint = color ?? IconTheme.of(context).color ?? c.text;
    return SvgPicture.asset(
      mono ? glyph.monoAsset : glyph.colorAsset,
      width: size,
      height: size,
      colorFilter: mono ? ColorFilter.mode(tint, BlendMode.srcIn) : null,
      colorMapper: !mono && c.isDark ? const _DarkBrandMapper() : null,
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      placeholderBuilder: (context) => SizedBox.square(dimension: size),
    );
  }
}

/// Padanan gelap ikon warna (SPEC-V3 §2.5): garis `#FF7AA0`, isi `#5A1A36`.
class _DarkBrandMapper extends ColorMapper {
  const _DarkBrandMapper();

  static const int _stroke = 0xFFB3164B;
  static const int _fill = 0xFFFCCFDD;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    return switch (color.toARGB32()) {
      _stroke => const Color(0xFFFF7AA0),
      _fill => const Color(0xFF5A1A36),
      _ => color,
    };
  }
}
