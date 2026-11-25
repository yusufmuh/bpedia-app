/// Bagian bersama layar autentikasi: kepala Bipy, pemisah "atau", lembar
/// persetujuan S&K setelah masuk, dan penutup alur masuk.
library;

import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';

/// Kerangka layar autentikasi: bilah atas datar dan isi bergulir selebar
/// maksimal 480.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.title,
    this.actions = const <Widget>[],
  });

  final String? title;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: BpAppBar(title: title, divider: false, actions: actions),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BpSpace.x5,
                0,
                BpSpace.x5,
                BpSpace.x8,
              ),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kepala layar autentikasi: Bipy di atas pendar `brandTint`, judul, dan
/// keterangan.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.title,
    required this.message,
    this.art,
    this.artHeight = 120,
  });

  final String title;
  final String message;

  /// Bawaan: Bipy melambai.
  final Widget? art;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Column(
      children: <Widget>[
        SizedBox(
          height: artHeight + 16,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                bottom: 0,
                child: Container(
                  width: artHeight * 1.5,
                  height: artHeight * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        c.brandTint,
                        c.brandTint.withValues(alpha: 0),
                      ],
                      stops: const <double>[0.4, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                child:
                    art ??
                    BipySprite(
                      BipySprites.wave,
                      height: artHeight,
                      semanticLabel: 'Bipy melambai',
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BpSpace.x3),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: BpText.titleL.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: BpSpace.x1),
        Text(
          message,
          textAlign: TextAlign.center,
          style: BpText.body.copyWith(color: c.textMuted),
        ),
      ],
    );
  }
}

/// Garis pemisah berteks di tengah ("atau").
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'atau'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BpSpace.x4),
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(color: c.line, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BpSpace.x3),
            child: Text(
              label,
              style: BpText.caption.copyWith(color: c.textMuted),
            ),
          ),
          Expanded(child: Divider(color: c.line, thickness: 1)),
        ],
      ),
    );
  }
}

/// Baris teks + tautan, mis. "Belum punya akun? Daftar".
class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(prompt, style: BpText.body.copyWith(color: c.textMuted)),
        BpTappable(
          onTap: onTap,
          minWidth: 0,
          builder: (context, states) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              action,
              style: BpText.subtitle.copyWith(color: c.brandStrong),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lembar "Setujui Syarat & Ketentuan" setelah masuk. True bila disetujui.
Future<bool> showTermsConsent(BuildContext context) async {
  final services = AppScope.of(context);
  final router = services.router;
  final result = await showBpSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    useRootNavigator: true,
    builder: (sheetContext) {
      final c = sheetContext.bp;
      return BpSheet(
        title: 'Setujui Syarat & Ketentuan',
        showClose: false,
        footer: Row(
          children: <Widget>[
            Expanded(
              child: PillButton(
                label: 'Nanti saja',
                variant: PillButtonVariant.neutral,
                expand: true,
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ),
            const SizedBox(width: BpSpace.x3),
            Expanded(
              child: PillButton(
                label: 'Setuju',
                expand: true,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Sebelum lanjut, setujui Syarat & Ketentuan dan Kebijakan '
              'Privasi Bpedia Demo ya, Babes.',
              style: BpText.body.copyWith(color: c.text),
            ),
            const SizedBox(height: BpSpace.x3),
            for (final point in _consentPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: BpSpace.x2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.circleCheck,
                        size: 18,
                        color: c.success,
                      ),
                    ),
                    const SizedBox(width: BpSpace.x2),
                    Expanded(
                      child: Text(
                        point,
                        style: BpText.bodyS.copyWith(color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: BpSpace.x2,
              children: <Widget>[
                PillButton(
                  label: 'Baca S&K',
                  variant: PillButtonVariant.text,
                  size: PillButtonSize.small,
                  onPressed: () => router.go(sheetContext, const TermsRoute()),
                ),
                PillButton(
                  label: 'Baca Kebijakan Privasi',
                  variant: PillButtonVariant.text,
                  size: PillButtonSize.small,
                  onPressed: () =>
                      router.go(sheetContext, const PrivacyRoute()),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

const List<String> _consentPoints = <String>[
  'Kelopak, voucher, dan hadiah mengikuti aturan program yang tampil di app.',
  'Data akun demo hanya tersimpan di perangkat ini.',
  'Kata sandi tidak pernah disimpan atau dikirim.',
];

/// Menutup alur masuk/daftar: meminta persetujuan S&K bila perlu, lalu
/// menutup layar autentikasi dan membuka [next].
Future<void> finishAuthFlow(
  BuildContext context, {
  String? next,
  String? message,
}) async {
  final services = AppScope.of(context);
  if (services.auth.needsTermsAcceptance) {
    final accepted = await showTermsConsent(context);
    if (!context.mounted) return;
    if (!accepted) {
      await services.auth.signOut();
      if (!context.mounted) return;
      showAppSnack(
        context,
        'Setujui S&K dulu untuk memakai akun. Kamu tetap bisa belanja sebagai '
        'tamu.',
      );
      return;
    }
    await services.auth.acceptTerms();
    if (!context.mounted) return;
  }
  services.haptics.success();
  showAppSnack(
    context,
    message ??
        'Hai, ${services.auth.profile?.name ?? 'Babes'}! Kamu sudah masuk.',
  );
  services.router.completeLogin(context, next: next);
}
