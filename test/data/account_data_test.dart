import 'package:bpedia_app/data/address/address_repository.dart';
import 'package:bpedia_app/data/demo/demo_clock_repository.dart';
import 'package:bpedia_app/data/inbox/inbox_repository.dart';
import 'package:bpedia_app/data/search/search_history_repository.dart';
import 'package:bpedia_app/data/settings/settings_repository.dart';
import 'package:bpedia_app/data/wishlist/wishlist_repository.dart';
import 'package:bpedia_app/services/analytics/analytics.dart';
import 'package:flutter/material.dart' show Brightness, ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

import 'support/fakes.dart';

AddressDraft _draft({String label = 'Kantor', String recipient = 'Budi'}) =>
    AddressDraft(
      label: label,
      recipient: recipient,
      phone: '085711112222',
      street: 'Jl. Asia Afrika No. 8',
      district: 'Sumur Bandung',
      city: 'Bandung',
      province: 'Jawa Barat',
      postalCode: '40111',
      note: 'Lantai 3',
    );

void main() {
  group('AddressRepository', () {
    late AddressRepository book;

    setUp(() => book = AddressRepository());

    test('alamat pertama otomatis jadi alamat utama', () {
      expect(book.isEmpty, isTrue);
      expect(book.primary, isNull);
      final first = book.add(sampleAddress);
      expect(first.isPrimary, isTrue);
      expect(first.phone, '6281234567890');
      expect(first.phoneLabel, '0812-3456-7890');
      expect(
        first.fullAddress,
        'Jl. Melati No. 12, Coblong, Bandung, Jawa Barat 40132',
      );
      final second = book.add(_draft());
      expect(second.isPrimary, isFalse);
      expect(book.primary!.id, first.id);
      expect(book.addresses.length, 2);
    });

    test('ganti alamat utama: selalu tepat satu, tampil paling atas', () {
      final first = book.add(sampleAddress);
      final second = book.add(_draft());
      expect(book.setPrimary(second.id), isTrue);
      expect(book.addresses.first.id, second.id);
      expect(book.addresses.where((a) => a.isPrimary).length, 1);
      expect(book.byId(first.id)!.isPrimary, isFalse);
      expect(book.setPrimary('tidak-ada'), isFalse);

      final third = book.add(_draft(label: 'Kos'), makePrimary: true);
      expect(book.primary!.id, third.id);
    });

    test('ubah mempertahankan status utama; hapus memilih utama baru', () {
      final first = book.add(sampleAddress);
      final second = book.add(_draft());
      final updated = book.update(first.id, _draft(recipient: 'Budi Santoso'))!;
      expect(updated.recipient, 'Budi Santoso');
      expect(updated.isPrimary, isTrue);
      expect(updated.toDraft().note, 'Lantai 3');
      expect(book.update('tidak-ada', _draft()), isNull);

      expect(book.remove(first.id), isTrue);
      expect(book.primary!.id, second.id);
      expect(book.remove(first.id), isFalse);
      expect(book.remove(second.id), isTrue);
      expect(book.isEmpty, isTrue);
    });

    test('validasi per kolom', () {
      const bad = AddressDraft(
        label: '',
        recipient: '',
        phone: '123',
        street: 'Jl',
        district: '',
        city: '',
        province: '',
        postalCode: '4013',
      );
      expect(bad.validate().keys.toSet(), AddressField.values.toSet());
      expect(sampleAddress.validate(), isEmpty);
      expect(() => book.add(bad), throwsArgumentError);
      expect(book.isEmpty, isTrue);
    });

    test('bolak-balik JSON; ID ganda ditolak', () {
      book
        ..add(sampleAddress)
        ..add(_draft());
      final copy = AddressRepository()..restore(book.toJson());
      expect(copy.addresses.length, 2);
      expect(copy.primary!.id, book.primary!.id);
      expect(copy.add(_draft(label: 'Kos')).id, isNot(book.addresses[1].id));

      final json = book.toJson()! as Map<String, Object?>;
      final items = json['items']! as List<Object?>;
      expect(
        () => copy.restore(<String, Object?>{
          'seq': 2,
          'items': <Object?>[items.first, items.first],
        }),
        throwsFormatException,
      );
      expect(copy.addresses.length, 3);
    });
  });

  group('WishlistRepository', () {
    test('toggle, urutan terbaru dulu, analitik, dan persistensi', () {
      final catalog = loadCatalog();
      final analytics = LocalAnalytics();
      final wishlist = WishlistRepository(
        catalog: catalog,
        analytics: analytics,
      );
      expect(wishlist.toggle(codeA), isTrue);
      expect(wishlist.toggle(codeB), isTrue);
      expect(wishlist.toggle('TIDAK-ADA'), isFalse);
      expect(wishlist.codes, <String>[codeB, codeA]);
      expect(wishlist.products.first.code, codeB);
      expect(wishlist.contains(codeA), isTrue);
      expect(wishlist.count, 2);
      expect(
        analytics.eventNames,
        <String>[AfEvent.addToWishlist, AfEvent.addToWishlist],
      );

      expect(wishlist.toggle(codeA), isFalse);
      expect(wishlist.codes, <String>[codeB]);

      final copy = WishlistRepository(catalog: catalog)
        ..restore(<String, Object?>{
          'codes': <Object?>[codeB, codeB, codeA],
        });
      expect(copy.codes, <String>[codeB, codeA]);
      expect(
        () => copy.restore(<String, Object?>{'codes': 'rusak'}),
        throwsFormatException,
      );
    });
  });

  group('SearchHistoryRepository', () {
    test('10 terakhir, tanpa ganda, terbaru di atas', () {
      final analytics = LocalAnalytics();
      final history = SearchHistoryRepository(analytics: analytics);
      for (var i = 1; i <= 12; i++) {
        history.record('cari $i');
      }
      expect(history.terms.length, SearchHistoryRepository.capacity);
      expect(history.terms.first, 'cari 12');
      expect(history.terms.last, 'cari 3');

      history.record('  CARI   5 ');
      expect(history.terms.first, 'CARI 5');
      expect(history.terms.where((t) => t.toLowerCase() == 'cari 5').length, 1);
      history.record('   ');
      expect(history.terms.length, 10);
      expect(analytics.records.first.values[AfParam.searchString], 'CARI 5');

      history.remove('CARI 5');
      expect(history.terms, isNot(contains('CARI 5')));
      final copy = SearchHistoryRepository()..restore(history.toJson());
      expect(copy.terms, history.terms);
      history.clear();
      expect(history.terms, isEmpty);
    });
  });

  group('InboxRepository', () {
    test('terbaru di atas, belum dibaca, tandai semua, kapasitas 100', () {
      var now = DateTime.utc(2026, 11, 25, 3);
      final inbox = InboxRepository(clock: WibClock(now: () => now));
      final first = inbox.add(
        kind: InboxKind.order,
        title: 'Pesanan dikemas',
        body: 'Pesanan #BP-1 sedang dikemas.',
        route: '/pesanan/BP-1',
      );
      now = now.add(const Duration(minutes: 5));
      final second = inbox.add(
        kind: InboxKind.promo,
        title: 'Black Friday',
        body: 'Mulai 27 Nov.',
      );
      expect(inbox.messages.first.id, second.id);
      expect(inbox.messages.first.at, now);
      expect(inbox.unreadCount, 2);

      inbox.markRead(first.id);
      inbox.markRead(first.id);
      expect(inbox.unreadCount, 1);
      inbox.markAllRead();
      expect(inbox.unreadCount, 0);

      final copy = InboxRepository(clock: WibClock(now: () => now))
        ..restore(inbox.toJson());
      expect(copy.messages.length, 2);
      expect(copy.messages.last.route, '/pesanan/BP-1');
      expect(copy.messages.last.kind, InboxKind.order);
      expect(copy.add(kind: InboxKind.reward, title: 'a', body: 'b').id, 'N3');

      inbox.remove(first.id);
      expect(inbox.messages.single.id, second.id);

      for (var i = 0; i < 120; i++) {
        inbox.add(kind: InboxKind.reward, title: 'Hadiah $i', body: 'isi');
      }
      expect(inbox.messages.length, InboxRepository.capacity);
      expect(inbox.messages.first.title, 'Hadiah 119');
      expect(
        () => copy.restore(<String, Object?>{'seq': -1, 'items': <Object?>[]}),
        throwsFormatException,
      );
    });
  });

  group('SettingsRepository', () {
    test('bawaan: ikut sistem, suara dan getar nyala, musik mati', () {
      final settings = SettingsRepository();
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.soundOn, isTrue);
      expect(settings.hapticsOn, isTrue);
      expect(settings.reduceMotion, isFalse);
      expect(settings.musicOn, isFalse);
    });

    test('ubah, tukar tema, simpan, dan muat', () {
      final settings = SettingsRepository();
      var notified = 0;
      settings.addListener(() => notified++);
      settings
        ..setThemeMode(ThemeMode.dark)
        ..setThemeMode(ThemeMode.dark)
        ..setSoundOn(false)
        ..setHapticsOn(false)
        ..setReduceMotion(true)
        ..setMusicOn(true);
      expect(notified, 5);
      settings.toggleTheme(Brightness.dark);
      expect(settings.themeMode, ThemeMode.light);
      settings.toggleTheme(Brightness.light);
      expect(settings.themeMode, ThemeMode.dark);

      final copy = SettingsRepository()..restore(settings.toJson());
      expect(copy.settings, settings.settings);
      expect(copy.settings.hashCode, settings.settings.hashCode);
      expect(
        () => copy.restore(<String, Object?>{'themeMode': 'ungu'}),
        throwsFormatException,
      );
      copy.restore(null);
      expect(copy.settings, const AppSettings());
    });
  });

  group('DemoClockRepository', () {
    test('memajukan hari, lompat ke Sabtu, dan kembali', () {
      final clock = WibClock(now: () => DateTime.utc(2026, 11, 25, 3));
      final demo = DemoClockRepository(clock: clock);
      final start = clock.today;
      expect(demo.todayLabel, wibDateLabel(start));

      demo.advanceDays(2);
      expect(demo.today, start + 2);
      expect(demo.offsetDays, 2);
      expect(() => demo.advanceDays(0), throwsRangeError);
      expect(
        () => demo.advanceDays(DemoClockRepository.maxAdvanceDays + 1),
        throwsRangeError,
      );

      demo.jumpToNextSaturday();
      expect(weekdayName(demo.today), 'Sabtu');
      expect(demo.today, greaterThan(start + 2));

      final copy = DemoClockRepository(
        clock: WibClock(now: () => DateTime.utc(2026, 11, 25, 3)),
      )..restore(demo.toJson());
      expect(copy.today, demo.today);
      expect(
        () => copy.restore(<String, Object?>{'offsetDays': -3}),
        throwsFormatException,
      );

      demo.reset();
      expect(demo.today, start);
      expect(clock.demoOffsetDays, 0);
    });
  });
}
