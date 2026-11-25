# PROGRESS-F3 · Layar akun `bpedia_app` (agen F3)

Milik agen F3: `lib/features/{auth,account,address,settings,notifications,info,demo}/**`,
`lib/features/account_routes.dart`, `test/features/{auth,account,address,settings,notifications,info,demo}/**`,
`test/shots/f3_shot_test.dart`, berkas ini. Tidak commit (repo bersama).

Perintah verifikasi:

```
flutter analyze lib/features/account_routes.dart lib/features/auth lib/features/account lib/features/address lib/features/settings lib/features/notifications lib/features/info lib/features/demo test/features/auth test/features/account test/features/address test/features/settings test/features/notifications test/features/info test/features/demo test/shots/f3_shot_test.dart
flutter test --concurrency=3 test/features/auth test/features/account test/features/address test/features/settings test/features/notifications test/features/info test/features/demo
flutter test --concurrency=3 test/shots/f3_shot_test.dart   # PNG di build/shots/f3_*.png
```

## Tonggak

- [x] 0. Baca RENCANA, BRIEF, SPEC §1-4/§10-12, KEPUTUSAN, FITUR, BACKLOG, PROGRESS A/D/S, kode app/data/design, rujukan (Blibli Akun, Shopee Saya, Bpedia Login Play Store, Figma Beranda)
- [x] 1. `account_routes.dart` + bantuan UI bersama F3 (`account/account_ui.dart`)
- [x] 2. Auth: Masuk, Daftar cepat/lengkap, Lupa sandi, Ubah sandi OTP, persetujuan S&K setelah masuk
- [x] 3. Akun (tamu/masuk, ringkasan pesanan, dompet Kelopak, menu) + Profil
- [x] 4. Buku alamat + formulir alamat (tambah/ubah/hapus/utama, mode pilih)
- [x] 5. Pengaturan (tema, suara, musik, getar, kurangi gerak, pengingat Roda Sabtu)
- [x] 6. Notifikasi (kotak masuk, filter, tandai dibaca, hapus)
- [x] 7. Info: Bantuan (WhatsApp Bpedia Care, FAQ), Tentang (unduh, media sosial), S&K, Privasi
- [x] 8. Mode Demo (tanggal WIB, akun, Kelopak via `DemoRewardsTools`, App Flyer, deep link, analitik, atur ulang, galeri, info build)
- [x] 9. Tes widget tiap layar (alur utama, kosong, tamu, 200% lebar 360)
- [x] 10. Tangkap layar putaran 1 (terang + gelap, 390x844 dan 360x640) dilihat + dicatat
- [x] 11. Tangkap layar putaran 2 setelah perbaikan
- [x] 12. analyze 0 isu + angka tes dicatat

## Keputusan

- Pose diam Bipy bergerak memakai `BipyPose` (milik S, `lib/app/phone_frame.dart`); sprite memakai
  `BipySprite` dari `package:kelopak_hub/kit.dart`.

- Port uji Mode Demo: `DemoRewardsTools` (`lib/features/demo/demo_rewards_tools.dart`, diekspor
  `account_routes.dart`): `grantKelopak`, `resetRewards`, `demoActions` (`DemoRewardsAction`). Adaptor
  hadiah I1 cukup mengimplementasikannya; Mode Demo memeriksa `services.rewards is DemoRewardsTools`.
- Mode pilih alamat (`AddressesRoute(selecting: true)`): ketuk kartu = `setPrimary` + kembali. Checkout
  (F2) cukup membaca `addresses.primary` setelah kembali.
- App Flyer di Mode Demo memakai pratinjau sendiri (`demo/demo_flyer.dart`) dan TIDAK memanggil
  `markFlyerShown`, supaya jatah harian Beranda tetap utuh.
- S&K setelah masuk: lembar persetujuan muncul bila `auth.needsTermsAcceptance` (masuk/daftar cepat/
  Google); "Nanti saja" = keluar lagi.
- Tes: pakai `openF3` (layar ponsel 390x844). Di 800x600 bawaan, app tampil sebagai kolom web dan
  ketukan tes meleset (lihat catatan risiko di laporan).
- Halaman dengan Bipy yang terus bergerak (BipyPose) tidak pernah "tenang": pakai `pumpFor`, bukan
  `pumpAndSettle`.

## Putaran tangkap layar (26 Nov)

