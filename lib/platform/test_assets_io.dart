/// VM: baca berkas dari folder kerja (akar paket saat `flutter test`).
library;

import 'dart:io';

/// Isi teks berkas proyek di [path], atau null bila tidak bisa dibaca.
String? readProjectFileSync(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return null;
  }
}
