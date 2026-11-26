import 'package:flutter/material.dart';

/// Token warna Bpedia (SPEC-V3 §2.1). Ambil lewat `context.bp`.
///
/// Kanvas netral, pink hanya sinyal. Pasangan teks yang dijamin kontrasnya
/// (>= 4,5:1) diuji di `test/design/tokens_contrast_test.dart`.
@immutable
class BpColors extends ThemeExtension<BpColors> {
  const BpColors({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.line,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.brand,
    required this.onBrand,
    required this.brandStrong,
    required this.brandTint,
    required this.brandLine,
    required this.gold,
    required this.goldTint,
    required this.onGoldTint,
    required this.sale,
    required this.onSale,
    required this.success,
    required this.successTint,
    required this.warning,
    required this.warningTint,
    required this.danger,
    required this.dangerTint,
    required this.info,
    required this.infoTint,
    required this.scrim,
  });

  final Brightness brightness;

  /// Latar scaffold dan celah antarseksi.
  final Color canvas;

  /// Seksi, kartu, app bar, bottom nav, sheet.
  final Color surface;

  /// Kolom cari, chip netral, kerangka gambar.
  final Color surfaceMuted;

  /// Dialog, menu, kartu di atas [surface] gelap.
  final Color surfaceRaised;

  /// Garis 1 px dan border kartu produk.
  final Color line;

  final Color text;
  final Color textMuted;

  /// Harga coret dan meta di atas [surface]. Di atas [surfaceMuted] atau
  /// [canvas] pakai [textMuted].
  final Color textFaint;

  /// Isi tombol utama, ikon aktif, indikator. Untuk teks aksen pakai
  /// [brandStrong].
  final Color brand;
  final Color onBrand;

  /// Harga, angka penting, teks aksen.
  final Color brandStrong;

  /// Latar chip aktif, lencana lembut, sorotan baris.
  final Color brandTint;

  /// Border chip aktif, garis kupon.
  final Color brandLine;

  /// Dekoratif (bintang rating, koin). Bukan warna teks.
  final Color gold;
  final Color goldTint;
  final Color onGoldTint;

  /// Lencana diskon.
  final Color sale;
  final Color onSale;

  final Color success;
  final Color successTint;
  final Color warning;
  final Color warningTint;
  final Color danger;
  final Color dangerTint;
  final Color info;
  final Color infoTint;

  /// Tirai di atas gambar (penghitung carousel, pita "Stok habis"). Teks di
  /// atasnya selalu putih.
  final Color scrim;

  bool get isDark => brightness == Brightness.dark;

