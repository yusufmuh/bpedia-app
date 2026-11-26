# Catatan perubahan

## 3.0.0

Pembangunan ulang Bpedia Demo (clean-room) dengan zona Hadiah Kelopak
dari paket `kelopak_hub`.

### Baru

- App belanja: Beranda, katalog dan pencarian, Hot Item, detail produk,
  wishlist, keranjang dengan centang dan "Urungkan", checkout (alamat,
  kurir, pembayaran simulasi, voucher, Kelopak, hadiah gratis), pesanan
  (bayar, kirim, terima, batal, beli lagi), kotak masuk, akun, alamat,
  pengaturan suara, getar, musik, dan tema.
- Zona Hadiah: Check-in Harian, Roda Sabtu, Misi Belanja, Voucherku,
  Hadiah Saya, dan riwayat Kelopak. 1 Kelopak = Rp100.
- Pengingat Roda Sabtu (Sabtu 09.00 WIB) lewat notifikasi lokal dengan ikon
  kecil tulip monokrom `ic_stat_bpedia`.
- AppsFlyer opsional lewat `--dart-define`, deep link `bpedia-demo://`.
- Mode Demo: geser kalender WIB, isi Kelopak, atur kuota dan promo roda,
  simulasi deep link, log analitik, atur ulang data.
- Data v2 dibawa saat pertama dibuka: keranjang (baris produk pensiun
  dibuang), pengaturan, geseran kalender, dan data Kelopak.

### Aturan yang dijaga

- Progres Misi Belanja di keranjang dan halaman misi hanya menghitung
  barang yang dicentang. Bila pesanan lain sudah memenuhi tahap aktif dan
  menunggu diterima, keranjang menyebut pesanan itu dan menghitung tahap
  berikutnya, tanpa menjanjikan voucher tahap aktif.
- Nomor pesanan `BP-YYMMDD-NNNN` tidak memakai ulang nomor yang tercatat di
  catatan Kelopak. Pesanan yang tercatat di Kelopak tetapi hilang dari
  dokumen app dibatalkan saat app dibuka dan Kelopak, voucher, serta
  hadiahnya kembali.
- Kabar pembatalan menyebut apa yang benar-benar dikembalikan catatan
  Kelopak.
- Mode Demo menawarkan "Kembali ke hari ini + atur ulang Kelopak" bila ada
  catatan Kelopak bertanggal sesudah hari nyata.