80 PNG `build/shots/f3_<layar>_<390|360>_<terang|gelap>.png` (20 layar x 2 ukuran x 2 tema), dilihat lewat
lembar kontak. Rujukan: Blibli Akun (kartu profil + panel dompet, 4 ikon pesanan, menu berkelompok),
Shopee "Saya" (Pesanan Saya / Dompet Saya), layar Login Bpedia Play Store.

- Putaran 1: galat kolom Masuk tidak terlihat di gambar (tes memompa satu bingkai saja; animasi galat
  belum jalan) -> tes tangkap layar memompa dua bingkai; "Keluar" sebagai baris menu label hitam ->
  tombol pil netral "Keluar" ikon merah di bawah menu; keterangan menu terlalu panjang (2 baris) ->
  dipersingkat; tombol unduh "Google Play" patah 2 baris -> label platform dihapus; aksi kartu alamat
  rata kiri -> rata kanan; Mode Demo "+1000" -> "+1.000", platform "android" -> "Android".
- Tes 200% lebar 360 menemukan luapan: kartu kode OTP (Row -> Wrap), "Tandai dibaca" di bilah atas
  (menjadi ikon bertooltip pada huruf besar), status AppsFlyer di Mode Demo (Row -> Column).
- Putaran 2: sel dompet "senilai Rp12.800" patah di 360 -> "Rp12.800"; semua layar dilihat ulang terang,
  gelap, 360: tanpa luapan, pink hanya pada tombol utama, harga/angka aksen, lencana, status aktif.

## Angka terakhir (26 Nov 2026)

- `flutter analyze` (16 jalur F3): No issues found.
- `flutter test --concurrency=3` (7 folder tes F3 + `test/shots/f3_shot_test.dart`): 143 lolos, 0 gagal
  (63 tes widget + 80 tangkap layar).

## Cakupan fitur (riset/FITUR-BPEDIA.md, bagian F3)

| # | Fitur | Layar / aksi F3 |
|---|---|---|
| 1 | Masuk HP/email + sandi, lupa sandi, butuh bantuan | `/masuk` (validasi bentuk, sandi tidak disimpan), "Lupa kata sandi?", Bantuan dari `/lupa-sandi` |
| 2 | Masuk/daftar Google | "Masuk dengan Google (demo)" (akun contoh) |
| 3 | Masuk sebagai tamu | "Lanjut sebagai tamu"; strip tamu di Akun |
| 4 | Daftar cepat + lengkap | `/daftar` (chip cepat/lengkap), `/daftar?mode=lengkap` |
| 5 | Atur ulang sandi via email, ubah sandi OTP | `/lupa-sandi` → "Cek emailmu" (demo); `/akun/sandi` OTP tampil di layar |
| 6 | Setuju S&K setelah masuk; S&K + Privasi | Lembar persetujuan setelah masuk; `/snk`, `/privasi` |
| 16 | Buku alamat (daftar, tambah, ubah, hapus, utama) | `/akun/alamat`, `/akun/alamat/baru`, `/akun/alamat/:id`, mode pilih; tanpa peta (dicatat) |
| 19 | Pesanan per status (ringkasan) | Strip "Pesanan saya" 4 status berlencana di Akun → `/pesanan?status=` (layar milik F2) |
| 20 | Notifikasi | `/notifikasi` (saring, belum dibaca bertitik, tandai semua, geser hapus, ketuk buka rute) |
| 21 | Profil, nomor HP, ubah sandi | `/akun/profil`, `/akun/sandi` |
| 22 | Riwayat poin | Menu "Riwayat Kelopak" + sel dompet → `/hadiah/riwayat` (layar milik H2) |
| 24 | Bantuan WhatsApp CS + jam layanan | `/bantuan` (Bpedia Care, FAQ, syarat Gratis ongkir*, lapor masalah, komunitas) |
| 25 | Unduh app, media sosial | `/tentang` (Google Play, App Store, situs, Instagram, TikTok, Facebook) |
| 26 | Deep link OneLink + AppsFlyer | Mode Demo: simulasi `deep_link_value`, status AppsFlyer, log event |
| 9 | Pop-up promo | Mode Demo "Tampilkan App Flyer" (pratinjau; Beranda milik F1) |

## Cara melanjutkan

Kerjakan tonggak yang belum dicentang dari atas; berkas yang sudah ada jangan ditulis ulang.
