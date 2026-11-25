/// Riwayat pencarian lokal: 10 kata kunci terakhir.
library;

import 'dart:async';

import 'package:kelopak_hub/kelopak_hub.dart';

import '../../services/analytics/analytics.dart';
import '../storage/document_repository.dart';

/// Kata kunci pencarian terakhir, terbaru lebih dulu.
class SearchHistoryRepository extends DocumentRepository {
  SearchHistoryRepository({Analytics? analytics}) : _analytics = analytics;

  /// Jumlah kata kunci yang disimpan.
  static const int capacity = 10;

  /// Panjang kata kunci terpanjang yang disimpan.
  static const int maxTermLength = 60;

  final Analytics? _analytics;
  List<String> _terms = const <String>[];

  @override
  String get sectionKey => 'searchHistory';

  /// Kata kunci, terbaru lebih dulu.
  List<String> get terms => _terms;

  /// Mencatat pencarian [term] (dan event `af_search`). Kata kunci kosong
  /// diabaikan; yang sudah ada (tanpa beda huruf besar/kecil) naik ke atas.
  void record(String term) {
    var text = term.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return;
    if (text.length > maxTermLength) text = text.substring(0, maxTermLength);
    final lower = text.toLowerCase();
    _terms = List<String>.unmodifiable(
      <String>[
        text,
        ..._terms.where((other) => other.toLowerCase() != lower),
      ].take(capacity),
    );
    unawaited(_analytics?.logSearch(text));
    changed();
  }

  /// Menghapus satu kata kunci.
  void remove(String term) {
    if (!_terms.contains(term)) return;
    _terms = List<String>.unmodifiable(_terms.where((other) => other != term));
    changed();
  }

  /// Menghapus semua riwayat.
  void clear() {
    if (_terms.isEmpty) return;
    _terms = const <String>[];
    changed();
  }

  @override
  Object? toJson() => <String, Object?>{'terms': _terms};

  @override
  void restoreState(Object? json) {
    if (json == null) {
      _terms = const <String>[];
      return;
    }
    final terms = readStringList(asJsonMap(json, 'riwayat cari'), 'terms');
    _terms = List<String>.unmodifiable(terms.take(capacity));
  }
}
