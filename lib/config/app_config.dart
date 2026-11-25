/// Identitas aplikasi, tautan resmi Bpedia, dan nilai yang diberikan saat build.
library;

import 'package:flutter/foundation.dart' show TargetPlatform;

/// Konfigurasi statis aplikasi.
abstract final class AppConfig {
  /// Nama tampil (label peluncur).
  static const String appName = 'Bpedia Demo';

  /// Versi yang tampil di Tentang dan Mode Demo (sama dengan `pubspec.yaml`).
  static const String appVersion = '3.0.0';

  /// Nomor build (sama dengan `pubspec.yaml`).
  static const int buildNumber = 30;

  /// ID aplikasi Android.
  static const String applicationId = 'id.bpedia.preview';

  /// Kunci AppsFlyer; hanya dari `--dart-define=AF_DEV_KEY=...`, tidak pernah di repo.
  static const String appsFlyerDevKey = String.fromEnvironment('AF_DEV_KEY');

  /// ID App Store untuk AppsFlyer di iOS (`--dart-define=AF_IOS_APP_ID=...`).
  static const String appsFlyerIosAppId = String.fromEnvironment(
    'AF_IOS_APP_ID',
  );

  /// Log debug AppsFlyer (`--dart-define=AF_DEBUG=true`).
  static const bool appsFlyerDebug = bool.fromEnvironment('AF_DEBUG');

  /// Situs resmi Bpedia.
  static const String website = 'https://bpedia.id';

  /// Halaman app Bpedia resmi di Google Play.
  static const String playStoreListing =
      'https://play.google.com/store/apps/details?id=com.wot.beautypedia';

  /// Halaman app Bpedia resmi di App Store.
  static const String appStoreListing =
      'https://apps.apple.com/app/id6751265630';

  /// Nomor WhatsApp Bpedia Care (format internasional tanpa tanda plus).
  static const String whatsAppNumber = '6282318591288';

  /// Nomor WhatsApp Bpedia Care untuk ditampilkan.
  static const String whatsAppDisplay = '+62 823-1859-1288';

  /// Jam layanan Bpedia Care.
  static const String careHours = 'Senin sampai Minggu, 08.00 sampai 21.00 WIB';

  /// Akun media sosial resmi (footer bpedia.id, potret 25 Nov 2026).
  static const String instagram = 'https://www.instagram.com/bpedia.ofc/';

  /// Halaman Facebook resmi.
  static const String facebook = 'https://facebook.com/beautypediaofc';

  /// Akun TikTok resmi.
  static const String tiktok = 'https://www.tiktok.com/@bpedia.ofc';

  /// Tautan toko app untuk [platform]: App Store di perangkat Apple, Google
  /// Play selain itu.
  static String storeListingFor(TargetPlatform platform) => switch (platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => appStoreListing,
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => playStoreListing,
  };
}
