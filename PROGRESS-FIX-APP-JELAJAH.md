# PROGRESS FIX APP-JELAJAH

Lingkup: lib/features/{home,catalog,search,product,hot,event,wishlist}, shop_routes.dart, tes terkait, test/shots/f1_shot_test.dart.

## Temuan
- [x] P1-01 hapus seksi Kategori Beranda
- [x] P1-02 Hot Item Beranda: hanya kampanye berjalan, kartu lebar
- [x] P1-03 hapus tombol Bipy mengambang
- [x] P1-04 susunan kepala Beranda
- [x] P1-05 strip tamu 56 dp
- [x] P1-07 rel kategori Katalog ubin
- [x] P1-08 event: kisi produk di bawah judul
- [x] P1-09 App Flyer CTA + petunjuk tutup
- [x] P1-11 pil hitung mundur Hot
- [x] P1-12 halaman Hot Item per kampanye
- [x] P1-13 detail produk strip Hot, thumbnail, Hemat, lencana
- [x] P1-14 bilah bawah produk
- [x] P1-15 lembar tambah keranjang
- [x] P1-16 lembar filter
- [x] P1-17 halaman event: banner, chip, detail, event lainnya, bagikan
- [x] P1-18 Beranda: event promo, baris kepercayaan, Gratis, indikator
- [x] P1-19 Brand pilihan + tab rekomendasi
- [x] P1-21 Wishlist
- [x] P1-22 shot 3 event
- [x] BL UnpaidOrderBanner di Beranda
- [x] BL lencana "Ongkir mulai 9rb"
- [x] BL animasi terbang ke keranjang

## Catatan
- Beranda + Hot Item: 2 putaran banding pair_sheet selesai (home2.jpg). Tes home + hot lolos.
- Label ongkir diturunkan dari tarif kurir demo (8.000) -> "Ongkir mulai 8rb" (Figma 9rb; data app 8rb).
- Katalog, lembar filter, flyer, 3 event: shot + banding 2 putaran (kat1/kat2, ev1). Tes catalog/event/home lolos.
- Produk + lembar jumlah: banding 2 putaran (prod1/prod2). Animasi terbang (cart_flight.dart) + tes. Tersisa: P1-21 wishlist, README/CHANGELOG, verifikasi akhir.
- Wishlist: banding 2 putaran (wl1/wl2). Mode Atur hapus massal + chip kategori + ikon cari.
- Akhir: flutter analyze repo 0 isu; tes lingkup (7 folder fitur + f1_shot_test) 123 lolos.
- Dilewati: bilah bawah tab Akun di Wishlist (rute di luar shell, berkas app/shell di luar lingkup); README/CHANGELOG (di luar lingkup berkas agen ini).
