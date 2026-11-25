/// Platform ber-`dart:io`: AppsFlyer aktif hanya di Android/iOS dan hanya bila
/// kunci diberikan saat build (`--dart-define=AF_DEV_KEY=...`).
library;

import 'package:flutter/foundation.dart';

import 'analytics.dart';
import 'appsflyer_analytics.dart';

/// [AppsFlyerAnalytics], atau null bila bukan Android/iOS, [devKey] kosong,
/// atau iOS tanpa [iosAppId].
Analytics? createAppsFlyerAnalytics({
  required String devKey,
  String iosAppId = '',
  bool debug = false,
}) {
  if (devKey.isEmpty) return null;
  final platform = defaultTargetPlatform;
  if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
    return null;
  }
  if (platform == TargetPlatform.iOS && iosAppId.isEmpty) return null;
  return AppsFlyerAnalytics(devKey: devKey, iosAppId: iosAppId, debug: debug);
}
