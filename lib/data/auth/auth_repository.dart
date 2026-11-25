/// Akun dan sesi. [AuthRepository] adalah port yang diganti tim developer
/// dengan API asli; [LocalAuthRepository] adalah implementasi demo lokal yang
/// **tidak pernah menyimpan atau mengirim kata sandi**.
library;

import 'dart:async';
import 'dart:math';

import 'package:kelopak_hub/kelopak_hub.dart';

import '../../services/analytics/analytics.dart';
import '../storage/document_repository.dart';
import 'auth_validators.dart';

export 'auth_validators.dart';

/// Kolom formulir akun, untuk menempelkan pesan galat di kolom yang tepat.
enum AuthField {
  identifier,
  name,
  phone,
  email,
  password,
  passwordConfirmation,
  terms,
  otp,
}

/// Hasil sebuah aksi akun.
final class AuthResult {
  /// Berhasil; [message] opsional untuk ditampilkan, [demoCode] hanya diisi
  /// oleh permintaan OTP demo.
  const AuthResult.ok({this.message, this.demoCode})
    : errors = const <AuthField, String>{};

  /// Gagal validasi; [errors] berisi pesan per kolom.
  const AuthResult.invalid(this.errors) : message = null, demoCode = null;

  /// Pesan galat per kolom (kosong bila berhasil).
  final Map<AuthField, String> errors;

  /// Pesan informasi untuk pengguna.
  final String? message;

  /// Kode OTP demo (ditampilkan di layar karena tidak ada SMS/email sungguhan).
  final String? demoCode;

  /// Apakah aksi berhasil.
  bool get ok => errors.isEmpty;

  /// Pesan galat kolom [field], atau null.
  String? errorFor(AuthField field) => errors[field];

  /// Pesan galat pertama, atau null.
  String? get firstError => errors.isEmpty ? null : errors.values.first;
}

/// Profil lokal pengguna.
final class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.createdAtMs,
    this.phone,
    this.email,
    this.viaGoogle = false,
    this.termsAccepted = false,
  });

  /// Membaca profil tersimpan.
  factory UserProfile.fromJson(Object? source) {
    final json = asJsonMap(source, 'profil');
    final profile = UserProfile(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      phone: readOptionalString(json, 'phone'),
      email: readOptionalString(json, 'email'),
      viaGoogle: readBool(json, 'viaGoogle', fallback: false),
      termsAccepted: readBool(json, 'termsAccepted', fallback: false),
      createdAtMs: readInt(json, 'createdAtMs'),
    );
    if (profile.id.isEmpty || profile.name.isEmpty) {
      throw const FormatException('Profil tidak sah');
    }
    return profile;
  }

  /// ID pelanggan lokal (dipakai sebagai ID analitik).
  final String id;

  /// Nama tampil.
  final String name;

  /// Nomor HP ternormalisasi (`628…`), bila ada.
  final String? phone;

  /// Email, bila ada.
  final String? email;

  /// Masuk lewat Google (demo).
  final bool viaGoogle;

  /// Sudah menyetujui S&K.
  final bool termsAccepted;

  /// Waktu profil dibuat (milidetik sejak epoch).
  final int createdAtMs;

  /// Inisial untuk avatar ("AP" dari "Ayu Putri").
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.first.isEmpty ? '' : words.first[0];
    final last = words.length > 1 && words.last.isNotEmpty ? words.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// Nomor HP untuk ditampilkan, atau null.
  String? get phoneLabel => phone == null ? null : formatPhone(phone!);

  /// Kontak utama untuk ditampilkan: nomor HP, lalu email.
  String get contactLabel => phoneLabel ?? email ?? '';

  /// Salinan dengan bidang diganti.
  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    bool? termsAccepted,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    viaGoogle: viaGoogle,
    termsAccepted: termsAccepted ?? this.termsAccepted,
    createdAtMs: createdAtMs,
  );

  /// Bentuk JSON (tanpa kata sandi: tidak pernah ada).
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'viaGoogle': viaGoogle,
    'termsAccepted': termsAccepted,
    'createdAtMs': createdAtMs,
  };
}

/// Port akun. Layar hanya memakai antarmuka ini.
abstract class AuthRepository extends DocumentRepository {
  /// Apakah ada sesi aktif.
  bool get isLoggedIn;

  /// Profil sesi aktif, atau null untuk tamu.
  UserProfile? get profile;

  /// Sudah masuk tetapi belum menyetujui S&K (tampilkan layar persetujuan).
  bool get needsTermsAcceptance;

  /// Masuk dengan nomor HP atau email + kata sandi.
  Future<AuthResult> signIn({
    required String identifier,
    required String password,
  });

  /// Masuk dengan Google.
  Future<AuthResult> signInWithGoogle();

  /// Daftar cepat: nama, nomor HP, email.
  Future<AuthResult> registerQuick({
    required String name,
    required String phone,
    required String email,
  });

