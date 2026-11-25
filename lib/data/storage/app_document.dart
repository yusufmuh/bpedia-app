/// Dokumen JSON tunggal milik app (`bpedia_app_v3`), ber-`revision`.
///
/// Tiap repositori adalah satu [DocumentSection]. Dokumen yang hilang, rusak,
/// atau berskema lain dimuat sebagai keadaan bersih; seksi yang rusak diatur
/// ulang sendiri tanpa mengganggu seksi lain. Sebelum menulis, dokumen
/// tersimpan dibaca lagi: bila instans lain (tab browser kedua) menyimpan
/// revisi yang lebih baru, dokumen itu diadopsi, bukan ditimpa.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kelopak_hub/kelopak_hub.dart'
    show JsonMap, KeyValueStore, MemoryKeyValueStore;

import 'migrate_v2.dart';

/// Kunci penyimpanan dokumen app v3.
const String appDocumentKey = 'bpedia_app_v3';

/// Versi skema yang ditulis ke dokumen.
const int appDocumentSchema = 1;

/// Satu bagian dokumen yang dimiliki sebuah repositori.
abstract interface class DocumentSection {
  /// Nama seksi di dalam dokumen.
  String get sectionKey;

  /// Isi seksi sebagai JSON.
  Object? toJson();

  /// Memulihkan seksi dari [json]; null berarti keadaan bawaan. Melempar
  /// [FormatException] bila [json] tidak sah.
  void restore(Object? json);
}

/// Asal data setelah [AppDocument.load].
enum DocumentOrigin {
  /// Tidak ada dokumen: pemakaian pertama.
  fresh,

  /// Dokumen v3 dibaca.
  loaded,

  /// Tidak ada dokumen v3; keranjang dan pengaturan dibawa dari dokumen v2.
  migratedV2,

  /// Dokumen tidak bisa dipakai (JSON rusak atau skema lain): mulai bersih.
  corrupt,
}

/// Penyimpan dokumen app dengan tulis tertunda dan revisi.
class AppDocument {
  /// [saveDelay] nol berarti menyimpan lewat mikrotugas tanpa `Timer`
  /// (dipakai tes widget, yang menolak timer tertunda).
  AppDocument({
    required KeyValueStore store,
    this.saveDelay = const Duration(milliseconds: 300),
  }) : _store = store;

  /// Jeda antara perubahan dan penulisan ke penyimpanan.
  final Duration saveDelay;

  KeyValueStore _store;
  final List<DocumentSection> _sections = <DocumentSection>[];
  final ValueNotifier<int> _adoptedUpdates = ValueNotifier<int>(0);
  Future<void> _saving = Future<void>.value();
  Timer? _timer;
  bool _saveQueued = false;
  bool _disposed = false;
  int _revision = 0;
  Object? _lastSaveError;
  List<String> _resetSections = const <String>[];

  /// Penyimpanan yang dipakai (memori bila penyimpanan perangkat gagal dibaca).
  KeyValueStore get store => _store;

  /// Revisi dokumen yang terakhir dibaca atau ditulis.
  int get revision => _revision;

  /// Galat simpan terakhir; null setelah simpan berhasil.
  Object? get lastSaveError => _lastSaveError;

  /// Seksi yang diatur ulang karena isinya rusak pada pemuatan terakhir.
  List<String> get resetSections => _resetSections;

  /// Berapa kali data diganti dokumen lebih baru dari instans lain. Kerangka
  /// app memberi tahu pengguna tiap kali nilainya naik.
  ValueListenable<int> get adoptedUpdates => _adoptedUpdates;

  /// Mendaftarkan [section]; panggil sebelum [load].
  void register(DocumentSection section) {
    assert(
      _sections.every((other) => other.sectionKey != section.sectionKey),
      'Seksi ${section.sectionKey} terdaftar dua kali',
    );
    _sections.add(section);
  }

