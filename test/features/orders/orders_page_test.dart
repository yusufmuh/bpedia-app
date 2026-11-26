import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/design/design.dart' show formatRupiah;
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

      Finder tab(String label) =>
          find.descendant(of: find.byType(TabBar), matching: find.text(label));
      Finder badge(String label) => find.descendant(
        of: find.ancestor(of: tab(label), matching: find.byType(Row)).first,
        matching: find.text('1'),
      );
      expect(tab('Menunggu pembayaran'), findsOneWidget);
      expect(badge('Menunggu pembayaran'), findsOneWidget);
      expect(badge('Dikemas'), findsOneWidget);
      expect(find.text('Menunggu pembayaran (1)'), findsNothing);
      expect(find.text('#${unpaid.id}'), findsOneWidget);
      expect(find.text('#${cod.id}'), findsOneWidget);
      expect(find.textContaining('Belanja · 25 Nov 2026'), findsNWidgets(2));
      expect(find.text('Bayar sekarang'), findsOneWidget);
      expect(find.text('Lihat detail'), findsOneWidget);
      expect(find.text('Total 2 barang'), findsOneWidget);
      expect(find.text('+1 produk lain'), findsOneWidget);
      expect(
        find.text('Hadiah gratis ikut: Pinkflash Duo Lipgloss Pf-L13 - D02'),
        findsOneWidget,
      );
      expect(
        find.text('Bayar di tempat. Pesanan sedang dikemas.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Cari'), findsOneWidget);
      expect(find.byTooltip('Keranjang'), findsWidgets);

      await tester.tap(tab('Dikemas'));
      await settle(tester);
      expect(find.text('#${cod.id}'), findsOneWidget);
      expect(find.text('#${unpaid.id}'), findsNothing);
      expect(find.text('1 pesanan menunggu pembayaran'), findsNothing);
    });

    testWidgets('banner menunggu pembayaran di atas daftar membuka bayar', (
      tester,
    ) async {
      final services = f2Services(rewards: FakeRewards());
      final unpaid = await placeOrder(services);
      await placeOrder(
        services,
        lines: const <String, int>{facialWash: 1},
        paymentId: 'cod',
      );
      await pumpF2(tester, services, location: '/pesanan');

      final banner = find.text('1 pesanan menunggu pembayaran');
      expect(banner, findsOneWidget);
      expect(
        find.text('#${unpaid.id} · batas 26 Nov, 10.00 WIB'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(banner).dy,
        lessThan(tester.getTopLeft(find.text('#${unpaid.id}')).dy),
      );
      await tester.tap(banner);
      await settle(tester);
      expect(find.text('Simulasikan pembayaran (DEMO)'), findsOneWidget);
      expect(find.text('#${unpaid.id}'), findsOneWidget);
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
      await tester.tap(find.text('Bayar sekarang'));
      await settle(tester);
      expect(find.text('Simulasikan pembayaran (DEMO)'), findsOneWidget);
      expect(find.text('#${order.id}'), findsOneWidget);
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

      expect(find.text('Kontrol simulasi'), findsOneWidget);
      expect(find.text('DEMO'), findsOneWidget);
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
      expect(find.text('Beli lagi'), findsWidgets);
      expect(find.text('Hubungi CS'), findsOneWidget);
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
      expect(find.text('Batalkan pesanan ini?'), findsOneWidget);
      expect(find.text('128 Kelopak kembali ke saldo'), findsOneWidget);
      expect(
        find.text('Hadiah gratis kembali menunggu di keranjang'),
        findsOneWidget,
      );
      // Belum dibayar: tidak ada dana yang dikembalikan.
      expect(find.textContaining('Dana Rp'), findsNothing);
      expect(
        find.textContaining('Pembatalan tidak bisa diurungkan'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ya, batalkan'));
      await settle(tester);

      expect(services.orders.byId(order.id)!.status, OrderStatus.cancelled);
      expect(rewards.balance, 128);
      expect(rewards.pendingGifts, hasLength(1));
      expect(find.text('Dibatalkan'), findsWidgets);
    });

    testWidgets('batal pesanan lunas: dana dan voucher dirinci per butir', (
      tester,
    ) async {
      final rewards = FakeRewards();
      final services = f2Services(rewards: rewards);
      services.cart
        ..add(sunscreen, qty: 2)
        ..add(nightCream);
      final cart = services.cart;
      final shipping = services.shipping
          .options(
            weightGrams: cart.selectedWeightGrams,
            goodsSubtotal: cart.selectedSubtotal,
          )
          .first;
      final placed = await services.orders.place(
        OrderDraft(
          items: cart.selectedItems,
          address: services.addresses.primary,
          shipping: shipping,
          payment: PaymentCatalog.byId('qris'),
          quote: rewards.quote(
            CheckoutRequest(
              lines: cart.linesForCheckout,
              shippingFee: shipping.fee,
              voucherId: 'V1',
            ),
          ),
        ),
      );
      final order = placed.order!;
      await services.orders.pay(order.id);
      final paid = services.orders.byId(order.id)!;
      await pumpF2(tester, services, location: '/pesanan/${order.id}');

      await tester.tap(find.text('Batalkan pesanan'));
      await settle(tester);
      expect(find.text('128 Kelopak kembali ke saldo'), findsOneWidget);
      expect(
        find.text('Voucher Misi Belanja bisa dipakai lagi'),
        findsOneWidget,
      );
      expect(
        find.text('Dana ${formatRupiah(paid.total)} dikembalikan (simulasi)'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Hubungi CS, Beli lagi di kepala Produk, chip misi, hadiah Rp0',
      (tester) async {
        final services = f2Services(rewards: FakeRewards());
        final order = await placeOrder(
          services,
          lines: const <String, int>{sunscreen: 1, facialWash: 1},
          paymentId: 'cod',
        );
        await pumpF2(tester, services, location: '/pesanan/${order.id}');

        // Dikemas: Batalkan pesanan + Hubungi CS di kaki, headset di kepala.
        expect(find.text('Batalkan pesanan'), findsOneWidget);
        expect(find.text('Hubungi CS'), findsOneWidget);
        expect(find.byTooltip('Hubungi CS'), findsOneWidget);

        await scrollTo(tester, find.text('Produk misi'));
        expect(find.text('Produk misi'), findsOneWidget);
        await scrollTo(tester, find.text('Hadiah gratis (1 barang)'));
        expect(find.text('Rp0'), findsWidgets);

        await scrollTo(tester, find.text('Beli lagi'));
        await tester.tap(find.text('Beli lagi'));
        await settle(tester);
        expect(services.cart.quantityOf(sunscreen), 1);
        expect(services.cart.quantityOf(facialWash), 1);
      },
    );

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
