import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kelopak_hub/kelopak_hub.dart' show shortDateLabel;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../data/address/address_repository.dart';
import '../../data/cart/cart_repository.dart';
import '../../data/orders/order_repository.dart';
import '../../data/payment/payment_catalog.dart';
import '../../data/rewards/rewards_gateway.dart';
import '../../data/shipping/shipping_repository.dart';
import '../../data/wib_dates.dart';
import '../../design/design.dart';
import '../../services/analytics/analytics.dart';
import '../../services/sound/sound_service.dart';
import '../cart/widgets/line_parts.dart';
import '../orders/order_format.dart';
import 'widgets/checkout_sheets.dart';
import 'widgets/payment_summary.dart';

/// `/checkout` [K16]: alamat, barang, hadiah gratis, kurir, voucher,
/// sakelar "Pakai Kelopak" (menyala bawaan), metode bayar, rincian, dan
/// "Buat pesanan". Total Rp0 → "Lunas dengan Kelopak" tanpa metode bayar.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _courierId;
  String? _voucherId;

  /// Sebelum pembeli memilih sendiri, voucher sah terbesar dipakai otomatis.
  bool _voucherChosen = false;
  bool _useKelopak = true;
  String _paymentId = PaymentCatalog.defaultMethodId;
  bool _placing = false;
  bool _logged = false;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.cart,
        services.rewards,
        services.addresses,
        services.auth,
      ]),
      builder: (context, _) => _build(context, services),
    );
  }

  Widget _build(BuildContext context, AppServices services) {
    final c = context.bp;
    final Widget body;
    Widget? bottom;
    if (!services.auth.isLoggedIn) {
      body = _Blocked(
        pose: 'pose_host',
        title: 'Masuk dulu untuk checkout',
        message: 'Keranjangmu aman. Setelah masuk, kamu kembali ke sini.',
        actionLabel: 'Masuk',
        onAction: () => services.router.go(
          context,
          const LoginRoute(next: AppRoutes.checkout),
        ),
      );
    } else if (!services.catalog.isLoaded) {
      body = const _CheckoutSkeleton();
    } else if (!services.cart.hasSelection) {
      body = _Blocked(
        pose: 'pose_semangat',
        title: 'Belum ada produk dipilih',
        message: 'Centang minimal 1 produk di keranjang untuk checkout.',
        actionLabel: 'Ke keranjang',
        onAction: () => services.router.back(context),
      );
    } else {
      final model = _model(services);
      _logInitiated(services, model);
      body = _CheckoutBody(
        model: model,
        services: services,
        onCourier: (id) => setState(() => _courierId = id),
        onPickVoucher: () => _pickVoucher(model),
        onKelopak: (value) {
          services.haptics.selection();
          setState(() => _useKelopak = value);
        },
        onPayment: (id) => setState(() => _paymentId = id),
        onPickPayment: _pickPayment,
      );
      bottom = _CheckoutBar(
        model: model,
        busy: _placing,
        onPlace: () => _place(services, model),
      );
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(title: 'Checkout'),
      body: body,
      bottomNavigationBar: bottom,
    );
  }

  _CheckoutModel _model(AppServices services) {
    final cart = services.cart;
    final items = cart.selectedItems;
    final subtotal = cart.selectedSubtotal;
    final options = services.shipping.options(
      weightGrams: cart.selectedWeightGrams,
      goodsSubtotal: subtotal,
    );
    final shipping = options.firstWhere(
      (option) => option.id == _courierId,
      orElse: () => options.first,
    );
    final rewards = services.rewards;
    final vouchers = rewards.available
        ? rewards.vouchersFor(subtotal)
        : const <VoucherOption>[];
    VoucherOption? voucher;
    if (_voucherChosen) {
      for (final option in vouchers) {
        if (option.id == _voucherId && option.usable) voucher = option;
      }
    } else {
      voucher = bestUsableVoucher(vouchers);
    }
    final quote = rewards.quote(
      CheckoutRequest(
        lines: cart.linesForCheckout,
        shippingFee: shipping.fee,
        voucherId: voucher?.id,
        useKelopak: _useKelopak,
      ),
    );
    final kelopakPreview = rewards.available && !_useKelopak
        ? rewards
              .quote(
                CheckoutRequest(
                  lines: cart.linesForCheckout,
                  shippingFee: shipping.fee,
                  voucherId: voucher?.id,
                ),
              )
              .kelopakValue
        : quote.kelopakValue;
    var itemCount = 0;
    for (final item in items) {
      itemCount += item.qty;
    }
    return _CheckoutModel(
      items: items,
      itemCount: itemCount,
      address: services.addresses.primary,
      shippingOptions: options,
      shipping: shipping,
      vouchers: vouchers,
      voucher: voucher,
      rewardsAvailable: rewards.available,
      kelopakBalance: rewards.kelopakBalance,
      useKelopak: _useKelopak,
      kelopakPreview: kelopakPreview,
      payment: PaymentCatalog.byId(_paymentId) ?? PaymentCatalog.methods.first,
      quote: quote,
    );
  }

  void _logInitiated(AppServices services, _CheckoutModel model) {
    if (_logged) return;
    _logged = true;
    unawaited(
      services.analytics.logInitiatedCheckout(
        productCodes: <String>[
          for (final item in model.items) item.product.code,
        ],
        total: model.quote.goodsSubtotal,
        itemCount: model.itemCount,
      ),
    );
  }

  Future<void> _pickVoucher(_CheckoutModel model) async {
    final choice = await showVoucherSheet(
      context,
      vouchers: model.vouchers,
      selectedId: model.voucher?.id,
    );
    if (!mounted || choice == null) return;
    setState(() {
      _voucherChosen = true;
      _voucherId = choice.voucherId;
    });
  }

  Future<void> _pickPayment(PaymentKind kind) async {
    final id = await showPaymentMethodSheet(
      context,
      selectedId: _paymentId,
      kind: kind,
    );
    if (!mounted || id == null) return;
    setState(() => _paymentId = id);
  }

  Future<void> _place(AppServices services, _CheckoutModel model) async {
    if (_placing) return;
    final messenger = ScaffoldMessenger.of(context);
    if (model.address == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(OrderProblem.missingAddress.message)),
        );
      return;
    }
    setState(() => _placing = true);
    final result = await services.orders.place(
      OrderDraft(
        items: model.items,
        address: model.address,
        shipping: model.shipping,
        payment: model.quote.total == 0 ? null : model.payment,
        quote: model.quote,
      ),
    );
    if (!mounted) return;
    setState(() => _placing = false);
    final order = result.order;
    if (order == null) {
      services.sound.play(SoundCue.softError, withHaptic: false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(result.message ?? 'Pesanan gagal dibuat.')),
        );
      return;
    }
    services.haptics.success();
    await services.router.replace(
      context,
      order.status == OrderStatus.awaitingPayment
          ? PaymentRoute(order.id)
          : OrderSuccessRoute(order.id),
    );
  }
}

