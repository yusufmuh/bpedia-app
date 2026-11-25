/// Implementasi web `browser.dart` (package:web).
library;

import 'dart:async';

import 'package:web/web.dart' as web;

/// Apakah browser meminta gerak dikurangi (`prefers-reduced-motion: reduce`).
bool browserPrefersReducedMotion() =>
    web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/// Memanggil [onChange] saat tab lain dari asal yang sama mengubah [key] di
/// localStorage (atau mengosongkannya). Browser hanya mengirim peristiwa ini ke
/// tab lain, tidak ke tab yang menulis. Mengembalikan fungsi untuk berhenti.
void Function() watchBrowserStorageKey(String key, void Function() onChange) {
  final subscription = web.EventStreamProviders.storageEvent
      .forTarget(web.window)
      .listen((event) {
        final changed = event.key;
        if (changed == null || changed == key) onChange();
      });
  return () => unawaited(subscription.cancel());
}
