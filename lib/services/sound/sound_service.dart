/// Efek suara dan musik latar (audioplayers). Mengikuti pengaturan "Suara"
/// dan "Musik"; kegagalan audio tidak pernah sampai ke pemanggil.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'haptics.dart';

/// Cue suara dari `assets/audio/`.
enum SoundCue {
  tap('tap', volume: 0.35, minIntervalMs: 60, haptic: HapticKind.selection),
  tick(
    'tick',
    volume: 0.3,
    maxPlayers: 4,
    minIntervalMs: 40,
    haptic: HapticKind.selection,
  ),
  claim('claim', haptic: HapticKind.light),
  bonus('bonus', haptic: HapticKind.medium),
  spinStart('spin_start', haptic: HapticKind.selection),
  winProduct('win_product', haptic: HapticKind.heavy),
  unlock('unlock', haptic: HapticKind.light),
  softError('soft_error'),
  brandNotifikasi('brand_notifikasi', haptic: HapticKind.success);

  const SoundCue(
    this.id, {
    this.volume = 0.8,
    this.maxPlayers = 2,
    this.minIntervalMs = 120,
    this.haptic = HapticKind.none,
  });

  /// Nama berkas tanpa ekstensi; juga nama cue yang dikenal modul game.
  final String id;

  /// Volume 0..1.
  final double volume;

  /// Jumlah pemutar yang boleh berbunyi bersamaan.
  final int maxPlayers;

  /// Jeda minimum antar pemutaran cue yang sama.
  final int minIntervalMs;

  /// Getar pendamping.
  final HapticKind haptic;

  /// Jalur relatif terhadap `assets/` (awalan bawaan audioplayers).
  String get asset => 'audio/$id.mp3';

  /// Cue ber-[id], atau null.
  static SoundCue? byId(String id) {
    for (final cue in values) {
      if (cue.id == id) return cue;
    }
    return null;
  }
}

/// Jingle Bpedia sebagai musik latar zona Hadiah.
const String bgmAsset = 'audio/bgm_jingle.mp3';

/// Volume musik latar.
const double bgmVolume = 0.35;

/// Pemutar efek suara dan musik latar.
///
/// [SoundService.silent] tidak menyentuh platform audio dan mencatat cue
/// yang diminta di [history] (dipakai tes).
class SoundService {
  /// Layanan suara sungguhan.
  SoundService({Haptics? haptics})
    : _silent = false,
      haptics = haptics ?? Haptics();

  /// Layanan senyap untuk tes dan platform tanpa audio.
  SoundService.silent({Haptics? haptics})
    : _silent = true,
      haptics = haptics ?? Haptics(runner: (_) async {});

  static const int _retryAfterMs = 5000;
  static const int _historyCapacity = 50;

  /// Getar pendamping cue.
  final Haptics haptics;

  final bool _silent;
  final Map<SoundCue, AudioPool> _ready = <SoundCue, AudioPool>{};
  final Map<SoundCue, Future<AudioPool?>> _loading =
      <SoundCue, Future<AudioPool?>>{};
  final Map<SoundCue, int> _lastPlayMs = <SoundCue, int>{};
  final Map<SoundCue, int> _failedAtMs = <SoundCue, int>{};
  final List<SoundCue> _history = <SoundCue>[];
  final Stopwatch _stopwatch = Stopwatch()..start();
  Future<void>? _contextReady;
  Future<void> _musicQueue = Future<void>.value();
  AudioPlayer? _bgm;
  bool _bgmPlaying = false;
  bool _musicEnabled = false;
  bool _foreground = true;
  int _musicHolders = 0;
  bool _disposed = false;
  Object? _lastError;

  /// Apakah layanan senyap.
  bool get isSilent => _silent;

  /// Galat audio terakhir (untuk Mode Demo); null bila belum ada.
  Object? get lastError => _lastError;

  /// Cue yang lolos gerbang pengaturan, terlama lebih dulu (maks. 50).
  List<SoundCue> get history => List<SoundCue>.unmodifiable(_history);

  /// Mengikuti pengaturan "Suara".
  bool soundOn = true;

  /// Mengikuti pengaturan "Musik".
  bool get musicOn => _musicEnabled;
  set musicOn(bool value) {
    if (_musicEnabled == value) return;
    _musicEnabled = value;
    _syncMusic();
  }

  /// Jumlah layar yang sedang meminta musik latar.
  int get musicHolders => _musicHolders;

  /// Apakah musik latar seharusnya berbunyi sekarang.
  bool get wantsMusic =>
      !_disposed && _musicEnabled && _musicHolders > 0 && _foreground;

