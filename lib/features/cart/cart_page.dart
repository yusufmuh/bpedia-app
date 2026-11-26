import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/shell.dart' show LoginButton;
import '../../data/rewards/rewards_gateway.dart';
import '../../design/design.dart';
import '../checkout/widgets/checkout_sheets.dart' show bestUsableVoucher;
import '../orders/order_format.dart';
import 'widgets/cart_item_tile.dart';
import 'widgets/cart_nudges.dart';
import 'widgets/line_parts.dart';
import 'widgets/recommendations.dart';

/// `/keranjang` [K17]: barang berbayar, hadiah gratis Rp0 dari
/// [RewardsGateway.pendingGifts], dorongan Kelopak dan misi, total, Checkout.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.catalog,
        services.cart,
        services.rewards,
        services.auth,
        services.addresses,
      ]),
      builder: (context, _) => _CartView(services: services),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final catalog = services.catalog;
    final cart = services.cart;
    final title = catalog.isLoaded && !cart.isEmpty
        ? 'Keranjang (${cart.lineCount})'
        : 'Keranjang';
    final Widget body;
    Widget? bottom;
    if (catalog.loadError != null) {
      body = _CartError(services: services);
    } else if (!catalog.isLoaded) {
      body = const _CartSkeleton();
    } else {
      final gifts = services.rewards.available
          ? services.rewards.pendingGifts
          : const <GiftLine>[];
      if (cart.isEmpty && gifts.isEmpty) {
        body = _EmptyCart(services: services);
      } else {
        body = _CartContent(services: services, gifts: gifts);
        bottom = _CartBottomBar(services: services, hasGifts: gifts.isNotEmpty);
      }
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: BpAppBar(
        title: title,
        actions: <Widget>[
          IconButton(
            tooltip: 'Wishlist',
            icon: BrandIcon(BrandGlyph.wishlist, color: c.text),
            onPressed: () => services.router.go(context, const WishlistRoute()),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: bottom,
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({required this.services, required this.gifts});

  final AppServices services;
  final List<GiftLine> gifts;

  @override
  Widget build(BuildContext context) {
    final cart = services.cart;
    final rewards = services.rewards;
    final loggedIn = services.auth.isLoggedIn;
    final items = cart.items;
    final missionCodes = rewards.available
        ? rewards.missionProductCodes
        : const <String>{};
    final hint = rewards.available && loggedIn && !cart.isEmpty
        ? rewards.missionHintFor(cart.pricedLines)
        : null;
    final rates = services.shipping.rates;
    final freeFrom = rates.isEmpty ? null : rates.first.freeFromSubtotal;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: loggedIn
              ? ShipToBar(
                  label: _addressLabel(),
                  onTap: () => services.router.go(
                    context,
                    services.addresses.primary == null
                        ? const AddressFormRoute()
                        : const AddressesRoute(selecting: true),
                  ),
                )
              : const _GuestStrip(),
        ),
        if (hint != null)
          SliverToBoxAdapter(
            child: MissionStrip(
              hint: hint,
              onOpen: () => services.router.go(context, const MissionRoute()),
            ),
          ),
        if (!cart.isEmpty && freeFrom != null)
          SliverToBoxAdapter(
            child: FreeShippingStrip(
              courierName: rates.first.name,
              freeFrom: freeFrom,
              subtotal: cart.selectedSubtotal,
            ),
          ),
        if (!cart.isEmpty) ...<Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: BpSpace.sectionGap)),
          SliverToBoxAdapter(child: _StoreHeader(services: services)),
          SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              indent: 52,
              color: context.bp.line,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final code = item.product.code;
              return CartItemTile(
                item: item,
                missionProduct: missionCodes.contains(code),
                onSelected: (value) => cart.setSelected(code, value),
                onQtyChanged: (qty) => _setQty(context, code, qty),
                onRemove: () => _remove(context, code),
                onOpen: () => services.router.go(context, ProductRoute(code)),
              );
            },
          ),
        ],
        if (gifts.isNotEmpty)
          SliverToBoxAdapter(
            child: _GiftSection(services: services, gifts: gifts),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: BpSpace.sectionGap)),
        SliverToBoxAdapter(
          child: RecommendationSection(
            exclude: <String>[for (final item in items) item.product.code],
          ),
        ),
      ],
    );
  }

  String? _addressLabel() {
    final address = services.addresses.primary;
    if (address == null) return null;
    return '${address.label} · ${address.district}, ${address.city}';
  }

  void _setQty(BuildContext context, String code, int qty) {
    final change = services.cart.setQty(code, qty);
    final limit = change.limit;
    if (limit == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(limit.message)));
  }

  void _remove(BuildContext context, String code) {
    final product = services.catalog.byCode(code);
    final removed = services.cart.remove(code);
    if (removed == null) return;
    services.haptics.light();
    showUndoSnackBar(
      context,
      message: 'Dihapus: ${product?.name ?? 'produk'}',
      onUndo: () => services.cart.undoRemove(removed),
    );
  }
}