  /// Membaca dokumen dan memulihkan semua seksi. Tidak pernah melempar.
  Future<DocumentOrigin> load() async {
    String? raw;
    try {
      raw = await _store.read(appDocumentKey);
    } on Object {
      // Data yang tidak bisa dibaca tidak boleh tertimpa: sesi ini berjalan
      // di memori.
      _store = MemoryKeyValueStore();
      _revision = 0;
      _restoreAll(const <String, Object?>{});
      return DocumentOrigin.corrupt;
    }
    if (raw == null || raw.isEmpty) {
      final migrated = await _readV2();
      _revision = 0;
      _restoreAll(migrated ?? const <String, Object?>{});
      if (migrated == null) return DocumentOrigin.fresh;
      markDirty();
      return DocumentOrigin.migratedV2;
    }
    final envelope = _decode(raw);
    if (envelope == null) {
      _revision = 0;
      _restoreAll(const <String, Object?>{});
      return DocumentOrigin.corrupt;
    }
    _revision = envelope.revision;
    _restoreAll(envelope.sections);
    return DocumentOrigin.loaded;
  }

  /// Menjadwalkan satu penyimpanan.
  void markDirty() {
    if (_disposed) return;
    if (saveDelay == Duration.zero) {
      _queueSave();
      return;
    }
    _timer ??= Timer(saveDelay, () {
      _timer = null;
      _queueSave();
    });
  }

  /// Selesai setelah semua perubahan tertunda ditulis.
  Future<void> flush() {
    final timer = _timer;
    if (timer != null) {
      timer.cancel();
      _timer = null;
      _queueSave();
    }
    return _saving;
  }

  /// Membaca ulang dokumen tersimpan dan mengadopsinya bila instans lain
  /// menyimpan revisi lebih baru. Mengembalikan apakah data diganti.
  Future<bool> syncFromStore() {
    final adopted = _saving.then((_) => _adoptNewer());
    _saving = adopted.then<void>((_) {});
    return adopted;
  }

  /// Mengembalikan semua seksi ke keadaan bawaan lalu menyimpannya (Mode
  /// Demo "Atur ulang data").
  void resetAll() {
    if (_disposed) return;
    _restoreAll(const <String, Object?>{});
    markDirty();
  }

  /// Dokumen saat ini sebagai teks JSON.
  String encode({int? revision}) => jsonEncode(<String, Object?>{
    'schema': appDocumentSchema,
    'revision': revision ?? _revision,
    'sections': <String, Object?>{
      for (final section in _sections) section.sectionKey: section.toJson(),
    },
  });

  /// Menulis perubahan tertunda lalu berhenti menerima perubahan baru.
  Future<void> dispose() async {
    await flush();
    _disposed = true;
    _adoptedUpdates.dispose();
  }

  void _queueSave() {
    if (_saveQueued || _disposed) return;
    _saveQueued = true;
    _saving = _saving.then((_) async {
      _saveQueued = false;
      try {
        final stored = _decode(await _store.read(appDocumentKey));
        if (stored != null && stored.revision > _revision) {
          _adopt(stored);
        } else {
          final next = _revision + 1;
          await _store.write(appDocumentKey, encode(revision: next));
          _revision = next;
        }
        _lastSaveError = null;
      } on Object catch (error) {
        _lastSaveError = error;
      }
    });
  }

  Future<bool> _adoptNewer() async {
    if (_disposed) return false;
    final _Envelope? stored;
    try {
      stored = _decode(await _store.read(appDocumentKey));
    } on Object {
      return false;
    }
    if (_disposed || stored == null || stored.revision <= _revision) {
      return false;
    }
    _adopt(stored);
    return true;
  }

  void _adopt(_Envelope stored) {
    if (_disposed) return;
    _revision = stored.revision;
    _restoreAll(stored.sections);
    _adoptedUpdates.value++;
  }

  void _restoreAll(Map<String, Object?> sections) {
    final reset = <String>[];
    for (final section in _sections) {
      try {
        section.restore(sections[section.sectionKey]);
      } on FormatException {
        reset.add(section.sectionKey);
        section.restore(null);
      }
    }
    _resetSections = List<String>.unmodifiable(reset);
  }

  Future<JsonMap?> _readV2() async {
    try {
      return migrateV2Document(await _store.read(v2DocumentKey));
    } on Object {
      return null;
    }
  }

  static _Envelope? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    final revision = decoded['revision'];
    final sections = decoded['sections'];
    if (decoded['schema'] != appDocumentSchema ||
        revision is! int ||
        revision < 0 ||
        sections is! Map<String, Object?>) {
      return null;
    }
    return _Envelope(revision, sections);
  }
}

final class _Envelope {
  const _Envelope(this.revision, this.sections);

  final int revision;
  final Map<String, Object?> sections;
}
