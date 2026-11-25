# PROGRESS-D · Sistem desain `bpedia_app` (agen D)

Milik agen D: `lib/design/**`, `test/design/**`, `test/shots/design_shot_test.dart`, berkas ini.
Tidak commit (repo bersama). Perintah verifikasi:

```
flutter analyze lib/design test/design test/shots/design_shot_test.dart
flutter test --concurrency=3 test/design
flutter test --concurrency=3 test/shots/design_shot_test.dart   # PNG di build/shots/design_*.png
```

## Tonggak

- [x] 1. `tokens.dart` (BpColors terang/gelap, BpFest, BpSpace, BpRadius, BpShadows, BpMotion, BpSize, BpText)
- [x] 2. `theme.dart` (BpTheme.light()/dark(), `context.bp`)
- [x] 3. Widget dasar: AssetPicture, Skeleton, BrandIcon, PillButton, BpChip, StatusChip, DiscountBadge, PriceText, QtyStepper
- [x] 4. Widget tata letak: BpAppBar, SearchField, Section, SectionHeader, InfoRow, BpSwitchTile, StickyBottomBar, EmptyState, BpSheet
- [x] 5. Widget belanja: ProductCard (+ ProductCardData, ProductGrid), BannerCarousel, CartBadgeIcon, BpBottomNav
- [x] 6. `design.dart` (barrel) dan `gallery_page.dart`
- [x] 7. Tes: kontras token, skala teks 200% lebar 360, perilaku
- [x] 8. Tangkap layar putaran 1 (terang + gelap) dilihat dan dicatat
- [x] 9. Tangkap layar putaran 2 setelah perbaikan
- [x] 10. analyze 0 isu + tes lolos (angka dicatat di bawah)

## Keputusan

- Nilai token mengikuti SPEC §2.1. Empat nilai digeser sedikit karena nilai SPEC gagal aturan kontras SPEC sendiri
  (teks kecil >= 4,5:1): `textFaint` terang `#9A9398` -> `#7A7378` (3,00 -> 4,61 di `surface`), `textFaint` gelap
  `#857D82` -> `#908A8E` (4,41 -> 5,22), `warning` terang `#B26A00` -> `#9E5D00` (3,81 -> 4,69 di `warningTint`),
  `info` terang `#2F6FDE` -> `#2B68D4` (4,16 -> 4,59 di `infoTint`).
- `gold` adalah warna dekoratif (bintang rating, koin); selalu didampingi teks. Tidak dipakai sebagai warna teks.
- `brand` untuk isi tombol/ikon/indikator; teks aksen di atas `brandTint`/`surfaceMuted` memakai `brandStrong`.
- Ikon brand: satu berkas SVG per bentuk; padanan gelap dibuat dengan `ColorMapper` (garis `#FF7AA0`, isi `#5A1A36`), tanpa berkas baru.
- Widget tidak mengimpor `lib/data`, `lib/services`, `lib/app`, maupun `kelopak_hub`; format rupiah ada di `lib/design/format.dart`.
- Contoh di galeri memakai data nyata dari `assets/catalog/catalog.json` (potret 25 Nov 2026), disalin sebagai konstanta.

## Penyesuaian dari rujukan marketplace owner (REF-ECOM-A/B, 25 Nov sore)

Gambar yang dibuka: Tokopedia promo bundel (kartu produk), Tokopedia beranda (nav bawah, kepadatan), Blibli keranjang
(baris item, bilah total), Tokopedia pusat voucher (tiket), Shopee beranda, Shopee kisi produk berhadiah.
Pola yang diikuti (aset dan merek tidak ditiru):

- Kartu produk: gambar 1:1 penuh tepi; lencana diskon MENEMPEL pojok kanan atas (radius hanya kiri bawah), menggantikan
  posisi kiri atas di SPEC §4.2; tombol hati pindah ke kanan bawah gambar; pita manfaat opsional menempel kiri bawah
  gambar; nama 2 baris (tinggi selalu dicadangkan); satu baris meta setinggi tetap (rating bila ada) supaya harga
  sejajar antarkartu; harga = "Rp" kecil 12 + angka 16/700 `brandStrong` (elemen paling tebal), harga coret 12 di
  bawahnya; aksi `quickAdd` (bulat 32, bawaan SPEC) atau `addButton` (tombol "+ Keranjang" berbingkai selebar kartu,
  pola Tokopedia) atau `none` (rel Hot Item).
