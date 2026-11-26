/// Pengingat lokal Android dan iOS (flutter_local_notifications + timezone).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_service.dart';

/// Lokasi zona tetap untuk WIB. Plugin mengirim nama zona dan jam dinding ke
/// Android/iOS, yang memakai basis data zona milik sistem, jadi basis data
/// paket timezone (ratusan KB) tidak perlu dimuat.
final tz.Location _jakarta = tz.Location(
  'Asia/Jakarta',
  <int>[tz.minTime],
  <int>[0],
  <tz.TimeZone>[
    const tz.TimeZone(wibOffset, isDst: false, abbreviation: 'WIB'),
  ],
);

/// Pengingat lewat notifikasi lokal.
///
/// Jadwal memakai mode tidak eksak, jadi izin `SCHEDULE_EXACT_ALARM` tidak
/// diperlukan; sistem boleh menggeser waktu tampil beberapa menit.
class LocalReminderService implements ReminderService {
  LocalReminderService({
    this.androidIcon = defaultAndroidIcon,
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? now,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _now = now ?? DateTime.now;

  /// Ikon kecil notifikasi: siluet tulip putih bertransparansi
  /// (`res/drawable/ic_stat_bpedia.xml`, dijaga `res/raw/keep.xml`).
  static const String defaultAndroidIcon = '@drawable/ic_stat_bpedia';

  /// Warna aksen ikon kecil notifikasi (merah muda brand).
  static const Color accentColor = Color(0xFFD81F57);

  static const String _channelId = 'pengingat';
  static const String _channelName = 'Pengingat';
  static const String _channelDescription =
      'Pengingat Roda Sabtu dan promo yang kamu minta.';

  /// Nama resource ikon notifikasi Android.
  final String androidIcon;

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _now;
  bool _initialized = false;
  ReminderTapHandler? _onTap;

  @override
  bool get isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> init({ReminderTapHandler? onTap}) async {
    _onTap = onTap ?? _onTap;
    if (_initialized || !isSupported) return;
    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: AndroidInitializationSettings(androidIcon),
          iOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _handleResponse,
      );
      _initialized = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
        _handleResponse(response);
      }
    } on PlatformException catch (error) {
      debugPrint('Pengingat gagal disiapkan: ${error.code}');
    } on MissingPluginException catch (error) {
      debugPrint('Pengingat tidak tersedia: ${error.message}');
    }
  }

  @override
  Future<ReminderResult> scheduleWeekly(WeeklyReminder reminder) async {
    if (!isSupported) return ReminderResult.unsupported;
    try {
      await init();
      if (!_initialized) return ReminderResult.unsupported;
      if (!await _requestPermission()) return ReminderResult.permissionDenied;
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(
          nextOccurrenceUtc(reminder, _now()),
          _jakarta,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            color: accentColor,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: reminder.route,
      );
      return ReminderResult.scheduled;
    } on PlatformException catch (error) {
      debugPrint('Pengingat gagal dijadwalkan: ${error.code}');
      return ReminderResult.unsupported;
    } on MissingPluginException catch (error) {
      debugPrint('Pengingat tidak tersedia: ${error.message}');
      return ReminderResult.unsupported;
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!isSupported) return;
    try {
      await init();
      if (_initialized) await _plugin.cancel(id: id);
    } on PlatformException catch (error) {
      debugPrint('Pengingat gagal dibatalkan: ${error.code}');
    } on MissingPluginException catch (error) {
      debugPrint('Pengingat tidak tersedia: ${error.message}');
    }
  }

  @override
  Future<bool> isScheduled(int id) async {
    if (!isSupported) return false;
    try {
      await init();
      if (!_initialized) return false;
      final pending = await _plugin.pendingNotificationRequests();
      return pending.any((request) => request.id == id);
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  void _handleResponse(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty) _onTap?.call(route);
  }

  /// Android 13+ menampilkan dialog izin; versi di bawahnya langsung
  /// mengembalikan status notifikasi app.
  Future<bool> _requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }
}
