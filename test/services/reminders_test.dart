import 'package:bpedia_app/app/app_routes.dart';
import 'package:bpedia_app/services/reminders/create_reminder_service.dart';
import 'package:bpedia_app/services/reminders/local_reminder_service.dart';
import 'package:bpedia_app/services/reminders/reminder_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

/// Sisi native flutter_local_notifications tiruan.
class _FakeNotifications {
  final List<MethodCall> calls = <MethodCall>[];
  final Set<String> failing = <String>{};
  bool permissionGranted = true;
  bool initializeResult = true;
  Map<String, Object?>? launchDetails;
  List<Map<String, Object?>> pending = <Map<String, Object?>>[];

  List<String> get methods => <String>[for (final call in calls) call.method];

  MethodCall single(String method) =>
      calls.singleWhere((call) => call.method == method);

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    if (failing.contains(call.method)) {
      throw PlatformException(code: 'gagal_${call.method}');
    }
    return switch (call.method) {
      'initialize' => initializeResult,
      'getNotificationAppLaunchDetails' => launchDetails,
      'requestNotificationsPermission' => permissionGranted,
      'requestPermissions' => permissionGranted,
      'pendingNotificationRequests' => pending,
      _ => null,
    };
  }
}

void main() {
  group('nextOccurrenceUtc (Sabtu 09.00 WIB)', () {
    DateTime wib(int day, int hour, [int minute = 0]) =>
        DateTime.utc(2026, 11, day, hour - 7, minute);

    final nextSaturday = DateTime.utc(2026, 11, 28, 2);

    test('Rabu 25 Nov 2026 menuju Sabtu 28 Nov pukul 02.00 UTC', () {
      expect(nextOccurrenceUtc(wheelReminder, wib(25, 10)), nextSaturday);
    });

    test('tiap hari dalam minggu menuju Sabtu yang sama', () {
      for (var day = 22; day <= 27; day++) {
        expect(
          nextOccurrenceUtc(wheelReminder, wib(day, 12)),
          nextSaturday,
          reason: 'tanggal $day',
        );
      }
    });

    test('Sabtu sebelum 09.00: hari itu juga', () {
      expect(nextOccurrenceUtc(wheelReminder, wib(28, 8, 59)), nextSaturday);
    });

    test('Sabtu tepat 09.00 dan sesudahnya: minggu depan', () {
      final following = DateTime.utc(2026, 12, 5, 2);
      expect(nextOccurrenceUtc(wheelReminder, wib(28, 9)), following);
      expect(nextOccurrenceUtc(wheelReminder, wib(28, 21)), following);
    });

    test('hari dihitung menurut WIB, bukan UTC', () {
      // Jumat 27 Nov 18.30 UTC = Sabtu 28 Nov 01.30 WIB.
      expect(
        nextOccurrenceUtc(wheelReminder, DateTime.utc(2026, 11, 27, 18, 30)),
        nextSaturday,
      );
      // Sabtu 28 Nov 17.30 UTC = Minggu 29 Nov 00.30 WIB.
      expect(
        nextOccurrenceUtc(wheelReminder, DateTime.utc(2026, 11, 28, 17, 30)),
        DateTime.utc(2026, 12, 5, 2),
      );
    });

    test('waktu lokal perangkat dinormalkan dulu ke UTC', () {
      final local = DateTime.utc(2026, 11, 25, 3).toLocal();
      expect(nextOccurrenceUtc(wheelReminder, local), nextSaturday);
    });

    test('hasil selalu di depan, paling lama tujuh hari', () {
      var now = DateTime.utc(2026, 11, 20);
      for (var step = 0; step < 24 * 4 * 9; step++) {
        final next = nextOccurrenceUtc(wheelReminder, now);
        final gap = next.difference(now);
        expect(gap > Duration.zero, isTrue, reason: '$now');
        expect(gap <= const Duration(days: 7), isTrue, reason: '$now');
        final asWib = next.add(wibOffset);
        expect(asWib.weekday, DateTime.saturday);
        expect(asWib.hour, 9);
        expect(asWib.minute, 0);
        now = now.add(const Duration(minutes: 15));
      }
    });

    test('pengingat bermenit di hari lain', () {
      const reminder = WeeklyReminder(
        id: 7,
        title: 't',
        body: 'b',
        weekday: DateTime.monday,
        hour: 19,
        minute: 30,
      );
      // Senin 23 Nov 19.30 WIB = 12.30 UTC.
      expect(
        nextOccurrenceUtc(reminder, wib(23, 19, 29)),
        DateTime.utc(2026, 11, 23, 12, 30),
      );
      expect(
        nextOccurrenceUtc(reminder, wib(23, 19, 30)),
        DateTime.utc(2026, 11, 30, 12, 30),
      );
    });
  });

  group('wheelReminder', () {
    test('Sabtu 09.00 WIB dan membuka Roda Sabtu', () {
      expect(wheelReminder.weekday, DateTime.saturday);
      expect(wheelReminder.hour, 9);
      expect(wheelReminder.minute, 0);
      expect(wheelReminder.title, isNotEmpty);
      expect(wheelReminder.body, contains('Babes'));
      expect(parseAppRoute(wheelReminder.route!), isA<WheelRoute>());
    });

    test('pesan hasil berbahasa Indonesia dan tidak kosong', () {
      for (final result in ReminderResult.values) {
        expect(result.message.trim(), isNotEmpty, reason: result.name);
      }
      expect(ReminderResult.scheduled.message, contains('Sabtu'));
      expect(ReminderResult.scheduled.message, contains('09.00 WIB'));
    });
  });

  group('NoopReminderService', () {
    test('tidak didukung dan tidak menjadwalkan apa pun', () async {
      const service = NoopReminderService();
      await service.init(onTap: (_) {});

      expect(service.isSupported, isFalse);
      expect(
        await service.scheduleWeekly(wheelReminder),
        ReminderResult.unsupported,
      );
      expect(await service.isScheduled(wheelReminder.id), isFalse);
      await service.cancel(wheelReminder.id);
    });
  });

  group('MemoryReminderService', () {
    test('menjadwalkan, memeriksa, dan membatalkan', () async {
      final service = MemoryReminderService();

      expect(await service.isScheduled(wheelReminder.id), isFalse);
      expect(
        await service.scheduleWeekly(wheelReminder),
        ReminderResult.scheduled,
      );
      expect(await service.isScheduled(wheelReminder.id), isTrue);
      expect(service.scheduled.single.id, wheelReminder.id);

      await service.scheduleWeekly(wheelReminder);
      expect(service.scheduled, hasLength(1), reason: 'ID sama ditimpa');

      await service.cancel(wheelReminder.id);
      expect(await service.isScheduled(wheelReminder.id), isFalse);
    });

    test('izin ditolak: tidak terjadwal', () async {
      final service = MemoryReminderService(permissionGranted: false);

      expect(
        await service.scheduleWeekly(wheelReminder),
        ReminderResult.permissionDenied,
      );
      expect(service.scheduled, isEmpty);

      service.permissionGranted = true;
      expect(
        await service.scheduleWeekly(wheelReminder),
        ReminderResult.scheduled,
      );
    });

    test('platform tak didukung', () async {
      final service = MemoryReminderService(isSupported: false);
      expect(
        await service.scheduleWeekly(wheelReminder),
        ReminderResult.unsupported,
      );
      expect(service.scheduled, isEmpty);
    });

    test('ketukan membuka rute pengingat yang terjadwal', () async {
      final service = MemoryReminderService();
      final opened = <String>[];
      await service.init(onTap: opened.add);
      await service.init();

      service.tap(wheelReminder.id);
      expect(opened, isEmpty, reason: 'belum terjadwal');

      await service.scheduleWeekly(wheelReminder);
      service.tap(wheelReminder.id);
      expect(opened, <String>['/hadiah/roda']);
    });
  });

  group('createReminderService', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('notifikasi lokal hanya di Android dan iOS', () {
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        final service = createReminderService();
        final mobile =
            platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS;
        expect(service.isSupported, mobile, reason: '$platform');
        expect(service is LocalReminderService, mobile, reason: '$platform');
      }
    });
  });

  group('LocalReminderService (kanal plugin tiruan)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late _FakeNotifications native;
    late List<String> opened;
    late DebugPrintCallback previousPrint;

    setUp(() {
      native = _FakeNotifications();
      opened = <String>[];
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, native.handle);
      previousPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {};
    });

    tearDown(() {
      debugPrint = previousPrint;
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    LocalReminderService create() =>
        LocalReminderService(now: () => DateTime.utc(2026, 11, 25, 3));

    test('init menyiapkan plugin tanpa meminta izin, sekali saja', () async {
      final service = create();

      await service.init(onTap: opened.add);
      await service.init();

      expect(native.methods, <String>[
        'initialize',
        'getNotificationAppLaunchDetails',
      ]);
      final settings =
          (native.single('initialize').arguments as Map<Object?, Object?>);
      expect(settings['defaultIcon'], '@mipmap/ic_launcher');
    });

    test('menjadwalkan Sabtu 09.00 WIB, mingguan, tidak eksak', () async {
      final service = create();

      final result = await service.scheduleWeekly(wheelReminder);

      expect(result, ReminderResult.scheduled);
      expect(native.methods, <String>[
        'initialize',
        'getNotificationAppLaunchDetails',
        'requestNotificationsPermission',
        'zonedSchedule',
      ]);
      final arguments =
          native.single('zonedSchedule').arguments as Map<Object?, Object?>;
      expect(arguments['id'], wheelReminder.id);
      expect(arguments['title'], wheelReminder.title);
      expect(arguments['body'], wheelReminder.body);
      expect(arguments['payload'], '/hadiah/roda');
      expect(arguments['timeZoneName'], 'Asia/Jakarta');
      expect(arguments['scheduledDateTime'], '2026-11-28T09:00:00');
      expect(
        arguments['matchDateTimeComponents'],
        DateTimeComponents.dayOfWeekAndTime.index,
      );
      final specifics =
          arguments['platformSpecifics']! as Map<Object?, Object?>;
      expect(
        specifics['scheduleMode'],
        AndroidScheduleMode.inexactAllowWhileIdle.name,
      );
      expect(specifics['channelId'], 'pengingat');
      expect(specifics['channelName'], 'Pengingat');
      expect(
        native.methods,
        isNot(contains('requestExactAlarmsPermission')),
        reason: 'tanpa izin alarm tepat',
      );
    });

    test('izin ditolak: tidak ada jadwal', () async {
      native.permissionGranted = false;

      expect(
        await create().scheduleWeekly(wheelReminder),
        ReminderResult.permissionDenied,
      );
      expect(native.methods, isNot(contains('zonedSchedule')));
    });

    test('plugin gagal menjadwalkan: dilaporkan tak didukung', () async {
      native.failing.add('zonedSchedule');
      expect(
        await create().scheduleWeekly(wheelReminder),
        ReminderResult.unsupported,
      );
    });

    test(
      'plugin gagal disiapkan: tidak melempar dan tidak menjadwalkan',
      () async {
        native.failing.add('initialize');
        final service = create();

        await service.init(onTap: opened.add);
        expect(
          await service.scheduleWeekly(wheelReminder),
          ReminderResult.unsupported,
        );
        expect(await service.isScheduled(wheelReminder.id), isFalse);
        await service.cancel(wheelReminder.id);
        expect(native.methods, isNot(contains('zonedSchedule')));
        expect(native.methods, isNot(contains('cancel')));
      },
    );

    test('tanpa plugin terpasang: semua panggilan aman', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
      final service = create();

      await service.init();
      expect(
        await service.scheduleWeekly(wheelReminder),
        ReminderResult.unsupported,
      );
      expect(await service.isScheduled(1), isFalse);
      await service.cancel(1);
    });

    test('isScheduled membaca daftar tertunda; cancel memakai ID', () async {
      native.pending = <Map<String, Object?>>[
        <String, Object?>{
          'id': wheelReminder.id,
          'title': 't',
          'body': 'b',
          'payload': '/hadiah/roda',
        },
      ];
      final service = create();

      expect(await service.isScheduled(wheelReminder.id), isTrue);
      expect(await service.isScheduled(999), isFalse);

      await service.cancel(wheelReminder.id);
      final cancel = native.single('cancel').arguments;
      expect('$cancel', contains('${wheelReminder.id}'));
    });

    test('app dibuka dari notifikasi: rute langsung diteruskan', () async {
      native.launchDetails = <String, Object?>{
        'notificationLaunchedApp': true,
        'notificationResponse': <String, Object?>{
          'notificationId': wheelReminder.id,
          'actionId': null,
          'input': null,
          'notificationResponseType': 0,
          'payload': '/hadiah/roda',
        },
      };

      await create().init(onTap: opened.add);

      expect(opened, <String>['/hadiah/roda']);
    });

    test('app dibuka biasa: tidak ada rute yang diteruskan', () async {
      native.launchDetails = <String, Object?>{
        'notificationLaunchedApp': false,
      };

      await create().init(onTap: opened.add);

      expect(opened, isEmpty);
    });

    test('ketukan saat app berjalan meneruskan muatan rute', () async {
      await create().init(onTap: opened.add);

      Future<void> tap(String payload) => TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            _channel.name,
            _channel.codec.encodeMethodCall(
              MethodCall('didReceiveNotificationResponse', <String, Object?>{
                'notificationId': wheelReminder.id,
                'actionId': null,
                'input': null,
                'notificationResponseType': 0,
                'payload': payload,
              }),
            ),
            (_) {},
          );

      await tap('/hadiah/roda');
      await tap('');

      expect(opened, <String>['/hadiah/roda']);
    });

    test('di luar Android/iOS tidak pernah menyentuh plugin', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final service = create();

      await service.init(onTap: opened.add);
      expect(service.isSupported, isFalse);
      expect(
        await service.scheduleWeekly(wheelReminder),
        ReminderResult.unsupported,
      );
      expect(await service.isScheduled(wheelReminder.id), isFalse);
      await service.cancel(wheelReminder.id);

      expect(native.calls, isEmpty);
    });
  });
}
