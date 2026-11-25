/// Syarat & Ketentuan dan Kebijakan Privasi Bpedia Demo (FITUR #6). Isi
/// mengikuti aturan program di KEPUTUSAN-V3; nilai bertanda (demo) adalah
/// contoh yang masih menunggu keputusan bisnis.
library;

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import 'info_widgets.dart';

/// Keterangan berlaku dokumen.
const String legalUpdated = 'Berlaku sejak 25 Nov 2026 · versi demo';

/// Bagian Syarat & Ketentuan.
const List<ArticleSection> termsSections = <ArticleSection>[
  ArticleSection(
    title: 'Akun',
    bullets: <String>[
      'Masuk dengan nomor HP atau email, atau dengan Google (demo). Satu '
          'profil lokal untuk satu perangkat.',
      'Tamu boleh menjelajah, mencari, melihat detail produk, mengisi '
          'keranjang, dan melihat halaman game.',
      'Klaim check-in, putar roda, progres misi, checkout, Hadiahku, dan '
          'notifikasi membutuhkan akun.',
    ],
  ),
  ArticleSection(
    title: 'Kelopak',
    bullets: <String>[
      '1 Kelopak bernilai Rp100 dan hanya bisa dipakai di Bpedia.',
      'Di checkout, Kelopak memotong harga barang setelah voucher, tidak '
          'memotong ongkir, dan tidak membuat total kurang dari Rp0. Pecahan '
          'di bawah Rp100 tetap dibayar.',
      'Sakelar "Pakai Kelopak" menyala otomatis dan boleh dimatikan.',
      'Pesanan yang dibatalkan sebelum selesai mengembalikan Kelopak yang '
          'dipakai.',
    ],
  ),
  ArticleSection(
    title: 'Check-in Harian',
    bullets: <String>[
      'Klaim +1 Kelopak sekali sehari menurut tanggal WIB.',
      'Hari ke-7 beruntun mendapat bonus +3 Kelopak (7 hari = 10 Kelopak).',
      '30 hari beruntun tanpa putus mendapat 1 produk gratis.',
    ],
  ),
  ArticleSection(
    title: 'Roda Sabtu',
    bullets: <String>[
      'Satu putaran gratis tiap Sabtu (WIB) selama promo berlangsung.',
      'Hadiah berupa Kelopak atau produk gratis selama kuota tersedia. Tabel '
          'peluang dan sisa kuota tampil sebelum memutar; nilai peluang di demo '
          'ini adalah nilai contoh (demo).',
      'Hadiah produk dikirim bersama pesanan belanja berikutnya, tanpa ongkir '
          'tambahan.',
    ],
  ),
  ArticleSection(
    title: 'Misi Belanja',
    bullets: <String>[
      'Yang dihitung adalah subtotal produk misi dalam satu pesanan yang '
          'sudah selesai. Satu pesanan menyelesaikan paling banyak satu tahap.',
      'Tahap 1: produk misi minimal Rp75.000 mendapat voucher Rp10.000 untuk '
          'pesanan berikutnya minimal Rp100.000, berlaku 30 hari (demo).',
      'Tahap berikutnya terbuka setelah tahap sebelumnya selesai.',
    ],
  ),
  ArticleSection(
    title: 'Produk gratis dan voucher',
    bullets: <String>[
      'Produk gratis menunggu di keranjang sebagai baris Rp0 dan hanya bisa '
          'dikirim bersama minimal 1 produk berbayar.',
      'Bila pesanan dibatalkan, hadiah dan voucher kembali bisa dipakai.',
      'Syarat minimum voucher dihitung dari subtotal barang sebelum potongan '
          'Kelopak.',
    ],
  ),
  ArticleSection(
    title: 'Pembayaran dan pengiriman',
    paragraphs: <String>[
      'Di Bpedia Demo semua metode pembayaran adalah simulasi dan ongkir '
          'memakai tarif contoh bertanda (demo). Tidak ada uang yang berpindah '
          'dan tidak ada barang yang dikirim.',
    ],
  ),
  ArticleSection(
    title: 'Bantuan',
    paragraphs: <String>[
      'Pertanyaan tentang akun, pesanan, dan program hadiah dapat disampaikan '
          'ke Bpedia Care lewat WhatsApp ${AppConfig.whatsAppDisplay}, '
          '${AppConfig.careHours}.',
    ],
  ),
];

/// Bagian Kebijakan Privasi.
const List<ArticleSection> privacySections = <ArticleSection>[
  ArticleSection(
    title: 'Data yang disimpan',
    bullets: <String>[
      'Profil (nama, nomor HP, email), buku alamat, keranjang, wishlist, '
          'riwayat pencarian, pesanan, notifikasi, pengaturan, dan data hadiah '
          'Kelopak.',
      'Semua data itu tersimpan di perangkat ini saja dan tidak dikirim ke '
          'server Bpedia.',
    ],
  ),
  ArticleSection(
    title: 'Kata sandi',
    paragraphs: <String>[
      'Kata sandi hanya diperiksa bentuknya lalu dibuang. Kata sandi tidak '
          'pernah disimpan, dicatat, atau dikirim. Kode OTP demo ditampilkan '
          'di layar dan tidak dikirim lewat SMS atau email.',
    ],
  ),
  ArticleSection(
    title: 'Analitik',
    bullets: <String>[
      'Event penggunaan (mis. masuk, cari, tambah ke keranjang, checkout, '
          'klaim hadiah) dicatat di perangkat dan bisa dilihat di Mode Demo.',
      'AppsFlyer hanya aktif di Android dan iOS bila build menyertakan kunci '
          'AppsFlyer. Tanpa kunci, tidak ada data analitik yang keluar dari '
          'perangkat.',
    ],
  ),
  ArticleSection(
    title: 'Notifikasi',
    paragraphs: <String>[
      'Pengingat Roda Sabtu adalah notifikasi lokal yang dijadwalkan di '
          'perangkat. Izin notifikasi diminta saat kamu menyalakannya dan bisa '
          'dimatikan kapan saja di Pengaturan.',
    ],
  ),
  ArticleSection(
    title: 'Tautan luar',
    paragraphs: <String>[
      'WhatsApp, toko aplikasi, situs, dan media sosial Bpedia dibuka di '
          'aplikasi masing-masing dan mengikuti kebijakan privasi layanan itu.',
    ],
  ),
  ArticleSection(
    title: 'Menghapus data',
    paragraphs: <String>[
      'Keluar dari akun menutup sesi. Menu Mode Demo > Atur ulang data '
          'menghapus seluruh data app dan data hadiah di perangkat ini.',
    ],
  ),
];

/// Halaman Syarat & Ketentuan.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) => const ArticlePage(
    title: 'Syarat & Ketentuan',
    heading: 'Syarat & Ketentuan Bpedia Demo',
    updated: legalUpdated,
    intro:
        'Ini ketentuan untuk aplikasi demo. Ketentuan resmi Bpedia berlaku di '
        'aplikasi dan situs bpedia.id.',
    sections: termsSections,
  );
}

/// Halaman Kebijakan Privasi.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => const ArticlePage(
    title: 'Kebijakan Privasi',
    heading: 'Kebijakan Privasi Bpedia Demo',
    updated: legalUpdated,
    intro:
        'Ringkasan cara aplikasi demo memperlakukan datamu. Kebijakan resmi '
        'Bpedia berlaku di aplikasi dan situs bpedia.id.',
    sections: privacySections,
  );
}
