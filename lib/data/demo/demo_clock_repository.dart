/// Geseran hari Mode Demo yang tersimpan (untuk uji Sabtu dan streak).
library;

import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

import '../storage/document_repository.dart';

/// Mengatur `WibClock.demoOffsetDays` dan menyimpannya.
class DemoClockRepository extends DocumentRepository {
  DemoClockRepository({required WibClock clock}) : _clock = clock;

  /// Langkah terbesar [advanceDays].
  static const int maxAdvanceDays = 30;

  final WibClock _clock;

  @override
  String get sectionKey => 'clock';

  /// Hari yang ditambahkan Mode Demo (0 atau lebih).
  int get offsetDays => _clock.demoOffsetDays;

  /// Hari WIB yang dipakai app.
  int get today => _clock.today;

  /// Label hari ini: "Sabtu, 28 Nov 2026".
  String get todayLabel => wibDateLabel(_clock.today);

  /// Memajukan kalender demo [days] hari (1..[maxAdvanceDays]).
  void advanceDays(int days) {
    RangeError.checkValueInInterval(days, 1, maxAdvanceDays, 'days');
    _clock.demoOffsetDays += days;
    changed();
  }

  /// Memajukan kalender demo ke Sabtu berikutnya.
  void jumpToNextSaturday() {
    _clock.demoOffsetDays += _clock.nextSaturday() - _clock.today;
    changed();
  }

  /// Kembali ke tanggal nyata.
  void reset() {
    if (_clock.demoOffsetDays == 0) return;
    _clock.demoOffsetDays = 0;
    changed();
  }

  @override
  Object? toJson() => <String, Object?>{'offsetDays': _clock.demoOffsetDays};

  @override
  void restoreState(Object? json) {
    final offset = json == null
        ? 0
        : readInt(asJsonMap(json, 'jam demo'), 'offsetDays', fallback: 0);
    if (offset < 0) throw const FormatException('Geseran hari negatif');
    _clock.demoOffsetDays = offset;
  }
}
