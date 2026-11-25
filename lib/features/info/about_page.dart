/// Tentang (FITUR #25): identitas Bpedia, keunggulan, unduh app, situs, dan
/// media sosial resmi, plus keterangan Bpedia Demo.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../config/app_config.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';
import 'info_widgets.dart';

/// Halaman Tentang.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final links = services.links;
    final c = context.bp;
    const failed = 'Tautan belum bisa dibuka. Coba lagi sebentar, Babes.';
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(title: 'Tentang Bpedia'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: BpSpace.x6),
        children: <Widget>[
          Section(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x6,
              BpSpace.screen,
              BpSpace.x5,
            ),
            child: Column(
              children: <Widget>[
                AssetPicture(
                  c.isDark
                      ? 'assets/images/logo_wordmark_reverse.webp'
                      : 'assets/images/logo_wordmark_bipy.webp',
                  width: 200,
                  height: 84,
                  fit: BoxFit.contain,
                  showSkeleton: false,
                  semanticLabel: 'Bpedia',
                ),
                const SizedBox(height: BpSpace.x3),
                Text(
                  'Belanja kecantikan original, lebih seru bareng Bipy.',
                  textAlign: TextAlign.center,
                  style: BpText.subtitle.copyWith(color: c.text),
                ),
                const SizedBox(height: BpSpace.x1),
                Text(
                  '${AppConfig.appName} ${AppConfig.appVersion} '
                  '(${AppConfig.buildNumber})',
                  textAlign: TextAlign.center,
                  style: BpText.caption.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: BpSpace.x4),
                const _TrustRow(),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(
              title: 'Unduh aplikasi Bpedia',
              subtitle: 'Belanja dan pantau pesanan dari ponselmu.',
            ),
            inset: true,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _StoreButton(
                    label: 'Google Play',
                    icon: LucideIcons.play,
                    onTap: () => openExternal(
                      context,
                      links.openPlayStore,
                      fallback: failed,
                    ),
                  ),
                ),
                const SizedBox(width: BpSpace.x2),
                Expanded(
                  child: _StoreButton(
                    label: 'App Store',
                    icon: LucideIcons.smartphone,
                    onTap: () => openExternal(
                      context,
                      links.openAppStore,
                      fallback: failed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Ikuti Bpedia'),
            padding: const EdgeInsets.only(bottom: BpSpace.x2),
            child: Column(
              children: <Widget>[
                InfoRow(
                  label: 'Situs Bpedia',
                  helper: 'bpedia.id',
                  leading: const Icon(LucideIcons.globe),
                  onTap: () => openExternal(
                    context,
                    links.openWebsite,
                    fallback: failed,
                  ),
                ),
                InfoRow(
                  label: 'Instagram',
                  helper: '@bpedia.ofc',
                  leading: const Icon(LucideIcons.camera),
                  onTap: () => openExternal(
                    context,
                    links.openInstagram,
                    fallback: failed,
                  ),
                ),
                InfoRow(
                  label: 'TikTok',
                  helper: '@bpedia.ofc',
                  leading: const Icon(LucideIcons.music2),
                  onTap: () =>
                      openExternal(context, links.openTikTok, fallback: failed),
                ),
                InfoRow(
                  label: 'Facebook',
                  helper: 'beautypediaofc',
                  leading: const Icon(LucideIcons.thumbsUp),
                  onTap: () => openExternal(
                    context,
                    links.openFacebook,
                    fallback: failed,
                  ),
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Tentang demo ini'),
            inset: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${AppConfig.appName} adalah prototipe untuk menguji tampilan '
                  'baru dan program hadiah Kelopak: Check-in Harian, Roda '
                  'Sabtu, dan Misi Belanja. Katalog memakai potret produk '
                  'bpedia.id 25 Nov 2026. Pembayaran dan ongkir hanya '
                  'simulasi.',
                  style: BpText.body.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: BpSpace.x3),
                Wrap(
                  spacing: BpSpace.x2,
                  runSpacing: BpSpace.x2,
                  children: <Widget>[
                    PillButton(
                      label: 'Syarat & Ketentuan',
                      variant: PillButtonVariant.neutral,
                      size: PillButtonSize.small,
                      onPressed: () =>
                          services.router.go(context, const TermsRoute()),
                    ),
                    PillButton(
                      label: 'Kebijakan Privasi',
                      variant: PillButtonVariant.neutral,
                      size: PillButtonSize.small,
                      onPressed: () =>
                          services.router.go(context, const PrivacyRoute()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: BpSpace.screen),
            child: NoteBox(
              icon: LucideIcons.badgeCheck,
              message:
                  'Gratis ongkir* mengikuti promo yang berlaku di app Bpedia. '
                  'Lihat syaratnya di Bantuan.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    const items = <(BrandGlyph, String)>[
      (BrandGlyph.original, '100% Original'),
      (BrandGlyph.best, 'BPOM terverifikasi'),
      (BrandGlyph.ongkir, 'Gratis ongkir*'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final (glyph, label) in items)
          Expanded(
            child: Column(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.brandTint,
                    shape: BoxShape.circle,
                  ),
                  child: BrandIcon(
                    glyph,
                    size: 26,
                    style: BrandIconStyle.color,
                  ),
                ),
                const SizedBox(height: BpSpace.x1),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: BpText.caption.copyWith(color: c.text),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      onTap: onTap,
      semanticLabel: 'Unduh di $label',
      focusRadius: BpRadius.cardAll,
      builder: (context, states) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.x3,
          vertical: BpSpace.x2,
        ),
        decoration: BoxDecoration(
          color: c.isDark ? c.surfaceMuted : c.text,
          borderRadius: BpRadius.cardAll,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: c.isDark ? c.text : c.surface, size: 22),
            const SizedBox(width: BpSpace.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Unduh di',
                    style: BpText.caption.copyWith(
                      color: (c.isDark ? c.text : c.surface).withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: BpText.subtitle.copyWith(
                      color: c.isDark ? c.text : c.surface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
