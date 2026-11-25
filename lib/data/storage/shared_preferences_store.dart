/// Penyimpanan perangkat untuk dokumen app (shared_preferences).
library;

import 'package:kelopak_hub/kelopak_hub.dart'
    show KeyValueStore, MemoryKeyValueStore;
import 'package:shared_preferences/shared_preferences.dart';

/// [KeyValueStore] di atas [SharedPreferencesAsync]
/// (DataStore di Android, NSUserDefaults di iOS, localStorage di web).
final class SharedPreferencesKeyValueStore implements KeyValueStore {
  /// Memakai [preferences] atau [SharedPreferencesAsync] bawaan.
  ///
  /// Melempar [StateError] bila platform shared_preferences belum terdaftar.
  SharedPreferencesKeyValueStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> delete(String key) => _preferences.remove(key);
}

/// Penyimpanan perangkat, atau memori bila platform tidak menyediakannya.
KeyValueStore platformKeyValueStore() {
  try {
    return SharedPreferencesKeyValueStore();
  } on StateError {
    return MemoryKeyValueStore();
  }
}
