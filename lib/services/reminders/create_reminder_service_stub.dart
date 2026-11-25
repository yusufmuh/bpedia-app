/// Platform tanpa `dart:io` (web): browser tidak mendukung notifikasi
/// terjadwal.
library;

import 'reminder_service.dart';

/// Selalu [NoopReminderService] di web.
ReminderService createReminderService() => const NoopReminderService();
