import 'dart:convert';

import 'package:bpedia_app/data/storage/app_document.dart';
import 'package:bpedia_app/data/storage/document_repository.dart';
import 'package:bpedia_app/data/storage/migrate_v2.dart';
import 'package:bpedia_app/data/storage/shared_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart';

/// Seksi contoh: satu bilangan tak negatif.
class CounterRepository extends DocumentRepository {
  CounterRepository(this.sectionKey);

  @override
  final String sectionKey;

  int value = 0;

  void set(int next) {
    value = next;
    changed();
  }

  @override
  Object? toJson() => <String, Object?>{'value': value};

  @override
  void restoreState(Object? json) {
    if (json == null) {
      value = 0;
      return;
    }
    if (json is! Map<String, Object?>) {
      throw const FormatException('Seksi bukan objek');
    }
    final next = json['value'];
    if (next is! int || next < 0) {
      throw const FormatException('Nilai tidak sah');
    }
    value = next;
  }
}

/// Penyimpanan yang bisa dibuat gagal membaca atau menulis.
class FlakyStore implements KeyValueStore {
  final MemoryKeyValueStore inner = MemoryKeyValueStore();
  bool failReads = false;
  bool failWrites = false;
  int writes = 0;

  @override
  Future<String?> read(String key) {
    if (failReads) throw StateError('baca gagal');
    return inner.read(key);
  }

  @override
  Future<void> write(String key, String value) {
    if (failWrites) throw StateError('tulis gagal');
    writes++;
    return inner.write(key, value);
  }

  @override
  Future<void> delete(String key) => inner.delete(key);
}

String envelope(
  Map<String, Object?> sections, {
  int revision = 1,
  int schema = 1,
}) => jsonEncode(<String, Object?>{
  'schema': schema,
  'revision': revision,
  'sections': sections,
});

