import 'dart:io';

import 'package:bpedia_app/services/sound/haptics.dart';
import 'package:bpedia_app/services/sound/sound_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SoundCue', () {
    test('cue RENCANA §7.5 dan §10 lengkap dan namanya unik', () {
      expect(
        SoundCue.values.map((cue) => cue.id).toSet(),
        hasLength(SoundCue.values.length),
      );
      expect(SoundCue.values.map((cue) => cue.id).toSet(), <String>{
        'claim',
        'bonus',
        'spin_start',
        'tick',
        'win_product',
        'unlock',
        'tap',
        'soft_error',
        'brand_notifikasi',
        'win_kelopak',
        'mission_done',
        'pop',
        'win_jingle',
      });
      expect(bgmAsset, 'audio/bgm_jingle.mp3');
      expect(bgmWheelAsset, 'audio/bgm_roda.mp3');
    });

    test('tiap cue dan musik latar punya berkas di assets/audio', () {
      for (final cue in SoundCue.values) {
        expect(cue.asset, 'audio/${cue.id}.mp3');
        final file = File('assets/${cue.asset}');
        expect(file.existsSync(), isTrue, reason: cue.asset);
        expect(file.lengthSync(), greaterThan(0), reason: cue.asset);
      }
      expect(File('assets/$bgmAsset').existsSync(), isTrue);
    });

    test('volume dan batas pemutar masuk akal', () {
      for (final cue in SoundCue.values) {
        expect(cue.volume, inInclusiveRange(0.05, 1.0), reason: cue.id);
        expect(cue.maxPlayers, greaterThanOrEqualTo(1), reason: cue.id);
        expect(cue.minIntervalMs, greaterThan(0), reason: cue.id);
      }
      expect(bgmVolume, inInclusiveRange(0.05, 1.0));
    });

    test('byId mengenal nama cue modul game', () {
      expect(SoundCue.byId('spin_start'), SoundCue.spinStart);
      expect(SoundCue.byId('win_product'), SoundCue.winProduct);
      expect(SoundCue.byId('tidak_ada'), isNull);
      expect(SoundCue.byId(''), isNull);
    });
  });

  group('SoundService.silent', () {
    late List<HapticKind> buzzed;
    late SoundService sound;

    setUp(() {
      buzzed = <HapticKind>[];
      sound = SoundService.silent(
        haptics: Haptics(runner: (kind) async => buzzed.add(kind)),
      );
    });

    test('mencatat cue dan memicu getar pendampingnya', () {
      sound.play(SoundCue.claim);
      sound.play(SoundCue.winProduct);

      expect(sound.isSilent, isTrue);
      expect(sound.history, <SoundCue>[SoundCue.claim, SoundCue.winProduct]);
      expect(buzzed, <HapticKind>[HapticKind.light, HapticKind.heavy]);
      expect(sound.lastError, isNull);
    });

    test('suara mati: cue tidak tercatat, getar tetap jalan', () {
      sound.soundOn = false;
      sound.play(SoundCue.bonus);

      expect(sound.history, isEmpty);
      expect(buzzed, <HapticKind>[HapticKind.medium]);
    });

    test('getar mati: cue tetap tercatat tanpa getar', () {
      sound.haptics.enabled = false;
      sound.play(SoundCue.bonus);

      expect(sound.history, <SoundCue>[SoundCue.bonus]);
      expect(buzzed, isEmpty);
    });

    test('withHaptic false dan cue tanpa getar tidak menggetarkan', () {
      sound.play(SoundCue.claim, withHaptic: false);
      sound.play(SoundCue.softError);

      expect(sound.history, <SoundCue>[SoundCue.claim, SoundCue.softError]);
      expect(buzzed, isEmpty);
    });

    test('cue yang sama beruntun ditahan jeda minimumnya', () {
      sound.play(SoundCue.claim);
      sound.play(SoundCue.claim);
      sound.play(SoundCue.unlock);

      expect(sound.history, <SoundCue>[SoundCue.claim, SoundCue.unlock]);
    });

    test('playById: nama dikenal diputar, nama asing diabaikan', () {
      expect(sound.playById('unlock'), isTrue);
      expect(sound.playById('ledakan'), isFalse);
      expect(sound.history, <SoundCue>[SoundCue.unlock]);
    });

    test('riwayat dibatasi 50 cue terakhir dan tidak bisa diubah', () async {
      for (var index = 0; index < 60; index++) {
        sound.play(SoundCue.values[index % SoundCue.values.length]);
      }
      expect(sound.history.length, lessThanOrEqualTo(50));
      expect(() => sound.history.add(SoundCue.tap), throwsUnsupportedError);
    });

    test('musik butuh pengaturan nyala, layar peminta, dan app di depan', () {
      expect(sound.wantsMusic, isFalse);

      sound.startMusic();
      expect(sound.wantsMusic, isFalse, reason: 'pengaturan Musik mati');

      sound.musicOn = true;
      expect(sound.wantsMusic, isTrue);

      sound.setForeground(false);
      expect(sound.wantsMusic, isFalse);
      sound.setForeground(true);
      expect(sound.wantsMusic, isTrue);

      sound.startMusic();
      sound.stopMusic();
      expect(sound.musicHolders, 1);
      expect(sound.wantsMusic, isTrue, reason: 'masih ada satu layar');

      sound.stopMusic();
      expect(sound.wantsMusic, isFalse);
      sound.stopMusic();
      expect(sound.musicHolders, 0, reason: 'tidak pernah negatif');
    });

    test('warmUp tidak menyentuh platform audio', () async {
      await sound.warmUp();
      expect(sound.lastError, isNull);
    });

    test('setelah dispose semua panggilan diabaikan', () async {
      sound.musicOn = true;
      sound.startMusic();
      await sound.dispose();
      await sound.dispose();

      sound.play(SoundCue.claim);
      sound.startMusic();
      sound.stopMusic();
      sound.setForeground(false);

      expect(sound.history, isEmpty);
      expect(buzzed, isEmpty);
      expect(sound.wantsMusic, isFalse);
      expect(sound.musicHolders, 1);
    });
  });

  group('SoundService (tanpa plugin audio)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('kegagalan audio tidak sampai ke pemanggil', () async {
      final sound = SoundService(haptics: Haptics(runner: (_) async {}));

      expect(sound.isSilent, isFalse);
      sound.play(SoundCue.tap);
      await sound.warmUp();
      sound
        ..musicOn = true
        ..startMusic();
      await sound.dispose();

      expect(sound.history, <SoundCue>[SoundCue.tap]);
      expect(sound.lastError, isNotNull);
    });
  });

  group('Haptics', () {
    late List<HapticKind> buzzed;

    setUp(() => buzzed = <HapticKind>[]);

    Haptics create() => Haptics(runner: (kind) async => buzzed.add(kind));

    test('tiap jenis diteruskan ke platform', () {
      create()
        ..light()
        ..medium()
        ..heavy()
        ..success()
        ..selection();

      expect(buzzed, <HapticKind>[
        HapticKind.light,
        HapticKind.medium,
        HapticKind.heavy,
        HapticKind.success,
        HapticKind.selection,
      ]);
    });

    test('pengaturan Getar mati: tidak ada getar', () {
      final haptics = create()..enabled = false;
      haptics
        ..light()
        ..selection();
      expect(buzzed, isEmpty);

      haptics.enabled = true;
      haptics.light();
      expect(buzzed, <HapticKind>[HapticKind.light]);
    });

    test('none diabaikan', () {
      create().perform(HapticKind.none);
      expect(buzzed, isEmpty);
    });

    test('getar seleksi beruntun dibatasi, jenis lain tidak', () {
      final haptics = create();
      for (var index = 0; index < 5; index++) {
        haptics.selection();
      }
      haptics
        ..light()
        ..light();

      expect(
        buzzed.where((kind) => kind == HapticKind.selection),
        hasLength(1),
      );
      expect(buzzed.where((kind) => kind == HapticKind.light), hasLength(2));
    });

    test('perangkat tanpa motor getar: galat platform ditelan', () async {
      Haptics(
        runner: (_) async => throw PlatformException(code: 'tanpa-getar'),
      ).light();
      Haptics(
        runner: (_) async => throw MissingPluginException('tanpa kanal'),
      ).heavy();

      await pumpEventQueue();
    });

    test('pelari bawaan memanggil kanal getar platform', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final calls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add('${call.arguments}');
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      Haptics()
        ..selection()
        ..light()
        ..medium()
        ..heavy();
      await pumpEventQueue();

      expect(calls, <String>[
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ]);
    });
  });
}
