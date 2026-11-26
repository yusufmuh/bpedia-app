# Bpedia Demo (bpedia-app)

Aplikasi belanja kecantikan Bpedia versi demo 3.0.0 dengan zona Hadiah
Kelopak: Check-in Harian, Roda Sabtu, dan Misi Belanja. 1 Kelopak = Rp100.
Maskot: Bipy. Teks layar berbahasa Indonesia; data akun, pesanan, dan
pembayaran adalah simulasi di perangkat.

## Prasyarat

- Flutter `>=3.41.0`, Dart `^3.11.0` (lihat `pubspec.yaml`).
- Android SDK untuk build APK; Xcode untuk iOS.
- Repo saudara (lihat bagian berikut).

## Susunan repo

App memakai mesin Kelopak dan zona Hadiah dari paket `kelopak_hub`, yang
membawa tiga game sebagai dependensinya:

```
00 game flutter/
  bpedia-app/            app belanja (repo ini)
  bpedia-kelopak-hub/    mesin Kelopak + Zona Hadiah (paket kelopak_hub)
  bpedia-daily-checkin/  game Check-in Harian
  bpedia-roda-sabtu/     game Roda Sabtu
  bpedia-misi-belanja/   game Misi Belanja
```

Saat ini `pubspec.yaml` merujuk hub lewat path:

```yaml
kelopak_hub:
  path: ../bpedia-kelopak-hub
```

### Rencana rilis: dependensi git ber-tag

Langkah ini dikerjakan saat rilis, bukan oleh agen pengembang:

1. Owner membuat repo `github.com/yusufmuh/bpedia-app` lalu menambahkan
   remote `origin`.
2. Setelah hub diberi tag `v3.0.0`, ganti dependensi menjadi:

   ```yaml
   kelopak_hub:
     git:
       url: https://github.com/yusufmuh/bpedia-kelopak-hub.git
       ref: v3.0.0
   ```

3. Jalankan `flutter pub get`, lalu commit `pubspec.lock` yang baru.
4. Untuk pengembangan lokal, buat `pubspec_overrides.yaml` (tambahkan ke
   `.gitignore`, jangan di-commit):

   ```yaml
   dependency_overrides:
     kelopak_hub:
       path: ../bpedia-kelopak-hub
   ```

## Perintah harian

```sh
flutter pub get
flutter analyze
flutter test --concurrency=3
```

Tes dibagi per folder (`test/data`, `test/services`, `test/integration`,
`test/features/...`, `test/shots`). Tes `test/shots` menulis tangkapan layar
untuk dibandingkan dengan rujukan desain.

## Build

### Web

```sh
flutter build web --release
```

### Android (APK rilis)

```sh
flutter build apk --release \
  --dart-define=AF_DEV_KEY=<kunci AppsFlyer> \
  --dart-define=AF_DEBUG=false
```

iOS menambahkan `--dart-define=AF_IOS_APP_ID=<ID App Store>`. Tanpa
`AF_DEV_KEY`, AppsFlyer tidak aktif dan analitik hanya dicatat di log lokal
(terlihat di Mode Demo). Kunci tidak pernah disimpan di repo.

### Tanda tangan rilis Android

`android/app/build.gradle.kts` membaca `android/key.properties` (diabaikan
git). Tanpa berkas itu, build rilis memakai kunci debug. Formatnya:

```properties
storeFile=<path berkas keystore>
storePassword=<kata sandi keystore>
keyAlias=<alias kunci>
keyPassword=<kata sandi kunci>
```

Jangan menyalin keystore atau `key.properties` ke repo, catatan, atau log.

## Deep link

Skema `bpedia-demo://` terdaftar di `AndroidManifest.xml` dan
`ios/Runner/Info.plist`. Jalurnya sama dengan rute app, mis.
`bpedia-demo://hadiah/roda` atau `bpedia-demo://produk/<kode produk>`.

Uji di Android:

```sh
adb shell am start -a android.intent.action.VIEW \
  -d "bpedia-demo://hadiah/roda" id.bpedia.preview
```

Uji di simulator iOS:

```sh
xcrun simctl openurl booted "bpedia-demo://hadiah/roda"
```

Deep link AppsFlyer (OneLink) bisa disimulasikan dari Mode Demo.

## Mode Demo

Buka `/demo` (Akun > Mode Demo). Isinya:

- Kalender WIB: maju 1 atau 7 hari, lompat ke Sabtu berikutnya, kembali ke
  hari ini. Check-in yang diklaim di tanggal geseran tetap bertanggal itu;
  bila ada catatan seperti itu, bagian Kelopak menampilkan aksi
  "Kembali ke hari ini + atur ulang Kelopak".
- Akun demo, isi saldo Kelopak, kuota dan promo Roda Sabtu.
- Simulasi deep link, status AppsFlyer, log analitik.
- Atur ulang semua data, galeri komponen desain, info build.

## Peta integrasi Kelopak

- `lib/data/rewards/rewards_gateway.dart`: port hadiah yang dikenal app
  (kutipan checkout, commit, batal, kirim, selesai, petunjuk misi).
- `lib/integration/kelopak_rewards_gateway.dart`: adaptor port itu di atas
  `KelopakController` hub.
- `lib/integration/bpedia_kelopak_host.dart`: `KelopakHost` milik app (masuk,
  router, keranjang, katalog, suara, pengingat, analitik, kotak masuk).
- `lib/integration/kelopak_integration.dart`: pembuat gateway, rute
  `/hadiah/*`, dan `KelopakRoot` di atas navigator.
- `lib/config/demo_campaign.dart`: kampanye demo (produk roda, tahap misi).
- Backend: `LocalKelopakBackend` (penyimpanan perangkat) dipakai saat ini.
  `RemoteKelopakBackend` di hub adalah titik sambung server; lihat
  `../bpedia-kelopak-hub/HANDOFF-PENGEMBANG.md`.

Aturan penting yang dijaga app:

- Progres Misi Belanja dihitung dari barang yang dicentang (satu pesanan).
  Bila pesanan lain sudah memenuhi tahap aktif dan menunggu diterima,
  keranjang tidak menjanjikan voucher tahap itu.
- Nomor pesanan `BP-YYMMDD-NNNN`. Nomor yang sudah tercatat di catatan
  Kelopak dilewati. Pesanan yang masih berjalan di catatan Kelopak tetapi
  hilang dari dokumen app dibatalkan saat app dibuka, sehingga Kelopak,
  voucher, dan hadiahnya kembali.

## Lisensi

Lisensi belum ditetapkan pemilik. Sampai ada keputusan owner, repo ini tidak
membawa berkas LICENSE dan tidak boleh dianggap berlisensi terbuka.
