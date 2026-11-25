/// Migrasi sekali jalan dari dokumen app v2 (`bpedia_preview_state_v1`).
///
/// Hanya keranjang, pengaturan, dan geseran hari Mode Demo yang dibawa. Data
/// Kelopak dimigrasikan oleh paket `kelopak_hub`. Kunci lama tidak dihapus.
library;

import 'dart:convert';

import 'package:kelopak_hub/kelopak_hub.dart' show JsonMap;

/// Kunci penyimpanan dokumen app v2.
const String v2DocumentKey = 'bpedia_preview_state_v1';

/// Mengubah teks dokumen v2 menjadi seksi dokumen v3 (`cart`, `settings`,
/// `clock`), atau null bila [raw] kosong, rusak, atau bukan skema 1.
JsonMap? migrateV2Document(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?> || decoded['schema'] != 1) return null;
  final sections = <String, Object?>{};

  final settings = decoded['settings'];
  if (settings is Map<String, Object?>) {
    final theme = settings['themeMode'];
    sections['settings'] = <String, Object?>{
      if (theme == 'light' || theme == 'dark' || theme == 'system')
        'themeMode': theme,
      if (settings['sfxEnabled'] is bool) 'soundOn': settings['sfxEnabled'],
      if (settings['musicEnabled'] is bool) 'musicOn': settings['musicEnabled'],
      if (settings['hapticsEnabled'] is bool)
        'hapticsOn': settings['hapticsEnabled'],
    };
  }

  final shop = decoded['shop'];
  if (shop is Map<String, Object?>) {
    final cart = shop['cart'];
    if (cart is List<Object?>) {
      final lines = <Object?>[];
      for (final line in cart) {
        if (line is! Map<String, Object?>) continue;
        final productId = line['productId'];
        final qty = line['qty'];
        if (productId is String && qty is int && qty >= 1) {
          lines.add(<String, Object?>{
            'productCode': productId,
            'qty': qty,
            'selected': true,
          });
        }
      }
      sections['cart'] = <String, Object?>{'lines': lines};
    }
  }

  final offset = decoded['clockOffsetDays'];
  if (offset is int && offset > 0) {
    sections['clock'] = <String, Object?>{'offsetDays': offset};
  }
  return sections;
}
