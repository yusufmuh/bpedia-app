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

/// Topik bantuan (ubin "Pilih topik").
enum HelpTopic {
  rewards('Kelopak & hadiah', LucideIcons.gift),
  orders('Pesanan & kirim', LucideIcons.truck),
  payment('Cara bayar', LucideIcons.creditCard),
  returns('Retur & refund', LucideIcons.rotateCcw),
  account('Akun', LucideIcons.circleUserRound);

  const HelpTopic(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Tanya-jawab Bantuan.
const List<FaqItem> helpFaq = <FaqItem>[
  FaqItem(
    'Apa itu Kelopak?',
    'Kelopak adalah poin hadiah Bpedia. 1 Kelopak bernilai Rp100. Kumpulkan '
        'dari Check-in Harian dan Roda Sabtu, lalu pakai untuk memotong harga '
        'barang saat checkout.',
    topic: HelpTopic.rewards,
  ),
  FaqItem(
    'Bagaimana memakai Kelopak saat checkout?',
    'Sakelar "Pakai Kelopak" menyala otomatis di checkout. Kelopak hanya '
        'memotong harga barang, bukan ongkir, dan total tidak pernah kurang '
        'dari Rp0. Kalau pesanan dibatalkan, Kelopak dikembalikan.',
    topic: HelpTopic.rewards,
  ),
  FaqItem(
    'Kapan produk gratis dari hadiah dikirim?',
    'Produk gratis dari Roda Sabtu atau Check-in hari ke-30 masuk ke '
        'keranjang sebagai baris Rp0 dan dikirim bersama pesanan belanja '
        'berikutnya, tanpa ongkir tambahan. Tambahkan minimal 1 produk berbayar '
        'supaya hadiahmu bisa ikut dikirim.',
    topic: HelpTopic.orders,
  ),
  FaqItem(
    'Apa syarat Gratis ongkir*?',
    'Tanda bintang berarti gratis ongkir mengikuti promo yang sedang berlaku '
        'di app Bpedia (wilayah, kurir, dan minimal belanja bisa berbeda). Di '
        'Bpedia Demo, ongkir dihitung dengan tarif contoh bertanda (demo).',
    topic: HelpTopic.orders,
  ),
  FaqItem(
    'Apakah pembayaran di Bpedia Demo sungguhan?',
    'Tidak. QRIS, transfer bank, gerai, dompet digital, dan COD di demo ini '
        'hanya simulasi. Tidak ada uang yang berpindah.',
    topic: HelpTopic.payment,
  ),
  FaqItem(
    'Kenapa harus masuk untuk main game hadiah?',
    'Klaim check-in, putar roda, progres misi, checkout, dan notifikasi '
        'butuh akun supaya Kelopak dan hadiahmu tercatat. Tamu tetap bisa '
        'jelajah, cari, dan mengisi keranjang.',
    topic: HelpTopic.account,
  ),
  FaqItem(
    'Apakah kata sandi saya disimpan?',
    'Tidak. Akun di Bpedia Demo hanya tersimpan di perangkat ini dan kata '
        'sandi tidak pernah disimpan atau dikirim.',
    topic: HelpTopic.account,
  ),
  FaqItem(
    'Bagaimana cara melacak pesanan?',
    'Buka tab Transaksi lalu pilih pesananmu. Statusnya tampil di sana: '
        'Menunggu pembayaran, Dikemas, Dikirim, atau Selesai. Di Bpedia Demo '
        'pengiriman hanya simulasi.',
    topic: HelpTopic.orders,
  ),
  FaqItem(
    'Bagaimana cara mengajukan retur atau refund?',
    'Chat Bpedia Care lewat WhatsApp dan sertakan nomor pesanan serta foto '
        'produk. Tim akan menjelaskan langkah berikutnya. Di Bpedia Demo tidak '
        'ada barang dikirim dan tidak ada uang yang berpindah.',
    topic: HelpTopic.returns,
  ),
  FaqItem(
    'Bagaimana cara mengubah alamat pengiriman?',
    'Buka Akun > Alamat untuk menambah, mengubah, atau memilih alamat utama. '
        'Saat checkout kamu juga bisa memilih alamat lain.',
    topic: HelpTopic.account,
  ),
];

/// Tanya-jawab yang cocok dengan [query] (judul atau jawaban) dan [topic].
List<FaqItem> filterFaq(
  List<FaqItem> items, {
  String query = '',
  HelpTopic? topic,
}) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  return <FaqItem>[
    for (final item in items)
      if ((topic == null || item.topic == topic) &&
          words.every(
            (word) =>
                item.question.toLowerCase().contains(word) ||
                item.answer.toLowerCase().contains(word),
          ))
        item,
  ];
}

/// Halaman Bantuan ("Pusat bantuan").
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _search = TextEditingController();
  final GlobalKey _faqKey = GlobalKey(debugLabel: 'help-faq');
  HelpTopic? _topic;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _chooseTopic(HelpTopic topic) {
    setState(() => _topic = _topic == topic ? null : topic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _faqKey.currentContext;
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: BpMotion.reduced(context)
            ? Duration.zero
            : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _chat(BuildContext context, [String? message]) => openExternal(
    context,
    () => message == null
        ? AppScope.of(context).links.openWhatsAppCare()
        : AppScope.of(context).links.openWhatsAppCare(message),
    fallback:
        'WhatsApp belum bisa dibuka. Hubungi ${AppConfig.whatsAppDisplay}.',
  );

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final faq = filterFaq(helpFaq, query: _search.text, topic: _topic);
    final lastOrder = services.auth.isLoggedIn && !services.orders.isEmpty
        ? services.orders.orders.first
        : null;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(title: 'Pusat bantuan'),
      bottomNavigationBar: StickyBottomBar(
        child: PillButton(
          label: 'Chat CS WhatsApp',
          icon: const BrandIcon(BrandGlyph.chat, size: 20),
          expand: true,
          onPressed: () => _chat(context),
        ),
      ),
      body: ListView(
        cacheExtent: 4000,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Hai, Babes!',
                                style: BpText.bodyS.copyWith(
                                  color: c.brandStrong,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Semantics(
                                header: true,
                                child: Text(
                                  'Ada yang bisa kami bantu?',
                                  style: BpText.titleL.copyWith(color: c.text),
                                ),
                              ),
                              const SizedBox(height: BpSpace.x1),
                              Text(
                                'Bpedia Care siap membantu lewat WhatsApp, '
                                '${AppConfig.careHours}.',
                                style: BpText.bodyS.copyWith(
                                  color: c.textMuted,
                                ),
                              ),
                              const SizedBox(height: BpSpace.x2),
                              PillButton(
                                label: 'Chat Bpedia Care',
                                variant: PillButtonVariant.outline,
                                size: PillButtonSize.small,
                                icon: const BrandIcon(
                                  BrandGlyph.chat,
                                  size: 18,
                                ),
                                onPressed: () => _chat(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: BpSpace.x2),
                        const BipyPose(
                          'assets/bipy/bipy_pose_host.webp',
                          height: 120,
                        ),
                      ],
                    ),
                    const SizedBox(height: BpSpace.x3),
                    SearchField(
                      key: const ValueKey<String>('help-search'),
                      controller: _search,
                      hint: 'Cari bantuan, mis. lacak pesanan',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (lastOrder != null)
            Section(
              header: const SectionHeader(title: 'Bantuan pesanan terakhir'),
              inset: true,
              child: InfoRow(
                label: lastOrder.items.isEmpty
                    ? 'Pesanan ${lastOrder.id}'
                    : lastOrder.items.first.name,
                helper: '${lastOrder.id} \u00b7 ${lastOrder.status.label}',
                leading: const Icon(LucideIcons.package),
                onTap: () =>
                    services.router.go(context, OrderDetailRoute(lastOrder.id)),
              ),
            ),
          Section(
            header: const SectionHeader(title: 'Pilih topik'),
            padding: const EdgeInsets.only(bottom: BpSpace.x3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final topic in HelpTopic.values)
                    Expanded(
                      child: _TopicTile(
                        topic: topic,
                        selected: _topic == topic,
                        onTap: () => _chooseTopic(topic),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Section(
            key: _faqKey,
            header: SectionHeader(
              title: _topic == null
                  ? 'Pertanyaan populer'
                  : 'Pertanyaan: ${_topic!.label}',
              actionLabel: 'Semua topik',
              onAction: _topic == null
                  ? null
                  : () => setState(() => _topic = null),
            ),
            padding: const EdgeInsets.only(bottom: BpSpace.x2),
            child: faq.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BpSpace.screen,
                      0,
                      BpSpace.screen,
                      BpSpace.x3,
                    ),
                    child: Text(
                      'Belum ada jawaban untuk "${_search.text.trim()}". '
                      'Tanya langsung ke Bpedia Care lewat WhatsApp, ya.',
                      style: BpText.bodyS.copyWith(color: c.textMuted),
                    ),
                  )
                : FaqList(items: faq),
          ),
          const Section(
            header: SectionHeader(
              title: 'Masih butuh bantuan?',
              subtitle: 'Bpedia Care, ${AppConfig.careHours}',
            ),
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
                  onTap: () => _chat(context, reportProblemMessage),
                ),
                InfoRow(
                  label: 'Syarat dan ketentuan',
                  leading: const Icon(LucideIcons.fileText),
                  onTap: () => services.router.go(context, const TermsRoute()),
                ),
                InfoRow(
                  label: 'Kebijakan privasi',
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

/// Ubin topik bantuan: ikon 48 dp dan label dua baris.
class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final HelpTopic topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      onTap: onTap,
      semanticLabel: 'Topik ${topic.label}',
      selected: selected,
      focusRadius: BpRadius.cardAll,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(vertical: BpSpace.x1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.brand : c.brandTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                topic.icon,
                size: 22,
                color: selected ? c.onBrand : c.brandStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              topic.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: BpText.caption.copyWith(
                color: selected ? c.brandStrong : c.text,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
