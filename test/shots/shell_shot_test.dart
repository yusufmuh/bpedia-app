import 'dart:async';

import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/shot.dart';

/// Kode produk nyata dari `assets/catalog/catalog.json`.
const String _productA = 'P68B13S01000010';
const String _productB = 'P39A06S01000007';

const Size _webWide = Size(1280, 800);
const Size _webTall = Size(1600, 1040);
const Size _tablet = Size(800, 1100);

AppServices _services(WidgetTester tester, {required bool dark}) {
  final services = AppServices.forTest();
  services.settings.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
  // dispose() menunggu I/O sungguhan yang tidak pernah selesai di jam palsu
  // testWidgets; dilepas tanpa ditunggu setelah pohon widget dibongkar.
  addTearDown(() => unawaited(services.dispose()));
  return services;
}

void main() {
  for (final dark in <bool>[false, true]) {
    final suffix = dark ? 'gelap' : 'terang';

    testWidgets('kerangka beranda $suffix', (tester) async {
      final services = _services(tester, dark: dark);
      services.cart
        ..add(_productA)
        ..add(_productB, qty: 2);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/'),
        name: 'shell_beranda_$suffix',
      );
      expect(find.text('Beranda sedang disiapkan'), findsOneWidget);
    });

    testWidgets('kerangka tab hadiah $suffix', (tester) async {
      final services = _services(tester, dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/hadiah'),
        name: 'shell_hadiah_$suffix',
      );
      expect(find.text('Zona Hadiah segera dibuka'), findsOneWidget);
    });

    testWidgets('kerangka tab katalog ponsel kecil $suffix', (tester) async {
      final services = _services(tester, dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/katalog'),
        name: 'shell_katalog_360_$suffix',
        size: shotSmallPhone,
      );
      expect(find.text('Katalog sedang disiapkan'), findsOneWidget);
    });

    testWidgets('halaman 404 $suffix', (tester) async {
      final services = _services(tester, dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/promo-rahasia/2026'),
        name: 'shell_404_$suffix',
      );
      expect(find.text('Waduh, tujuanmu nggak ada!'), findsOneWidget);
    });

    testWidgets('halaman belum tersedia $suffix', (tester) async {
      final services = _services(tester, dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/keranjang'),
        name: 'shell_belum_tersedia_$suffix',
      );
      expect(find.text('Halaman ini belum tersedia'), findsOneWidget);
    });

    testWidgets('web lebar $suffix', (tester) async {
      final services = _services(tester, dark: dark);
      services.cart.add(_productA);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/'),
        name: 'shell_web_1280_$suffix',
        size: _webWide,
        pixelRatio: 1,
      );
      expect(find.text('Beranda sedang disiapkan'), findsOneWidget);
    });

    testWidgets('web tinggi kolom melayang $suffix', (tester) async {
      final services = _services(tester, dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/hadiah'),
        name: 'shell_web_1600_$suffix',
        size: _webTall,
        pixelRatio: 1,
      );
      expect(find.text('Zona Hadiah segera dibuka'), findsOneWidget);
    });

    testWidgets('tablet $suffix', (tester) async {
      final services = _services(tester, dark: dark);
      await shot(
        tester,
        BpediaApp(services: services, initialLocation: '/akun'),
        name: 'shell_tablet_$suffix',
        size: _tablet,
        pixelRatio: 1,
      );
      expect(find.text('Akun sedang disiapkan'), findsOneWidget);
    });
  }

  testWidgets('transisi pindah halaman', (tester) async {
    final services = _services(tester, dark: false);
    await pumpShot(tester, BpediaApp(services: services, initialLocation: '/'));
    await tester.pump(const Duration(milliseconds: 900));
    services.router.openLocation('/tidak-ada');
    await tester.pump();
    await shotStrip(
      tester,
      'shell_transisi',
      frames: 8,
      step: const Duration(milliseconds: 40),
    );
    expect(find.text('Waduh, tujuanmu nggak ada!'), findsOneWidget);
  });

  testWidgets('Bipy mengintip di halaman 404', (tester) async {
    final services = _services(tester, dark: false);
    await pumpShot(tester, BpediaApp(services: services, initialLocation: '/'));
    await tester.pump(const Duration(milliseconds: 900));
    services.router.openLocation('/tidak-ada');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await shotStrip(
      tester,
      'shell_404_gerak',
      frames: 8,
      step: const Duration(milliseconds: 110),
    );
    expect(find.text('Ke Beranda'), findsOneWidget);
  });
}
