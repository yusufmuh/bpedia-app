/// Perlengkapan tes integrasi I1: app lengkap (tiga grup fitur + zona
/// Hadiah) di atas gateway Kelopak sungguhan dengan penyimpanan memori.
library;

import 'dart:async';
import 'dart:math';

import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/address/address_repository.dart';
import 'package:bpedia_app/features/account_routes.dart';
import 'package:bpedia_app/features/order_routes.dart';
import 'package:bpedia_app/features/shop_routes.dart';
import 'package:bpedia_app/integration/kelopak_integration.dart';
import 'package:bpedia_app/integration/kelopak_rewards_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart' show KeyValueStore;

import '../support/shot.dart';

/// Rabu, 25 Nov 2026, 10.00 WIB (bawaan `AppServices.forTest`).
final DateTime wednesday = AppServices.testNow;

/// Sabtu, 28 Nov 2026, 10.00 WIB: Roda Sabtu buka.
final DateTime saturday = DateTime.utc(2026, 11, 28, 3);

/// Produk nyata dari `assets/catalog/catalog.json`.
const String sunscreen = 'P68B13S01000010'; // Rp46.196, bukan produk misi
const String nightCream = 'P39A06S01000007'; // Rp26.000, misi tahap 1

/// Undian roda tetap: `nextInt` selalu memberi [roll] (dibatasi `max - 1`).
/// Roll 0 = hadiah produk (bobot pertama), 9999 = 1 Kelopak.
class FixedRandom implements Random {
  FixedRandom(this.roll);

  final int roll;

  @override
  int nextInt(int max) => roll < max ? roll : max - 1;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

/// Alamat contoh (data karangan).
const AddressDraft sampleAddress = AddressDraft(
  label: 'Rumah',
  recipient: 'Sinta Maharani',
  phone: '081234567890',
  street: 'Jl. Melati Raya No. 12, RT 03/RW 05',
  district: 'Cilandak',
  city: 'Jakarta Selatan',
  province: 'DKI Jakarta',
  postalCode: '12430',
);

/// Layanan app lengkap dengan gateway Kelopak. Data Kelopak belum dimuat:
/// panggil [loadKelopak].
AppServices i1Services({
  bool loggedIn = true,
  int roll = 9999,
  DateTime? now,
  KeyValueStore? store,
  bool dark = false,
  bool withAddress = true,
}) {
  final services = AppServices.forTest(
    now: now,
    store: store,
    loggedIn: loggedIn,
    rewardsBuilder: (services) => createKelopakGateway(
      services,
      random: FixedRandom(roll),
      watchDayChange: false,
    ),
  );
  for (final register in <RouteRegistrar>[
    registerShopRoutes,
    registerOrderRoutes,
    registerAccountRoutes,
    registerKelopakRoutes,
  ]) {
    register(services.router);
  }
  attachKelopak(services);
  if (loggedIn && withAddress) services.addresses.add(sampleAddress);
  services.settings.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
  addTearDown(() => unawaited(services.dispose()));
  return services;
}

/// Gateway Kelopak milik [services].
KelopakRewardsGateway gatewayOf(AppServices services) =>
    services.rewards as KelopakRewardsGateway;

/// Memuat data Kelopak (penyimpanan memori: selesai lewat mikrotugas).
Future<KelopakRewardsGateway> loadKelopak(AppServices services) async {
  final gateway = gatewayOf(services);
  await gateway.controller.load();
  return gateway;
}

/// Memasang app pada [location].
Future<void> pumpI1(
  WidgetTester tester,
  AppServices services, {
  required String location,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await loadShotFonts(tester);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    BpediaApp(services: services, initialLocation: location),
  );
  await settle(tester);
}

/// Menunggu transisi dan animasi masuk tanpa `pumpAndSettle` (Bipy dan
/// hiasan pesta bergerak terus-menerus).
Future<void> settle(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Membuka [location] lewat router app lalu menunggu transisi.
Future<void> openLocation(
  WidgetTester tester,
  AppServices services,
  String location,
) async {
  services.router.openLocation(location);
  await settle(tester);
}

/// Gulir [finder] ke dalam layar pada daftar gulir terakhir yang terlihat.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.pump();
}
