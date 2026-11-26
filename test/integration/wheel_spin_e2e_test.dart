import 'package:bpedia_app/app/app_routes.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart' as hub;

import 'i1_harness.dart';

/// Memompa bingkai sampai [finder] muncul (roda berputar terus-menerus,
/// jadi `pumpAndSettle` tidak dipakai).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 250),
  int maxSteps = 80,
}) async {
  for (var i = 0; i < maxSteps && finder.evaluate().isEmpty; i++) {
    await tester.pump(step);
  }
  expect(finder, findsWidgets);
}

void main() {
  testWidgets('Sabtu: mengetuk "Putar gratis" di layar Roda memutar roda, '
      'Kelopak masuk, dan tombol berganti', (tester) async {
    final services = i1Services(now: saturday, roll: 9999);
    final gateway = await loadKelopak(services);
    expect(gateway.hasBadge(RewardsEntry.wheel), isTrue);

    await pumpI1(tester, services, location: const WheelRoute().location);
    expect(find.byType(hub.KelopakWheelScreen), findsOneWidget);
    final spin = find.text('Putar gratis');
    expect(spin, findsOneWidget);

    await tester.tap(spin);
    await tester.pump();
    expect(find.text('Sedang berputar'), findsOneWidget);

    await pumpUntilFound(tester, find.text('Kelopak masuk, Babes!'));
    expect(gateway.controller.state.spins, hasLength(1));
    expect(gateway.kelopakBalance, 1);
    expect(gateway.hasBadge(RewardsEntry.wheel), isFalse);
    expect(services.analyticsLog.eventNames, contains('bp_wheel_spin'));

    await tester.tapAt(const Offset(195, 40));
    await pumpUntilFound(tester, find.text('Belanja pakai Kelopak'));
    expect(find.text('Putar gratis'), findsNothing);
  });
}