  static const BpColors light = BpColors(
    brightness: Brightness.light,
    canvas: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF3F3F5),
    surfaceRaised: Color(0xFFFFFFFF),
    line: Color(0xFFECECEF),
    text: Color(0xFF1F1A1D),
    textMuted: Color(0xFF6B6468),
    textFaint: Color(0xFF7A7378),
    brand: Color(0xFFD81F57),
    onBrand: Color(0xFFFFFFFF),
    brandStrong: Color(0xFFB3164B),
    brandTint: Color(0xFFFDE7EC),
    brandLine: Color(0xFFF7C6D4),
    gold: Color(0xFFF5B83D),
    goldTint: Color(0xFFFFF4DB),
    onGoldTint: Color(0xFF8A5A00),
    sale: Color(0xFFE5173F),
    onSale: Color(0xFFFFFFFF),
    success: Color(0xFF1E7A55),
    successTint: Color(0xFFE9F7F0),
    warning: Color(0xFF9E5D00),
    warningTint: Color(0xFFFFF1DC),
    danger: Color(0xFFC62828),
    dangerTint: Color(0xFFFDECEC),
    info: Color(0xFF2B68D4),
    infoTint: Color(0xFFEAF1FE),
    scrim: Color(0x99000000),
  );

  static const BpColors dark = BpColors(
    brightness: Brightness.dark,
    canvas: Color(0xFF0F0E10),
    surface: Color(0xFF1A181B),
    surfaceMuted: Color(0xFF242126),
    surfaceRaised: Color(0xFF242126),
    line: Color(0xFF2E2A30),
    text: Color(0xFFF4F0F2),
    textMuted: Color(0xFFB5ADB2),
    textFaint: Color(0xFF908A8E),
    brand: Color(0xFFFF7AA0),
    onBrand: Color(0xFF2A0A18),
    brandStrong: Color(0xFFF9A2C1),
    brandTint: Color(0xFF3B1026),
    brandLine: Color(0xFF5A1A36),
    gold: Color(0xFFF5B83D),
    goldTint: Color(0xFF3A2C0A),
    onGoldTint: Color(0xFFFFD98A),
    sale: Color(0xFFFF5C7A),
    onSale: Color(0xFF2A0A18),
    success: Color(0xFF5FD3A0),
    successTint: Color(0xFF12301F),
    warning: Color(0xFFFFB95C),
    warningTint: Color(0xFF3A2708),
    danger: Color(0xFFFF8A80),
    dangerTint: Color(0xFF3A1414),
    info: Color(0xFF8DB4FF),
    infoTint: Color(0xFF14233F),
    scrim: Color(0x99000000),
  );

  @override
  BpColors copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceRaised,
    Color? line,
    Color? text,
    Color? textMuted,
    Color? textFaint,
    Color? brand,
    Color? onBrand,
    Color? brandStrong,
    Color? brandTint,
    Color? brandLine,
    Color? gold,
    Color? goldTint,
    Color? onGoldTint,
    Color? sale,
    Color? onSale,
    Color? success,
    Color? successTint,
    Color? warning,
    Color? warningTint,
    Color? danger,
    Color? dangerTint,
    Color? info,
    Color? infoTint,
    Color? scrim,
  }) {
    return BpColors(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandStrong: brandStrong ?? this.brandStrong,
      brandTint: brandTint ?? this.brandTint,
      brandLine: brandLine ?? this.brandLine,
      gold: gold ?? this.gold,
      goldTint: goldTint ?? this.goldTint,
      onGoldTint: onGoldTint ?? this.onGoldTint,
      sale: sale ?? this.sale,
      onSale: onSale ?? this.onSale,
      success: success ?? this.success,
      successTint: successTint ?? this.successTint,
      warning: warning ?? this.warning,
      warningTint: warningTint ?? this.warningTint,
      danger: danger ?? this.danger,
      dangerTint: dangerTint ?? this.dangerTint,
      info: info ?? this.info,
      infoTint: infoTint ?? this.infoTint,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  BpColors lerp(BpColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BpColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      line: mix(line, other.line),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      textFaint: mix(textFaint, other.textFaint),
      brand: mix(brand, other.brand),
      onBrand: mix(onBrand, other.onBrand),
      brandStrong: mix(brandStrong, other.brandStrong),
      brandTint: mix(brandTint, other.brandTint),
      brandLine: mix(brandLine, other.brandLine),
      gold: mix(gold, other.gold),
      goldTint: mix(goldTint, other.goldTint),
      onGoldTint: mix(onGoldTint, other.onGoldTint),
      sale: mix(sale, other.sale),
      onSale: mix(onSale, other.onSale),
      success: mix(success, other.success),
      successTint: mix(successTint, other.successTint),
      warning: mix(warning, other.warning),
      warningTint: mix(warningTint, other.warningTint),
      danger: mix(danger, other.danger),
      dangerTint: mix(dangerTint, other.dangerTint),
      info: mix(info, other.info),
      infoTint: mix(infoTint, other.infoTint),
      scrim: mix(scrim, other.scrim),
    );
  }
}

