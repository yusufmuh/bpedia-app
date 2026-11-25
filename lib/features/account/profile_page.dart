/// Profil (FITUR #21): ubah nama, email, dan nomor HP; info akun; pintasan
/// ubah kata sandi.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/wib_dates.dart';
import '../../design/design.dart';
import 'account_ui.dart';

/// Halaman profil.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  Map<AuthField, String> _errors = const <AuthField, String>{};
  bool _busy = false;
  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    final profile = AppScope.of(context).auth.profile;
    if (profile == null) return;
    _filled = true;
    _name.text = profile.name;
    _email.text = profile.email ?? '';
    _phone.text = profile.phoneLabel ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final auth = AppScope.of(context).auth;
    final current = auth.profile;
    if (current == null) return;
    setState(() => _busy = true);
    final errors = <AuthField, String>{};
    final profileResult = await auth.updateProfile(
      name: _name.text,
      email: _email.text,
    );
    errors.addAll(profileResult.errors);
    final phoneChanged =
        normalizePhone(_phone.text) != current.phone &&
        !(current.phone == null && _phone.text.trim().isEmpty);
    if (phoneChanged) {
      final phoneResult = await auth.updatePhone(_phone.text);
      errors.addAll(phoneResult.errors);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _errors = errors;
    });
    if (errors.isEmpty) {
      AppScope.of(context).haptics.success();
      showAppSnack(context, 'Profil tersimpan.');
      _phone.text = auth.profile?.phoneLabel ?? _phone.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return ListenableBuilder(
      listenable: services.auth,
      builder: (context, _) {
        final profile = services.auth.profile;
        if (profile == null) {
          return Scaffold(
            backgroundColor: c.surface,
            appBar: const BpAppBar(title: 'Profil'),
            body: Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  imageAsset: 'assets/bipy/bipy_ngintip.webp',
                  title: 'Masuk dulu, Babes',
                  message: 'Profil tampil setelah kamu masuk ke akun.',
                  actionLabel: 'Masuk',
                  onAction: () => services.router.replace(
                    context,
                    const LoginRoute(next: AppRoutes.profile),
                  ),
                ),
              ),
            ),
          );
        }
        final joined = wibDateTimeLabel(
          DateTime.fromMillisecondsSinceEpoch(profile.createdAtMs, isUtc: true),
        );
        return Scaffold(
          backgroundColor: c.canvas,
          appBar: const BpAppBar(title: 'Profil'),
          bottomNavigationBar: StickyBottomBar(
            child: PillButton(
              label: 'Simpan perubahan',
              expand: true,
              busy: _busy,
              onPressed: _save,
            ),
          ),
          body: ListView(
            children: <Widget>[
              Section(
                child: Column(
                  children: <Widget>[
                    InitialsAvatar(initials: profile.initials, size: 76),
                    const SizedBox(height: BpSpace.x2),
                    Text(
                      profile.name,
                      textAlign: TextAlign.center,
                      style: BpText.title.copyWith(color: c.text),
                    ),
                    Text(
                      'ID pelanggan ${profile.id}',
                      textAlign: TextAlign.center,
                      style: BpText.caption.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Section(
                header: const SectionHeader(title: 'Data diri'),
                inset: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LabeledField(
                      fieldKey: const ValueKey<String>('profile-name'),
                      label: 'Nama lengkap',
                      controller: _name,
                      prefixIcon: LucideIcons.user,
                      textInputAction: TextInputAction.next,
                      errorText: _errors[AuthField.name],
                    ),
                    const SizedBox(height: BpSpace.x4),
                    LabeledField(
                      fieldKey: const ValueKey<String>('profile-email'),
                      label: 'Email',
                      controller: _email,
                      hint: 'nama@email.com',
                      prefixIcon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      errorText: _errors[AuthField.email],
                    ),
                    const SizedBox(height: BpSpace.x4),
                    LabeledField(
                      fieldKey: const ValueKey<String>('profile-phone'),
                      label: 'Nomor HP',
                      controller: _phone,
                      hint: '0812 3456 7890',
                      prefixIcon: LucideIcons.smartphone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                      ],
                      maxLength: 18,
                      errorText: _errors[AuthField.phone],
                      helperText:
                          'Di app Bpedia, nomor baru diverifikasi dengan OTP.',
                    ),
                  ],
                ),
              ),
              Section(
                header: const SectionHeader(title: 'Keamanan dan akun'),
                padding: const EdgeInsets.only(bottom: BpSpace.x2),
                child: Column(
                  children: <Widget>[
                    InfoRow(
                      label: 'Ubah kata sandi',
                      helper: 'Dengan kode OTP (demo)',
                      leading: const Icon(LucideIcons.lock),
                      onTap: () => services.router.go(
                        context,
                        const ChangePasswordRoute(),
                      ),
                    ),
                    InfoRow(
                      label: 'Metode masuk',
                      leading: const Icon(LucideIcons.logIn),
                      value: profile.viaGoogle
                          ? 'Google (demo)'
                          : 'Nomor HP atau email',
                    ),
                    InfoRow(
                      label: 'Bergabung',
                      leading: const Icon(LucideIcons.calendar),
                      value: joined,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(BpSpace.screen),
                child: NoteBox(
                  icon: LucideIcons.shieldCheck,
                  message: LocalAuthRepository.demoNote,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
