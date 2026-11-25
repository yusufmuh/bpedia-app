/// Platform tanpa `dart:io` (web): AppsFlyer tidak tersedia.
library;

import 'analytics.dart';

/// Selalu null di web.
Analytics? createAppsFlyerAnalytics({
  required String devKey,
  String iosAppId = '',
  bool debug = false,
}) => null;
