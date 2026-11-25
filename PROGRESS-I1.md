# PROGRESS-I1 · Integrasi app + Kelopak hub (agen I1)

Milik agen I1: `lib/integration/**`, `lib/config/demo_campaign.dart`, penyambung di `lib/app/` dan
`lib/main.dart` (seminimal mungkin), `test/integration/**`, `test/shots/i1_shot_test.dart`, berkas ini.
Tidak commit (repo bersama).

## Tonggak

- [x] 0. Baca RENCANA (§3, §4, §7.4, §9, §10, §12), KEPUTUSAN, BACKLOG, PROGRESS semua agen app + hub
- [x] 1. `lib/config/demo_campaign.dart` (kampanye demo §12)
- [x] 2. `lib/integration/`: `KelopakRewardsGateway`, `BpediaKelopakHost`, pemetaan event -> Analytics + Inbox, cue suara
- [x] 3. Penyambung: rute `/hadiah/*`, tab rewards, `main.dart`, migrasi v2 saat mulai, Mode Demo (isi saldo/atur ulang)
- [x] 4. Tes ujung ke ujung `test/integration/**`
- [x] 5. analyze seluruh proyek 0 isu + `flutter test --concurrency=3` seluruh proyek lolos
- [x] 6. Tangkap layar alur utama terang/gelap, dilihat dan dinilai

## Keputusan

- Berkas: `lib/integration/{kelopak_integration,kelopak_rewards_gateway,bpedia_kelopak_host,kelopak_event_bridge}.dart`.
  `main.dart` = `runBpediaApp(routes: [shop, order, account, registerKelopakRoutes], rewardsBuilder: buildKelopakRewards, configure: attachKelopak)`.
- Penyambung minimal di berkas A/S: `AppServices.navigatorWrapper` (TransitionBuilder?, `app_services.dart`) dan
  `_frame` di `app.dart` membungkus navigator dengannya. `attachKelopak` memasang `KelopakRoot`
  (KelopakScope + KelopakNavigation lewat `router.openLocation` + refreshDay saat resume + sinkron antartab web)
  di atas navigator, jadi halaman dan lembar hub selalu menemukan scope.
- Migrasi v2: `LocalKelopakBackend.load` memindahkan `bpedia_preview_state_v1` bila dokumen v3 belum ada;
  `buildKelopakRewards` menunggu `controller.load()` saat bootstrap.
- Peristiwa: analitik + kotak masuk untuk check-in, roda, voucher promo; misi tuntas hanya analitik (kotak masuk
  lewat `missionMessage` pesanan); peristiwa terikat pesanan (redeem, gift attached/shipped/received, refund)
  tidak dicatat lagi karena `OrderRepository` sudah mencatatnya.
- Suara: cue baru `winKelopak, missionDone, pop, winJingle` di `SoundService`; `startMusic/stopMusic({asset})`
  dengan tumpukan permintaan (terakhir berbunyi). `KelopakMusic` memegang musik selama TickerMode halaman aktif.
  Cue game diputar tanpa getar (kit game sudah memberi getar).
- Tamu: saldo/voucher/hadiah 0 di port; data Kelopak tetap di perangkat (satu profil per perangkat).

## Angka terakhir (26 Nov 2026)

- `flutter analyze` seluruh bpedia-app: No issues found. `flutter test --concurrency=3` seluruh bpedia-app: 803 lolos, 0 gagal
  (termasuk 19 tes `test/integration` + 10 tangkap layar `test/shots/i1_shot_test.dart`).
- Hub setelah perbaikan kecil: `flutter analyze` 0 isu, `flutter test test/ui` 38 lolos.

## Tangkap layar (build/shots/i1_*.png)

- Putaran 1: App Flyer menutupi Beranda (perilaku benar sekali sehari; tes kini `markFlyerShown`); sel "1 voucher"
  strip dompet patah dua baris; judul tahap misi terlalu panjang (terpotong di kartu Misi zona Hadiah).
- Perbaikan: judul tahap "Skincare Animate" / "Pinkflash & Focallure"; sel strip dompet hub (H2) dirapatkan
  (gambar 20, jarak 4, padding 8/4); kartu mini check-in tamu di strip game hub menulis "Sudah klaim" -> "+1 tiap hari".
- Putaran 2: Beranda (masuk/tamu), Zona Hadiah, keranjang dengan hadiah gratis, checkout dengan potongan Kelopak,
  terang dan gelap: tanpa luapan, strip satu baris, pink hanya aksen di layar belanja.

## Perubahan di berkas agen lain (dicatat untuk orkestrator)

- A: `lib/app/app_services.dart` (+`navigatorWrapper`), `lib/services/sound/sound_service.dart` (4 cue, musik per aset),
  `test/services/sound_test.dart` (daftar cue diperbarui).
- S: `lib/app/app.dart` `_frame` memakai `navigatorWrapper`.
- H2 (repo hub): `lib/src/embed/wallet_strip.dart` (jarak sel), `lib/src/embed/game_strip.dart` (label tamu).

## Cara melanjutkan

Kerjakan tonggak yang belum dicentang dari atas; berkas yang sudah ada jangan ditulis ulang.