final class _CheckoutModel {
  const _CheckoutModel({
    required this.items,
    required this.itemCount,
    required this.address,
    required this.shippingOptions,
    required this.shipping,
    required this.vouchers,
    required this.voucher,
    required this.rewardsAvailable,
    required this.kelopakBalance,
    required this.useKelopak,
    required this.kelopakPreview,
    required this.payment,
    required this.quote,
  });

  final List<CartItem> items;
  final int itemCount;
  final Address? address;
  final List<ShippingOption> shippingOptions;
  final ShippingOption shipping;
  final List<VoucherOption> vouchers;
  final VoucherOption? voucher;
  final bool rewardsAvailable;
  final int kelopakBalance;
  final bool useKelopak;

  /// Potongan rupiah bila sakelar Kelopak menyala.
  final int kelopakPreview;
  final PaymentMethod payment;
  final CheckoutQuote quote;

  int get savings => quote.voucherAmount + quote.kelopakValue;
  int get usableVoucherCount => vouchers.where((v) => v.usable).length;
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({
    required this.model,
    required this.services,
    required this.onCourier,
    required this.onPickVoucher,
    required this.onKelopak,
    required this.onPayment,
    required this.onPickPayment,
  });

  final _CheckoutModel model;
  final AppServices services;
  final ValueChanged<String> onCourier;
  final VoidCallback onPickVoucher;
  final ValueChanged<bool> onKelopak;
  final ValueChanged<String> onPayment;
  final ValueChanged<PaymentKind> onPickPayment;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final quote = model.quote;
    final paidByKelopak = quote.total == 0;
    final missionCodes = services.rewards.available
        ? services.rewards.missionProductCodes
        : const <String>{};
    final voucher = model.voucher;
    return ListView(
      padding: const EdgeInsets.only(bottom: BpSpace.x2),
      children: <Widget>[
        _AddressSection(address: model.address, services: services),
        Section(
          header: SectionHeader(
            title: 'Pesanan (${model.itemCount} barang)',
            leading: _SectionIcon(
              child: BrandIcon(
                BrandGlyph.bag,
                size: BpSize.iconDense,
                color: c.brandStrong,
              ),
            ),
          ),
          child: Column(
            children: <Widget>[
              for (final item in model.items)
                _OrderLine(
                  item: item,
                  mission: missionCodes.contains(item.product.code),
                ),
            ],
          ),
        ),
        if (quote.gifts.isNotEmpty)
          Section(
            padding: const EdgeInsets.only(bottom: BpSpace.x1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GiftSectionHeader(
                  count: quote.gifts.length,
                  subtitle: 'Ikut dikirim, tanpa ongkir tambahan',
                ),
                for (final gift in quote.gifts)
                  GiftTile(
                    name: gift.name,
                    sourceLabel: gift.sourceLabel,
                    thumbSize: 56,
                    imageAsset: services.catalog
                        .byCode(gift.productCode)
                        ?.primaryImage,
                    normalPrice: services.catalog
                        .byCode(gift.productCode)
                        ?.price,
                  ),
              ],
            ),
          ),
        Section(
          header: const SectionHeader(
            title: 'Pengiriman',
            leading: _SectionIcon(
              child: BrandIcon(
                BrandGlyph.ongkir,
                size: BpSize.iconDense,
                style: BrandIconStyle.color,
              ),
            ),
          ),
          child: Column(
            children: <Widget>[
              for (final option in model.shippingOptions)
                ChoiceTile(
                  title: option.name,
                  subtitle:
                      '${etaDateRangeLabel(option.etaLabel, services.clock.instant)} '
                      '${ShippingRepository.demoTag}',
                  selected: option.id == model.shipping.id,
                  onTap: () => onCourier(option.id),
                  trailing: _FeeLabel(option: option),
                ),
            ],
          ),
        ),
        Section(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (model.rewardsAvailable)
                InfoRow(
                  label: voucher != null ? 'Voucher · 1 dipakai' : 'Voucher',
                  leading: const BrandIcon(
                    BrandGlyph.voucher,
                    style: BrandIconStyle.color,
                  ),
                  value: voucher != null
                      ? '-${formatRupiah(voucher.amount)}'
                      : (model.usableVoucherCount > 0
                            ? '${model.usableVoucherCount} bisa dipakai'
                            : (model.vouchers.isEmpty
                                  ? 'Belum ada voucher'
                                  : 'Belum memenuhi syarat')),
                  valueColor: voucher != null ? c.success : null,
                  helper: voucher?.title,
                  onTap: onPickVoucher,
                ),
              if (model.rewardsAvailable) ...<Widget>[
                Divider(height: 1, thickness: 1, indent: 52, color: c.line),
                BpSwitchTile(
                  title: 'Pakai Kelopak',
                  subtitle: _kelopakSubtitle(),
                  value: model.useKelopak && model.kelopakBalance > 0,
                  onChanged: model.kelopakBalance > 0 ? onKelopak : null,
                  leading: const AssetPicture(
                    'assets/icons3d/kelopak.webp',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    showSkeleton: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BpSpace.screen,
                    0,
                    BpSpace.screen,
                    BpSpace.x3,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          LucideIcons.info,
                          size: 14,
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(width: BpSpace.x2),
                      Expanded(
                        child: Text(
                          '1 Kelopak = Rp100. Memotong harga barang, tidak '
                          'memotong ongkir.',
                          style: BpText.caption.copyWith(color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (paidByKelopak)
          Section(inset: true, child: _PaidNote(kelopak: quote.kelopakUsed))
        else
          Section(
            header: SectionHeader(
              title: 'Metode pembayaran',
              subtitle: 'Simulasi, tanpa uang sungguhan',
              leading: _SectionIcon(
                child: Icon(
                  LucideIcons.wallet,
                  size: BpSize.iconDense,
                  color: c.brandStrong,
                ),
              ),
            ),
            padding: const EdgeInsets.only(bottom: BpSpace.x2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final (index, entry)
                    in PaymentCatalog.grouped.entries.indexed) ...<Widget>[
                  if (index > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      endIndent: BpSpace.screen,
                      color: c.line,
                    ),
                  PaymentKindTile(
                    kind: entry.key,
                    methods: entry.value,
                    selected: model.payment.kind == entry.key,
                    chosen: model.payment.kind == entry.key
                        ? model.payment
                        : null,
                    onTap: entry.value.length == 1
                        ? () => onPayment(entry.value.single.id)
                        : () => onPickPayment(entry.key),
                  ),
                ],
                if (model.payment.isCod)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BpSpace.screen,
                      BpSpace.x1,
                      BpSpace.screen,
                      0,
                    ),
                    child: Text(
                      'Bayar tunai ke kurir saat paket tiba. Pesanan langsung '
                      'dikemas.',
                      style: BpText.caption.copyWith(color: c.textMuted),
                    ),
                  ),
              ],
            ),
          ),
        Section(
          header: const SectionHeader(title: 'Rincian pembayaran'),
          child: PaymentSummary(
            goodsSubtotal: quote.goodsSubtotal,
            itemCount: model.itemCount,
            shippingFee: quote.shippingFee,
            voucherAmount: quote.voucherAmount,
            voucherTitle: voucher?.title,
            kelopakUsed: quote.kelopakUsed,
            kelopakValue: quote.kelopakValue,
            giftCount: quote.gifts.length,
            total: quote.total,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.screen,
            BpSpace.x2,
            BpSpace.screen,
            BpSpace.x4,
          ),
          child: Text(
            'Dengan membuat pesanan, kamu menyetujui Syarat dan Ketentuan '
            'Bpedia. Ini aplikasi demo: tidak ada barang maupun uang '
            'sungguhan.',
            textAlign: TextAlign.center,
            style: BpText.caption.copyWith(color: c.textMuted),
          ),
        ),
      ],
    );
  }

  String _kelopakSubtitle() {
    final balance = model.kelopakBalance;
    if (balance == 0) {
      return 'Saldo 0 Kelopak. Kumpulkan lewat Check-in Harian.';
    }
    return 'Saldo ${kelopakAmountLabel(balance)} · potong '
        '${formatRupiah(model.kelopakPreview)}';
  }
}

/// "Tiba 27 - 28 Nov" dari label kurir "Tiba 2 sampai 3 hari" terhadap jam
/// app (WIB). Label lain dikembalikan apa adanya.
String etaDateRangeLabel(String etaLabel, DateTime now) {
  final match = RegExp(r'(\d+)\s*sampai\s*(\d+)\s*hari').firstMatch(etaLabel);
  if (match == null) return etaLabel;
  final today = wibDayOfInstant(now);
  final from = shortDateLabel(today + int.parse(match.group(1)!));
  final to = shortDateLabel(today + int.parse(match.group(2)!));
  final fromParts = from.split(' ');
  final toParts = to.split(' ');
  if (fromParts.length == 2 &&
      toParts.length == 2 &&
      fromParts[1] == toParts[1]) {
    return 'Tiba ${fromParts[0]} - $to';
  }
  return 'Tiba $from - $to';
}

/// Ikon kepala seksi 20 dp.
class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: BpSpace.x2),
    child: child,
  );
}

