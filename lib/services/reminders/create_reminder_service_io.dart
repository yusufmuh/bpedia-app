/// Platform ber-`dart:io`: notifikasi lokal hanya di Android dan iOS.
library;

import 'package:flutter/foundation.dart';

import 'local_reminder_service.dart';
import 'reminder_service.dart';

/// [LocalReminderService] di Android/iOS, selain itu [NoopReminderService].
ReminderService createReminderService() {
  final mobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return mobile ? LocalReminderService() : const NoopReminderService();
}
