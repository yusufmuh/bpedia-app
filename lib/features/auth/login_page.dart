/// Layar Masuk (SPEC §4.8, FITUR #1–#3): nomor HP/email + kata sandi, Google
/// (demo), lanjut sebagai tamu, tautan daftar dan lupa sandi.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/auth/auth_repository.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';
import 'auth_flow.dart';

/// Layar Masuk. [next] dibuka setelah berhasil masuk.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.next});

  /// Lokasi tujuan setelah masuk (`?lanjut=`).
  final String? next;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();
  Map<AuthField, String> _errors = const <AuthField, String>{};
  bool _submitted = false;
  bool _busy = false;
  bool _googleBusy = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _revalidate() {
    if (!_submitted) return;
    setState(() {
      _errors = <AuthField, String>{
        AuthField.identifier: ?validateIdentifier(_identifier.text),
        AuthField.password: ?validatePassword(_password.text),
      };
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final auth = AppScope.of(context).auth;
    setState(() {
      _submitted = true;
      _busy = true;
    });
    final result = await auth.signIn(
      identifier: _identifier.text,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _errors = result.errors;
    });
    if (!result.ok) {
      AppScope.of(context).haptics.light();
      return;
    }
    _password.clear();
    await finishAuthFlow(context, next: widget.next, message: result.message);
  }

  Future<void> _google() async {
    if (_googleBusy) return;
    final auth = AppScope.of(context).auth;
    setState(() => _googleBusy = true);
    final result = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleBusy = false);
    await finishAuthFlow(context, next: widget.next, message: result.message);
  }

  @override
  Widget build(BuildContext context) {
    final router = AppScope.of(context).router;
    return AuthScaffold(
      title: 'Masuk',
      children: <Widget>[
        const AuthHero(
          title: 'Masuk ke Bpedia',
          message:
              'Belanja produk original dan kumpulkan Kelopak dari tiap pesanan.',
        ),
        const SizedBox(height: BpSpace.x6),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LabeledField(
                fieldKey: const ValueKey<String>('login-identifier'),
                label: 'Nomor HP atau email',
                controller: _identifier,
                hint: 'Contoh: 0812 3456 7890',
                prefixIcon: LucideIcons.user,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[
                  AutofillHints.email,
                  AutofillHints.telephoneNumber,
                ],
                errorText: _errors[AuthField.identifier],
                onChanged: (_) => _revalidate(),
              ),
              const SizedBox(height: BpSpace.x4),
              PasswordField(
                fieldKey: const ValueKey<String>('login-password'),
                label: 'Kata sandi',
                controller: _password,
                textInputAction: TextInputAction.done,
                errorText: _errors[AuthField.password],
                onChanged: (_) => _revalidate(),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: PillButton(
            label: 'Lupa kata sandi?',
            variant: PillButtonVariant.text,
            size: PillButtonSize.small,
            onPressed: () => router.go(context, const ForgotPasswordRoute()),
          ),
        ),
        const SizedBox(height: BpSpace.x2),
        PillButton(
          key: const ValueKey<String>('login-submit'),
          label: 'Masuk',
          expand: true,
          busy: _busy,
          onPressed: _submit,
        ),
        const OrDivider(),
        PillButton(
          label: 'Masuk dengan Google (demo)',
          variant: PillButtonVariant.neutral,
          expand: true,
          busy: _googleBusy,
          icon: const Icon(LucideIcons.circleUserRound),
          onPressed: _google,
        ),
        const SizedBox(height: BpSpace.x3),
        PillButton(
          label: 'Lanjut sebagai tamu',
          variant: PillButtonVariant.text,
          expand: true,
          onPressed: () => router.back(context),
        ),
        const SizedBox(height: BpSpace.x2),
        AuthLinkRow(
          prompt: 'Belum punya akun?',
          action: 'Daftar',
          onTap: () =>
              router.replace(context, RegisterRoute(next: widget.next)),
        ),
        const SizedBox(height: BpSpace.x5),
        const NoteBox(
          message: LocalAuthRepository.demoNote,
          icon: LucideIcons.shieldCheck,
        ),
      ],
    );
  }
}
