/// Lupa kata sandi (FITUR #5): email → "Cek emailmu" (demo, tidak ada email
/// yang dikirim).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/phone_frame.dart' show BipyPose;
import '../../data/auth/auth_repository.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';
import 'auth_flow.dart';

/// Layar lupa kata sandi.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _email = TextEditingController();
  String? _error;
  String? _sentTo;
  String? _note;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final auth = AppScope.of(context).auth;
    setState(() => _busy = true);
    final result = await auth.requestPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.errorFor(AuthField.email);
      if (result.ok) {
        _sentTo = _email.text.trim().toLowerCase();
        _note = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final router = AppScope.of(context).router;
    final sentTo = _sentTo;
    if (sentTo != null) {
      return AuthScaffold(
        title: 'Lupa kata sandi',
        children: <Widget>[
          const SizedBox(height: BpSpace.x4),
          const _BadgedBipy(
            asset: 'assets/bipy/bipy_pose_semangat.webp',
            icon: LucideIcons.mail,
            height: 128,
            semanticLabel: 'Bipy dengan amplop email',
          ),
          const SizedBox(height: BpSpace.x3),
          Semantics(
            header: true,
            child: Text(
              'Cek emailmu, Babes',
              textAlign: TextAlign.center,
              style: BpText.titleL.copyWith(color: c.text),
            ),
          ),
          const SizedBox(height: BpSpace.x1),
          Text.rich(
            TextSpan(
              text: 'Kalau terdaftar, tautan atur ulang kata sandi dikirim ke ',
              children: <InlineSpan>[
                TextSpan(
                  text: maskEmail(sentTo),
                  style: BpText.body.copyWith(
                    color: c.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: '. Buka tautannya untuk membuat kata sandi baru.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: BpText.body.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: BpSpace.x5),
          PillButton(
            label: 'Kembali ke Masuk',
            expand: true,
            onPressed: () => router.replace(context, const LoginRoute()),
          ),
          const SizedBox(height: BpSpace.x2),
          PillButton(
            label: 'Kirim ulang tautan',
            variant: PillButtonVariant.text,
            expand: true,
            onPressed: () => setState(() => _sentTo = null),
          ),
          const SizedBox(height: BpSpace.x2),
          AuthLinkRow(
            prompt: 'Email tidak masuk?',
            action: 'Hubungi CS',
            onTap: () => router.go(context, const HelpRoute()),
          ),
          const SizedBox(height: BpSpace.x4),
          const NoteBox(
            tone: StatusTone.info,
            message:
                'Belum ada di kotak masuk? Periksa folder spam atau promosi, '
                'dan pastikan alamat email yang kamu isi benar.',
          ),
          const SizedBox(height: BpSpace.x3),
          NoteBox(
            icon: LucideIcons.shieldCheck,
            title: 'Mode demo',
            message: _note ?? LocalAuthRepository.demoNote,
          ),
        ],
      );
    }
    return AuthScaffold(
      title: 'Lupa kata sandi',
      children: <Widget>[
        const SizedBox(height: BpSpace.x2),
        const _BadgedBipy(
          asset: 'assets/bipy/bipy_ngintip.webp',
          icon: LucideIcons.lock,
          height: 112,
          semanticLabel: 'Bipy dengan gembok',
        ),
        const SizedBox(height: BpSpace.x3),
        Semantics(
          header: true,
          child: Text(
            'Atur ulang kata sandi',
            textAlign: TextAlign.center,
            style: BpText.titleL.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: BpSpace.x1),
        Text(
          'Tenang, Babes. Masukkan email akunmu, kami kirim tautan untuk '
          'membuat kata sandi baru.',
          textAlign: TextAlign.center,
          style: BpText.body.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: BpSpace.x6),
        LabeledField(
          fieldKey: const ValueKey<String>('forgot-email'),
          label: 'Email',
          controller: _email,
          hint: 'nama@email.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const <String>[AutofillHints.email],
          errorText: _error,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: BpSpace.x5),
        PillButton(
          label: 'Kirim tautan',
          expand: true,
          busy: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: BpSpace.x4),
        AuthLinkRow(
          prompt: 'Ingat kata sandimu?',
          action: 'Masuk',
          onTap: () => router.replace(context, const LoginRoute()),
        ),
        const SizedBox(height: BpSpace.x5),
        const _ResetSteps(
          steps: <String>[
            'Isi email akun terdaftar',
            'Buka tautan dari Bpedia',
            'Buat kata sandi baru',
          ],
        ),
        const SizedBox(height: BpSpace.x3),
        const NoteBox(
          icon: LucideIcons.shieldCheck,
          message:
              'Demo: tidak ada email atau SMS yang dikirim. Akun demo tidak '
              'menyimpan kata sandi, jadi kamu bisa langsung masuk lagi.',
        ),
        const SizedBox(height: BpSpace.x3),
        AuthLinkRow(
          prompt: 'Butuh bantuan?',
          action: 'Hubungi Bpedia Care',
          onTap: () => router.go(context, const HelpRoute()),
        ),
      ],
    );
  }
}

/// Email tersamar untuk layar "Cek emailmu": huruf pertama, `***`, dan huruf
/// terakhir sebelum `@` (mis. `n***a@contoh.id`).
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final local = email.substring(0, at);
  final domain = email.substring(at);
  if (local.length == 1) return '$local***$domain';
  return '${local[0]}***${local[local.length - 1]}$domain';
}

/// Pose Bipy di lingkaran `brandTint` dengan lencana ikon di kanan bawah.
class _BadgedBipy extends StatelessWidget {
  const _BadgedBipy({
    required this.asset,
    required this.icon,
    required this.height,
    required this.semanticLabel,
  });

  final String asset;
  final IconData icon;
  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final circle = height * 1.05;
    return Center(
      child: Semantics(
        image: true,
        label: semanticLabel,
        child: ExcludeSemantics(
          child: SizedBox(
            width: circle + 8,
            height: height + 8,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: circle,
                    height: circle,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.brandTint,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  child: KeyedSubtree(
                    key: ValueKey<String>(asset),
                    child: BipyPose(asset, height: height),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 6,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.brand,
                      border: Border.all(color: c.surface, width: 2),
                      boxShadow: BpShadows.floating(c),
                    ),
                    child: Icon(icon, size: 18, color: c.onBrand),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Panduan tiga langkah atur ulang; langkah pertama aktif.
class _ResetSteps extends StatelessWidget {
  const _ResetSteps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BpSpace.card,
        vertical: BpSpace.x3,
      ),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BpRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < steps.length; i++)
            Semantics(
              label: 'Langkah ${i + 1} dari ${steps.length}: ${steps[i]}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? c.brand : c.surface,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: BpText.label.copyWith(
                          color: i == 0 ? c.onBrand : c.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: BpSpace.x3),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: BpText.bodyS.copyWith(
                          color: i == 0 ? c.text : c.textMuted,
                          fontWeight: i == 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
