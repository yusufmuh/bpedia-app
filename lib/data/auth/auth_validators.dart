/// Validasi bentuk isian akun (Dart murni). Mengembalikan pesan galat
/// Indonesia, atau null bila isian sah.
library;

final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
final RegExp _digits = RegExp(r'^\d+$');

/// Panjang kata sandi terpendek.
const int minPasswordLength = 6;

/// Apakah [value] berbentuk email.
bool looksLikeEmail(String value) => _email.hasMatch(value.trim());

/// Nomor HP Indonesia dalam bentuk `628…`, atau null bila [value] bukan nomor
/// HP yang sah. Menerima `08…`, `8…`, `628…`, `+628…`, dengan spasi atau
/// tanda hubung.
String? normalizePhone(String value) {
  var digits = value.replaceAll(RegExp(r'[\s\-().]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  if (!_digits.hasMatch(digits)) return null;
  if (digits.startsWith('0')) {
    digits = '62${digits.substring(1)}';
  } else if (digits.startsWith('8')) {
    digits = '62$digits';
  }
  if (!digits.startsWith('628')) return null;
  if (digits.length < 11 || digits.length > 15) return null;
  return digits;
}

/// "0812-3456-7890" dari nomor ternormalisasi `628…`.
String formatPhone(String normalized) {
  final local = normalized.startsWith('62')
      ? '0${normalized.substring(2)}'
      : normalized;
  final parts = <String>[];
  for (var i = 0; i < local.length; i += 4) {
    parts.add(local.substring(i, i + 4 > local.length ? local.length : i + 4));
  }
  return parts.join('-');
}

/// Validasi nama.
String? validateName(String value) {
  final name = value.trim();
  if (name.isEmpty) return 'Isi nama dulu ya, Babes.';
  if (name.length < 2) return 'Nama minimal 2 huruf.';
  if (name.length > 60) return 'Nama maksimal 60 huruf.';
  return null;
}

/// Validasi email.
String? validateEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return 'Isi email dulu ya, Babes.';
  if (!looksLikeEmail(email)) return 'Format email belum benar.';
  return null;
}

/// Validasi nomor HP.
String? validatePhone(String value) {
  if (value.trim().isEmpty) return 'Isi nomor HP dulu ya, Babes.';
  if (normalizePhone(value) == null) {
    return 'Nomor HP belum benar. Contoh: 0812 3456 7890.';
  }
  return null;
}

/// Validasi kolom "Nomor HP atau email".
String? validateIdentifier(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Isi nomor HP atau email dulu ya, Babes.';
  if (text.contains('@')) return validateEmail(text);
  if (normalizePhone(text) == null) {
    return 'Masukkan nomor HP atau email yang benar.';
  }
  return null;
}

/// Validasi bentuk kata sandi (tidak pernah disimpan atau dikirim).
String? validatePassword(String value) {
  if (value.isEmpty) return 'Isi kata sandi dulu ya, Babes.';
  if (value.length < minPasswordLength) {
    return 'Kata sandi minimal $minPasswordLength karakter.';
  }
  return null;
}

/// Validasi konfirmasi kata sandi.
String? validatePasswordConfirmation(String password, String confirmation) {
  if (confirmation.isEmpty) return 'Ulangi kata sandi.';
  if (confirmation != password) return 'Konfirmasi kata sandi belum sama.';
  return null;
}
