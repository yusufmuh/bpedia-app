/// Tautan keluar app: WhatsApp CS, toko aplikasi, media sosial (url_launcher).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Membuka [uri] di luar app; true bila berhasil.
typedef UriOpener = Future<bool> Function(Uri uri);

/// Pembuka tautan resmi Bpedia. Tidak pernah melempar: kegagalan
/// dikembalikan sebagai false supaya layar bisa menampilkan pesan.
class Links {
  Links({UriOpener? opener, TargetPlatform? platform})
    : _opener = opener ?? _launchExternally,
      _platform = platform;

  /// Pesan pembuka bawaan untuk WhatsApp CS.
  static const String defaultCareMessage =
      'Halo Bpedia Care, saya butuh bantuan.';

  final UriOpener _opener;
  final TargetPlatform? _platform;

  /// Tautan WhatsApp CS Bpedia dengan [message] terisi.
  static Uri whatsAppCareUri([String message = defaultCareMessage]) =>
      Uri.https(
        'wa.me',
        '/${AppConfig.whatsAppNumber}',
        message.isEmpty ? null : <String, String>{'text': message},
      );

  /// Membuka obrolan WhatsApp CS.
  Future<bool> openWhatsAppCare([String message = defaultCareMessage]) =>
      openUri(whatsAppCareUri(message));

  /// Membuka halaman Bpedia di toko aplikasi platform ini.
  Future<bool> openStoreListing() =>
      open(AppConfig.storeListingFor(_platform ?? defaultTargetPlatform));

  /// Membuka halaman Bpedia di Google Play.
  Future<bool> openPlayStore() => open(AppConfig.playStoreListing);

  /// Membuka halaman Bpedia di App Store.
  Future<bool> openAppStore() => open(AppConfig.appStoreListing);

  /// Membuka situs bpedia.id.
  Future<bool> openWebsite() => open(AppConfig.website);

  /// Membuka Instagram Bpedia.
  Future<bool> openInstagram() => open(AppConfig.instagram);

  /// Membuka Facebook Bpedia.
  Future<bool> openFacebook() => open(AppConfig.facebook);

  /// Membuka TikTok Bpedia.
  Future<bool> openTikTok() => open(AppConfig.tiktok);

  /// Membuka [url]; hanya `https` yang diterima.
  Future<bool> open(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return Future<bool>.value(false);
    return openUri(uri);
  }

  /// Membuka [uri]; hanya `https` yang diterima.
  Future<bool> openUri(Uri uri) async {
    if (uri.scheme != 'https' || uri.host.isEmpty) return false;
    try {
      return await _opener(uri);
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
