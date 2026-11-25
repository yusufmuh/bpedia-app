/// Dasar semua repositori yang tersimpan di dokumen app.
library;

import 'package:flutter/foundation.dart';

import 'app_document.dart';

/// Repositori `ChangeNotifier` yang menjadi satu seksi [AppDocument].
///
/// Tanpa [attach] repositori tetap berfungsi di memori (berguna untuk tes).
abstract class DocumentRepository extends ChangeNotifier
    implements DocumentSection {
  AppDocument? _document;
  bool _disposed = false;

  /// Apakah [dispose] sudah dipanggil.
  @protected
  bool get isDisposed => _disposed;

  /// Menyambungkan repositori ke [document] sebagai seksi [sectionKey].
  void attach(AppDocument document) {
    _document = document;
    document.register(this);
  }

  /// Memulihkan keadaan dari [json] (null = bawaan) tanpa memberi tahu
  /// pendengar. Melempar [FormatException] bila [json] tidak sah; keadaan
  /// lama harus tetap utuh bila melempar.
  @protected
  void restoreState(Object? json);

  @override
  void restore(Object? json) {
    restoreState(json);
    if (!_disposed) notifyListeners();
  }

  /// Memberi tahu pendengar dan menjadwalkan penyimpanan.
  @protected
  void changed() {
    if (_disposed) return;
    notifyListeners();
    _document?.markDirty();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