/// Satu jenis pembayaran sebagai baris radio berikon: QRIS, transfer bank,
/// gerai, dompet digital, COD. Jenis dengan beberapa pilihan (bank, gerai)
/// membuka lembar pilihan saat diketuk.
class PaymentKindTile extends StatelessWidget {
  const PaymentKindTile({
    super.key,
    required this.kind,
    required this.methods,
    required this.selected,
    required this.onTap,
    this.chosen,
  });

  final PaymentKind kind;
  final List<PaymentMethod> methods;
  final bool selected;

  /// Metode terpilih dari jenis ini (mis. BCA untuk transfer bank).
  final PaymentMethod? chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final pick = chosen;
    final icon = paymentKindIcon(kind);
    final (String title, String? subtitle) = switch (kind) {
      PaymentKind.qris => (
        'QRIS',
        'Bayar dari aplikasi bank atau dompet digital',
      ),
      PaymentKind.virtualAccount => (
        'Transfer bank (virtual account)',
        pick != null ? pick.name : '${methods.length} bank tersedia',
      ),
      PaymentKind.retail => (
        'Bayar di gerai',
        pick != null ? pick.name : 'Minimarket terdekat',
      ),
      PaymentKind.ewallet => ('Dompet digital', null),
      PaymentKind.cod => ('Bayar di tempat (COD)', null),
    };
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: BpTappable(
        onTap: onTap,
        selected: selected,
        pressScale: false,
        alignment: Alignment.centerLeft,
        focusRadius: BpRadius.tileAll,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BpSpace.screen,
            vertical: 10,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: BpSize.iconDense,
                color: selected ? c.brandStrong : c.text,
              ),
              const SizedBox(width: BpSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: BpText.body.copyWith(color: c.text)),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: BpSpace.x2),
              if (methods.length > 1 && !selected)
                Padding(
                  padding: const EdgeInsets.only(right: BpSpace.x2),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: c.textMuted,
                  ),
                ),
              RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({required this.address, required this.services});

  final Address? address;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final value = address;
    if (value == null) {
      return Section(
        header: const SectionHeader(title: 'Alamat pengiriman'),
        inset: true,
        child: Container(
          padding: const EdgeInsets.all(BpSpace.x3),
          decoration: BoxDecoration(
            color: c.warningTint,
            borderRadius: BpRadius.cardAll,
          ),
          child: Row(
            children: <Widget>[
              Icon(LucideIcons.mapPinOff, color: c.warning),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Text(
                  'Belum ada alamat. Tambah alamat supaya pesanan bisa dikirim.',
                  style: BpText.bodyS.copyWith(color: c.text),
                ),
              ),
              const SizedBox(width: BpSpace.x2),
              PillButton(
                label: 'Tambah alamat',
                size: PillButtonSize.small,
                onPressed: () =>
                    services.router.go(context, const AddressFormRoute()),
              ),
            ],
          ),
        ),
      );
    }
    return Section(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x3,
              BpSpace.x2,
              BpSpace.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.brandTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: c.brandStrong,
                  ),
                ),
                const SizedBox(width: BpSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: BpSpace.x2,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            'Alamat pengiriman',
                            style: BpText.bodyS.copyWith(color: c.textMuted),
                          ),
                          if (value.isPrimary)
                            const StatusChip(
                              label: 'Utama',
                              tone: StatusTone.brand,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${value.label} · ${value.recipient} · '
                        '${value.phoneLabel}',
                        style: BpText.subtitle.copyWith(color: c.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value.fullAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BpText.bodyS.copyWith(color: c.textMuted),
                      ),
                      if (value.note.isNotEmpty)
                        Text(
                          'Catatan: ${value.note}',
                          style: BpText.caption.copyWith(color: c.textMuted),
                        ),
                    ],
                  ),
                ),
                PillButton(
                  label: 'Ubah',
                  variant: PillButtonVariant.text,
                  size: PillButtonSize.small,
                  onPressed: () => services.router.go(
                    context,
                    const AddressesRoute(selecting: true),
                  ),
                ),
              ],
            ),
          ),
          const _AirmailStripe(),
        ],
      ),
    );
  }
}

