/// Profil (FITUR #21): foto profil Bipy, ubah nama, tanggal lahir, jenis
/// kelamin, email, dan nomor HP; info akun; pintasan ubah kata sandi.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kelopak_hub/kelopak_hub.dart'
    show KeyValueStore, shortDateLabel;
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
  ProfileExtras _extras = const ProfileExtras();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    final services = AppScope.of(context);
    final profile = services.auth.profile;
    if (profile == null) return;
    _filled = true;
    _name.text = profile.name;
    _email.text = profile.email ?? '';
    _phone.text = profile.phoneLabel ?? '';
    ProfileExtras.load(services.store, profile.id).then((extras) {
      if (mounted) setState(() => _extras = extras);
    });
  }

  Future<void> _pickBirthDate() async {
    final now = AppScope.of(context).clock.instant;
    final current = _extras.birthDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() => _extras = _extras.copyWith(birthDate: picked));
  }

  Future<void> _pickAvatar() async {
    final chosen = await showBpSheet<String>(
      context: context,
      builder: (sheetContext) => _AvatarPicker(
        selected: _extras.avatar ?? ProfileExtras.defaultAvatar,
      ),
    );
    if (chosen == null || !mounted) return;
    final services = AppScope.of(context);
    final profile = services.auth.profile;
    if (profile == null) return;
    setState(() => _extras = _extras.copyWith(avatar: chosen));
    await _extras.save(services.store, profile.id);
    if (mounted) showAppSnack(context, 'Foto profil diganti.');
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
    final store = AppScope.of(context).store;
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
    if (errors.isEmpty) {
      await _extras.save(store, current.id);
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
            appBar: const BpAppBar(title: 'Ubah profil'),
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
          appBar: const BpAppBar(title: 'Ubah profil'),
          bottomNavigationBar: StickyBottomBar(
            child: PillButton(
              label: 'Simpan',
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
                    BpTappable(
                      onTap: _pickAvatar,
                      semanticLabel: 'Foto profil. Ganti foto',
                      focusRadius: const BorderRadius.all(Radius.circular(60)),
                      builder: (context, states) => _BipyAvatar(
                        asset: _extras.avatar ?? ProfileExtras.defaultAvatar,
                      ),
                    ),
                    PillButton(
                      label: 'Ganti foto',
                      variant: PillButtonVariant.text,
                      size: PillButtonSize.small,
                      onPressed: _pickAvatar,
                    ),
                    Text(
                      'Foto profil bawaan memakai Bipy, maskot Bpedia.',
                      textAlign: TextAlign.center,
                      style: BpText.caption.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID pelanggan ${profile.id}',
                      textAlign: TextAlign.center,
                      style: BpText.caption.copyWith(color: c.textFaint),
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
                      helperText:
                          'Nama ini tampil di Akun dan label pengiriman.',
                    ),
                    const SizedBox(height: BpSpace.x4),
                    _BirthDateField(
                      value: _extras.birthDate,
                      onTap: _pickBirthDate,
                      onClear: _extras.birthDate == null
                          ? null
                          : () => setState(
                              () => _extras = _extras.copyWith(
                                clearBirthDate: true,
                              ),
                            ),
                    ),
                    const SizedBox(height: BpSpace.x4),
                    _GenderField(
                      value: _extras.gender,
                      onChanged: (gender) => setState(
                        () => _extras = _extras.copyWith(gender: gender),
                      ),
                    ),
                  ],
                ),
              ),
              Section(
                header: const SectionHeader(
                  title: 'Kontak',
                  subtitle: 'Dipakai untuk masuk dan info pesanan',
                ),
                inset: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
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

/// Jenis kelamin di profil.
enum ProfileGender {
  female('perempuan', 'Perempuan'),
  male('laki-laki', 'Laki-laki');

  const ProfileGender(this.id, this.label);

  final String id;
  final String label;

  static ProfileGender? byId(Object? id) {
    for (final gender in values) {
      if (gender.id == id) return gender;
    }
    return null;
  }
}

/// Data profil tambahan yang hanya tersimpan di perangkat: foto Bipy,
/// tanggal lahir, dan jenis kelamin.
@immutable
class ProfileExtras {
  const ProfileExtras({this.avatar, this.birthDate, this.gender});

  /// Pose Bipy bawaan untuk foto profil.
  static const String defaultAvatar = 'assets/bipy/bipy_wajah_senyum.webp';

  /// Pose Bipy yang bisa dipilih sebagai foto profil.
  static const List<(String, String)> avatars = <(String, String)>[
    ('assets/bipy/bipy_wajah_senyum.webp', 'Senyum'),
    ('assets/bipy/bipy_wajah_wink.webp', 'Kedip'),
    ('assets/bipy/bipy_menyapa.webp', 'Menyapa'),
    ('assets/bipy/bipy_pose_semangat.webp', 'Semangat'),
    ('assets/bipy/bipy_tas_hati.webp', 'Tas hati'),
  ];

  final String? avatar;
  final DateTime? birthDate;
  final ProfileGender? gender;

  static String storageKey(String profileId) =>
      'bpedia.profile_extras.$profileId';

  ProfileExtras copyWith({
    String? avatar,
    DateTime? birthDate,
    bool clearBirthDate = false,
    ProfileGender? gender,
  }) => ProfileExtras(
    avatar: avatar ?? this.avatar,
    birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
    gender: gender ?? this.gender,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'avatar': ?avatar,
    if (birthDate case final DateTime date)
      'birthDate':
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
    'gender': ?gender?.id,
  };

  static ProfileExtras fromJson(Object? json) {
    if (json is! Map) return const ProfileExtras();
    final avatar = json['avatar'];
    final day = tryParseWibDay(json['birthDate'] as String?);
    final date = day == null ? null : dateOfWibDay(day);
    return ProfileExtras(
      avatar: avatars.any((a) => a.$1 == avatar) ? avatar as String : null,
      birthDate: date == null
          ? null
          : DateTime(date.year, date.month, date.day),
      gender: ProfileGender.byId(json['gender']),
    );
  }

  static Future<ProfileExtras> load(
    KeyValueStore store,
    String profileId,
  ) async {
    try {
      final raw = await store.read(storageKey(profileId));
      if (raw == null) return const ProfileExtras();
      return fromJson(jsonDecode(raw));
    } on FormatException {
      return const ProfileExtras();
    }
  }

  Future<void> save(KeyValueStore store, String profileId) =>
      store.write(storageKey(profileId), jsonEncode(toJson()));
}

/// "17 Agu 1998" dari tanggal kalender.
String birthDateLabel(DateTime date) =>
    '${shortDateLabel(wibDayFromDate(date.year, date.month, date.day))} '
    '${date.year}';

/// Avatar Bipy 96 dp bercincin `brand` dengan lencana kamera.
class _BipyAvatar extends StatelessWidget {
  const _BipyAvatar({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.brand, width: 3),
            ),
            child: ClipOval(
              child: ColoredBox(
                color: c.brandTint,
                child: _AvatarArt(asset: asset, size: 88),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: ExcludeSemantics(
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.brand,
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: Icon(LucideIcons.camera, size: 15, color: c.onBrand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lembar pilihan foto profil dari pose Bipy.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpSheet(
      title: 'Ganti foto profil',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Demo: pilih pose Bipy. Di app Bpedia, foto bisa diambil dari '
            'galeri atau kamera.',
            style: BpText.bodyS.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: BpSpace.x3),
          Wrap(
            spacing: BpSpace.x3,
            runSpacing: BpSpace.x3,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final (asset, label) in ProfileExtras.avatars)
                BpTappable(
                  onTap: () => Navigator.of(context).pop(asset),
                  semanticLabel: 'Bipy $label',
                  selected: asset == selected,
                  focusRadius: BpRadius.cardAll,
                  builder: (context, states) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.brandTint,
                          border: Border.all(
                            color: asset == selected ? c.brand : c.line,
                            width: asset == selected ? 3 : 1,
                          ),
                        ),
                        child: ClipOval(
                          child: _AvatarArt(asset: asset, size: 62),
                        ),
                      ),
                      const SizedBox(height: BpSpace.x1),
                      Text(
                        label,
                        style: BpText.caption.copyWith(
                          color: asset == selected ? c.brandStrong : c.text,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kolom "Tanggal lahir (opsional)": membuka pemilih tanggal.
class _BirthDateField extends StatelessWidget {
  const _BirthDateField({
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final date = value;
    final clear = onClear;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              text: 'Tanggal lahir',
              children: <InlineSpan>[
                TextSpan(
                  text: ' (opsional)',
                  style: BpText.caption.copyWith(color: c.textMuted),
                ),
              ],
            ),
            style: BpText.subtitle.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: 6),
        BpTappable(
          key: const ValueKey<String>('profile-birthdate'),
          onTap: onTap,
          semanticLabel:
              'Tanggal lahir, opsional, '
              '${date == null ? 'belum diisi' : birthDateLabel(date)}',
          focusRadius: BpRadius.cardAll,
          pressScale: false,
          builder: (context, states) => Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BpRadius.cardAll,
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: <Widget>[
                Icon(LucideIcons.calendar, size: 20, color: c.textMuted),
                const SizedBox(width: BpSpace.x3),
                Expanded(
                  child: Text(
                    date == null ? 'Pilih tanggal' : birthDateLabel(date),
                    style: BpText.body.copyWith(
                      color: date == null ? c.textFaint : c.text,
                    ),
                  ),
                ),
                if (clear != null)
                  IconButton(
                    tooltip: 'Hapus tanggal lahir',
                    onPressed: clear,
                    icon: Icon(LucideIcons.x, size: 18, color: c.textMuted),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: c.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pilihan jenis kelamin: dua tombol radio berdampingan.
class _GenderField extends StatelessWidget {
  const _GenderField({required this.value, required this.onChanged});

  final ProfileGender? value;
  final ValueChanged<ProfileGender> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Jenis kelamin',
            style: BpText.subtitle.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            for (final gender in ProfileGender.values) ...<Widget>[
              if (gender.index > 0) const SizedBox(width: BpSpace.x2),
              Expanded(
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: value == gender,
                  child: BpTappable(
                    onTap: () => onChanged(gender),
                    semanticLabel: gender.label,
                    focusRadius: BpRadius.cardAll,
                    pressScale: false,
                    builder: (context, states) {
                      final selected = value == gender;
                      return Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: selected ? c.brandTint : c.surface,
                          borderRadius: BpRadius.cardAll,
                          border: Border.all(
                            color: selected ? c.brand : c.line,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              selected
                                  ? LucideIcons.circleDot
                                  : LucideIcons.circle,
                              size: 20,
                              color: selected ? c.brand : c.textMuted,
                            ),
                            const SizedBox(width: BpSpace.x2),
                            Flexible(
                              child: Text(
                                gender.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BpText.body.copyWith(
                                  color: selected ? c.brandStrong : c.text,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Gambar Bipy diam untuk avatar: wajah utuh, pose dipotong dari kepala.
class _AvatarArt extends StatelessWidget {
  const _AvatarArt({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final face = asset.contains('wajah');
    return ExcludeSemantics(
      child: AssetPicture(
        asset,
        width: size,
        height: size,
        fit: face ? BoxFit.contain : BoxFit.cover,
        alignment: Alignment.topCenter,
        cacheWidth: (size * 3).round(),
        showSkeleton: false,
      ),
    );
  }
}
