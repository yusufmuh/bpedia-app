import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/shell.dart' show LoginButton;
import '../../data/rewards/rewards_gateway.dart';
import '../../design/design.dart';
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
      appBar: BpAppBar(title: title),
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
    final saving = rewards.available && loggedIn && cart.hasSelection
        ? rewards
              .quote(
                CheckoutRequest(lines: cart.linesForCheckout, shippingFee: 0),
              )
              .kelopakValue
        : 0;

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
          SliverToBoxAdapter(child: _SelectAllBar(services: services)),
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
        if (saving > 0 || hint != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: BpSpace.sectionGap),
              child: ColoredBox(
                color: context.bp.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: BpSpace.x3),
                  child: Column(
                    children: <Widget>[
                      if (saving > 0)
                        KelopakNudge(
                          balance: rewards.kelopakBalance,
                          saving: saving,
                        ),
                      if (saving > 0 && hint != null)
                        const SizedBox(height: BpSpace.x2),
                      if (hint != null)
                        MissionNudge(
                          hint: hint,
                          onOpen: () =>
                              services.router.go(context, const MissionRoute()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
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
    return '${address.label} · ${address.recipient}';
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

class _SelectAllBar extends StatelessWidget {
  const _SelectAllBar({required this.services});

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
            semanticLabel: 'Pilih semua',
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => cart.selectAll(!cart.allSelected),
              child: Text(
                'Pilih semua (${cart.lineCount})',
                style: BpText.subtitle.copyWith(color: c.text),
              ),
            ),
          ),
          if (selected > 0)
            PillButton(
              label: 'Hapus ($selected)',
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

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({required this.services, required this.hasGifts});

  final AppServices services;
  final bool hasGifts;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final cart = services.cart;
    var strikeSaving = 0;
    for (final item in cart.selectedItems) {
      final strike = item.product.strikePrice;
      if (strike != null && strike > item.product.price) {
        strikeSaving += (strike - item.product.price) * item.qty;
      }
    }
    final blocked = !cart.hasSelection;
    return StickyBottomBar.total(
      total: cart.selectedSubtotal,
      caption: strikeSaving > 0 ? 'Hemat ${formatRupiah(strikeSaving)}' : null,
      actionLabel: 'Checkout (${cart.selectedLineCount})',
      onAction: blocked
          ? null
          : () => services.router.go(context, const CheckoutRoute()),
      header: blocked && hasGifts
          ? Container(
              color: c.warningTint,
              padding: const EdgeInsets.symmetric(
                horizontal: BpSpace.screen,
                vertical: BpSpace.x2,
              ),
              child: Text(
                'Pilih minimal 1 produk berbayar supaya hadiahmu ikut dikirim.',
                style: BpText.caption.copyWith(color: c.warning),
              ),
            )
          : null,
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
