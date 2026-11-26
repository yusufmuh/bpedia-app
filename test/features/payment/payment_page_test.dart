import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/features/payment/payment_page.dart';
import 'package:bpedia_app/features/payment/widgets/qr_demo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelopak_hub/kelopak_hub.dart' show WibClock;

import '../orders/f2_harness.dart';

void main() {
  testWidgets('QRIS: total, batas bayar, QR contoh, nomor pesanan', (
    tester,
  ) async {
    final services = f2Services(rewards: FakeRewards());
    final order = await placeOrder(services);
    await pumpF2(tester, services, location: '/bayar/${order.id}');
    expect(find.text('Total pembayaran'), findsOneWidget);
    expect(find.text('Selesaikan pembayaran dalam'), findsOneWidget);
    expect(find.text('Batas Kamis, 26 Nov 2026, 10.00 WIB'), findsOneWidget);
    expect(find.byType(QrDemo), findsOneWidget);
    expect(find.text('#${order.id}'), findsOneWidget);
    expect(find.text('Salin'), findsOneWidget);
    expect(find.text('Ganti'), findsOneWidget);
    expect(find.text('Lihat rincian'), findsOneWidget);
    // 128 Kelopak + 1 hadiah dari FakeRewards bawaan.
    expect(
      find.text(
        '128 Kelopak memotong Rp12.800. Hadiah gratis ikut di paket ini.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('hitung mundur berjalan dari jam app setiap detik', (
    tester,
  ) async {
    var now = AppServices.testNow;
    final services = f2Services(
      rewards: FakeRewards(),
      clock: WibClock(now: () => now),
    );
    final order = await placeOrder(services);
    await pumpF2(tester, services, location: '/bayar/${order.id}');
    expect(find.text('24'), findsOneWidget);
    expect(find.text('00'), findsNWidgets(2));
    expect(find.text('Jam'), findsOneWidget);
    expect(find.text('Menit'), findsOneWidget);
    expect(find.text('Detik'), findsOneWidget);

    now = now.add(const Duration(hours: 1, minutes: 2, seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('22'), findsOneWidget);
    expect(find.text('57'), findsNWidgets(2));
    expect(find.text('Batas Kamis, 26 Nov 2026, 10.00 WIB'), findsOneWidget);
  });

  testWidgets('Lihat rincian membuka detail; Ganti menawarkan checkout ulang', (
    tester,
  ) async {
    final rewards = FakeRewards();
    final services = f2Services(rewards: rewards);
    final order = await placeOrder(services);
    await pumpF2(tester, services, location: '/bayar/${order.id}');
    await tester.tap(find.text('Ganti'));
    await settle(tester);
    expect(find.text('Ganti metode pembayaran'), findsOneWidget);
    await tester.tap(find.text('Checkout ulang'));
    await settle(tester);
    expect(services.orders.byId(order.id)!.status, OrderStatus.cancelled);
    expect(rewards.balance, 128);
    expect(services.cart.lineCount, 2);
    expect(find.text('Keranjang (2)'), findsOneWidget);
  });

  testWidgets('VA: nomor virtual account demo bisa disalin', (tester) async {
    final services = f2Services();
    final order = await placeOrder(services, paymentId: 'va-bca');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpF2(tester, services, location: '/bayar/${order.id}');
    expect(find.text('Nomor virtual account (demo)'), findsOneWidget);
    expect(find.text(demoPaymentCode(order.id)), findsOneWidget);
    await tester.tap(find.byTooltip('Salin Nomor virtual account (demo)'));
    await settle(tester);
    expect(find.text('Nomor virtual account (demo) disalin'), findsOneWidget);
  });

  test('kode bayar demo tetap per pesanan dan berkelompok empat', () {
    expect(demoPaymentCode('BP-261125-0001'), '8808 2611 2500 01');
    expect(demoPaymentCode('BP-261125-0001', retail: true), '7726 1125 0001');
  });

  testWidgets('bayar nanti membuka detail pesanan', (tester) async {
    final services = f2Services();
    final order = await placeOrder(services);
    await pumpF2(tester, services, location: '/bayar/${order.id}');
    await tester.tap(find.text('Bayar nanti, lihat pesanan'));
    await settle(tester);
    expect(find.text('Detail pesanan'), findsOneWidget);
  });

  testWidgets('pesanan yang sudah dibayar tidak bisa dibayar lagi', (
    tester,
  ) async {
    final services = f2Services();
    final order = await placeOrder(services, paymentId: 'cod');
    await pumpF2(tester, services, location: '/bayar/${order.id}');
    expect(find.text('Pesanan ini sudah dibayar'), findsOneWidget);
    expect(find.text('Simulasikan pembayaran (DEMO)'), findsNothing);
  });

  testWidgets('pesanan tidak ditemukan', (tester) async {
    final services = f2Services();
    await pumpF2(tester, services, location: '/bayar/BP-000000-0009');
    expect(find.text('Pesanan tidak ditemukan'), findsOneWidget);
  });

  testWidgets('lewat batas bayar: pesanan dibatalkan dengan pesan jelas', (
    tester,
  ) async {
    var now = AppServices.testNow;
    final services = f2Services(clock: WibClock(now: () => now));
    final order = await placeOrder(services);
    now = now.add(const Duration(hours: 25));
    await pumpF2(tester, services, location: '/bayar/${order.id}');
    await tester.tap(find.text('Simulasikan pembayaran (DEMO)'));
    await settle(tester);
    expect(services.orders.byId(order.id)!.status, OrderStatus.cancelled);
    expect(
      find.text('Batas waktu pembayaran habis. Pesanan dibatalkan.'),
      findsOneWidget,
    );
  });

  testWidgets('skala teks 200% lebar 360 tanpa luapan', (tester) async {
    final services = f2Services();
    final order = await placeOrder(services, paymentId: 'va-mandiri');
    await pumpF2(
      tester,
      services,
      location: '/bayar/${order.id}',
      size: const Size(360, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.text('Cara bayar'));
    expect(tester.takeException(), isNull);
  });
}
