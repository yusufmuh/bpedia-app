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
    final router = AppScope.of(context).router;
    final sentTo = _sentTo;
    if (sentTo != null) {
      return AuthScaffold(
        title: 'Lupa kata sandi',
        children: <Widget>[
          const SizedBox(height: BpSpace.x4),
          AuthHero(
            title: 'Cek emailmu, Babes',
            message:
                'Kalau $sentTo terdaftar, tautan atur ulang kata sandi dikirim '
                'ke sana. Buka tautannya untuk membuat kata sandi baru.',
            art: const BipyPose(
              'assets/bipy/bipy_pose_semangat.webp',
              height: 128,
            ),
            artHeight: 128,
          ),
          const SizedBox(height: BpSpace.x5),
          NoteBox(
            tone: StatusTone.gold,
            icon: LucideIcons.flaskConical,
            title: 'Mode demo',
            message: _note ?? LocalAuthRepository.demoNote,
          ),
          const SizedBox(height: BpSpace.x5),
          PillButton(
            label: 'Kembali ke Masuk',
            expand: true,
            onPressed: () => router.replace(context, const LoginRoute()),
          ),
          const SizedBox(height: BpSpace.x2),
          PillButton(
            label: 'Kirim ulang',
            variant: PillButtonVariant.text,
            expand: true,
            onPressed: () => setState(() => _sentTo = null),
          ),
        ],
      );
    }
    return AuthScaffold(
      title: 'Lupa kata sandi',
      children: <Widget>[
        const AuthHero(
          title: 'Atur ulang kata sandi',
          message:
              'Masukkan email akunmu. Kami kirim tautan untuk membuat kata '
              'sandi baru.',
          art: BipyPose('assets/bipy/bipy_ngintip.webp', height: 112),
          artHeight: 112,
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
          prompt: 'Butuh bantuan?',
          action: 'Hubungi Bpedia Care',
          onTap: () => router.go(context, const HelpRoute()),
        ),
      ],
    );
  }
}
