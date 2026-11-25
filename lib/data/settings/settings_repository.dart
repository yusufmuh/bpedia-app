/// Preferensi pengguna: tema, suara, getar, kurangi gerak, musik.
library;

import 'package:flutter/material.dart' show Brightness, ThemeMode;
import 'package:kelopak_hub/kelopak_hub.dart';

import '../storage/document_repository.dart';

/// Preferensi tak-berubah.
final class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.soundOn = true,
    this.hapticsOn = true,
    this.reduceMotion = false,
    this.musicOn = false,
  });

  /// Membaca preferensi; kunci yang hilang memakai nilai bawaan.
  factory AppSettings.fromJson(Object? source) {
    final json = asJsonMap(source, 'pengaturan');
    return AppSettings(
      themeMode: readEnum(
        json,
        'themeMode',
        ThemeMode.values,
        fallback: ThemeMode.system,
      ),
      soundOn: readBool(json, 'soundOn', fallback: true),
      hapticsOn: readBool(json, 'hapticsOn', fallback: true),
      reduceMotion: readBool(json, 'reduceMotion', fallback: false),
      musicOn: readBool(json, 'musicOn', fallback: false),
    );
  }

  /// Terang, gelap, atau ikuti sistem.
  final ThemeMode themeMode;

  /// Efek suara (bawaan menyala).
  final bool soundOn;

  /// Getar (bawaan menyala).
  final bool hapticsOn;

  /// Kurangi gerak (bawaan mati; pengaturan sistem tetap dihormati).
  final bool reduceMotion;

  /// Musik latar di zona Hadiah (bawaan mati).
  final bool musicOn;

  /// Salinan dengan bidang diganti.
  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundOn,
    bool? hapticsOn,
    bool? reduceMotion,
    bool? musicOn,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    soundOn: soundOn ?? this.soundOn,
    hapticsOn: hapticsOn ?? this.hapticsOn,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    musicOn: musicOn ?? this.musicOn,
  );

  /// Bentuk JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'themeMode': themeMode.name,
    'soundOn': soundOn,
    'hapticsOn': hapticsOn,
    'reduceMotion': reduceMotion,
    'musicOn': musicOn,
  };

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.soundOn == soundOn &&
      other.hapticsOn == hapticsOn &&
      other.reduceMotion == reduceMotion &&
      other.musicOn == musicOn;

  @override
  int get hashCode =>
      Object.hash(themeMode, soundOn, hapticsOn, reduceMotion, musicOn);
}

/// Preferensi pengguna yang tersimpan.
class SettingsRepository extends DocumentRepository {
  AppSettings _settings = const AppSettings();

  @override
  String get sectionKey => 'settings';

  /// Preferensi saat ini.
  AppSettings get settings => _settings;

  /// Terang, gelap, atau ikuti sistem.
  ThemeMode get themeMode => _settings.themeMode;

  /// Efek suara.
  bool get soundOn => _settings.soundOn;

  /// Getar.
  bool get hapticsOn => _settings.hapticsOn;

  /// Kurangi gerak.
  bool get reduceMotion => _settings.reduceMotion;

  /// Musik latar.
  bool get musicOn => _settings.musicOn;

  /// Memilih tema.
  void setThemeMode(ThemeMode mode) =>
      _update(_settings.copyWith(themeMode: mode));

  /// Sakelar tema Beranda: dari tampilan [current] ke kebalikannya.
  void toggleTheme(Brightness current) => setThemeMode(
    current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  );

  /// Efek suara nyala/mati.
  void setSoundOn(bool value) => _update(_settings.copyWith(soundOn: value));

  /// Getar nyala/mati.
  void setHapticsOn(bool value) =>
      _update(_settings.copyWith(hapticsOn: value));

  /// Kurangi gerak nyala/mati.
  void setReduceMotion(bool value) =>
      _update(_settings.copyWith(reduceMotion: value));

  /// Musik latar nyala/mati.
  void setMusicOn(bool value) => _update(_settings.copyWith(musicOn: value));

  void _update(AppSettings next) {
    if (next == _settings) return;
    _settings = next;
    changed();
  }

  @override
  Object? toJson() => _settings.toJson();

  @override
  void restoreState(Object? json) {
    _settings = json == null
        ? const AppSettings()
        : AppSettings.fromJson(json);
  }
}