/// Snackbar "Urungkan" 4 detik.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        action: SnackBarAction(label: 'Urungkan', onPressed: onUndo),
      ),
    );
}

/// Kepala grup toko: centang semua barang toko, "Bpedia Official", chip
/// Original, dan "Hapus" untuk barang yang dicentang.
class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final cart = services.cart;
    final selected = cart.selectedLineCount;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.only(left: BpSpace.x1, right: BpSpace.x2),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: cart.allSelected ? true : (selected == 0 ? false : null),
            tristate: true,
            onChanged: (_) => cart.selectAll(!cart.allSelected),
            semanticLabel: 'Pilih semua produk Bpedia Official',
          ),
          BrandIcon(BrandGlyph.bag, size: BpSize.iconDense, color: c.text),
          const SizedBox(width: BpSpace.x2),
          Expanded(
            child: Wrap(
              spacing: BpSpace.x2,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  'Bpedia Official',
                  style: BpText.subtitle.copyWith(color: c.text),
                ),
                StatusChip(
                  label: 'Original',
                  tone: StatusTone.brand,
                  icon: Icon(
                    LucideIcons.badgeCheck,
                    size: 12,
                    color: c.brandStrong,
                  ),
                ),
              ],
            ),
          ),
          if (selected > 0)
            Semantics(
              label: 'Hapus $selected produk yang dicentang',
              button: true,
              excludeSemantics: true,
              child: PillButton(
                label: 'Hapus',
                variant: PillButtonVariant.text,
                size: PillButtonSize.small,
                onPressed: () {
                  final removed = cart.removeSelected();
                  if (removed.isEmpty) return;
                  services.haptics.light();
                  showUndoSnackBar(
                    context,
                    message: '${removed.length} produk dihapus dari keranjang',
                    onUndo: () => cart.restoreAll(removed),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _GiftSection extends StatelessWidget {
  const _GiftSection({required this.services, required this.gifts});

  final AppServices services;
  final List<GiftLine> gifts;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final ready = services.cart.hasSelection;
    return Padding(
      padding: const EdgeInsets.only(top: BpSpace.sectionGap),
      child: ColoredBox(
        color: c.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GiftSectionHeader(
              count: gifts.length,
              subtitle:
                  'Dikirim bersama pesanan berbayar, tanpa ongkir tambahan',
            ),
            for (final gift in gifts)
              GiftTile(
                name: gift.name,
                sourceLabel: gift.sourceLabel,
                imageAsset: services.catalog
                    .byCode(gift.productCode)
                    ?.primaryImage,
                normalPrice: services.catalog.byCode(gift.productCode)?.price,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BpSpace.screen,
                0,
                BpSpace.screen,
                BpSpace.x3,
              ),
              child: ready
                  ? _GiftStatus(
                      color: c.success,
                      background: c.successTint,
                      text: 'Dikirim bersama pesanan ini',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _GiftStatus(
                          color: c.warning,
                          background: c.warningTint,
                          text:
                              'Tambah minimal 1 produk supaya hadiahmu bisa dikirim',
                        ),
                        const SizedBox(height: BpSpace.x2),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: PillButton(
                            label: 'Belanja sekarang',
                            variant: PillButtonVariant.outline,
                            size: PillButtonSize.small,
                            onPressed: () => services.router.go(
                              context,
                              const CatalogRoute(),
                            ),
                          ),
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

class _GiftStatus extends StatelessWidget {
  const _GiftStatus({
    required this.color,
    required this.background,
    required this.text,
  });

  final Color color;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.x3,
          vertical: BpSpace.x2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BpRadius.tileAll,
        ),
        child: Text(
          text,
          style: BpText.bodyS.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GuestStrip extends StatelessWidget {
  const _GuestStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(
        BpSpace.screen,
        BpSpace.x2,
        BpSpace.screen,
        BpSpace.x2,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          BpSpace.x3,
          BpSpace.x2,
          BpSpace.x2,
          BpSpace.x2,
        ),
        decoration: BoxDecoration(
          color: c.brandTint,
          borderRadius: BpRadius.cardAll,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Masuk untuk checkout dan pakai Kelopak, Babes.',
                style: BpText.bodyS.copyWith(color: c.text),
              ),
            ),
            const SizedBox(width: BpSpace.x2),
            const LoginButton(next: '/keranjang'),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan harga keranjang dari kutipan yang sama dengan checkout: voucher
/// terbaik yang sah + Kelopak (sakelar checkout menyala bawaan).
final class _CartPricing {
  const _CartPricing({
    required this.subtotal,
    required this.strikeSaving,
    required this.voucherAmount,
    required this.voucherTitle,
    required this.kelopakUsed,
    required this.kelopakValue,
  });

  factory _CartPricing.of(AppServices services) {
    final cart = services.cart;
    final rewards = services.rewards;
    var strikeSaving = 0;
    for (final item in cart.selectedItems) {
      final strike = item.product.strikePrice;
      if (strike != null && strike > item.product.price) {
        strikeSaving += (strike - item.product.price) * item.qty;
      }
    }
    final subtotal = cart.selectedSubtotal;
    if (!rewards.available || !services.auth.isLoggedIn || !cart.hasSelection) {
      return _CartPricing(
        subtotal: subtotal,
        strikeSaving: strikeSaving,
        voucherAmount: 0,
        voucherTitle: null,
        kelopakUsed: 0,
        kelopakValue: 0,
      );
    }
    final voucher = bestUsableVoucher(rewards.vouchersFor(subtotal));
    final quote = rewards.quote(
      CheckoutRequest(
        lines: cart.linesForCheckout,
        shippingFee: 0,
        voucherId: voucher?.id,
      ),
    );
    return _CartPricing(
      subtotal: subtotal,
      strikeSaving: strikeSaving,
      voucherAmount: quote.voucherAmount,
      voucherTitle: quote.voucherAmount > 0 ? voucher?.title : null,
      kelopakUsed: quote.kelopakUsed,
      kelopakValue: quote.kelopakValue,
    );
  }

  final int subtotal;
  final int strikeSaving;
  final int voucherAmount;
  final String? voucherTitle;
  final int kelopakUsed;
  final int kelopakValue;

  int get checkoutSaving => voucherAmount + kelopakValue;

  /// Total barang setelah voucher dan Kelopak, sebelum ongkir.
  int get total => subtotal - checkoutSaving;

  /// Harga awal yang dicoret: harga normal sebelum diskon produk dan
  /// potongan checkout. Null bila tidak ada potongan sama sekali.
  int? get strikeTotal {
    final original = subtotal + strikeSaving;
    return original > total ? original : null;
  }
}

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({required this.services, required this.hasGifts});

  final AppServices services;
  final bool hasGifts;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final cart = services.cart;
    final pricing = _CartPricing.of(services);
    final blocked = !cart.hasSelection;
    final selected = cart.selectedLineCount;
    final Widget? header;
    if (blocked && hasGifts) {
      header = Container(
        color: c.warningTint,
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.screen,
          vertical: BpSpace.x2,
        ),
        child: Text(
          'Pilih minimal 1 produk berbayar supaya hadiahmu ikut dikirim.',
          style: BpText.caption.copyWith(color: c.warning),
        ),
      );
    } else if (pricing.checkoutSaving > 0) {
      header = CartSavingsCard(
        voucherAmount: pricing.voucherAmount,
        kelopakUsed: pricing.kelopakUsed,
        kelopakValue: pricing.kelopakValue,
        onTap: () => _showPriceDetail(context, pricing),
      );
    } else {
      header = null;
    }
    final strike = pricing.strikeTotal;
    return StickyBottomBar(
      header: header,
      padding: const EdgeInsets.fromLTRB(
        BpSpace.x1,
        BpSpace.x2,
        BpSpace.screen,
        BpSpace.x2,
      ),
      child: Row(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 32,
                child: Checkbox(
                  value: cart.allSelected
                      ? true
                      : (selected == 0 ? false : null),
                  tristate: true,
                  onChanged: (_) => cart.selectAll(!cart.allSelected),
                  semanticLabel: 'Pilih semua',
                ),
              ),
              ExcludeSemantics(
                child: SizedBox(
                  width: 48,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Semua',
                      style: BpText.label.copyWith(color: c.textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.only(right: BpSpace.x3),
            color: c.line,
          ),
          Expanded(
            child: BpTappable(
              onTap: blocked ? null : () => _showPriceDetail(context, pricing),
              pressScale: false,
              alignment: Alignment.centerLeft,
              focusRadius: BpRadius.tileAll,
              semanticLabel:
                  'Total ${formatRupiah(pricing.total)}'
                  '${strike == null ? '' : ', harga awal ${formatRupiah(strike)}'}'
                  '. Lihat rincian',
              builder: (context, states) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Total',
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                      if (strike != null) ...<Widget>[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            formatRupiah(strike),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BpText.caption.copyWith(
                              color: c.textFaint,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: c.textFaint,
                              fontFeatures: BpText.tabular,
                            ),
                          ),
                        ),
                      ],
                      if (!blocked)
                        Icon(
                          LucideIcons.chevronUp,
                          size: 16,
                          color: c.textMuted,
                        ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      formatRupiah(pricing.total),
                      maxLines: 1,
                      style: BpText.titleL.copyWith(
                        fontSize: 18,
                        height: 24 / 18,
                        color: c.brandStrong,
                        fontFeatures: BpText.tabular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: BpSpace.x2),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.45,
            ),
            child: PillButton(
              label: 'Checkout ($selected)',
              onPressed: blocked
                  ? null
                  : () => services.router.go(context, const CheckoutRoute()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPriceDetail(BuildContext context, _CartPricing pricing) {
    return showBpSheet<void>(
      context: context,
      builder: (sheetContext) {
        final c = sheetContext.bp;
        final title = pricing.voucherTitle;
        return BpSheet(
          title: 'Rincian harga',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InfoRow(
                label: 'Subtotal produk (${services.cart.selectedLineCount})',
                value: formatRupiah(pricing.subtotal),
                padding: EdgeInsets.zero,
              ),
              if (pricing.strikeSaving > 0)
                InfoRow(
                  label: 'Sudah termasuk diskon produk',
                  value: formatRupiah(pricing.strikeSaving),
                  valueColor: c.success,
                  padding: EdgeInsets.zero,
                ),
              if (pricing.voucherAmount > 0)
                InfoRow(
                  label: title == null ? 'Voucher' : 'Voucher · $title',
                  value: '-${formatRupiah(pricing.voucherAmount)}',
                  valueColor: c.success,
                  padding: EdgeInsets.zero,
                ),
              if (pricing.kelopakValue > 0)
                InfoRow(
                  label:
                      'Kelopak dipakai · '
                      '${kelopakAmountLabel(pricing.kelopakUsed)}',
                  value: '-${formatRupiah(pricing.kelopakValue)}',
                  valueColor: c.success,
                  padding: EdgeInsets.zero,
                ),
              Divider(height: BpSpace.x4, color: c.line),
              InfoRow(
                label: 'Total sebelum ongkir',
                value: formatRupiah(pricing.total),
                emphasized: true,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: BpSpace.x2),
              Text(
                'Ongkir dihitung di checkout. Kelopak hanya memotong harga '
                'barang, bukan ongkir.',
                style: BpText.caption.copyWith(color: c.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Section(
          child: EmptyState(
            illustration: const BipySprite(
              BipySprites.walk,
              height: 120,
              semanticLabel: 'Bipy berjalan membawa tas belanja',
            ),
            title: 'Keranjangmu masih kosong',
            message: 'Yuk, isi dengan skincare dan makeup favoritmu, Babes.',
            actionLabel: 'Mulai belanja',
            onAction: () => services.router.go(context, const HomeRoute()),
          ),
        ),
        const RecommendationSection(exclude: <String>[]),
      ],
    );
  }
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      label: 'Memuat keranjang',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 1),
        itemBuilder: (context, index) => ColoredBox(
          color: c.surface,
          child: const Padding(
            padding: EdgeInsets.all(BpSpace.screen),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Skeleton(width: 20, height: 20, radius: BpRadius.badge),
                SizedBox(width: BpSpace.x3),
                Skeleton(width: 72, height: 72),
                SizedBox(width: BpSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Skeleton.line(),
                      SizedBox(height: 6),
                      Skeleton.line(width: 140),
                      SizedBox(height: BpSpace.x3),
                      Skeleton.line(width: 90, height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartError extends StatelessWidget {
  const _CartError({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: EmptyState(
          illustration: const FloatingBipy(pose: 'pose_semangat', height: 120),
          title: 'Keranjang belum bisa dimuat',
          message: 'Data produk gagal dibaca. Coba lagi sebentar, Babes.',
          actionLabel: 'Coba lagi',
          onAction: () => services.catalog.load(DefaultAssetBundle.of(context)),
        ),
      ),
    );
  }
}
