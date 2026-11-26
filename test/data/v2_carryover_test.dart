import 'dart:convert';

import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/storage/app_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart'
    show MemoryKeyValueStore, v2DocumentKey;

/// Kasus v2 yang dibawa ke app v3 lewat pemuatan pertama: keranjang (baris
/// produk pensiun dibuang), pengaturan suara dan tema, dan geseran kalender
/// Mode Demo.
void main() {
  const kept = 'P39A06S01000002';
  const retired = 'P00X00S09999999';

  Future<AppServices> openWithV2(Map<String, Object?> v2) async {
    final store = MemoryKeyValueStore();
    await store.write(v2DocumentKey, jsonEncode(v2));
    final services = AppServices.forTest(store: store);
    addTearDown(services.dispose);
    expect(await services.load(), DocumentOrigin.migratedV2);
    return services;
  }

  test('keranjang v2: baris produk pensiun dibuang, yang lain tetap', () async {
    final services = await openWithV2(<String, Object?>{
      'schema': 1,
      'shop': <String, Object?>{
        'cart': <Object?>[
          <String, Object?>{'productId': kept, 'qty': 2},
          <String, Object?>{'productId': retired, 'qty': 1},
        ],
      },
    });

    expect(services.catalog.byCode(retired), isNull);
    expect(services.cart.items.map((item) => item.product.code), <String>[
      kept,
    ]);
    expect(services.cart.quantityOf(kept), 2);
    expect(services.cart.allSelected, isTrue);
  });

  test('pengaturan suara dan tema v2 dipakai app v3', () async {
    final services = await openWithV2(<String, Object?>{
      'schema': 1,
      'settings': <String, Object?>{
        'themeMode': 'dark',
        'sfxEnabled': false,
        'musicEnabled': true,
        'hapticsEnabled': false,
      },
    });

    expect(services.settings.themeMode, ThemeMode.dark);
    expect(services.settings.soundOn, isFalse);
    expect(services.settings.musicOn, isTrue);
    expect(services.settings.hapticsOn, isFalse);
  });

  test('geseran kalender Mode Demo v2 menggeser hari app', () async {
    final services = await openWithV2(<String, Object?>{
      'schema': 1,
      'clockOffsetDays': 3,
    });

    expect(services.demoClock.offsetDays, 3);
    expect(services.demoClock.today, services.demoClock.realToday + 3);
    expect(services.clock.today, services.demoClock.today);
    services.demoClock.reset();
    expect(services.clock.today, services.demoClock.realToday);
  });
}
