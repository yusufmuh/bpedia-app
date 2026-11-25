/// Bantuan (FITUR #24): Bpedia Care lewat WhatsApp, jam layanan, tanya-jawab
/// (termasuk syarat "Gratis ongkir*"), komunitas, dan lapor masalah.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/phone_frame.dart' show BipyPose;
import '../../config/app_config.dart';
import '../../design/design.dart';
import '../account/account_page.dart' show communityEventId;
import 'info_widgets.dart';

/// Pesan pembuka WhatsApp untuk lapor masalah aplikasi.
const String reportProblemMessage =
    'Halo Bpedia Care, saya ingin melaporkan masalah di aplikasi Bpedia.';

/// Tanya-jawab Bantuan.
const List<FaqItem> helpFaq = <FaqItem>[
  FaqItem(
    'Apa itu Kelopak?',
    'Kelopak adalah poin hadiah Bpedia. 1 Kelopak bernilai Rp100. Kumpulkan '
        'dari Check-in Harian dan Roda Sabtu, lalu pakai untuk memotong harga '
        'barang saat checkout.',
  ),
  FaqItem(
    'Bagaimana memakai Kelopak saat checkout?',
    'Sakelar "Pakai Kelopak" menyala otomatis di checkout. Kelopak hanya '
        'memotong harga barang, bukan ongkir, dan total tidak pernah kurang '
        'dari Rp0. Kalau pesanan dibatalkan, Kelopak dikembalikan.',
  ),
  FaqItem(
    'Kapan produk gratis dari hadiah dikirim?',
    'Produk gratis dari Roda Sabtu atau Check-in hari ke-30 masuk ke '
        'keranjang sebagai baris Rp0 dan dikirim bersama pesanan belanja '
        'berikutnya, tanpa ongkir tambahan. Tambahkan minimal 1 produk berbayar '
        'supaya hadiahmu bisa ikut dikirim.',
  ),
  FaqItem(
    'Apa syarat Gratis ongkir*?',
    'Tanda bintang berarti gratis ongkir mengikuti promo yang sedang berlaku '
        'di app Bpedia (wilayah, kurir, dan minimal belanja bisa berbeda). Di '
        'Bpedia Demo, ongkir dihitung dengan tarif contoh bertanda (demo).',
  ),
  FaqItem(
    'Apakah pembayaran di Bpedia Demo sungguhan?',
    'Tidak. QRIS, transfer bank, gerai, dompet digital, dan COD di demo ini '
        'hanya simulasi. Tidak ada uang yang berpindah.',
  ),
  FaqItem(
    'Kenapa harus masuk untuk main game hadiah?',
    'Klaim check-in, putar roda, progres misi, checkout, dan notifikasi '
        'butuh akun supaya Kelopak dan hadiahmu tercatat. Tamu tetap bisa '
        'jelajah, cari, dan mengisi keranjang.',
  ),
  FaqItem(
    'Apakah kata sandi saya disimpan?',
    'Tidak. Akun di Bpedia Demo hanya tersimpan di perangkat ini dan kata '
        'sandi tidak pernah disimpan atau dikirim.',
  ),
];

/// Halaman Bantuan.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final links = services.links;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(title: 'Bantuan'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: BpSpace.x6),
        children: <Widget>[
          Section(
            padding: EdgeInsets.zero,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[c.brandTint, c.surface],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BpSpace.screen,
                  BpSpace.x4,
                  BpSpace.screen,
                  BpSpace.x4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Semantics(
                            header: true,
                            child: Text(
                              'Ada yang bisa dibantu, Babes?',
                              style: BpText.titleL.copyWith(color: c.text),
                            ),
                          ),
                          const SizedBox(height: BpSpace.x1),
                          Text(
                            'Tim Bpedia Care siap membantu lewat WhatsApp.',
                            style: BpText.bodyS.copyWith(color: c.textMuted),
                          ),
                          const SizedBox(height: BpSpace.x3),
                          PillButton(
                            label: 'Chat Bpedia Care',
                            icon: const BrandIcon(BrandGlyph.chat, size: 20),
                            onPressed: () => openExternal(
                              context,
                              links.openWhatsAppCare,
                              fallback:
                                  'WhatsApp belum bisa dibuka. Hubungi '
                                  '${AppConfig.whatsAppDisplay}.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: BpSpace.x2),
                    const BipyPose(
                      'assets/bipy/bipy_pose_host.webp',
                      height: 132,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Section(
            padding: EdgeInsets.symmetric(vertical: BpSpace.x2),
            child: Column(
              children: <Widget>[
                InfoRow(
                  label: 'WhatsApp Bpedia Care',
                  leading: Icon(LucideIcons.phone),
                  value: AppConfig.whatsAppDisplay,
                ),
                InfoRow(
                  label: 'Jam layanan',
                  leading: Icon(LucideIcons.clock),
                  helper: AppConfig.careHours,
                ),
              ],
            ),
          ),
          const Section(
            header: SectionHeader(title: 'Pertanyaan umum'),
            padding: EdgeInsets.only(bottom: BpSpace.x2),
            child: FaqList(items: helpFaq),
          ),
          Section(
            header: const SectionHeader(title: 'Lainnya'),
            padding: const EdgeInsets.only(bottom: BpSpace.x2),
            child: Column(
              children: <Widget>[
                InfoRow(
                  label: 'Gabung Komunitas WhatsApp',
                  helper: 'Info promo dan tips cantik dari Bpedia',
                  leading: const Icon(LucideIcons.usersRound),
                  onTap: () => services.router.go(
                    context,
                    const EventRoute(communityEventId),
                  ),
                ),
                InfoRow(
                  label: 'Laporkan masalah aplikasi',
                  helper: 'Lewat WhatsApp Bpedia Care',
                  leading: const Icon(LucideIcons.bug),
                  onTap: () => openExternal(
                    context,
                    () => links.openWhatsAppCare(reportProblemMessage),
                    fallback:
                        'WhatsApp belum bisa dibuka. Hubungi '
                        '${AppConfig.whatsAppDisplay}.',
                  ),
                ),
                InfoRow(
                  label: 'Syarat & Ketentuan',
                  leading: const Icon(LucideIcons.fileText),
                  onTap: () => services.router.go(context, const TermsRoute()),
                ),
                InfoRow(
                  label: 'Kebijakan Privasi',
                  leading: const Icon(LucideIcons.shieldCheck),
                  onTap: () =>
                      services.router.go(context, const PrivacyRoute()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
