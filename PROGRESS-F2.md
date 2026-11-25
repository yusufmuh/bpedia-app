# PROGRESS-F2 · Layar transaksi `bpedia_app` (agen F2)

Milik agen F2: `lib/features/{cart,checkout,payment,orders}/**`, `lib/features/order_routes.dart`,
`test/features/{cart,checkout,payment,orders}/**`, `test/shots/f2_shot_test.dart`, berkas ini.
Tidak commit (repo bersama). Tidak menyentuh `lib/design`, `lib/data`, `lib/services`, `lib/app`.

Perintah verifikasi:

```
flutter analyze lib/features/order_routes.dart lib/features/cart lib/features/checkout lib/features/payment lib/features/orders test/features/cart test/features/checkout test/features/payment test/features/orders test/shots/f2_shot_test.dart
flutter test --concurrency=3 test/features/cart test/features/checkout test/features/payment test/features/orders
flutter test --concurrency=3 test/shots/f2_shot_test.dart   # PNG di build/shots/f2_*.png
```

## Tonggak

- [x] 0. Baca RENCANA, BRIEF, KEPUTUSAN, SPEC §1-4/§10-12, FITUR, REF-ECOM, PROGRESS A/D/S, kode app/data/design
- [x] 1. `order_routes.dart` + bersama (baris hadiah, gambar baris, format)
- [x] 2. Keranjang (`/keranjang`) [K17]
- [x] 3. Checkout (`/checkout`) [K16] + lembar voucher + lembar metode bayar
- [x] 4. Pembayaran simulasi (`/bayar/:id`) + layar sukses (`/pesanan/:id/sukses`)
- [x] 5. Transaksi (tab `orders`, `/pesanan?status=`) + detail pesanan (`/pesanan/:id`) + `UnpaidOrderBanner`
- [x] 6. Tes widget tiap layar (alur utama, kosong, tamu, 200% lebar 360)
- [x] 7. Tangkap layar putaran 1 (terang + gelap, 390x844 dan 360x640) dilihat + dicatat
- [x] 8. Tangkap layar putaran 2 setelah perbaikan
- [x] 9. analyze 0 isu + angka tes dicatat

## Keputusan

- Alamat checkout = `addresses.primary`. Ubah alamat membuka `AddressesRoute(selecting: true)` milik F3;
  kontrak yang diasumsikan: memilih alamat di sana menjadikannya alamat utama lalu kembali.
- Tamu: keranjang boleh diisi; tombol Checkout lewat `router.go(CheckoutRoute)` yang mengalihkan ke `/masuk?lanjut=/checkout`.

## Putaran 1 (26 Nov, dilihat)

- Baris harga + stepper keranjang dan baris produk checkout tidak rata kanan (Wrap menyusut) -> lebar penuh.
- Opsi kurir gratis menulis "Gratis" dua kali -> satu label.
- Baris voucher "Pilih voucher" padahal ada voucher terkunci -> "Belum memenuhi syarat".
- Garis waktu menunggu bayar mengulang "Menunggu pembayaran" -> langkah 2 "Pembayaran diterima" (belum).
- Konfeti sukses meledak di atas ringkasan -> asal di hero; judul app bar "Pesanan berhasil".
- Daftar transaksi pendek menyisakan ruang kosong -> rekomendasi di akhir daftar.
- Kepala kartu pesanan meluap 3 px pada 200%/360 (tes) -> Wrap.
- Catatan lingkungan: `build/unit_test_assets` basi (sprite hub tidak ada) -> `flutter pub get --offline`
  (pubspec.lock hanya berubah versi paket path 2.0.0 -> 3.0.0) dan hapus `AssetManifest.bin` agar dibangun ulang.

## Putaran 2 (26 Nov, dilihat)

Dilihat ulang: keranjang 390/360 terang+gelap, checkout panjang + 360 + lunas Kelopak, bayar QRIS, sukses,
transaksi 390/360, transaksi tamu/kosong, detail panjang. Harga dan stepper rata kanan, ongkir gratis satu label,
garis waktu bersih, konfeti di hero, tidak ada luapan. Keadaan tamu/kosong Transaksi diberi rekomendasi supaya
tidak ada ruang kosong mati. Pink hanya di CTA, harga, status aktif, centang.

## Angka terakhir (26 Nov 2026)

- analyze folder F2 (perintah di atas): No issues found.
- `flutter test --concurrency=3 test/features/cart test/features/checkout test/features/payment test/features/orders test/shots/f2_shot_test.dart`:
  70 lolos, 0 gagal (11 keranjang, 10 checkout, 8 pembayaran, 13 transaksi/detail/banner, 28 tangkap layar).

## Rute dan layar

| Rute | Layar | Berkas |
|---|---|---|
| `/keranjang` | Keranjang [K17] | `cart/cart_page.dart` |
| `/checkout` | Checkout [K16] + lembar voucher + lembar metode bayar | `checkout/checkout_page.dart`, `checkout/widgets/*` |
| `/bayar/:id` | Pembayaran simulasi (QRIS contoh, VA/gerai demo, COD) | `payment/payment_page.dart` |
| `/pesanan/:id/sukses` | Layar sukses (centang, konfeti, ringkasan) | `payment/order_success_page.dart` |
| tab `orders` `/pesanan?status=` | Transaksi bertab status | `orders/orders_page.dart` |
| `/pesanan/:id` | Detail pesanan + garis waktu + kontrol DEMO + batal | `orders/order_detail_page.dart` |
| (widget) | `UnpaidOrderBanner` untuk Beranda (F1) | ekspor `order_routes.dart` |

## Cakupan fitur (FITUR-BPEDIA)

| # | Fitur | Di mana |
|---|---|---|
| 14 | Keranjang: centang, pilih semua, jumlah, hapus (+urung), total, Checkout | `/keranjang` |
| 15 | Hadiah reward di keranjang dan checkout | seksi "Hadiah gratis" keranjang, checkout, detail |
| 16 | Alamat (pakai/ubah dari checkout) | checkout -> `AddressesRoute(selecting)` / `AddressFormRoute` (layar F3) |
| 17 | Kurir + ongkir demo | checkout "Pengiriman" |
| 18 | QRIS, VA 8 bank, gerai, dompet digital, COD (simulasi) | lembar metode bayar, `/bayar/:id` |
| 19 | Transaksi per status, belum dibayar di Beranda, detail | tab Transaksi, `UnpaidOrderBanner`, `/pesanan/:id` |

## Kebutuhan untuk agen lain

- F1: pasang `UnpaidOrderBanner()` (impor `features/order_routes.dart`) di Beranda butir 6.
- F3: `AddressesRoute(selecting: true)` sebaiknya menjadikan alamat yang dipilih sebagai alamat utama lalu kembali
  (checkout memakai `addresses.primary`).
- main.dart (S/I1): tambah `registerOrderRoutes` ke `runBpediaApp(routes: ...)`.
- I1: `CompletionResult.celebrate(context)` dipanggil dari detail/daftar setelah "Pesanan diterima"; gateway hub
  dipakai lewat `RewardsGateway` saja. Layar sukses memakai `ConfettiBurst` dari `package:kelopak_hub/kit.dart`.

## Cara melanjutkan

Kerjakan tonggak yang belum dicentang dari atas. Periksa `git status` dan berkas di folder milik F2.