/// Garis putus pink-emas di bawah alamat (gaya amplop kiriman).
class _AirmailStripe extends StatelessWidget {
  const _AirmailStripe();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return ExcludeSemantics(
      child: SizedBox(
        height: 3,
        width: double.infinity,
        child: CustomPaint(
          painter: _AirmailPainter(first: c.brand, second: c.gold),
        ),
      ),
    );
  }
}

class _AirmailPainter extends CustomPainter {
  const _AirmailPainter({required this.first, required this.second});

  final Color first;
  final Color second;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 18.0;
    const gap = 6.0;
    final paints = <Paint>[Paint()..color = first, Paint()..color = second];
    var x = 0.0;
    var index = 0;
    while (x < size.width) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, dash, size.height),
          Radius.circular(size.height / 2),
        ),
        paints[index % 2],
      );
      x += dash + gap;
      index++;
    }
  }

  @override
  bool shouldRepaint(_AirmailPainter oldDelegate) =>
      oldDelegate.first != first || oldDelegate.second != second;
}

class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.item, required this.mission});

  final CartItem item;
  final bool mission;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final product = item.product;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.screen,
          vertical: 6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LineThumb(asset: product.primaryImage, size: 56),
            const SizedBox(width: BpSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BpText.bodyS.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: BpSpace.x2,
                    runSpacing: 2,
                    children: <Widget>[
                      Wrap(
                        spacing: BpSpace.x2,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            '${item.qty} x ${formatRupiah(product.price)}',
                            style: BpText.caption.copyWith(color: c.textMuted),
                          ),
                          if (mission) const MissionChip(),
                        ],
                      ),
                      Text(
                        formatRupiah(item.lineTotal),
                        style: BpText.subtitle.copyWith(
                          color: c.text,
                          fontFeatures: BpText.tabular,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilah lekat checkout. Total Rp0 memakai susunan dua baris supaya label
/// "Buat pesanan · Lunas dengan Kelopak" muat satu baris di lebar 390.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.model,
    required this.busy,
    required this.onPlace,
  });

  final _CheckoutModel model;
  final bool busy;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final quote = model.quote;
    final used = quote.kelopakUsed;
    final caption = model.savings > 0
        ? 'Hemat ${formatRupiah(model.savings)}'
              '${used > 0 ? ' · ${kelopakAmountLabel(used)}' : ''}'
        : null;
    if (quote.total != 0) {
      return StickyBottomBar.total(
        total: quote.total,
        label: 'Total pembayaran',
        caption: caption,
        actionLabel: 'Buat pesanan',
        busy: busy,
        onAction: onPlace,
      );
    }
    return StickyBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            liveRegion: true,
            label:
                'Total pembayaran ${formatRupiah(0)}'
                '${caption == null ? '' : ', $caption'}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Total pembayaran',
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                      Text(
                        formatRupiah(0),
                        style: BpText.titleL.copyWith(
                          fontSize: 18,
                          height: 24 / 18,
                          color: c.text,
                          fontFeatures: BpText.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                if (caption != null)
                  Flexible(
                    child: Text(
                      caption,
                      textAlign: TextAlign.end,
                      style: BpText.label.copyWith(
                        color: c.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: BpSpace.x2),
          PillButton(
            key: const ValueKey<String>('checkout-buat-pesanan'),
            label: 'Buat pesanan · Lunas dengan Kelopak',
            expand: true,
            busy: busy,
            onPressed: onPlace,
          ),
        ],
      ),
    );
  }
}

