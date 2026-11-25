# PROGRESS-A · agen A (data, layanan, inti app)

Cakupan: `lib/app/{app_routes,app_router,app_services,app_scope}.dart`, `lib/config/**`, `lib/data/**`,
`lib/services/**`, `lib/platform/**`, `test/{app,data,services}/**`, konfigurasi native plugin.
Tidak commit (repo bersama). Tidak menyentuh `lib/design`, `lib/main.dart`, `lib/features`.

## Tonggak

- [x] T1 Fondasi: `config/app_config.dart`, `platform/browser*.dart`, `data/storage/*` (dokumen `bpedia_app_v3`, migrasi v2), `data/wib_dates.dart`
- [x] T2 Katalog + promo (aset JSON), pengiriman, metode bayar
- [x] T3 Repositori: pengaturan, jam demo, auth, alamat, wishlist, riwayat cari, kotak masuk, keranjang
- [x] T4 Port hadiah (`rewards_gateway.dart`, `NoRewardsGateway`) + `OrderRepository`
- [x] T5 Layanan: analitik (AppsFlyer bersyarat), suara + getar, pengingat, tautan
- [x] T6 Inti app: rute, router, `AppServices` (bootstrap + forTest), `AppScope`
- [x] T7 Konfigurasi native Android/iOS (manifest, desugaring, receiver, keep.xml ikon notifikasi, Info.plist, AppDelegate)
- [x] T8 Tes menyeluruh + analyze bersih + tangkap layar halaman 404 bawaan (256 tes lolos: test/app, test/data, test/services)

Catatan 25 Nov malam: semua tonggak selesai. `flutter analyze` foldermu 0 isu; `flutter test --concurrency=3 test/app test/data test/services` = 256 lolos, 0 gagal. Halaman 404 bawaan dirender terang + gelap (`test/shots/app_not_found_shot_test.dart` -> `build/shots/app_404_bawaan_{terang,gelap}.png`) dan sudah dilihat: rapi, tanpa luapan.

Belum diverifikasi di sini (di luar wewenang agen A): build Android/iOS/web sungguhan (orkestrator), AppsFlyer dengan kunci asli, notifikasi di perangkat.

## Keputusan penting

- Dokumen tunggal `bpedia_app_v3` berisi seksi per repositori; seksi rusak diatur ulang sendiri, dokumen rusak total → mulai bersih.
- Simpan tertunda 300 ms di perangkat; `AppServices.forTest` memakai tunda nol (mikrotugas, tanpa Timer) supaya aman di `testWidgets`.
- Katalog dan promo di `forTest` dibaca sinkron dari berkas aset (impor bersyarat `dart:io`), jadi `AppServices.forTest()` sinkron.
- Gateway hadiah dipasang lewat `rewardsBuilder` (I1); bawaan `NoRewardsGateway`.
- Event analitik yang dicatat lapisan data: `af_login`, `af_complete_registration`, `af_add_to_cart`, `af_add_to_wishlist`, `af_search`, `af_purchase`, `bp_kelopak_redeem`, `bp_voucher_redeem`, `bp_gift_attached`. Layar mencatat `af_content_view` dan `af_initiated_checkout`.
- Ongkir dan metode bayar bertanda demo; dompet digital satu entri (nama dompet tidak ada di sumber publik).

## Tes layanan (test/services)

- `analytics_test.dart`: LocalAnalytics (200 event, urutan, pendengar), bentuk parameter event belanja, CompositeAnalytics, `createAppsFlyerAnalytics` per platform.
- `appsflyer_analytics_test.dart`: `AppsFlyerSdk.private` + kanal tiruan: urutan mulai SDK 7, sesi-siap, deep link, kegagalan tidak melempar.
- `sound_test.dart`: cue vs berkas aset, gerbang Suara/Getar/Musik, jeda minimum, Haptics.
- `reminders_test.dart`: `nextOccurrenceUtc`, layanan memori/noop, `LocalReminderService` lewat kanal plugin tiruan (jadwal Sabtu 09.00 Asia/Jakarta, tidak eksak, izin ditolak, ketukan).
- `links_test.dart`: WhatsApp CS, toko app per platform, hanya https, galat platform menjadi false.

## Cara melanjutkan

Kerjakan tonggak yang belum dicentang dari atas. Verifikasi:
`flutter analyze lib/app lib/config lib/data lib/services lib/platform test/app test/data test/services`
`flutter test --concurrency=3 test/app test/data test/services`