  /// Memuat semua efek supaya pemutaran pertama tidak terlambat.
  Future<void> warmUp() async {
    if (_silent || _disposed) return;
    await _ensureAudioContext();
    for (final cue in SoundCue.values) {
      await _poolFor(cue);
    }
  }

  /// Memutar [cue] beserta getarnya. Suara dan getar punya sakelar sendiri.
  void play(SoundCue cue, {bool withHaptic = true}) {
    if (_disposed) return;
    if (withHaptic) haptics.perform(cue.haptic);
    if (!soundOn) return;
    final now = _stopwatch.elapsedMilliseconds;
    final last = _lastPlayMs[cue];
    if (last != null && now - last < cue.minIntervalMs) return;
    _lastPlayMs[cue] = now;
    _history.add(cue);
    if (_history.length > _historyCapacity) _history.removeAt(0);
    if (_silent) return;
    final pool = _ready[cue];
    if (pool == null) {
      unawaited(_poolFor(cue));
      return;
    }
    unawaited(_guard(() => pool.start(volume: cue.volume)));
  }

  /// Memutar cue bernama [id] (nama cue modul game); nama tak dikenal
  /// diabaikan. Mengembalikan apakah nama dikenal.
  bool playById(String id) {
    final cue = SoundCue.byId(id);
    if (cue == null) return false;
    play(cue);
    return true;
  }

  /// Sebuah layar meminta musik latar. Pasangkan dengan [stopMusic].
  void startMusic() {
    if (_disposed) return;
    _musicHolders++;
    _syncMusic();
  }

  /// Layar yang meminta musik latar sudah ditutup.
  void stopMusic() {
    if (_disposed) return;
    if (_musicHolders > 0) _musicHolders--;
    _syncMusic();
  }

  /// App pindah ke latar belakang atau kembali ke depan.
  void setForeground(bool foreground) {
    if (_disposed || _foreground == foreground) return;
    _foreground = foreground;
    _syncMusic();
  }

  /// Melepas semua pemutar.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final pending in List<Future<AudioPool?>>.of(_loading.values)) {
      await pending;
    }
    final pools = List<AudioPool>.of(_ready.values);
    _ready.clear();
    for (final pool in pools) {
      await _guard(pool.dispose);
    }
    await _musicQueue;
    final bgm = _bgm;
    _bgm = null;
    if (bgm != null) await _guard(bgm.dispose);
  }

  Future<AudioPool?> _poolFor(SoundCue cue) {
    final ready = _ready[cue];
    if (ready != null) return Future<AudioPool?>.value(ready);
    final loading = _loading[cue];
    if (loading != null) return loading;
    final failedAt = _failedAtMs[cue];
    if (_disposed ||
        (failedAt != null &&
            _stopwatch.elapsedMilliseconds - failedAt < _retryAfterMs)) {
      return Future<AudioPool?>.value();
    }
    final created = _createPool(cue).then((pool) {
      _loading.remove(cue);
      if (pool == null) {
        _failedAtMs[cue] = _stopwatch.elapsedMilliseconds;
      } else {
        _ready[cue] = pool;
      }
      return pool;
    });
    _loading[cue] = created;
    return created;
  }

  Future<AudioPool?> _createPool(SoundCue cue) async {
    try {
      await _ensureAudioContext();
      final pool = await AudioPool.createFromAsset(
        path: cue.asset,
        maxPlayers: cue.maxPlayers,
      );
      if (_disposed) {
        await _guard(pool.dispose);
        return null;
      }
      return pool;
    } on Object catch (error) {
      _lastError = error;
      return null;
    }
  }

  /// Efek suara tidak mengambil fokus audio, jadi musik pengguna dari app
  /// lain tetap berjalan.
  Future<void> _ensureAudioContext() => _contextReady ??= _guard(
    () => AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    ),
  );

  void _syncMusic() {
    if (_silent) return;
    _musicQueue = _musicQueue.then((_) => _applyMusic());
  }

  Future<void> _applyMusic() async {
    final shouldPlay = wantsMusic;
    if (shouldPlay == _bgmPlaying) return;
    if (shouldPlay) {
      final player = _bgm ??= await _createBgm();
      if (player == null) return;
      _bgmPlaying = await _guard(() async {
        await player.setVolume(bgmVolume);
        await player.resume();
      });
    } else {
      final player = _bgm;
      if (player != null) await _guard(player.pause);
      _bgmPlaying = false;
    }
  }

  Future<AudioPlayer?> _createBgm() async {
    AudioPlayer? player;
    try {
      await _ensureAudioContext();
      player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setSource(AssetSource(bgmAsset));
      return player;
    } on Object catch (error) {
      _lastError = error;
      if (player != null) await _guard(player.dispose);
      return null;
    }
  }

  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on Object catch (error) {
      _lastError = error;
      return false;
    }
  }
}