class _FeeLabel extends StatelessWidget {
  const _FeeLabel({required this.option});

  final ShippingOption option;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    if (option.isFree) {
      return Text('Gratis', style: BpText.subtitle.copyWith(color: c.success));
    }
    return Text(
      formatRupiah(option.fee),
      style: BpText.subtitle.copyWith(
        color: c.text,
        fontFeatures: BpText.tabular,
      ),
    );
  }
}

class _PaidNote extends StatelessWidget {
  const _PaidNote({required this.kelopak});

  final int kelopak;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(BpSpace.x3),
        decoration: BoxDecoration(
          color: c.successTint,
          borderRadius: BpRadius.cardAll,
        ),
        child: Row(
          children: <Widget>[
            Icon(LucideIcons.badgeCheck, color: c.success),
            const SizedBox(width: BpSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Lunas dengan Kelopak',
                    style: BpText.subtitle.copyWith(color: c.success),
                  ),
                  Text(
                    '${kelopakAmountLabel(kelopak)} menutup seluruh harga. '
                    'Tidak perlu metode pembayaran.',
                    style: BpText.caption.copyWith(color: c.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blocked extends StatelessWidget {
  const _Blocked({
    required this.pose,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String pose;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: EmptyState(
          illustration: FloatingBipy(pose: pose, height: 140),
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }
}

class _CheckoutSkeleton extends StatelessWidget {
  const _CheckoutSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      label: 'Memuat checkout',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: BpSpace.sectionGap),
        children: <Widget>[
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: BpSpace.sectionGap),
              child: ColoredBox(
                color: c.surface,
                child: const Padding(
                  padding: EdgeInsets.all(BpSpace.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Skeleton.line(width: 140, height: 16),
                      SizedBox(height: BpSpace.x3),
                      Skeleton.line(),
                      SizedBox(height: 6),
                      Skeleton.line(width: 220),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
