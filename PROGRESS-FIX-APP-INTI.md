# Progres perbaikan APP-INTI

Lingkup: lib/data, lib/services, lib/integration, lib/config, lib/platform,
lib/main.dart, pubspec.yaml, android, ios, web, test/data, test/services,
test/integration, test/shots/i1_shot_test.dart. Tidak di-commit.

- [x] B1-01 progres misi hanya dari baris dicentang (`CartRepository.pricedLines` = `linesForCheckout`, `BpediaKelopakHost.cartLines` dicentang saja, `setCartQuantity` mencentang). Tes: `test/integration/kelopak_order_rules_test.dart` (gagal di kode lama, lolos sesudahnya).
- [x] B1-02 petunjuk misi keranjang saat pesanan lain menunggu: "Tahap N menunggu pesanan #… diterima. Tahap N+1: …", `reached=false`, lencana Misi (`missionProductCodes`) ikut tahap berikutnya. Tangkapan `i1_keranjang_misi_menunggu_*` dibandingkan dengan Figma `keranjang` (2 putaran).
- [x] B1-03 nomor pesanan: lewati nomor yang dikenal hub (`RewardsGateway.hasOrder`) dan coba lagi saat `duplicateOrder` (maks 50); pesanan hub `placed` yang hilang dari app dibatalkan sekali saat `cancelOverdue` pertama (`reconcileRewards`); kalimat batal dari `cancelAndReport` (`CancelRefund`).
- [x] B1-04 Mode Demo: aksi gateway `return-to-today-reset` muncul bila ada catatan Kelopak bertanggal sesudah hari nyata (`recordsAfterRealToday`), `DemoClockRepository.realToday`.
- [x] R1-11 ikon kecil notifikasi `@drawable/ic_stat_bpedia` (vector tulip putih), `keep.xml`, warna aksen #D81F57.
- [x] R1-03 README.md dan CHANGELOG.md 3.0.0. LICENSE dilewati (keputusan owner; README menyebut lisensi belum ditetapkan).
- [x] R1-02 dilewati (urusan rilis orkestrator); langkah dependensi git ber-tag + pubspec_overrides dicatat di README.
- [x] BACKLOG: kasus v2 (`test/data/v2_carryover_test.dart`: keranjang pensiun, suara/tema, geseran kalender; sisanya sudah di cart_test, orders_test, account_data_test); tes ujung ke ujung roda `test/integration/wheel_spin_e2e_test.dart`.
- [x] flutter analyze bersih (0 isu); tes lingkup lolos 242/242 (test/data, test/services, test/integration, test/shots/i1_shot_test.dart). kelopak_flow_test disesuaikan dengan checkout yang kini memakai voucher terbaik otomatis (perubahan agen TRANSAKSI).
