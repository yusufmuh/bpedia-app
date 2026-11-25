import 'dart:async';

import 'package:bpedia_app/app/app.dart';
import 'package:bpedia_app/app/app_services.dart';
import 'package:bpedia_app/data/address/address_repository.dart';
import 'package:bpedia_app/data/inbox/inbox_repository.dart';
import 'package:bpedia_app/data/orders/order_repository.dart';
import 'package:bpedia_app/data/payment/payment_catalog.dart';
import 'package:bpedia_app/data/rewards/rewards_gateway.dart';
import 'package:bpedia_app/features/account_routes.dart';
import 'package:bpedia_app/services/links.dart';
import 'package:bpedia_app/services/reminders/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kode produk nyata dari `assets/catalog/catalog.json`.
const String productA = 'P68B13S01000010';
const String productB = 'P39A06S01000007';

/// Alamat contoh (data karangan, bukan data pribadi nyata).
const AddressDraft sampleAddress = AddressDraft(
  label: 'Rumah',
  recipient: 'Ayu Lestari',
  phone: '0812 3456 7890',
  street: 'Jl. Melati Raya No. 12, RT 03/RW 05',
  district: 'Coblong',
  city: 'Bandung',
  province: 'Jawa Barat',
  postalCode: '40132',
  note: 'Pagar putih, dekat warung',
);

/// Alamat kantor contoh.
const AddressDraft officeAddress = AddressDraft(
  label: 'Kantor',
  recipient: 'Ayu Lestari',
  phone: '0813 2222 4444',
  street: 'Jl. Asia Afrika No. 8, Lantai 3',
  district: 'Sumur Bandung',
  city: 'Bandung',
  province: 'Jawa Barat',
  postalCode: '40111',
);

/// Gateway hadiah tiruan: tersedia, punya saldo, dan alat Mode Demo.
class FakeRewards extends NoRewardsGateway implements DemoRewardsTools {
  FakeRewards({
    this.balance = 128,
    this.vouchers = 2,
    this.gifts = const <GiftLine>[
      GiftLine(
        id: 'G1',
        productCode: productB,
        name: 'Produk gratis Roda Sabtu',
        sourceLabel: 'Roda Sabtu, 21 Nov',
      ),
    ],
    this.badge = true,
  });

  int balance;
  int vouchers;
  List<GiftLine> gifts;
  bool badge;
  int resets = 0;
  final List<String> actionsRun = <String>[];

  @override
  bool get available => true;

  @override
  int get kelopakBalance => balance;

  @override
  int get voucherCount => vouchers;

  @override
  List<GiftLine> get pendingGifts => gifts;

  @override
  bool hasBadge(RewardsEntry entry) => badge;

  @override
  Future<bool> grantKelopak(int amount) async {
    balance += amount;
    notifyListeners();
    return true;
  }

  @override
  Future<void> resetRewards() async {
    resets++;
    balance = 0;
    vouchers = 0;
    gifts = const <GiftLine>[];
    notifyListeners();
  }

  @override
  List<DemoRewardsAction> get demoActions => <DemoRewardsAction>[
    DemoRewardsAction(
      id: 'refill-quota',
      label: 'Isi kuota produk roda',
      description: 'Sisa kuota hadiah produk kembali 3.',
      run: () async {
        actionsRun.add('refill-quota');
        return 'Kuota produk roda diisi ulang.';
      },
    ),
  ];
}

/// Layanan uji dengan rute F3 terdaftar dan tema [dark].
AppServices f3Services({
  bool loggedIn = false,
  bool dark = false,
  RewardsGateway? rewards,
  ReminderService? reminders,
  UriOpener? opener,
}) {
  final services = AppServices.forTest(
    loggedIn: loggedIn,
    rewardsBuilder: rewards == null ? null : (_) => rewards,
    reminders: reminders,
    uriOpener: opener,
  );
  registerAccountRoutes(services.router);
  services.settings.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
  addTearDown(() => unawaited(services.dispose()));
  return services;
}

