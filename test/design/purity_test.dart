import 'dart:io';

import 'package:bpedia_app/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/design tidak mengimpor data, layanan, app, atau hub', () {
    final offenders = <String>[];
    final forbidden = RegExp(
      r'''import\s+['"](package:bpedia_app/(data|services|app|features|integration)/|package:kelopak_hub/|(\.\./)+(data|services|app|features|integration)/)''',
    );
    for (final entity in Directory('lib/design').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (forbidden.hasMatch(entity.readAsStringSync())) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('setiap BrandGlyph punya berkas mono dan warna', () {
    expect(BrandGlyph.values, hasLength(25));
    for (final glyph in BrandGlyph.values) {
      expect(File(glyph.monoAsset).existsSync(), isTrue, reason: glyph.id);
      expect(File(glyph.colorAsset).existsSync(), isTrue, reason: glyph.id);
    }
    expect(BrandGlyph.tryParse('skincare'), BrandGlyph.skincare);
    expect(BrandGlyph.tryParse('new'), BrandGlyph.newItem);
    expect(BrandGlyph.tryParse('tidak-ada'), isNull);
  });

  test('ikon warna memakai dua warna yang dipetakan untuk tema gelap', () {
    for (final glyph in BrandGlyph.values) {
      final svg = File(glyph.colorAsset).readAsStringSync().toUpperCase();
      expect(svg.contains('#B3164B'), isTrue, reason: glyph.id);
    }
  });
}
