# Progres perbaikan APP-DESAIN

Lingkup: `lib/design/**`, `lib/app/**`, `test/design/**`, `test/app/**`,
`test/shots/{design,shell,app_not_found}_shot_test.dart`. Tidak di-commit.

- [x] P1-10 Tombol Hadiah: `BpSize.rewardButton` 50, `rewardLift` 12, token baru
  `rewardRing` 4; bayangan `BpShadows.candy` y2 blur8 hitam 18%; koin 32;
  label Hadiah selalu w700 `c.text` (brandStrong saat terpilih). Tab biasa
  rata atas seperti Figma (label tidak turun 1,5 dp). `shell.dart` otomatis
  memakai token baru untuk area ketuk tonjolan.
- [x] P2-20 Sakelar: mati = trek `surfaceMuted`, garis `textFaint` 2, kenop
  `textFaint`; nyala = trek `brand`, kenop putih #FFFFFF di kedua tema (G5).
  `bp_switch_tile.dart` tidak menimpa warna.
- [x] BACKLOG tombol + Keranjang ProductCard menempel ke dasar kartu
  (Column spaceBetween; tanpa batas tinggi tetap rapat).
- [x] BACKLOG hit-test kolom web (PhoneFrame): diuji di 1280 dan 1600x1040
  (kolom melayang); ketukan tab, tonjolan Hadiah, dan luar kolom tepat.
  Tidak ada cacat yang perlu diubah di kode; tes regresi ditambahkan.

Tes baru: `test/design/widgets_behavior_test.dart` (token/cincin/label Hadiah,
sakelar G5, + Keranjang sejajar), `test/app/shell_test.dart` (ketukan kolom web).
Lembar banding: `bpedia-asset-build/v3/qa/app_desain/{nav_r1,nav_r2,pengaturan_r1,kartu_r1,kartu_r2}.jpg`.
