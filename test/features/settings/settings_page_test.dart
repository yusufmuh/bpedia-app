import 'package:bpedia_app/services/reminders/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account/f3_harness.dart';

void main() {
  testWidgets('tema terang, gelap, ikuti sistem tersimpan', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/akun/pengaturan');
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Tema Gelap'));
    await tester.pumpAndSettle();
    expect(services.settings.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Tampilan'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.bySemanticsLabel('Tema Ikuti sistem'));
    await tester.pumpAndSettle();
    expect(services.settings.themeMode, ThemeMode.system);
    expect(services.settings.toJson(), containsPair('themeMode', 'system'));
  });

  testWidgets('suara, musik, getar, kurangi gerak', (tester) async {
    final services = f3Services();
    await openF3(tester, services, '/akun/pengaturan');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Efek suara'));
    await tester.tap(find.text('Musik latar'));
    await tester.tap(find.text('Getar'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Kurangi gerak'));

    final settings = services.settings;
    expect(settings.soundOn, isFalse);
    expect(settings.musicOn, isTrue);
    expect(settings.hapticsOn, isFalse);
    expect(settings.reduceMotion, isTrue);
    expect(services.sound.soundOn, isFalse);
    // Kurangi gerak diteruskan ke MediaQuery seluruh app.
    expect(
      MediaQuery.of(tester.element(find.text('Tampilan'))).disableAnimations,
      isTrue,
    );
  });

  testWidgets('pengingat Roda Sabtu: nyala, ditolak, mati', (tester) async {
    final reminders = MemoryReminderService();
    final services = f3Services(reminders: reminders);
    await openF3(tester, services, '/akun/pengaturan');
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Ingatkan Roda Sabtu'));
    expect(reminders.scheduled.single.id, wheelReminder.id);
    expect(find.text(ReminderResult.scheduled.message), findsOneWidget);

    await tester.tap(find.text('Ingatkan Roda Sabtu'));
    await tester.pumpAndSettle();
    expect(reminders.scheduled, isEmpty);

    reminders.permissionGranted = false;
    await tester.tap(find.text('Ingatkan Roda Sabtu'));
    await tester.pumpAndSettle();
    expect(reminders.scheduled, isEmpty);
    expect(find.text(ReminderResult.permissionDenied.message), findsOneWidget);
  });

  testWidgets('pengingat tidak didukung (web) dinonaktifkan', (tester) async {
    final services = f3Services(reminders: const NoopReminderService());
    await openF3(tester, services, '/akun/pengaturan');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Tersedia di aplikasi Android dan iOS.'));
    expect(find.text('Tersedia di aplikasi Android dan iOS.'), findsOneWidget);
  });

  testWidgets('teks 200% lebar 360 tanpa luapan', (tester) async {
    setScreen(tester, size: const Size(360, 640), textScale: 2);
    final services = f3Services();
    await openF3(tester, services, '/akun/pengaturan');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Ingatkan Roda Sabtu'));
    expect(tester.takeException(), isNull);
  });
}
