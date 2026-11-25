/// Getar ringan untuk interaksi. Mengikuti pengaturan "Getar".
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// Jenis getar.
enum HapticKind { none, selection, light, medium, heavy, success }

/// Fungsi yang menjalankan satu getar platform.
typedef HapticRunner = Future<void> Function(HapticKind kind);

/// Pemicu getar; aman dipanggil di platform tanpa motor getar.
class Haptics {
  Haptics({this.enabled = true, HapticRunner? runner})
    : _runner = runner ?? _platformRunner;

  /// Jeda minimum antar getar seleksi (pasak roda bisa memicu puluhan kali
  /// per detik).
  static const int selectionMinIntervalMs = 84;

  /// Mengikuti pengaturan "Getar".
  bool enabled;

  final HapticRunner _runner;
  final Stopwatch _stopwatch = Stopwatch()..start();
  int? _lastSelectionMs;

  /// Menjalankan getar [kind].
  void perform(HapticKind kind) {
    if (!enabled || kind == HapticKind.none) return;
    if (kind == HapticKind.selection) {
      final now = _stopwatch.elapsedMilliseconds;
      final last = _lastSelectionMs;
      if (last != null && now - last < selectionMinIntervalMs) return;
      _lastSelectionMs = now;
    }
    unawaited(_safely(kind));
  }

  /// Getar seleksi (ketuk, pasak roda).
  void selection() => perform(HapticKind.selection);

  /// Getar ringan.
  void light() => perform(HapticKind.light);

  /// Getar sedang.
  void medium() => perform(HapticKind.medium);

  /// Getar kuat.
  void heavy() => perform(HapticKind.heavy);

  /// Getar berhasil.
  void success() => perform(HapticKind.success);

  Future<void> _safely(HapticKind kind) async {
    try {
      await _runner(kind);
    } on PlatformException {
      // Getar bersifat pelengkap: perangkat tanpa motor getar tetap diam.
    } on MissingPluginException {
      // Sama seperti di atas untuk platform tanpa kanal getar.
    }
  }

  static Future<void> _platformRunner(HapticKind kind) => switch (kind) {
    HapticKind.none => Future<void>.value(),
    HapticKind.selection => HapticFeedback.selectionClick(),
    HapticKind.light => HapticFeedback.lightImpact(),
    HapticKind.medium => HapticFeedback.mediumImpact(),
    HapticKind.heavy => HapticFeedback.heavyImpact(),
    HapticKind.success => HapticFeedback.successNotification(),
  };
}