- Kepadatan kisi: margin sisi 12, celah 8 (`BpSpace.gridMargin`, `BpSpace.grid`); padding isi kartu 8.
- Nav bawah: 5 tab, tinggi 60, garis atas 1 px; aktif = ikon brand berisi (gaya warna) + label `brandStrong` tebal,
  tanpa pil latar; nonaktif = garis `textMuted`; lencana angka merah pil; tombol Hadiah tengah menonjol (SPEC §3).
- Tiket voucher (`VoucherTicket`, tambahan di luar daftar RENCANA): potongan kiri ±30% berisi nilai besar, garis putus
  + lubang setengah lingkaran, badan syarat 1 baris + masa berlaku, tombol kecil Klaim/Pakai di kanan; keadaan redup
  dengan alasan.
- Bilah lekat: `StickyBottomBar.total` = "Total" + nominal 17/700 di kiri, tombol pil "Checkout (N)" di kanan.
- Baris keranjang: stepper pil berbingkai ringkas dengan ikon tong sampah saat jumlah 1 (`QtyStepper.onRemove`).

## Cara melanjutkan

Lihat tonggak yang belum dicentang. Semua berkas baru; tidak ada dependensi ke agen lain.
Sesi 2 (25 Nov sore): berkas sesi 1 (tokens, theme, format, 13 widget dasar/tata letak) sudah ada dan analyze bersih
setelah dua perbaikan kecil; lanjut dari InfoRow.

## Sesi 3 (25 Nov malam): verifikasi dan dua putaran tangkap layar

Keadaan awal sesi: semua berkas tonggak 1-7 sudah ada; analyze bersih, 144 tes desain lolos.

Putaran 1 (20 PNG `build/shots/design_*.png` dibuka dan dibandingkan dengan rujukan Tokopedia promo bundel,
Tokopedia beranda, Blibli keranjang). Temuan dan perbaikan:

- Nav bawah: label "Hadiah" hitam tebal saat tidak aktif bersaing dengan tab aktif -> `textMuted` 600; aktif `brandStrong` 700.
- Skala 200%: harga tanpa harga coret terpotong tombol tambah, harga coret patah jadi dua baris -> `PriceText`
  selalu satu baris dan mengecil (`FittedBox.scaleDown`), tidak pernah terpenggal.
- Skala 200%: judul `SectionHeader` terpenggal di tengah kata ("Rekome/ndasi") karena berebut lebar dengan
  "Lihat semua" -> di atas skala 1,5 tautan menjadi chevron saja (label tetap ada untuk pembaca layar).
- Skala 200%: `InfoRow` berlabel pendek terpenggal ("Vouche/r") -> di atas skala 1,5 nilai pindah ke bawah label.
- Skala 200%: tombol "+ Keranjang" terpotong elipsis -> isi tombol mengecil utuh.
- Tes tangkap layar: ikon koin di `BpSwitchTile` belum tampak di galeri terang (pudar-masuk `AssetPicture` belum
  selesai) -> jeda 400 ms sebelum simpan.

Putaran 2: semua PNG dibuat ulang dan dilihat lagi (galeri terang 2, skala 200% terang 1-2 dan gelap 2, kartu produk
gelap, nav terang dan gelap). Tidak ada luapan atau teks terpenggal; pink hanya pada tombol utama, harga, status aktif,
lencana, dan banner.

## Angka terakhir (25 Nov 2026 malam)

- `flutter analyze lib/design test/design test/shots/design_shot_test.dart`: No issues found.
- `flutter test --concurrency=3 test/design test/shots/design_shot_test.dart`: 158 lolos, 0 gagal
  (144 tes desain + 14 tes tangkap layar).

## Catatan untuk agen lain

- Impor satu pintu: `package:bpedia_app/design/design.dart`; galeri: `design/gallery_page.dart` (`DesignGalleryPage`).
- Tambahan di luar daftar RENCANA: `VoucherTicket`, `ProductGrid`/`SliverProductGrid`/`ProductRail`,
  `ProductCardSkeleton`, `BadgeIcon`/`CountBadge`/`DotBadge`, `BpBackButton`, `BpTappable`, `formatRupiah`.
- `test/support/shot.dart` tampil berubah di `git status`; bukan diubah agen D.
- Belum ada: baris item keranjang jadi (dirakit F2 dari `AssetPicture` + `PriceText` + `QtyStepper`), ubin pintasan
  ikon 3D Beranda (F1), `BipySprite` (dari `kelopak_hub/kit.dart`).