  /// Daftar lengkap dengan kata sandi dan persetujuan S&K.
  Future<AuthResult> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
    required bool acceptedTerms,
  });

  /// Meminta tautan atur ulang kata sandi ke [email].
  Future<AuthResult> requestPasswordReset(String email);

  /// Meminta OTP untuk mengubah kata sandi.
  Future<AuthResult> requestPasswordOtp();

  /// Mengubah kata sandi dengan OTP.
  Future<AuthResult> changePassword({
    required String otp,
    required String newPassword,
    required String passwordConfirmation,
  });

  /// Menyetujui S&K setelah masuk.
  Future<void> acceptTerms();

  /// Keluar.
  Future<void> signOut();

  /// Mengubah nama dan email.
  Future<AuthResult> updateProfile({
    required String name,
    required String email,
  });

  /// Mengubah nomor HP.
  Future<AuthResult> updatePhone(String phone);
}

/// Implementasi demo: satu profil lokal per perangkat, tanpa server.
///
/// Kata sandi hanya divalidasi bentuknya lalu dibuang; tidak ada bidang kata
/// sandi di keadaan maupun di dokumen tersimpan.
class LocalAuthRepository extends AuthRepository {
  LocalAuthRepository({
    Analytics? analytics,
    DateTime Function()? now,
    Random? random,
  }) : _analytics = analytics,
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  /// Catatan yang tampil di layar Masuk.
  static const String demoNote =
      'Demo: data tersimpan di perangkat ini saja, kata sandi tidak disimpan.';

  /// Nama akun contoh untuk "Masuk dengan Google (demo)".
  static const String googleDemoName = 'Babes Demo';

  /// Email akun contoh untuk "Masuk dengan Google (demo)".
  static const String googleDemoEmail = 'babes.demo@example.com';

  final Analytics? _analytics;
  final DateTime Function() _now;
  final Random _random;
  UserProfile? _profile;
  bool _loggedIn = false;
  String? _otp;

  @override
  String get sectionKey => 'auth';

  @override
  bool get isLoggedIn => _loggedIn && _profile != null;

  @override
  UserProfile? get profile => isLoggedIn ? _profile : null;

  @override
  bool get needsTermsAcceptance =>
      isLoggedIn && !(_profile?.termsAccepted ?? false);

  @override
  Future<AuthResult> signIn({
    required String identifier,
    required String password,
  }) async {
    final errors = <AuthField, String>{
      AuthField.identifier: ?validateIdentifier(identifier),
      AuthField.password: ?validatePassword(password),
    };
    if (errors.isNotEmpty) return AuthResult.invalid(errors);
    final text = identifier.trim();
    final email = text.contains('@') ? text.toLowerCase() : null;
    final phone = email == null ? normalizePhone(text) : null;
    final existing = _profile;
    final matches =
        existing != null &&
        ((email != null && existing.email == email) ||
            (phone != null && existing.phone == phone));
    _profile = matches
        ? existing
        : _newProfile(
            name: email == null ? 'Babes' : _nameFromEmail(email),
            phone: phone,
            email: email,
          );
    _startSession(method: 'password');
    return const AuthResult.ok();
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    final existing = _profile;
    _profile = existing != null && existing.viaGoogle
        ? existing
        : _newProfile(
            name: googleDemoName,
            email: googleDemoEmail,
            viaGoogle: true,
          );
    _startSession(method: 'google');
    return const AuthResult.ok(
      message: 'Demo: masuk dengan akun contoh, tanpa menghubungi Google.',
    );
  }

