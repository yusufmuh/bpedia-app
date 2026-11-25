# PROGRESS-S · Kerangka aplikasi `bpedia_app` (agen S)

Milik agen S: `lib/app/{app.dart,shell.dart,phone_frame.dart,not_found_page.dart}`, `lib/main.dart`,
`test/app/shell_*`, `test/shots/shell_shot_test.dart`, berkas ini. Tidak commit (repo bersama).

Perintah verifikasi:

```
flutter analyze lib/main.dart lib/app/app.dart lib/app/shell.dart lib/app/phone_frame.dart lib/app/not_found_page.dart test/app/shell_test.dart test/shots/shell_shot_test.dart
flutter test --concurrency=3 test/app/shell_test.dart
flutter test --concurrency=3 test/shots/shell_shot_test.dart   # PNG di build/shots/shell_*.png
```

## Tonggak

- [x] 0. Baca RENCANA, BRIEF, SPEC §1-4/§11, PROGRESS-A/D, kode `lib/app` + `lib/design`, rujukan owner
- [x] 1. `phone_frame.dart` (kolom 430 di lebar > 520, latar bermerek)
- [x] 2. `not_found_page.dart` (404 berdesain, Bipy ngintip)
- [x] 3. `shell.dart` (AppShell, tab malas, lencana, halaman pengganti tab, aksi bilah atas)
- [x] 4. `app.dart` (BpediaApp, transisi halaman, lokal id_ID) + `main.dart`
- [x] 5. Tes shell (tab, kembali, rute tak dikenal, lebar 360/390/1280)
- [x] 6. Tangkap layar putaran 1 dilihat + dicatat
- [x] 7. Tangkap layar putaran 2 setelah perbaikan
- [x] 8. analyze 0 isu + angka tes dicatat

## Keputusan

- Kode tonggak 1-4 sudah ada di disk (sesi 25 Nov); 26 Nov: analyze 7 berkas milik S = 0 isu
  (perbaikan: `TickerMode.valuesOf`, impor tak terpakai).
- Tes menggantung 10 menit: `addTearDown(services.dispose)` menunggu I/O sungguhan di jam palsu
  testWidgets. Diganti `addTearDown(() => unawaited(services.dispose()))` di kedua berkas tes S.
- 26 Nov 02.50: repo bersama TIDAK bisa dikompilasi karena berkas agen lain sedang berubah:
  `lib/data/orders/order_repository.dart` (A) bentrok nama `CheckoutQuote` dengan ekspor baru
  `kelopak_hub` (H1); `bpedia-roda-sabtu/lib/roda_sabtu.dart` mengekspor berkas yang sudah dihapus;
  `bpedia-misi-belanja/.../voucher_card.dart` memakai parameter `background` yang tidak ada.
  Bukan berkas S, jadi tidak disentuh. Verifikasi S memakai salinan di
  `C:/Users/Yusuf/coding/_verify-s/` (app + 4 repo saudara) dengan tambalan lokal minimal
  (`hide CheckoutQuote`, buang ekspor yang hilang, buang argumen `background/foreground`).
  Salin ulang berkas tes S ke sana setelah mengubahnya.

- Putaran 1 (dilihat): cahaya radial di belakang Bipy terpotong jadi persegi (Stack memotong ke
  lebar gambar) -> `_PoseStage` lebar penuh + `Clip.none`. Transisi: dua halaman buram bertumpuk
  di bingkai tengah, teks campur aduk -> pola pudar-tembus (lama pudar keluar 0-35 %, baru geser
  16 % + pudar masuk 30-100 %).
- Putaran 2 (dilihat): di bingkai tengah transisi tampak abu/hitam di belakang navigator ->
  `ColoredBox(c.canvas)` di belakang navigator (di dalam PhoneFrame). Ubin Akun mencampur ikon
  garis dan ikon 3D -> tiga ikon 3D (Saldo Kelopak, Voucher Saya, Hadiah Saya).
- Putaran 3: transisi bersih, 404/terang/gelap/360/tablet/web 1280/1600 dinilai baik.
- Angka terakhir (salinan verifikasi, 26 Nov): `shell_test` + `shell_shot_test` = 54 lolos, 0 gagal;
  analyze 7 berkas S = 0 isu. PNG: `C:/Users/Yusuf/coding/_verify-s/bpedia-app/build/shots/shell_*.png`.

## Cara fitur mendaftar

- Halaman: `router.register<ProductRoute>((context, route) => ProductPage(code: route.code));`
- Tab: `router.registerTab(AppTab.home, (context) => const HomePage());` (tab tanpa pendaftaran
  menampilkan `TabPlaceholderPage`). Pakai `PrimaryScrollController` agar ketuk tab aktif = gulir ke atas.
- Sambungkan di `main.dart`: `runBpediaApp(routes: [registerShopRoutes, ...], configure: ..., rewardsBuilder: ...)`.
- Bilah atas fitur: `ThemeToggleButton()`, `CartButton()`, `LoginButton(next: ...)` dari `lib/app/shell.dart`;
  tema lewat `AppScope.of(context).settings.toggleTheme(brightness)` / `setThemeMode`.

## Cara melanjutkan

Semua tonggak selesai. Setelah repo bersama bisa dikompilasi lagi (bentrok `CheckoutQuote` A/H1
beres), jalankan ulang perintah verifikasi di repo asli.
