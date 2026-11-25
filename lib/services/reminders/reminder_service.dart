/// Pengingat lokal "Ingatkan saya". Layar hanya mengenal antarmuka ini;
/// web dan desktop memakai [NoopReminderService] (`isSupported` false), jadi
/// tombol pengingat tidak ditampilkan di sana.
library;

import 'package:kelopak_hub/kelopak_hub.dart' show wibUtcOffsetHours;

/// Hasil permintaan pengingat, untuk dipetakan ke pesan di layar.
enum ReminderResult {
  /// Pengingat terjadwal.
  scheduled('Siap, Babes. Kami ingatkan tiap Sabtu pukul 09.00 WIB.'),

  /// Pengguna menolak izin notifikasi.
  permissionDenied(
    'Izin notifikasi belum diberikan. Nyalakan lewat pengaturan perangkat.',
  ),

  /// Platform tidak mendukung pengingat terjadwal.
  unsupported('Pengingat belum tersedia di perangkat ini.');

  const ReminderResult(this.message);

  /// Pesan untuk pengguna.
  final String message;
}

/// Dipanggil saat pengguna mengetuk notifikasi pengingat; [location] adalah
/// lokasi rute app (contoh `/hadiah/roda`).
typedef ReminderTapHandler = void Function(String location);

/// Pengingat mingguan pada hari dan jam WIB tertentu.
final class WeeklyReminder {
  const WeeklyReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.weekday,
    required this.hour,
    this.minute = 0,
    this.route,
  }) : assert(weekday >= DateTime.monday && weekday <= DateTime.sunday),
       assert(hour >= 0 && hour < 24),
       assert(minute >= 0 && minute < 60);

  /// ID notifikasi (unik per pengingat).
  final int id;
  final String title;
  final String body;

  /// Hari dalam minggu, `DateTime.monday`..`DateTime.sunday`, menurut WIB.
  final int weekday;

  /// Jam WIB.
  final int hour;

  /// Menit.
  final int minute;

  /// Lokasi rute yang dibuka saat notifikasi diketuk.
  final String? route;
}

/// Pengingat Roda Sabtu: tiap Sabtu pukul 09.00 WIB (KEPUTUSAN §4).
const WeeklyReminder wheelReminder = WeeklyReminder(
  id: 601,
  title: 'Roda Sabtu sudah buka',
  body: 'Putaran gratismu menunggu, Babes. Yuk putar sekarang.',
  weekday: DateTime.saturday,
  hour: 9,
  route: '/hadiah/roda',
);

/// Layanan pengingat lokal.
abstract interface class ReminderService {
  /// False di web dan desktop.
  bool get isSupported;

  /// Menyiapkan plugin dan pendengar ketuk. Aman dipanggil berulang; tidak
  /// meminta izin.
  Future<void> init({ReminderTapHandler? onTap});

  /// Menjadwalkan [reminder] berulang tiap minggu. Izin notifikasi diminta di
  /// sini, saat pengguna menyalakan pengingat.
  Future<ReminderResult> scheduleWeekly(WeeklyReminder reminder);

  /// Membatalkan pengingat ber-[id].
  Future<void> cancel(int id);

  /// Apakah pengingat ber-[id] sedang terjadwal.
  Future<bool> isScheduled(int id);
}

/// Pengingat untuk platform tanpa notifikasi terjadwal.
class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  bool get isSupported => false;

  @override
  Future<void> init({ReminderTapHandler? onTap}) async {}

  @override
  Future<ReminderResult> scheduleWeekly(WeeklyReminder reminder) async =>
      ReminderResult.unsupported;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<bool> isScheduled(int id) async => false;
}

/// Pengingat di memori untuk tes dan `AppServices.forTest`.
class MemoryReminderService implements ReminderService {
  MemoryReminderService({
    this.isSupported = true,
    this.permissionGranted = true,
  });

  @override
  final bool isSupported;

  /// Jawaban dialog izin notifikasi.
  bool permissionGranted;

  final Map<int, WeeklyReminder> _scheduled = <int, WeeklyReminder>{};
  ReminderTapHandler? _onTap;

  /// Pengingat yang sedang terjadwal.
  List<WeeklyReminder> get scheduled =>
      List<WeeklyReminder>.unmodifiable(_scheduled.values);

  @override
  Future<void> init({ReminderTapHandler? onTap}) async {
    _onTap = onTap ?? _onTap;
  }

  @override
  Future<ReminderResult> scheduleWeekly(WeeklyReminder reminder) async {
    if (!isSupported) return ReminderResult.unsupported;
    if (!permissionGranted) return ReminderResult.permissionDenied;
    _scheduled[reminder.id] = reminder;
    return ReminderResult.scheduled;
  }

  @override
  Future<void> cancel(int id) async {
    _scheduled.remove(id);
  }

  @override
  Future<bool> isScheduled(int id) async => _scheduled.containsKey(id);

  /// Meniru ketukan pada notifikasi ber-[id].
  void tap(int id) {
    final route = _scheduled[id]?.route;
    if (route != null && route.isNotEmpty) _onTap?.call(route);
  }
}

/// WIB tetap UTC+7 tanpa DST.
const Duration wibOffset = Duration(hours: wibUtcOffsetHours);

/// Kejadian [reminder] berikutnya (UTC) sesudah [now]. Tepat pada jamnya
/// dihitung sudah lewat, jadi hasilnya minggu depan.
DateTime nextOccurrenceUtc(WeeklyReminder reminder, DateTime now) {
  final wib = now.toUtc().add(wibOffset);
  final today = DateTime.utc(wib.year, wib.month, wib.day);
  var candidate = today.add(
    Duration(
      days: (reminder.weekday - today.weekday) % 7,
      hours: reminder.hour,
      minutes: reminder.minute,
    ),
  );
  if (!candidate.isAfter(wib)) {
    candidate = candidate.add(const Duration(days: 7));
  }
  return candidate.subtract(wibOffset);
}