  @override
  Future<AuthResult> registerQuick({
    required String name,
    required String phone,
    required String email,
  }) async {
    final errors = <AuthField, String>{
      AuthField.name: ?validateName(name),
      AuthField.phone: ?validatePhone(phone),
      AuthField.email: ?validateEmail(email),
    };
    if (errors.isNotEmpty) return AuthResult.invalid(errors);
    _profile = _newProfile(
      name: name.trim(),
      phone: normalizePhone(phone),
      email: email.trim().toLowerCase(),
    );
    _startSession(method: 'quick', registered: true);
    return const AuthResult.ok(
      message: 'Demo: akun langsung aktif, tanpa tautan aktivasi ke email.',
    );
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
    required bool acceptedTerms,
  }) async {
    final errors = <AuthField, String>{
      AuthField.name: ?validateName(name),
      AuthField.phone: ?validatePhone(phone),
      AuthField.email: ?validateEmail(email),
      AuthField.password: ?validatePassword(password),
      AuthField.passwordConfirmation: ?validatePasswordConfirmation(
        password,
        passwordConfirmation,
      ),
      if (!acceptedTerms)
        AuthField.terms: 'Setujui Syarat & Ketentuan untuk mendaftar.',
    };
    if (errors.isNotEmpty) return AuthResult.invalid(errors);
    _profile = _newProfile(
      name: name.trim(),
      phone: normalizePhone(phone),
      email: email.trim().toLowerCase(),
      termsAccepted: true,
    );
    _startSession(method: 'full', registered: true);
    return const AuthResult.ok();
  }

  @override
  Future<AuthResult> requestPasswordReset(String email) async {
    final error = validateEmail(email);
    if (error != null) {
      return AuthResult.invalid(<AuthField, String>{AuthField.email: error});
    }
    return const AuthResult.ok(
      message:
          'Demo: tidak ada email yang dikirim. Di aplikasi Bpedia, tautan atur '
          'ulang kata sandi dikirim ke emailmu.',
    );
  }

  @override
  Future<AuthResult> requestPasswordOtp() async {
    if (!isLoggedIn) {
      return const AuthResult.invalid(<AuthField, String>{
        AuthField.otp: 'Masuk dulu untuk mengubah kata sandi.',
      });
    }
    final code = _random.nextInt(1000000).toString().padLeft(6, '0');
    _otp = code;
    return AuthResult.ok(
      message: 'Demo: kode OTP ditampilkan di layar, tidak dikirim.',
      demoCode: code,
    );
  }

  @override
  Future<AuthResult> changePassword({
    required String otp,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    final expected = _otp;
    final errors = <AuthField, String>{
      if (expected == null)
        AuthField.otp: 'Minta kode OTP dulu.'
      else if (otp.trim() != expected)
        AuthField.otp: 'Kode OTP belum benar.',
      AuthField.password: ?validatePassword(newPassword),
      AuthField.passwordConfirmation: ?validatePasswordConfirmation(
        newPassword,
        passwordConfirmation,
      ),
    };
    if (errors.isNotEmpty) return AuthResult.invalid(errors);
    _otp = null;
    return const AuthResult.ok(
      message: 'Demo: alur selesai. Kata sandi tidak disimpan di perangkat.',
    );
  }

  @override
  Future<void> acceptTerms() async {
    final current = profile;
    if (current == null || current.termsAccepted) return;
    _profile = current.copyWith(termsAccepted: true);
    changed();
  }

  @override
  Future<void> signOut() async {
    if (!_loggedIn) return;
    _loggedIn = false;
    _otp = null;
    unawaited(_analytics?.setUserId(null));
    changed();
  }

  @override
  Future<AuthResult> updateProfile({
    required String name,
    required String email,
  }) async {
    final current = profile;
    if (current == null) return _notLoggedIn(AuthField.name);
    final errors = <AuthField, String>{
      AuthField.name: ?validateName(name),
      AuthField.email: ?validateEmail(email),
    };
    if (errors.isNotEmpty) return AuthResult.invalid(errors);
    _profile = current.copyWith(
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );
    changed();
    return const AuthResult.ok(message: 'Profil tersimpan.');
  }

  @override
  Future<AuthResult> updatePhone(String phone) async {
    final current = profile;
    if (current == null) return _notLoggedIn(AuthField.phone);
    final error = validatePhone(phone);
    if (error != null) {
      return AuthResult.invalid(<AuthField, String>{AuthField.phone: error});
    }
    _profile = current.copyWith(phone: normalizePhone(phone));
    changed();
    return const AuthResult.ok(message: 'Nomor HP tersimpan.');
  }

  /// Masuk seketika dengan profil contoh, tanpa formulir (Mode Demo dan
  /// tes). Profil yang sudah ada dipakai lagi.
  void signInAsDemo({
    String name = 'Babes Demo',
    String phone = '6281234567890',
  }) {
    _profile ??= _newProfile(name: name, phone: phone, termsAccepted: true);
    _startSession(method: 'demo');
  }

  @override
  Object? toJson() => <String, Object?>{
    'loggedIn': _loggedIn,
    'profile': _profile?.toJson(),
  };

  @override
  void restoreState(Object? json) {
    if (json == null) {
      _profile = null;
      _loggedIn = false;
      _otp = null;
      return;
    }
    final map = asJsonMap(json, 'akun');
    final profile = map['profile'] == null
        ? null
        : UserProfile.fromJson(map['profile']);
    final loggedIn = readBool(map, 'loggedIn', fallback: false);
    _profile = profile;
    _loggedIn = loggedIn && profile != null;
    _otp = null;
  }

  void _startSession({required String method, bool registered = false}) {
    _loggedIn = true;
    _otp = null;
    final analytics = _analytics;
    if (analytics != null) {
      unawaited(analytics.setUserId(_profile?.id));
      unawaited(
        registered
            ? analytics.logRegistration(method: method)
            : analytics.logLogin(method: method),
      );
    }
    changed();
  }

  UserProfile _newProfile({
    required String name,
    String? phone,
    String? email,
    bool viaGoogle = false,
    bool termsAccepted = false,
  }) {
    final createdAt = _now().millisecondsSinceEpoch;
    return UserProfile(
      id: 'BP${createdAt.toRadixString(36).toUpperCase()}',
      name: name,
      phone: phone,
      email: email,
      viaGoogle: viaGoogle,
      termsAccepted: termsAccepted,
      createdAtMs: createdAt,
    );
  }

  static String _nameFromEmail(String email) {
    final local = email.split('@').first;
    final words = local
        .split(RegExp(r'[._\-+0-9]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1));
    final name = words.join(' ');
    return name.length < 2 ? 'Babes' : name;
  }

  static AuthResult _notLoggedIn(AuthField field) => AuthResult.invalid(
    <AuthField, String>{field: 'Masuk dulu untuk mengubah profil.'},
  );
}
