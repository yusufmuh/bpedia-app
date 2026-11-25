import 'dart:convert';
import 'dart:math';

import 'package:bpedia_app/data/auth/auth_repository.dart';
import 'package:bpedia_app/data/storage/app_document.dart';
import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

const String _secret = 'RahasiaBanget#2026';

void main() {
  late LocalAnalytics analytics;
  late LocalAuthRepository auth;

  setUp(() {
    analytics = LocalAnalytics();
    auth = LocalAuthRepository(
      analytics: analytics,
      now: () => DateTime.utc(2026, 11, 25, 3),
      random: Random(7),
    );
  });

  group('validasi bentuk', () {
    test('nomor HP dinormalkan ke 62 dan ditampilkan berkelompok', () {
      expect(normalizePhone('0812-3456-7890'), '6281234567890');
      expect(normalizePhone('+62 812 3456 7890'), '6281234567890');
      expect(normalizePhone('81234567890'), '6281234567890');
      expect(normalizePhone('021-555-1234'), isNull);
      expect(normalizePhone('0812abc'), isNull);
      expect(normalizePhone('0812'), isNull);
      expect(formatPhone('6281234567890'), '0812-3456-7890');
    });

    test('pesan galat spesifik per kolom', () {
      expect(validateIdentifier(''), contains('nomor HP atau email'));
      expect(validateIdentifier('sari@'), 'Format email belum benar.');
      expect(validateIdentifier('12345'), isNotNull);
      expect(validateIdentifier('sari@contoh.id'), isNull);
      expect(validateIdentifier('081234567890'), isNull);
      expect(validatePassword(''), contains('kata sandi'));
      expect(validatePassword('12345'), contains('$minPasswordLength'));
      expect(validatePassword('123456'), isNull);
      expect(validatePasswordConfirmation('abcdef', ''), isNotNull);
      expect(validatePasswordConfirmation('abcdef', 'abcdeg'), isNotNull);
      expect(validatePasswordConfirmation('abcdef', 'abcdef'), isNull);
      expect(validateName(' '), isNotNull);
      expect(validateName('A'), isNotNull);
      expect(validateName('Sari'), isNull);
      expect(validateEmail('sari@contoh'), isNotNull);
      expect(looksLikeEmail(' sari@contoh.id '), isTrue);
    });
  });

  test('tamu: belum masuk dan tanpa profil', () {
    expect(auth.isLoggedIn, isFalse);
    expect(auth.profile, isNull);
    expect(auth.needsTermsAcceptance, isFalse);
  });

  test('masuk dengan email membuat profil lokal dan butuh setuju S&K', () async {
    final invalid = await auth.signIn(identifier: 'sari', password: '123');
    expect(invalid.ok, isFalse);
    expect(invalid.errorFor(AuthField.identifier), isNotNull);
    expect(invalid.errorFor(AuthField.password), isNotNull);
    expect(invalid.firstError, invalid.errorFor(AuthField.identifier));
    expect(auth.isLoggedIn, isFalse);

    final result = await auth.signIn(
      identifier: ' Sari.Dewi@Contoh.id ',
      password: _secret,
    );
    expect(result.ok, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.profile!.email, 'sari.dewi@contoh.id');
    expect(auth.profile!.name, 'Sari Dewi');
    expect(auth.profile!.initials, 'SD');
    expect(auth.profile!.contactLabel, 'sari.dewi@contoh.id');
    expect(auth.needsTermsAcceptance, isTrue);

    await auth.acceptTerms();
    expect(auth.needsTermsAcceptance, isFalse);
    expect(analytics.eventNames, <String>[AfEvent.login]);
    expect(analytics.userId, auth.profile!.id);
  });

  test('masuk dengan nomor HP; profil yang sama dipakai lagi', () async {
    await auth.signIn(identifier: '0812-3456-7890', password: _secret);
    final id = auth.profile!.id;
    expect(auth.profile!.phone, '6281234567890');
    expect(auth.profile!.phoneLabel, '0812-3456-7890');
    expect(auth.profile!.name, 'Babes');

    await auth.signOut();
    expect(auth.isLoggedIn, isFalse);
    expect(auth.profile, isNull);
    expect(analytics.userId, isNull);

    await auth.signIn(identifier: '+6281234567890', password: 'lainnya1');
    expect(auth.profile!.id, id);
  });

  test('kata sandi tidak pernah disimpan atau dicatat', () async {
    final store = MemoryKeyValueStore();
    final document = AppDocument(store: store, saveDelay: Duration.zero);
    auth.attach(document);

    await auth.signIn(identifier: 'sari@contoh.id', password: _secret);
    await auth.register(
      name: 'Sari Dewi',
      phone: '081234567890',
      email: 'sari@contoh.id',
      password: _secret,
      passwordConfirmation: _secret,
      acceptedTerms: true,
    );
    final otp = await auth.requestPasswordOtp();
    await auth.changePassword(
      otp: otp.demoCode!,
      newPassword: _secret,
      passwordConfirmation: _secret,
    );
    await document.flush();

    final saved = store.values[appDocumentKey]!;
    expect(saved, contains('sari@contoh.id'));
    expect(saved, isNot(contains(_secret)));
    expect(saved.toLowerCase(), isNot(contains('password')));
    expect(saved.toLowerCase(), isNot(contains('sandi')));
    expect(jsonEncode(auth.toJson()), isNot(contains(otp.demoCode!)));
    for (final record in analytics.records) {
      expect(jsonEncode(record.values), isNot(contains(_secret)));
    }
  });

  test('masuk dengan Google memakai akun contoh', () async {
    final result = await auth.signInWithGoogle();
    expect(result.ok, isTrue);
    expect(result.message, contains('Demo'));
    expect(auth.profile!.viaGoogle, isTrue);
    expect(auth.profile!.email, LocalAuthRepository.googleDemoEmail);
    expect(auth.profile!.name, LocalAuthRepository.googleDemoName);
  });

  test('daftar cepat: akun langsung aktif', () async {
    final invalid = await auth.registerQuick(
      name: '',
      phone: '123',
      email: 'salah',
    );
    expect(invalid.errors.keys, <AuthField>[
      AuthField.name,
      AuthField.phone,
      AuthField.email,
    ]);

    final result = await auth.registerQuick(
      name: ' Sari Dewi ',
      phone: '081234567890',
      email: 'Sari@Contoh.id',
    );
    expect(result.ok, isTrue);
    expect(result.message, contains('Demo'));
    expect(auth.profile!.name, 'Sari Dewi');
    expect(auth.profile!.phone, '6281234567890');
    expect(auth.profile!.email, 'sari@contoh.id');
    expect(auth.needsTermsAcceptance, isTrue);
    expect(analytics.eventNames, <String>[AfEvent.completeRegistration]);
  });

  test('daftar lengkap wajib setuju S&K dan konfirmasi sandi sama', () async {
    final invalid = await auth.register(
      name: 'Sari Dewi',
      phone: '081234567890',
      email: 'sari@contoh.id',
      password: _secret,
      passwordConfirmation: 'beda-sandi',
      acceptedTerms: false,
    );
    expect(invalid.errors.keys, <AuthField>[
      AuthField.passwordConfirmation,
      AuthField.terms,
    ]);
    expect(auth.isLoggedIn, isFalse);

    final result = await auth.register(
      name: 'Sari Dewi',
      phone: '081234567890',
      email: 'sari@contoh.id',
      password: _secret,
      passwordConfirmation: _secret,
      acceptedTerms: true,
    );
    expect(result.ok, isTrue);
    expect(auth.needsTermsAcceptance, isFalse);
  });

  test('lupa sandi: hanya memeriksa bentuk email', () async {
    expect((await auth.requestPasswordReset('salah')).ok, isFalse);
    final result = await auth.requestPasswordReset('sari@contoh.id');
    expect(result.ok, isTrue);
    expect(result.message, contains('tidak ada email yang dikirim'));
    expect(auth.isLoggedIn, isFalse);
  });

  test('ubah sandi dengan OTP demo', () async {
    expect(
      (await auth.requestPasswordOtp()).errorFor(AuthField.otp),
      contains('Masuk dulu'),
    );
    await auth.signIn(identifier: 'sari@contoh.id', password: _secret);
    expect(
      (await auth.changePassword(
        otp: '000000',
        newPassword: _secret,
        passwordConfirmation: _secret,
      )).errorFor(AuthField.otp),
      'Minta kode OTP dulu.',
    );

    final otp = await auth.requestPasswordOtp();
    expect(otp.demoCode, hasLength(6));
    final wrong = otp.demoCode == '111111' ? '222222' : '111111';
    expect(
      (await auth.changePassword(
        otp: wrong,
        newPassword: _secret,
        passwordConfirmation: _secret,
      )).errorFor(AuthField.otp),
      'Kode OTP belum benar.',
    );
    final done = await auth.changePassword(
      otp: otp.demoCode!,
      newPassword: _secret,
      passwordConfirmation: _secret,
    );
    expect(done.ok, isTrue);
    expect(done.message, contains('tidak disimpan'));
    expect(
      (await auth.changePassword(
        otp: otp.demoCode!,
        newPassword: _secret,
        passwordConfirmation: _secret,
      )).ok,
      isFalse,
    );
  });

  test('ubah profil dan nomor HP', () async {
    expect((await auth.updateProfile(name: 'A', email: 'a@b.id')).ok, isFalse);
    await auth.signIn(identifier: 'sari@contoh.id', password: _secret);

    expect(
      (await auth.updateProfile(name: 'S', email: 'salah')).errors.length,
      2,
    );
    final saved = await auth.updateProfile(
      name: ' Sari D. ',
      email: 'Baru@Contoh.id',
    );
    expect(saved.message, 'Profil tersimpan.');
    expect(auth.profile!.name, 'Sari D.');
    expect(auth.profile!.email, 'baru@contoh.id');

    expect((await auth.updatePhone('123')).ok, isFalse);
    expect((await auth.updatePhone('0857 1111 2222')).ok, isTrue);
    expect(auth.profile!.phone, '6285711112222');
    expect(auth.profile!.contactLabel, '0857-1111-2222');
  });

  test('sesi bertahan setelah dimuat ulang; JSON rusak ditolak', () async {
    await auth.signIn(identifier: 'sari@contoh.id', password: _secret);
    await auth.acceptTerms();
    final copy = LocalAuthRepository()..restore(auth.toJson());
    expect(copy.isLoggedIn, isTrue);
    expect(copy.profile!.id, auth.profile!.id);
    expect(copy.profile!.termsAccepted, isTrue);

    await auth.signOut();
    final signedOut = LocalAuthRepository()..restore(auth.toJson());
    expect(signedOut.isLoggedIn, isFalse);

    expect(
      () => copy.restore(<String, Object?>{
        'loggedIn': true,
        'profile': <String, Object?>{'id': '', 'name': ''},
      }),
      throwsFormatException,
    );
    expect(copy.isLoggedIn, isTrue);
    copy.restore(<String, Object?>{'loggedIn': true, 'profile': null});
    expect(copy.isLoggedIn, isFalse);
  });

  test('masuk seketika untuk Mode Demo dan tes', () {
    auth.signInAsDemo();
    expect(auth.isLoggedIn, isTrue);
    expect(auth.profile!.name, 'Babes Demo');
    expect(auth.needsTermsAcceptance, isFalse);
  });
}