/// Palet pesta (SPEC-V3 §2.1.3), sama di kedua tema. Di app belanja hanya
/// dipakai tombol Hadiah pada bottom nav.
abstract final class BpFest {
  static const Color festTop = Color(0xFFFF8FB1);
  static const Color festMid = Color(0xFFF0447A);
  static const Color festBottom = Color(0xFFB3164B);
  static const Color festDeep = Color(0xFF6B1439);
  static const Color festCream = Color(0xFFFFF6E9);
  static const Color goldLight = Color(0xFFFFE08A);
  static const Color gold = Color(0xFFF5B83D);
  static const Color goldDeep = Color(0xFFC98A0A);
  static const Color candyTop = Color(0xFFFF6B98);
  static const Color candyBottom = Color(0xFFD81F57);
  static const Color candyLip = Color(0xFF9E1242);

  static const LinearGradient candy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[candyTop, candyBottom],
  );
}

/// Grid 4 px.
abstract final class BpSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;

  /// Margin kiri-kanan layar.
  static const double screen = 16;

  /// Celah `canvas` antarseksi.
  static const double sectionGap = 8;

  /// Padding atas-bawah seksi.
  static const double section = 16;

  /// Padding dalam kartu.
  static const double card = 12;

  /// Celah antarkartu pada grid produk.
  static const double grid = 8;

  /// Margin kiri-kanan grid produk (lebih rapat dari margin layar, pola
  /// marketplace).
  static const double gridMargin = 12;

  /// Padding isi kartu produk.
  static const double cardDense = 8;
}

abstract final class BpRadius {
  static const double badge = 6;
  static const double tile = 10;
  static const double card = 12;
  static const double dialog = 20;
  static const double sheet = 24;
  static const double pill = 999;

  static const BorderRadius badgeAll = BorderRadius.all(Radius.circular(badge));
  static const BorderRadius tileAll = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

abstract final class BpSize {
  /// Target sentuh minimal.
  static const double touch = 48;
  static const double icon = 24;
  static const double iconDense = 20;
  static const double appBar = 56;
  static const double buttonLarge = 48;
  static const double buttonSmall = 40;
  static const double bottomNav = 60;

  /// Tombol Hadiah di tengah bottom nav (termasuk cincin) dan tinggi
  /// tonjolannya di atas bilah; dijaga kecil agar tidak menutupi konten.
  static const double rewardButton = 50;
  static const double rewardLift = 12;
  static const double rewardRing = 4;
}

/// Bayangan (SPEC-V3 §2.3). Tema gelap tidak memakai bayangan; pemisahnya
/// garis `line`.
abstract final class BpShadows {
  static List<BoxShadow> floating(BpColors colors) {
    if (colors.isDark) return const <BoxShadow>[];
    return const <BoxShadow>[
      BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 8),
    ];
  }

  static List<BoxShadow> stickyBar(BpColors colors) {
    if (colors.isDark) return const <BoxShadow>[];
    return const <BoxShadow>[
      BoxShadow(color: Color(0x0D000000), offset: Offset(0, -2), blurRadius: 8),
    ];
  }

  /// Tombol Hadiah yang menonjol di bottom nav.
  static const List<BoxShadow> candy = <BoxShadow>[
    BoxShadow(color: Color(0x2E000000), offset: Offset(0, 2), blurRadius: 8),
  ];
}

/// Kelas gerak (SPEC-V3 §2.4).
abstract final class BpMotion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration emphasis = Duration(milliseconds: 500);

  static const Curve microCurve = Curves.easeOut;
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasisCurve = Curves.elasticOut;

  /// Skala saat tombol ditekan.
  static const double pressScale = 0.97;

  /// `true` bila sistem atau pengaturan app meminta gerak dikurangi.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Gaya teks (SPEC-V3 §2.2). Tanpa warna: warna datang dari tema atau dari
/// `copyWith(color: context.bp.…)`.
abstract final class BpText {
  static const String family = 'Poppins';

  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle titleL = TextStyle(
    fontFamily: family,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle subtitle = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyS = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle label = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
  );

  /// Angka harga di kartu: elemen paling tebal pada kartu produk.
  static const TextStyle price = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    fontFeatures: tabular,
  );

  /// Awalan "Rp" kecil di depan angka harga.
  static const TextStyle priceUnit = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 22 / 12,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle priceL = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    fontFeatures: tabular,
  );
  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
}