void main() {
  late MemoryKeyValueStore store;

  (AppDocument, CounterRepository, CounterRepository) open(
    KeyValueStore target,
  ) {
    final document = AppDocument(store: target, saveDelay: Duration.zero);
    final a = CounterRepository('a')..attach(document);
    final b = CounterRepository('b')..attach(document);
    return (document, a, b);
  }

  setUp(() => store = MemoryKeyValueStore());

  group('AppDocument', () {
    test('tanpa dokumen: mulai bersih dan tidak menulis apa pun', () async {
      final (document, a, _) = open(store);

      expect(await document.load(), DocumentOrigin.fresh);
      await document.flush();

      expect(a.value, 0);
      expect(document.revision, 0);
      expect(await store.read(appDocumentKey), isNull);
    });

    test('simpan lalu muat memberi keadaan yang sama; revisi naik', () async {
      final (document, a, b) = open(store);
      await document.load();
      a.set(3);
      b.set(7);
      await document.flush();

      expect(document.revision, 1);
      expect(document.lastSaveError, isNull);
      final saved =
          jsonDecode((await store.read(appDocumentKey))!)
              as Map<String, Object?>;
      expect(saved['schema'], appDocumentSchema);
      expect(saved['revision'], 1);

      final (reopened, a2, b2) = open(store);
      expect(await reopened.load(), DocumentOrigin.loaded);
      expect(a2.value, 3);
      expect(b2.value, 7);
      expect(reopened.revision, 1);

      a2.set(4);
      await reopened.flush();
      expect(reopened.revision, 2);
    });

    test('beberapa perubahan berturutan ditulis sekali', () async {
      final flaky = FlakyStore();
      final (document, a, b) = open(flaky);
      await document.load();

      a.set(1);
      a.set(2);
      b.set(9);
      await document.flush();

      expect(flaky.writes, 1);
      expect(document.revision, 1);
    });

    test('JSON rusak atau skema lain: mulai bersih, tidak crash', () async {
      for (final raw in <String>[
        '{bukan json',
        '[]',
        '"teks"',
        envelope(<String, Object?>{}, schema: 2),
        jsonEncode(<String, Object?>{
          'schema': 1,
          'revision': -1,
          'sections': <String, Object?>{},
        }),
        jsonEncode(<String, Object?>{
          'schema': 1,
          'revision': 'x',
          'sections': <String, Object?>{},
        }),
        jsonEncode(<String, Object?>{
          'schema': 1,
          'revision': 1,
          'sections': <Object?>[],
        }),
      ]) {
        await store.write(appDocumentKey, raw);
        final (document, a, _) = open(store);

        expect(await document.load(), DocumentOrigin.corrupt, reason: raw);
        expect(a.value, 0, reason: raw);
        expect(document.revision, 0, reason: raw);
      }
    });

    test('dokumen rusak diperbaiki oleh simpan berikutnya', () async {
      await store.write(appDocumentKey, '{rusak');
      final (document, a, _) = open(store);
      await document.load();

      a.set(5);
      await document.flush();

      final (reopened, a2, _) = open(store);
      expect(await reopened.load(), DocumentOrigin.loaded);
      expect(a2.value, 5);
    });

    test('satu seksi rusak diatur ulang; seksi lain tetap', () async {
      await store.write(
        appDocumentKey,
        envelope(<String, Object?>{
          'a': <String, Object?>{'value': -4},
          'b': <String, Object?>{'value': 6},
        }, revision: 9),
      );
      final (document, a, b) = open(store);

      expect(await document.load(), DocumentOrigin.loaded);

      expect(a.value, 0);
      expect(b.value, 6);
      expect(document.resetSections, <String>['a']);
      expect(document.revision, 9);
    });

    test('seksi yang tidak dikenal diabaikan; seksi hilang = bawaan', () async {
      await store.write(
        appDocumentKey,
        envelope(<String, Object?>{
          'lain': <String, Object?>{'x': 1},
          'b': <String, Object?>{'value': 2},
        }),
      );
      final (document, a, b) = open(store);

      await document.load();

      expect(a.value, 0);
      expect(b.value, 2);
      expect(document.resetSections, isEmpty);
    });

    test(
      'penyimpanan gagal dibaca: berjalan di memori, data lama utuh',
      () async {
        final flaky = FlakyStore();
        final original = envelope(<String, Object?>{
          'a': <String, Object?>{'value': 8},
        }, revision: 4);
        await flaky.inner.write(appDocumentKey, original);
        flaky.failReads = true;
        final (document, a, _) = open(flaky);

        expect(await document.load(), DocumentOrigin.corrupt);
        a.set(1);
        await document.flush();

        expect(document.store, isA<MemoryKeyValueStore>());
        expect(document.store, isNot(same(flaky)));
        expect(await flaky.inner.read(appDocumentKey), original);
        expect(flaky.writes, 0);
      },
    );

    test('gagal menulis dicatat lalu pulih pada simpan berikutnya', () async {
      final flaky = FlakyStore();
      final (document, a, _) = open(flaky);
      await document.load();

      flaky.failWrites = true;
      a.set(1);
      await document.flush();
      expect(document.lastSaveError, isA<StateError>());
      expect(document.revision, 0);

      flaky.failWrites = false;
      a.set(2);
      await document.flush();
      expect(document.lastSaveError, isNull);
      expect(document.revision, 1);
    });

    test('revisi lebih baru dari tab lain diadopsi, bukan ditimpa', () async {
      final (first, a1, _) = open(store);
      final (second, a2, _) = open(store);
      await first.load();
      await second.load();

      a1.set(10);
      await first.flush();
      a2.set(99);
      await second.flush();

      expect(a2.value, 10);
      expect(second.revision, 1);
      expect(second.adoptedUpdates.value, 1);
      final (check, a3, _) = open(store);
      await check.load();
      expect(a3.value, 10);
    });

    test('syncFromStore mengambil simpanan baru tepat sekali', () async {
      final (first, a1, _) = open(store);
      final (second, a2, _) = open(store);
      await first.load();
      await second.load();
      var notified = 0;
      a2.addListener(() => notified++);

      a1.set(4);
      await first.flush();

      expect(await second.syncFromStore(), isTrue);
      expect(a2.value, 4);
      expect(notified, 1);
      expect(await second.syncFromStore(), isFalse);
      expect(second.adoptedUpdates.value, 1);
    });

    test('resetAll mengembalikan semua seksi dan menyimpannya', () async {
      final (document, a, b) = open(store);
      await document.load();
      a.set(3);
      b.set(4);
      await document.flush();

      document.resetAll();
      await document.flush();

      expect(a.value, 0);
      expect(b.value, 0);
      final (reopened, a2, b2) = open(store);
      await reopened.load();
      expect(a2.value, 0);
      expect(b2.value, 0);
    });

    test(
      'dispose menulis perubahan tertunda lalu berhenti menyimpan',
      () async {
        final flaky = FlakyStore();
        final (document, a, _) = open(flaky);
        await document.load();
        a.set(2);

        await document.dispose();
        expect(flaky.writes, 1);

        a.set(3);
        await Future<void>.delayed(Duration.zero);
        expect(flaky.writes, 1);
      },
    );

    testWidgets('tulis ditunda 300 ms dan digabung', (tester) async {
      final flaky = FlakyStore();
      final document = AppDocument(store: flaky);
      final a = CounterRepository('a')..attach(document);
      await document.load();

      a.set(1);
      await tester.pump(const Duration(milliseconds: 200));
      a.set(2);
      await tester.pump(const Duration(milliseconds: 99));
      expect(flaky.writes, 0);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(flaky.writes, 1);
      expect(document.revision, 1);

      a.set(3);
      await document.flush();
      expect(flaky.writes, 2);
    });
  });

  group('DocumentRepository', () {
    test('tanpa dokumen tetap berfungsi di memori', () {
      final repository = CounterRepository('a');
      var notified = 0;
      repository
        ..addListener(() => notified++)
        ..set(2);

      expect(repository.value, 2);
      expect(notified, 1);
    });

    test('setelah dispose tidak memberi tahu dan tidak melempar', () {
      final repository = CounterRepository('a');
      var notified = 0;
      repository
        ..addListener(() => notified++)
        ..dispose()
        ..set(5)
        ..restore(null);

      expect(notified, 0);
    });
  });

  group('migrasi v2', () {
    final v2 = jsonEncode(<String, Object?>{
      'schema': 1,
      'revision': 12,
      'clockOffsetDays': 3,
      'settings': <String, Object?>{
        'themeMode': 'dark',
        'sfxEnabled': false,
        'musicEnabled': true,
        'hapticsEnabled': false,
      },
      'shop': <String, Object?>{
        'cart': <Object?>[
          <String, Object?>{'productId': 'P39A06S01000002', 'qty': 2},
          <String, Object?>{'productId': 'P39A06S01000007', 'qty': 0},
          <String, Object?>{'productId': 7, 'qty': 1},
          'bukan baris',
        ],
        'orders': <Object?>[
          <String, Object?>{'id': 'BP-250101-0001'},
        ],
      },
      'rewards': <String, Object?>{'balance': 40},
    });

    test('hanya keranjang, pengaturan, dan geseran hari yang dibawa', () {
      final sections = migrateV2Document(v2)!;

      expect(sections.keys.toSet(), <String>{'settings', 'cart', 'clock'});
      expect(sections['settings'], <String, Object?>{
        'themeMode': 'dark',
        'soundOn': false,
        'musicOn': true,
        'hapticsOn': false,
      });
      expect(sections['cart'], <String, Object?>{
        'lines': <Object?>[
          <String, Object?>{
            'productCode': 'P39A06S01000002',
            'qty': 2,
            'selected': true,
          },
        ],
      });
      expect(sections['clock'], <String, Object?>{'offsetDays': 3});
    });

    test('nilai tak dikenal dilewati, bukan ditebak', () {
      final sections = migrateV2Document(
        jsonEncode(<String, Object?>{
          'schema': 1,
          'clockOffsetDays': -2,
          'settings': <String, Object?>{
            'themeMode': 'ungu',
            'sfxEnabled': 'ya',
          },
        }),
      )!;

      expect(sections['settings'], <String, Object?>{});
      expect(sections.containsKey('clock'), isFalse);
      expect(sections.containsKey('cart'), isFalse);
    });

    test('kosong, rusak, atau skema lain: tidak ada migrasi', () {
      expect(migrateV2Document(null), isNull);
      expect(migrateV2Document(''), isNull);
      expect(migrateV2Document('{rusak'), isNull);
      expect(migrateV2Document('[1,2]'), isNull);
      expect(migrateV2Document('{"schema":2}'), isNull);
    });

    test(
      'sekali jalan: dokumen v3 ditulis, kunci lama tidak dihapus',
      () async {
        await store.write(v2DocumentKey, v2);
        final document = AppDocument(store: store, saveDelay: Duration.zero);
        final other = CounterRepository('lain')..attach(document);

        expect(await document.load(), DocumentOrigin.migratedV2);
        await document.flush();

        expect(other.value, 0);
        expect(await store.read(v2DocumentKey), v2);
        expect(await store.read(appDocumentKey), isNotNull);

        final again = AppDocument(store: store, saveDelay: Duration.zero);
        CounterRepository('lain').attach(again);
        expect(await again.load(), DocumentOrigin.loaded);
      },
    );

    test('dokumen v3 yang sudah ada tidak ditimpa migrasi', () async {
      await store.write(v2DocumentKey, v2);
      await store.write(
        appDocumentKey,
        envelope(<String, Object?>{
          'a': <String, Object?>{'value': 5},
        }),
      );
      final (document, a, _) = open(store);

      expect(await document.load(), DocumentOrigin.loaded);
      expect(a.value, 5);
    });

    test('dokumen v2 rusak: mulai bersih', () async {
      await store.write(v2DocumentKey, '{rusak');
      final (document, a, _) = open(store);

      expect(await document.load(), DocumentOrigin.fresh);
      expect(a.value, 0);
    });
  });

  test('tanpa plugin penyimpanan: jatuh ke memori', () async {
    final fallback = platformKeyValueStore();

    expect(fallback, isA<MemoryKeyValueStore>());
    await fallback.write('k', 'v');
    expect(await fallback.read('k'), 'v');
    await fallback.delete('k');
    expect(await fallback.read('k'), isNull);
  });
}