/// App lengkap yang dibuka di [location].
Widget f3App(AppServices services, String location) =>
    BpediaApp(services: services, initialLocation: location);

/// Mengisi notifikasi contoh (pesanan, hadiah, promo).
void seedInbox(AppServices services) {
  services.inbox
    ..add(
      kind: InboxKind.promo,
      title: 'Black Friday mulai 27 Nov, 12.00 WIB',
      body:
          'Hot Item pilihan dengan harga spesial. Siapkan keranjangmu, Babes.',
      route: '/event/black-friday',
    )
    ..add(
      kind: InboxKind.reward,
      title: '+1 Kelopak dari Check-in Harian',
      body: 'Streak hari ke-3. Klaim lagi besok supaya bonus hari ke-7 aman.',
      route: '/hadiah/riwayat',
    )
    ..add(
      kind: InboxKind.order,
      title: 'Pesanan BP-261125-0001 sedang dikemas',
      body: 'Pembayaran diterima. Kami kabari lagi saat pesanan dikirim.',
      route: '/pesanan',
    );
  services.inbox.markRead(services.inbox.messages.last.id);
}

/// Membuat satu pesanan menunggu pembayaran (QRIS) dari keranjang.
Future<Order?> placeUnpaidOrder(AppServices services) async {
  if (services.addresses.isEmpty) services.addresses.add(sampleAddress);
  services.cart.add(productA);
  final shipping = services.shipping
      .options(
        weightGrams: services.cart.selectedWeightGrams,
        goodsSubtotal: services.cart.selectedSubtotal,
      )
      .first;
  final result = await services.orders.place(
    OrderDraft(
      items: services.cart.selectedItems,
      address: services.addresses.primary,
      shipping: shipping,
      payment: PaymentCatalog.byId('qris'),
      quote: services.rewards.quote(
        CheckoutRequest(
          lines: services.cart.linesForCheckout,
          shippingFee: shipping.fee,
          useKelopak: false,
        ),
      ),
    ),
  );
  return result.order;
}

/// Mengatur layar uji [size] dp dengan skala huruf [textScale].
void setScreen(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

/// Menggulir daftar utama sampai [finder] terlihat, lalu mengetuknya.
/// [settle] false untuk tujuan yang animasinya berulang (Bipy bergerak).
Future<void> tapVisible(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  await revealFromTop(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await pumpFor(tester);
  }
}

/// Memajukan waktu [duration] untuk halaman yang animasinya berulang. Bingkai
/// pertama memulai transisi; bingkai kedua memajukannya.
Future<void> pumpFor(
  WidgetTester tester, [
  Duration duration = const Duration(seconds: 1),
]) async {
  await tester.pump();
  await tester.pump(duration);
}

/// Memasang app di [location] pada layar ponsel 390x844 (kecuali tes sudah
/// mengatur layar sendiri dengan [setScreen]).
Future<void> openF3(
  WidgetTester tester,
  AppServices services,
  String location,
) async {
  if (tester.view.physicalSize == const Size(2400, 1800)) setScreen(tester);
  await tester.pumpWidget(f3App(services, location));
}

/// Menggulir daftar utama sampai [finder] terlihat.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, [
  double delta = 200,
]) async {
  await tester.scrollUntilVisible(finder, delta, scrollable: mainScrollable());
  await tester.pump();
}

/// Kembali ke awal daftar utama bila [finder] belum ada, lalu menggulir ke
/// bawah sampai terlihat.
Future<void> revealFromTop(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    tester.state<ScrollableState>(mainScrollable()).position.jumpTo(0);
    await tester.pump();
  }
  await tester.scrollUntilVisible(finder, 160, scrollable: mainScrollable());
}

/// Scrollable milik `ListView` teratas yang terlihat (bukan milik kolom isian).
Finder mainScrollable() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;
