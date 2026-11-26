/// Layar Daftar (FITUR #4): daftar cepat (nama, HP, email) dan daftar
/// lengkap (+ kata sandi, konfirmasi, setuju S&K). Demo lokal tanpa captcha
/// dan tanpa email aktivasi.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/auth/auth_repository.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';
import 'auth_flow.dart';

/// Layar Daftar. [full] memilih daftar lengkap.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.full = false, this.next});

  final bool full;

  /// Lokasi tujuan setelah daftar.
  final String? next;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  late bool _full = widget.full;
  bool _terms = false;
  bool _busy = false;
  bool _googleBusy = false;
  bool _submitted = false;
  Map<AuthField, String> _errors = const <AuthField, String>{};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Map<AuthField, String> _localErrors() => <AuthField, String>{
    AuthField.name: ?validateName(_name.text),
    AuthField.phone: ?validatePhone(_phone.text),
    AuthField.email: ?validateEmail(_email.text),
    if (_full) ...<AuthField, String>{
      AuthField.password: ?validatePassword(_password.text),
      AuthField.passwordConfirmation: ?validatePasswordConfirmation(
        _password.text,
        _confirm.text,
      ),
      if (!_terms)
        AuthField.terms: 'Setujui Syarat & Ketentuan untuk mendaftar.',
    },
  };

  void _revalidate() {
    if (_submitted) setState(() => _errors = _localErrors());
  }

  void _setMode(bool full) {
    if (full == _full) return;
    setState(() {
      _full = full;
      if (_submitted) _errors = _localErrors();
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final auth = AppScope.of(context).auth;
    setState(() {
      _submitted = true;
      _busy = true;
    });
    final result = _full
        ? await auth.register(
            name: _name.text,
            phone: _phone.text,
            email: _email.text,
            password: _password.text,
            passwordConfirmation: _confirm.text,
            acceptedTerms: _terms,
          )
        : await auth.registerQuick(
            name: _name.text,
            phone: _phone.text,
            email: _email.text,
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
    _confirm.clear();
    await finishAuthFlow(
      context,
      next: widget.next,
      message: result.message ?? 'Akunmu sudah aktif. Selamat belanja, Babes!',
    );
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
    final c = context.bp;
    final services = AppScope.of(context);
    final router = services.router;
    return AuthScaffold(
      title: 'Daftar',
      children: <Widget>[
        AuthHero(
          title: 'Daftar akun Bpedia',
          message: _full
              ? 'Lengkapi data dan buat kata sandi untuk akunmu.'
              : 'Cukup nama, nomor HP, dan email. Kata sandi bisa dibuat nanti.',
          artHeight: 104,
        ),
        if (services.rewards.available) ...<Widget>[
          const SizedBox(height: BpSpace.x5),
          const MemberPerksCard(),
        ],
        const SizedBox(height: BpSpace.x5),
        Semantics(
          container: true,
          label: 'Pilih cara daftar',
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: BpSpace.x2,
            runSpacing: BpSpace.x2,
            children: <Widget>[
              BpChip(
                label: 'Daftar cepat',
                selected: !_full,
                onTap: () => _setMode(false),
              ),
              BpChip(
                label: 'Daftar lengkap',
                selected: _full,
                onTap: () => _setMode(true),
              ),
            ],
          ),
        ),
        const SizedBox(height: BpSpace.x5),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LabeledField(
                fieldKey: const ValueKey<String>('register-name'),
                label: 'Nama lengkap',
                controller: _name,
                hint: 'Nama sesuai identitas',
                prefixIcon: LucideIcons.user,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.name],
                errorText: _errors[AuthField.name],
                onChanged: (_) => _revalidate(),
              ),
              const SizedBox(height: BpSpace.x4),
              LabeledField(
                fieldKey: const ValueKey<String>('register-phone'),
                label: 'Nomor HP',
                controller: _phone,
                hint: '0812 3456 7890',
                prefixIcon: LucideIcons.smartphone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.telephoneNumber],
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                ],
                maxLength: 18,
                errorText: _errors[AuthField.phone],
                onChanged: (_) => _revalidate(),
              ),
              const SizedBox(height: BpSpace.x4),
              LabeledField(
                fieldKey: const ValueKey<String>('register-email'),
                label: 'Email',
                controller: _email,
                hint: 'nama@email.com',
                prefixIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _full
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: const <String>[AutofillHints.email],
                errorText: _errors[AuthField.email],
                onChanged: (_) => _revalidate(),
                onSubmitted: _full ? null : (_) => _submit(),
              ),
              if (_full) ...<Widget>[
                const SizedBox(height: BpSpace.x4),
                PasswordField(
                  fieldKey: const ValueKey<String>('register-password'),
                  label: 'Kata sandi',
                  controller: _password,
                  newPassword: true,
                  textInputAction: TextInputAction.next,
                  errorText: _errors[AuthField.password],
                  onChanged: (_) => _revalidate(),
                ),
                const SizedBox(height: BpSpace.x4),
                PasswordField(
                  fieldKey: const ValueKey<String>('register-confirm'),
                  label: 'Ulangi kata sandi',
                  controller: _confirm,
                  hint: 'Ketik ulang kata sandi',
                  newPassword: true,
                  textInputAction: TextInputAction.done,
                  errorText: _errors[AuthField.passwordConfirmation],
                  onChanged: (_) => _revalidate(),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ],
          ),
        ),
        if (_full) ...<Widget>[
          const SizedBox(height: BpSpace.x3),
          MergeSemantics(
            child: InkWell(
              borderRadius: BpRadius.cardAll,
              onTap: () {
                setState(() => _terms = !_terms);
                _revalidate();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: BpSize.touch),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Checkbox(
                      value: _terms,
                      onChanged: (value) {
                        setState(() => _terms = value ?? false);
                        _revalidate();
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Saya setuju dengan Syarat & Ketentuan dan Kebijakan '
                          'Privasi Bpedia.',
                          style: BpText.bodyS.copyWith(color: c.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_errors[AuthField.terms] case final String error)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                error,
                style: BpText.caption.copyWith(color: c.danger),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Wrap(
              children: <Widget>[
                PillButton(
                  label: 'Baca S&K',
                  variant: PillButtonVariant.text,
                  size: PillButtonSize.small,
                  onPressed: () => router.go(context, const TermsRoute()),
                ),
                PillButton(
                  label: 'Baca Kebijakan Privasi',
                  variant: PillButtonVariant.text,
                  size: PillButtonSize.small,
                  onPressed: () => router.go(context, const PrivacyRoute()),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: BpSpace.x4),
        PillButton(
          label: 'Daftar',
          expand: true,
          busy: _busy,
          onPressed: _submit,
        ),
        const OrDivider(),
        PillButton(
          label: 'Daftar dengan Google (demo)',
          variant: PillButtonVariant.neutral,
          expand: true,
          busy: _googleBusy,
          icon: const Icon(LucideIcons.circleUserRound),
          onPressed: _google,
        ),
        const SizedBox(height: BpSpace.x4),
        AuthLinkRow(
          prompt: 'Sudah punya akun?',
          action: 'Masuk',
          onTap: () => router.replace(context, LoginRoute(next: widget.next)),
        ),
        const SizedBox(height: BpSpace.x5),
        NoteBox(
          icon: LucideIcons.shieldCheck,
          message: _full
              ? LocalAuthRepository.demoNote
              : 'Demo: akun langsung aktif tanpa tautan aktivasi ke email. '
                    'Data tersimpan di perangkat ini saja.',
        ),
      ],
    );
  }
}

/// Kartu "Untung jadi member Bpedia": tiga manfaat Zona Hadiah berikon 3D.
class MemberPerksCard extends StatelessWidget {
  const MemberPerksCard({super.key});

  static const List<(String, String, String)> _perks =
      <(String, String, String)>[
        ('assets/icons3d/checkin.webp', 'Check-in harian', '+1 Kelopak/hari'),
        ('assets/icons3d/roda.webp', 'Roda Sabtu', 'Produk gratis'),
        ('assets/icons3d/misi.webp', 'Misi Belanja', 'Voucher belanja'),
      ];

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        BpSpace.x2,
        BpSpace.x3,
        BpSpace.x2,
        BpSpace.x3,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BpRadius.cardAll,
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'Untung jadi member Bpedia',
              textAlign: TextAlign.center,
              style: BpText.bodyS.copyWith(
                color: c.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: BpSpace.x2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final (art, title, subtitle) in _perks)
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      children: <Widget>[
                        AssetPicture(
                          art,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          cacheWidth: 96,
                          showSkeleton: false,
                        ),
                        const SizedBox(height: BpSpace.x1),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: BpText.caption.copyWith(
                            color: c.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: BpText.caption.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
