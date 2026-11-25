import 'package:bpedia_app/config/app_config.dart';
import 'package:bpedia_app/services/links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Uri> opened;

  setUp(() => opened = <Uri>[]);

  Links create({bool result = true, TargetPlatform? platform}) => Links(
    opener: (uri) async {
      opened.add(uri);
      return result;
    },
    platform: platform,
  );

  group('WhatsApp CS', () {
    test('nomor Bpedia Care +62 823-1859-1288 dengan pesan pembuka', () {
      final uri = Links.whatsAppCareUri();

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/6282318591288');
      expect(uri.queryParameters['text'], Links.defaultCareMessage);
      expect(AppConfig.whatsAppDisplay, '+62 823-1859-1288');
      expect(
        AppConfig.whatsAppDisplay.replaceAll(RegExp(r'\D'), ''),
        AppConfig.whatsAppNumber,
      );
    });

    test('pesan khusus di-encode; pesan kosong tanpa parameter', () {
      final custom = Links.whatsAppCareUri('Pesanan BP-261125-0001 & retur?');
      expect(custom.queryParameters['text'], 'Pesanan BP-261125-0001 & retur?');
      expect(custom.toString(), isNot(contains(' ')));
      expect(custom.toString(), contains('%26'));

      final empty = Links.whatsAppCareUri('');
      expect(empty.hasQuery, isFalse);
      expect(empty.toString(), 'https://wa.me/6282318591288');
    });

    test('openWhatsAppCare membuka tautan itu', () async {
      expect(await create().openWhatsAppCare('Halo'), isTrue);
      expect(opened.single, Links.whatsAppCareUri('Halo'));
    });
  });

  group('tautan resmi', () {
    test('situs dan media sosial', () async {
      final links = create();

      expect(await links.openWebsite(), isTrue);
      expect(await links.openInstagram(), isTrue);
      expect(await links.openFacebook(), isTrue);
      expect(await links.openTikTok(), isTrue);

      expect(opened.map((uri) => uri.toString()), <String>[
        AppConfig.website,
        AppConfig.instagram,
        AppConfig.facebook,
        AppConfig.tiktok,
      ]);
      expect(opened.map((uri) => uri.scheme), everyElement('https'));
    });

    test('toko app mengikuti platform', () async {
      await create(platform: TargetPlatform.android).openStoreListing();
      await create(platform: TargetPlatform.iOS).openStoreListing();
      await create(platform: TargetPlatform.macOS).openStoreListing();
      await create(platform: TargetPlatform.windows).openStoreListing();

      expect(opened.map((uri) => uri.toString()), <String>[
        AppConfig.playStoreListing,
        AppConfig.appStoreListing,
        AppConfig.appStoreListing,
        AppConfig.playStoreListing,
      ]);
    });

    test('tanpa platform tersuntik memakai platform berjalan', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await create().openStoreListing();

      expect(opened.single.toString(), AppConfig.appStoreListing);
    });

    test('Google Play dan App Store bisa dibuka langsung', () async {
      final links = create();
      await links.openPlayStore();
      await links.openAppStore();

      expect(opened.first.host, 'play.google.com');
      expect(opened.last.host, 'apps.apple.com');
    });

    test('tiap tautan konfigurasi sah dan https', () {
      for (final url in <String>[
        AppConfig.website,
        AppConfig.playStoreListing,
        AppConfig.appStoreListing,
        AppConfig.instagram,
        AppConfig.facebook,
        AppConfig.tiktok,
      ]) {
        final uri = Uri.parse(url);
        expect(uri.scheme, 'https', reason: url);
        expect(uri.host, isNotEmpty, reason: url);
      }
    });
  });

  group('keamanan dan kegagalan', () {
    test('hanya https yang dibuka', () async {
      final links = create();

      for (final url in <String>[
        'http://bpedia.id',
        'tel:+6282318591288',
        'intent://scan/#Intent;scheme=zxing;end',
        'javascript:alert(1)',
        'file:///etc/hosts',
        'bpedia-demo://buka',
        'https://',
        'https:///jalur',
        '',
        '::tidak sah::',
      ]) {
        expect(await links.open(url), isFalse, reason: url);
      }
      expect(opened, isEmpty);
    });

    test('pembuka mengembalikan false diteruskan apa adanya', () async {
      expect(await create(result: false).openWebsite(), isFalse);
      expect(opened, hasLength(1));
    });

    test('galat platform menjadi false, bukan pengecualian', () async {
      final platformError = Links(
        opener: (_) async =>
            throw PlatformException(code: 'ACTIVITY_NOT_FOUND'),
      );
      final missingPlugin = Links(
        opener: (_) async => throw MissingPluginException('url_launcher'),
      );

      expect(await platformError.openWebsite(), isFalse);
      expect(await missingPlugin.openWhatsAppCare(), isFalse);
    });

    test('pembuka bawaan tanpa plugin terpasang: false', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(await Links().openWebsite(), isFalse);
    });
  });
}
