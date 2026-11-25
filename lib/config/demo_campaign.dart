/// Kampanye Kelopak demo (RENCANA §12, KEPUTUSAN §1–§4).
///
/// Semua angka di berkas ini bertanda (demo): nilai contoh yang harus
/// diputuskan bisnis sebelum rilis. Peluang roda memakai `demoSpinConfig`
/// modul Roda Sabtu (Produk gratis 5% selama kuota ada, 10 Kelopak 5%,
/// 5 Kelopak 15%, 3 Kelopak 30%, 1 Kelopak 45%; kuota habis → 1 Kelopak).
library;

import 'package:kelopak_hub/kelopak_hub.dart'
    show KelopakCampaign, KelopakPolicy, MissionStage;

import '../data/catalog/product.dart';

/// Produk Animate skincare yang dihitung di Misi Belanja tahap 1.
const List<String> demoMissionStage1Codes = <String>[
  'P39A06S01000021',
  'P39A06S01000044',
  'P39A06S01000089',
  'P39A06S01000003',
  'P39A06S01000007',
  'P39A06S01000032',
  'P39A06S01000046',
  'P39A06S01000090',
  'P39A06S01000091',
  'P39A06S01000002',
];

/// Brand yang semua produknya dihitung di Misi Belanja tahap 2.
const Set<String> demoMissionStage2Brands = <String>{'Pinkflash', 'Focallure'};

/// Hadiah produk Roda Sabtu, bergilir tiap pekan.
const List<String> demoWheelProductCodes = <String>[
  'P21P03C01000082',
  'P21F02C01000031',
  'P21P03C01000171',
  'P21P03C01000189',
];

/// Kuota hadiah produk Roda Sabtu per pekan.
const int demoWheelQuota = 3;

/// Hadiah produk Check-in Harian hari ke-30.
const String demoCheckIn30ProductCode = 'P39A06S01000089';

/// Bagian harga barang yang boleh ditutup Kelopak, dalam basis poin
/// (10000 = seluruh harga barang).
const int demoRedeemShareBp = KelopakPolicy.fullShareBp;

/// Kampanye demo di atas katalog [products]. Kode yang tidak ada di katalog
/// dibuang supaya hub tidak pernah menampilkan produk yang tidak bisa dibeli.
KelopakCampaign buildDemoCampaign(List<Product> products) {
  final known = <String>{for (final product in products) product.code};
  List<String> existing(Iterable<String> codes) =>
      List<String>.unmodifiable(codes.where(known.contains));

  final stage2Codes = existing(<String>[
    for (final product in products)
      if (demoMissionStage2Brands.contains(product.brand)) product.code,
  ]);
  return KelopakCampaign(
    policy: const KelopakPolicy(redeemShareBp: demoRedeemShareBp),
    wheelQuota: demoWheelQuota,
    wheelProductCodes: existing(demoWheelProductCodes),
    checkIn30ProductCode: known.contains(demoCheckIn30ProductCode)
        ? demoCheckIn30ProductCode
        : null,
    missionStages: <MissionStage>[
      MissionStage(
        number: 1,
        title: 'Skincare Animate',
        minOrderSubtotal: 75000,
        voucherAmount: 10000,
        voucherMinSpend: 100000,
        voucherValidDays: 30,
        productCodes: existing(demoMissionStage1Codes),
      ),
      MissionStage(
        number: 2,
        title: 'Pinkflash & Focallure',
        minOrderSubtotal: 100000,
        voucherAmount: 15000,
        voucherMinSpend: 150000,
        voucherValidDays: 30,
        productCodes: stage2Codes,
      ),
    ],
  );
}
