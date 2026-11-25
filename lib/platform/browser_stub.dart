/// Implementasi non-web `browser.dart`: tidak ada yang dibaca atau dipantau.
library;

/// Apakah browser meminta gerak dikurangi (selalu false di luar web).
bool browserPrefersReducedMotion() => false;

/// Memanggil `onChange` saat tab lain mengubah `key` di localStorage.
/// Mengembalikan fungsi untuk berhenti memantau.
void Function() watchBrowserStorageKey(String key, void Function() onChange) =>
    _stop;

void _stop() {}
