import 'dart:async';

import 'package:flutter/material.dart';
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
        onPickPayment: () => _pickPayment(),
      );
      bottom = StickyBottomBar.total(
        total: model.quote.total,
        label: 'Total pembayaran',
        caption: model.savings > 0
            ? 'Hemat ${formatRupiah(model.savings)}'
            : null,
        actionLabel: model.quote.total == 0
            ? 'Buat pesanan · Lunas dengan Kelopak'
            : 'Buat pesanan',
        busy: _placing,
        onAction: () => _place(services, model),
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
    for (final option in vouchers) {
      if (option.id == _voucherId && option.usable) voucher = option;
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
    setState(() => _voucherId = choice.voucherId);
  }

  Future<void> _pickPayment() async {
    final id = await showPaymentMethodSheet(context, selectedId: _paymentId);
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
    required this.onPickPayment,
  });

  final _CheckoutModel model;
  final AppServices services;
  final ValueChanged<String> onCourier;
  final VoidCallback onPickVoucher;
  final ValueChanged<bool> onKelopak;
  final VoidCallback onPickPayment;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final quote = model.quote;
    final paidByKelopak = quote.total == 0;
    return ListView(
      padding: const EdgeInsets.only(top: BpSpace.sectionGap),
      children: <Widget>[
        _AddressSection(address: model.address, services: services),
        Section(
          header: SectionHeader(title: 'Pesanan (${model.itemCount} barang)'),
          child: Column(
            children: <Widget>[
              for (final item in model.items) _OrderLine(item: item),
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
          header: const SectionHeader(title: 'Pengiriman'),
          child: Column(
            children: <Widget>[
              for (final option in model.shippingOptions)
                ChoiceTile(
                  title: option.name,
                  subtitle: '${option.etaLabel} ${ShippingRepository.demoTag}',
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
            children: <Widget>[
              if (model.rewardsAvailable)
                InfoRow(
                  label: 'Voucher',
                  leading: const BrandIcon(
                    BrandGlyph.voucher,
                    style: BrandIconStyle.color,
                  ),
                  value: model.voucher != null
                      ? '-${formatRupiah(model.voucher!.amount)}'
                      : (model.usableVoucherCount > 0
                            ? '${model.usableVoucherCount} bisa dipakai'
                            : (model.vouchers.isEmpty
                                  ? 'Belum ada voucher'
                                  : 'Belum memenuhi syarat')),
                  valueColor: model.voucher != null ? c.success : null,
                  helper: model.voucher?.title,
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
              ],
            ],
          ),
        ),
        if (paidByKelopak)
          Section(inset: true, child: _PaidNote(kelopak: quote.kelopakUsed))
        else
          Section(
            padding: const EdgeInsets.only(bottom: BpSpace.x2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                InfoRow(
                  label: 'Metode pembayaran',
                  value: model.payment.name,
                  leading: Icon(LucideIcons.wallet, color: c.text),
                  onTap: onPickPayment,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.screen,
                  ),
                  child: Text(
                    model.payment.isCod
                        ? 'Bayar tunai ke kurir saat paket tiba. Pesanan langsung dikemas.'
                        : PaymentCatalog.demoNote,
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
            voucherTitle: model.voucher?.title,
            kelopakUsed: quote.kelopakUsed,
            kelopakValue: quote.kelopakValue,
            total: quote.total,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.screen,
            0,
            BpSpace.screen,
            BpSpace.x6,
          ),
          child: Text(
            'Dengan membuat pesanan, kamu menyetujui Syarat dan Ketentuan '
            'Bpedia. Ini aplikasi demo: tidak ada barang maupun uang '
            'sungguhan.',
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
      header: SectionHeader(
        title: 'Alamat pengiriman',
        actionLabel: 'Ubah',
        onAction: () =>
            services.router.go(context, const AddressesRoute(selecting: true)),
      ),
      inset: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.mapPin, size: 20, color: c.brandStrong),
          ),
          const SizedBox(width: BpSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: BpSpace.x2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      value.recipient,
                      style: BpText.subtitle.copyWith(color: c.text),
                    ),
                    Text(
                      value.phoneLabel,
                      style: BpText.bodyS.copyWith(color: c.textMuted),
                    ),
                    StatusChip(label: value.label),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value.fullAddress,
                  style: BpText.bodyS.copyWith(color: c.text),
                ),
                if (value.note.isNotEmpty)
                  Text(
                    'Catatan: ${value.note}',
                    style: BpText.caption.copyWith(color: c.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.item});

  final CartItem item;

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
                    children: <Widget>[
                      Text(
                        '${item.qty} x ${formatRupiah(product.price)}',
                        style: BpText.caption.copyWith(color: c.textMuted),
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
