# PROGRESS-F1 · Layar jelajah `bpedia_app` (agen F1)

Milik agen F1: `lib/features/{home,catalog,search,product,hot,event,wishlist}/**`, `lib/features/shop_routes.dart`,
`test/features/{home,catalog,search,product,hot,event,wishlist}/**`, `test/shots/f1_shot_test.dart`, berkas ini.
Tidak commit (repo bersama). Tidak menyentuh `lib/design`, `lib/data`, `lib/services`, `lib/app`.

Perintah verifikasi (hanya folder F1):

```
T="test/features/home test/features/catalog test/features/search test/features/product test/features/hot test/features/event test/features/wishlist"
flutter analyze lib/features/shop_routes.dart lib/features/home lib/features/catalog lib/features/search lib/features/product lib/features/hot lib/features/event lib/features/wishlist $T test/shots/f1_shot_test.dart
flutter test --concurrency=3 $T
flutter test --concurrency=3 test/shots/f1_shot_test.dart   # PNG di build/shots/f1_*.png
```

## Tonggak

- [x] 0. Baca RENCANA, BRIEF, KEPUTUSAN, SPEC §1-4/§10-12, FITUR, PROGRESS A/D/S, kode app/data/design, rujukan owner
- [x] 1. Bersama: `catalog/shop_common.dart` (data kartu, kartu produk bertindak, tambah keranjang, label tanggal), `shop_routes.dart`
- [x] 2. Katalog (tab) + lembar Filter + urutan + chip filter aktif + kosong/galat/memuat
- [x] 3. Cari (riwayat + saran + hasil langsung)
- [x] 4. Detail produk (galeri, harga, lencana, misi, kirim, deskripsi, info, serupa, bilah bawah, lembar jumlah)
- [x] 5. Hot Item (kartu highlight, hitung mundur, bilah kuota, halaman daftar + filter + cari)
- [x] 6. Event Promo (hub + halaman event + klaim voucher 12.12 lewat port)
- [x] 7. Wishlist
- [x] 8. Beranda (header, strip akun/dompet, carousel, pintasan 3D, strip game, pengingat bayar, Hot Item, kategori, brand, rekomendasi, kepercayaan) + App Flyer
- [x] 9. Tes widget tiap layar (alur utama, kosong, tamu, 200% lebar 360)
- [x] 10. Tangkap layar putaran 1 dilihat + dicatat
- [x] 11. Tangkap layar putaran 2 setelah perbaikan
- [x] 12. analyze 0 isu + angka tes dicatat

## Keputusan

- Navigasi hanya `AppScope.of(context).router.go(...)`; lokasi dari `promo.json` diurai dengan `parseAppRoute`.
- Katalog adalah tab: parameter dibaca dari `router.tabRoute` (`CatalogRoute`); ubah filter = `router.go(CatalogRoute(...))`
  sehingga URL web ikut berubah.
- Hot Item: hitung mundur hanya bila hari WIB ini di dalam periode `hot.start..hot.end` (akhir = 24.00 WIB hari terakhir,
  data asli); di luar itu tampil periode. Bilah kuota dari `hot.quota` dan `hot.sold` potret katalog.

## Catatan sesi 26 Nov

- Semua layar tertulis; analyze folder F1 bersih. Tes home (10) dan katalog (9) lolos.
- Putaran 1 tangkap layar (dilihat): lembar Filter/jumlah tidak tampil karena tes hanya memompa satu bingkai (perbaiki di tes);
  tombol Masuk ganda pink -> strip tamu jadi outline; flyer punya tombol "Lihat promo" ganda dengan gambar -> gambar
  menjadi tombol; intro Hot Item berantakan -> baris judul + hitung mundur; hitung mundur > 24 jam -> "Berakhir N hari lagi";
  label pintasan rapat di 360 -> padding; katalog kosong -> tambah "Mungkin kamu suka".
- PERHATIAN: `dart format lib/features` dan `dart format test/features` sempat dijalankan sekali pada seluruh folder
  (termasuk berkas F2/F3, hanya spasi). Selanjutnya format hanya folder F1.

## Putaran 2 dan angka akhir (26 Nov)

- Putaran 2 dilihat (beranda tamu terang, hot item gelap, flyer gelap, lembar filter, lembar jumlah, wishlist, event 12.12):
  perbaikan putaran 1 terlihat; tidak ada luapan. Tes 200% menemukan luapan 2,7 px di intro Hot Item -> Wrap.
- `flutter analyze` folder F1: No issues found. `flutter test --concurrency=3 $T test/shots/f1_shot_test.dart`: 91 lolos,
  0 gagal (51 tes widget/unit + 40 tangkap layar).

## Rute dan layar

| Rute | Layar | Berkas |
|---|---|---|
| `/` (tab home) | Beranda + App Flyer | `home/home_page.dart`, `home_header.dart`, `home_sections.dart`, `app_flyer.dart` |
| `/katalog?...` (tab catalog) | Katalog + lembar Filter | `catalog/catalog_page.dart`, `filter_sheet.dart`, `catalog_query_route.dart` |
| `/cari?q=` | Cari | `search/search_page.dart` |
| `/produk/:kode` | Detail produk + lembar jumlah | `product/product_page.dart`, `add_to_cart_sheet.dart` |
| `/hot-item` | Hot Item | `hot/hot_items_page.dart`, `hot_deal_view.dart` |
| `/event`, `/event/:id` | Hub Event Promo, halaman event | `event/event_hub_page.dart`, `event_page.dart` |
| `/wishlist` | Wishlist | `wishlist/wishlist_page.dart` |

## Cakupan FITUR-BPEDIA (bagian F1)

| # | Fitur | Layar/aksi |
|---|---|---|
| 7 | Kolom cari, lonceng, keranjang | Kepala Beranda dan Katalog |
| 8, 23 | Event Promo | Carousel Beranda, `/event`, `/event/:id` |
| 9 | Pop-up promo | App Flyer sekali per hari WIB; `showActiveAppFlyer` untuk Mode Demo |
| 10 | Hot Item | Rel Beranda, `/hot-item` (filter tema + cari), pita di detail |
| 11 | Daftar produk | Rekomendasi Beranda (12 per langkah) + Katalog |
| 12 | Filter kategori/brand/harga, 6 urutan | Bar alat + lembar Filter |
| 13 | Detail produk + lencana | `/produk/:kode` |
| 26 | Deep link produk/Hot Item | Rute terdaftar; pengurai milik A |

## Kebutuhan untuk agen lain

- `lib/main.dart` (S/I1): `runBpediaApp(routes: [registerShopRoutes, ...])`.
- F3 Mode Demo: `showActiveAppFlyer(context)` dari `features/shop_routes.dart`.
- D (`ProductCard`, aksi `addButton`): tombol "+ Keranjang" tidak menempel ke dasar kartu, jadi pada baris grid dengan
  tinggi isi berbeda posisinya tidak sejajar (terlihat di `f1_wishlist_terang.png`).
- `SearchField.button` menampilkan kata kunci aktif dengan warna petunjuk (abu); di katalog lebih jelas bila warna teks.

## Cara melanjutkan

Kerjakan tonggak yang belum dicentang dari atas.
