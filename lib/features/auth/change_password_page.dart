/// Ubah kata sandi dengan OTP (FITUR #5, demo): kode ditampilkan di layar
/// karena tidak ada SMS/email sungguhan; kata sandi tidak disimpan.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_scope.dart';
import '../../app/phone_frame.dart' show BipyPose;
import '../../data/auth/auth_repository.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';
import 'auth_flow.dart';

/// Layar ubah kata sandi.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _otp = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  Map<AuthField, String> _errors = const <AuthField, String>{};
  String? _demoCode;
  String? _done;
  bool _requesting = false;
  bool _busy = false;

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_requesting) return;
    final auth = AppScope.of(context).auth;
    setState(() => _requesting = true);
    final result = await auth.requestPasswordOtp();
    if (!mounted) return;
    setState(() {
      _requesting = false;
      _errors = result.errors;
      _demoCode = result.demoCode ?? _demoCode;
    });
    if (result.ok) showAppSnack(context, 'Kode OTP baru sudah dibuat.');
  }

  Future<void> _submit() async {
    if (_busy) return;
    final auth = AppScope.of(context).auth;
    setState(() => _busy = true);
    final result = await auth.changePassword(
      otp: _otp.text,
      newPassword: _password.text,
      passwordConfirmation: _confirm.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _errors = result.errors;
      if (result.ok) {
        _done = result.message;
        _otp.clear();
        _password.clear();
        _confirm.clear();
      }
    });
    if (result.ok) AppScope.of(context).haptics.success();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final done = _done;
    if (done != null) {
      return AuthScaffold(
        title: 'Ubah kata sandi',
        children: <Widget>[
          const SizedBox(height: BpSpace.x4),
          const AuthHero(
            title: 'Kata sandi diperbarui',
            message: 'Pakai kata sandi baru saat masuk berikutnya, Babes.',
            art: BipyPose(
              'assets/bipy/bipy_pose_lompat_bintang.webp',
              height: 136,
            ),
            artHeight: 136,
          ),
          const SizedBox(height: BpSpace.x5),
          NoteBox(
            tone: StatusTone.gold,
            icon: LucideIcons.flaskConical,
            title: 'Mode demo',
            message: done,
          ),
          const SizedBox(height: BpSpace.x5),
          PillButton(
            label: 'Kembali ke Akun',
            expand: true,
            onPressed: () => services.router.back(context),
          ),
        ],
      );
    }
    final code = _demoCode;
    final c = context.bp;
    return AuthScaffold(
      title: 'Ubah kata sandi',
      children: <Widget>[
        const SizedBox(height: BpSpace.x2),
        Text(
          'Kami kirim kode OTP ke ${services.auth.profile?.contactLabel ?? 'kontakmu'}. '
          'Masukkan kodenya, lalu buat kata sandi baru.',
          style: BpText.body.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: BpSpace.x4),
        if (code == null)
          PillButton(
            label: 'Kirim kode OTP',
            variant: PillButtonVariant.tonal,
            expand: true,
            busy: _requesting,
            icon: const Icon(LucideIcons.send),
            onPressed: _requestOtp,
          )
        else
          _DemoCodeCard(code: code, busy: _requesting, onResend: _requestOtp),
        if (code == null && _errors[AuthField.otp] != null) ...<Widget>[
          const SizedBox(height: BpSpace.x2),
          Text(
            _errors[AuthField.otp]!,
            style: BpText.caption.copyWith(color: c.danger),
          ),
        ],
        const SizedBox(height: BpSpace.x5),
        LabeledField(
          fieldKey: const ValueKey<String>('otp-code'),
          label: 'Kode OTP',
          controller: _otp,
          hint: '6 angka',
          prefixIcon: LucideIcons.keyRound,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.oneTimeCode],
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          maxLength: 6,
          enabled: code != null,
          errorText: code == null ? null : _errors[AuthField.otp],
        ),
        const SizedBox(height: BpSpace.x4),
        PasswordField(
          fieldKey: const ValueKey<String>('otp-password'),
          label: 'Kata sandi baru',
          controller: _password,
          newPassword: true,
          textInputAction: TextInputAction.next,
          errorText: _errors[AuthField.password],
        ),
        const SizedBox(height: BpSpace.x4),
        PasswordField(
          fieldKey: const ValueKey<String>('otp-confirm'),
          label: 'Ulangi kata sandi baru',
          controller: _confirm,
          hint: 'Ketik ulang kata sandi baru',
          newPassword: true,
          textInputAction: TextInputAction.done,
          errorText: _errors[AuthField.passwordConfirmation],
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: BpSpace.x5),
        PillButton(
          label: 'Simpan kata sandi',
          expand: true,
          busy: _busy,
          onPressed: code == null ? null : _submit,
        ),
        const SizedBox(height: BpSpace.x5),
        const NoteBox(
          icon: LucideIcons.shieldCheck,
          message:
              'Demo: kode OTP tampil di layar, tidak dikirim. Kata sandi baru '
              'tidak disimpan di perangkat.',
        ),
      ],
    );
  }
}

class _DemoCodeCard extends StatelessWidget {
  const _DemoCodeCard({
    required this.code,
    required this.busy,
    required this.onResend,
  });

  final String code;
  final bool busy;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.x4,
        BpSpace.x3,
        BpSpace.x2,
        BpSpace.x3,
      ),
      decoration: BoxDecoration(
        color: c.goldTint,
        borderRadius: BpRadius.cardAll,
      ),
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: BpSpace.x2,
        children: <Widget>[
          Semantics(
            label: 'Kode OTP demo ${code.split('').join(' ')}',
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Kode OTP (demo)',
                  style: BpText.caption.copyWith(color: c.onGoldTint),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    code,
                    style: BpText.titleL.copyWith(
                      color: c.text,
                      letterSpacing: 6,
                      fontFeatures: BpText.tabular,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PillButton(
            label: 'Kirim ulang',
            variant: PillButtonVariant.text,
            size: PillButtonSize.small,
            busy: busy,
            onPressed: onResend,
          ),
        ],
      ),
    );
  }
}
