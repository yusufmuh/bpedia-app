import 'package:bpedia_app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

typedef _Pair = (String name, Color foreground, Color background);

/// Pasangan teks kecil yang dipakai widget desain (>= 4,5:1).
List<_Pair> _textPairs(BpColors c) => <_Pair>[
  ('text / surface', c.text, c.surface),
  ('text / canvas', c.text, c.canvas),
  ('text / surfaceMuted', c.text, c.surfaceMuted),
  ('text / surfaceRaised', c.text, c.surfaceRaised),
  ('textMuted / surface', c.textMuted, c.surface),
  ('textMuted / canvas', c.textMuted, c.canvas),
  ('textMuted / surfaceMuted', c.textMuted, c.surfaceMuted),
  ('textFaint / surface', c.textFaint, c.surface),
  ('onBrand / brand', c.onBrand, c.brand),
  ('brandStrong / surface', c.brandStrong, c.surface),
  ('brandStrong / canvas', c.brandStrong, c.canvas),
  ('brandStrong / brandTint', c.brandStrong, c.brandTint),
  ('brandStrong / surfaceMuted', c.brandStrong, c.surfaceMuted),
  ('onGoldTint / goldTint', c.onGoldTint, c.goldTint),
  ('onSale / sale', c.onSale, c.sale),
  ('success / surface', c.success, c.surface),
  ('success / successTint', c.success, c.successTint),
  ('warning / surface', c.warning, c.surface),
  ('warning / warningTint', c.warning, c.warningTint),
  ('warning / surfaceMuted', c.warning, c.surfaceMuted),
  ('danger / surface', c.danger, c.surface),
  ('danger / dangerTint', c.danger, c.dangerTint),
  ('info / surface', c.info, c.surface),
  ('info / infoTint', c.info, c.infoTint),
  (
    'putih / scrim di atas surface',
    Colors.white,
    Color.alphaBlend(c.scrim, c.surface),
  ),
];

/// Ikon, teks besar, dan batas kontrol aktif (>= 3:1).
List<_Pair> _iconPairs(BpColors c) => <_Pair>[
  ('brand / surface', c.brand, c.surface),
  ('brand / canvas', c.brand, c.canvas),
  ('brand / brandTint', c.brand, c.brandTint),
  ('sale / surface', c.sale, c.surface),
  ('textMuted / surface', c.textMuted, c.surface),
  ('textFaint / surfaceMuted', c.textFaint, c.surfaceMuted),
  ('surface / success', c.surface, c.success),
  ('text / goldTint', c.text, c.goldTint),
];

void main() {
  for (final (name, colors) in <(String, BpColors)>[
    ('terang', BpColors.light),
    ('gelap', BpColors.dark),
  ]) {
    group('kontras tema $name', () {
      for (final (pair, foreground, background) in _textPairs(colors)) {
        test('teks $pair >= 4,5', () {
          expect(
            _contrast(foreground, background),
            greaterThanOrEqualTo(4.5),
            reason: pair,
          );
        });
      }
      for (final (pair, foreground, background) in _iconPairs(colors)) {
        test('ikon $pair >= 3', () {
          expect(
            _contrast(foreground, background),
            greaterThanOrEqualTo(3),
            reason: pair,
          );
        });
      }
    });
  }

  test('palet tombol Hadiah: putih terbaca di atas gradasi permen', () {
    expect(_contrast(Colors.white, BpFest.candyBottom), greaterThan(4.5));
    expect(_contrast(Colors.white, BpFest.candyTop), greaterThan(2.5));
  });

  test('tema membawa BpColors dan Poppins', () {
    for (final theme in <ThemeData>[BpTheme.light(), BpTheme.dark()]) {
      final colors = theme.extension<BpColors>();
      expect(colors, isNotNull);
      expect(colors!.brightness, theme.brightness);
      expect(theme.scaffoldBackgroundColor, colors.canvas);
      expect(theme.colorScheme.primary, colors.brand);
      expect(theme.textTheme.bodyMedium?.fontFamily, BpText.family);
      expect(theme.useMaterial3, isTrue);
    }
  });

  test('BpColors.lerp dan copyWith menjaga nilai', () {
    expect(
      BpColors.light.lerp(BpColors.dark, 0).surface,
      BpColors.light.surface,
    );
    expect(
      BpColors.light.lerp(BpColors.dark, 1).surface,
      BpColors.dark.surface,
    );
    expect(BpColors.light.lerp(null, 0.5), same(BpColors.light));
    final changed = BpColors.light.copyWith(brand: const Color(0xFF000000));
    expect(changed.brand, const Color(0xFF000000));
    expect(changed.surface, BpColors.light.surface);
  });

  test('format rupiah, rating, dan lencana', () {
    expect(formatRupiah(0), 'Rp0');
    expect(formatRupiah(10000), 'Rp10.000');
    expect(formatRupiah(1250000), 'Rp1.250.000');
    expect(formatRupiah(-12800), '-Rp12.800');
    expect(formatRating(5), '5,0');
    expect(formatRating(4.86), '4,9');
    expect(formatBadgeCount(7), '7');
    expect(formatBadgeCount(120), '99+');
  });
}
