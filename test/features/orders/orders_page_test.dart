import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/features/order_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'f2_harness.dart';

void main() {
  group('Transaksi', () {
    testWidgets('tamu: ajakan masuk', (tester) async {
      final services = f2Services(loggedIn: false);
      await pumpF2(tester, services, location: '/pesanan');
      expect(find.text('Masuk untuk melihat pesananmu'), findsOneWidget);
      await tester.tap(find.text('Masuk'));
      await settle(tester);
      expect(find.text('Halaman masuk /pesanan'), findsOneWidget);
    });

    testWidgets('kosong: Bipy + Mulai belanja', (tester) async {
      final services = f2Services();
      await pumpF2(tester, services, location: '/pesanan');
      expect(find.text('Belum ada pesanan'), findsOneWidget);
      expect(find.text('Mulai belanja'), findsOneWidget);
    });

    testWidgets('tab status berjumlah, kartu dengan aksi sesuai status', (
      tester,
    ) async {
      final services = f2Services(rewards: FakeRewards());
      final unpaid = await placeOrder(services);
      final cod = await placeOrder(
        services,
        lines: const <String, int>{facialWash: 1},
        paymentId: 'cod',
      );
      await pumpF2(tester, services, location: '/pesanan');

      expect(find.text('Menunggu pembayaran (1)'), findsOneWidget);
      expect(find.text('Dikemas (1)'), findsOneWidget);
      expect(find.text(unpaid.id), findsOneWidget);
      expect(find.text(cod.id), findsOneWidget);
      expect(find.text('Bayar'), findsOneWidget);
      expect(find.text('Lacak'), findsOneWidget);
      expect(find.text('+1 produk lain'), findsOneWidget);
      expect(find.text('+1 hadiah gratis'), findsOneWidget);

      await tester.tap(find.text('Dikemas (1)'));
      await settle(tester);
      expect(find.text(cod.id), findsOneWidget);
      expect(find.text(unpaid.id), findsNothing);
    });

    testWidgets('?status= membuka tab yang sesuai', (tester) async {
      final services = f2Services();
      await placeOrder(services, paymentId: 'cod');
      await pumpF2(tester, services, location: '/pesanan?status=selesai');
      expect(find.text('Belum ada pesanan selesai'), findsOneWidget);
    });

    testWidgets('kartu Bayar membuka pembayaran', (tester) async {
      final services = f2Services();
      final order = await placeOrder(services);
      await pumpF2(tester, services, location: '/pesanan');
      await tester.tap(find.text('Bayar'));
      await settle(tester);
      expect(find.text('Simulasikan pembayaran (DEMO)'), findsOneWidget);
      expect(find.text(order.id), findsOneWidget);
    });
  });

  group('Detail pesanan', () {
    testWidgets('kontrol simulasi: bayar → kirim → diterima → perayaan misi', (
      tester,
    ) async {
      final rewards = FakeRewards(celebrateMission: true);
      final services = f2Services(rewards: rewards);
      final order = await placeOrder(services);
      await pumpF2(tester, services, location: '/pesanan/${order.id}');

      expect(find.text('Kontrol simulasi (DEMO)'), findsOneWidget);
      expect(find.text('Status pesanan'), findsOneWidget);
      await tester.tap(find.text('Simulasikan pembayaran'));
      await settle(tester);
      expect(services.orders.byId(order.id)!.status, OrderStatus.packing);

      await tester.tap(find.text('Kirim pesanan'));
      await settle(tester);
      expect(services.orders.byId(order.id)!.status, OrderStatus.shipped);

      await tester.tap(find.text('Pesanan diterima').last);
      await settle(tester);
      expect(services.orders.byId(order.id)!.status, OrderStatus.completed);
      expect(rewards.celebrations, 1);
      expect(find.text('Misi tuntas'), findsOneWidget);
      await tester.tap(find.text('Mantap'));
      await settle(tester);
      expect(find.text('Beli lagi'), findsOneWidget);
      expect(
        find.text('Misi Belanja tahap 1 tuntas. Voucher Rp10.000 masuk.'),
        findsOneWidget,
      );
    });

    testWidgets('batal: konfirmasi menyebut pengembalian, Kelopak kembali', (
      tester,
    ) async {
      final rewards = FakeRewards();
      final services = f2Services(rewards: rewards);
      final order = await placeOrder(services);
      expect(rewards.balance, 0);
      expect(rewards.pendingGifts, isEmpty);
      await pumpF2(tester, services, location: '/pesanan/${order.id}');

      await tester.tap(find.text('Batalkan pesanan'));
      await settle(tester);
      expect(find.text('Batalkan pesanan?'), findsOneWidget);
      expect(find.textContaining('128 Kelopak'), findsOneWidget);
      expect(find.textContaining('1 hadiah gratis'), findsOneWidget);
      await tester.tap(find.text('Ya, batalkan'));
      await settle(tester);

      expect(services.orders.byId(order.id)!.status, OrderStatus.cancelled);
      expect(rewards.balance, 128);
      expect(rewards.pendingGifts, hasLength(1));
      expect(find.text('Dibatalkan'), findsWidgets);
    });

    testWidgets('batal bisa dibatalkan lewat Kembali', (tester) async {
      final services = f2Services();
      final order = await placeOrder(services);
      await pumpF2(tester, services, location: '/pesanan/${order.id}');
      await tester.tap(find.text('Batalkan pesanan'));
      await settle(tester);
      await tester.tap(find.text('Kembali'));
      await settle(tester);
      expect(
        services.orders.byId(order.id)!.status,
        OrderStatus.awaitingPayment,
      );
    });

    testWidgets('pesanan tidak ada', (tester) async {
      final services = f2Services();
      await pumpF2(tester, services, location: '/pesanan/BP-000000-0000');
      expect(find.text('Pesanan tidak ditemukan'), findsOneWidget);
    });

    testWidgets('skala teks 200% lebar 360 tanpa luapan', (tester) async {
      final services = f2Services(rewards: FakeRewards());
      final order = await placeOrder(services);
      await pumpF2(
        tester,
        services,
        location: '/pesanan/${order.id}',
        size: const Size(360, 640),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await scrollTo(tester, find.text('Rincian pembayaran'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('daftar pada skala 200% lebar 360 tanpa luapan', (
      tester,
    ) async {
      final services = f2Services(rewards: FakeRewards());
      await placeOrder(services);
      await pumpF2(
        tester,
        services,
        location: '/pesanan',
        size: const Size(360, 640),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('UnpaidOrderBanner', () {
    testWidgets('tampil saat ada pesanan menunggu bayar, Bayar membuka', (
      tester,
    ) async {
      final services = f2Services();
      services.router.registerTab(
        AppTab.home,
        (context) => const Scaffold(body: SafeArea(child: UnpaidOrderBanner())),
      );
      final order = await placeOrder(services);
      await pumpF2(tester, services, location: '/');
      expect(
        find.text('Selesaikan pembayaran pesanan #${order.id}'),
        findsOneWidget,
      );
      await tester.tap(find.text('Bayar'));
      await settle(tester);
      expect(find.text('Simulasikan pembayaran (DEMO)'), findsOneWidget);
    });

    testWidgets('tidak tampil tanpa pesanan menunggu bayar', (tester) async {
      final services = f2Services();
      services.router.registerTab(
        AppTab.home,
        (context) => const Scaffold(body: SafeArea(child: UnpaidOrderBanner())),
      );
      await placeOrder(services, paymentId: 'cod');
      await pumpF2(tester, services, location: '/');
      expect(find.textContaining('Selesaikan pembayaran'), findsNothing);
    });
  });
}
