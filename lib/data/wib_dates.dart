/// Konversi tanggal kalender WIB ke nomor hari WIB (hari sejak 1970-01-01 WIB)
/// yang dipakai `WibClock.today`.
library;

import 'package:kelopak_hub/kelopak_hub.dart'
    show shortDateLabel, wibUtcOffsetHours;

/// Nomor hari WIB untuk tanggal kalender WIB [year]-[month]-[day].
int wibDayFromDate(int year, int month, int day) =>
    DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Tanggal kalender (UTC tengah malam) dari nomor hari WIB.
DateTime dateOfWibDay(int wibDay) =>
    DateTime.utc(1970).add(Duration(days: wibDay));

/// Nomor hari WIB dari teks `YYYY-MM-DD`, atau null bila bentuknya salah.
int? tryParseWibDay(String? iso) {
  if (iso == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return wibDayFromDate(year, month, day);
}

/// Nomor hari WIB dari teks `YYYY-MM-DD`; melempar [FormatException] bila salah.
int parseWibDay(String iso) {
  final day = tryParseWibDay(iso);
  if (day == null) throw FormatException('Tanggal tidak sah: $iso');
  return day;
}

/// "251126" untuk nomor pesanan (`YYMMDD` tanggal WIB).
String compactWibDate(int wibDay) {
  final date = dateOfWibDay(wibDay);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.year % 100)}${two(date.month)}${two(date.day)}';
}

/// Nomor hari WIB dari sebuah waktu.
int wibDayOfInstant(DateTime instant) =>
    (instant.toUtc().millisecondsSinceEpoch +
        wibUtcOffsetHours * Duration.millisecondsPerHour) ~/
    Duration.millisecondsPerDay;

/// Jam WIB sebuah waktu: "09.05".
String wibClockLabel(DateTime instant) {
  final wib = instant.toUtc().add(const Duration(hours: wibUtcOffsetHours));
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(wib.hour)}.${two(wib.minute)}';
}

/// Tanggal dan jam WIB sebuah waktu: "26 Nov 2026, 09.05 WIB".
String wibDateTimeLabel(DateTime instant) {
  final day = wibDayOfInstant(instant);
  return '${shortDateLabel(day)} ${dateOfWibDay(day).year}, '
      '${wibClockLabel(instant)} WIB';
}
