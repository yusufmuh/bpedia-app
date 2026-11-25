/// Halaman event (`/event/:id`): banner, penjelasan, voucher event (klaim
/// 12.12 lewat port hadiah), syarat, produk terkait, dan tombol aksi.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/shell.dart' show CartButton;
import '../../data/promo/promo_repository.dart';
import '../../design/design.dart';
import '../catalog/shop_common.dart';

/// Halaman event ber-ID [id].
class EventPage extends StatelessWidget {
  const EventPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final event = services.promo.eventById(id);
    if (event == null) {
      return Scaffold(
        appBar: const BpAppBar(title: 'Event Promo'),
        body: Center(
          child: SingleChildScrollView(
            child: EmptyState(
              imageAsset: 'assets/bipy/bipy_ngintip.webp',
              title: 'Event tidak ditemukan',
              message: 'Event ini sudah selesai atau tautannya salah, Babes.',
              actionLabel: 'Lihat semua event',
              onAction: () =>
                  services.router.go(context, const EventHubRoute()),
            ),
          ),
        ),
      );
    }
    return _EventView(event: event);
  }
}

class _EventView extends StatelessWidget {
  const _EventView({required this.event});

  final PromoEvent event;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final products = services.catalog.byCodes(event.productCodes);
    final cta = event.cta;
    final voucher = event.voucher;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: BpAppBar(
        title: event.title,
        actions: const <Widget>[CartButton()],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 3,
              child: AssetPicture(event.banner, semanticLabel: event.title),
            ),
          ),
          SliverToBoxAdapter(
            child: Section(
              padding: const EdgeInsets.all(BpSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      event.title,
                      style: BpText.titleL.copyWith(color: c.text),
                    ),
                  ),
                  if (event.period.isNotEmpty) ...<Widget>[
                    const SizedBox(height: BpSpace.x2),
                    StatusChip(
                      label: event.period,
                      tone: StatusTone.brand,
                      icon: const Icon(LucideIcons.calendar),
                    ),
                  ],
                  if (event.summary.isNotEmpty) ...<Widget>[
                    const SizedBox(height: BpSpace.x3),
                    Text(
                      event.summary,
                      style: BpText.body.copyWith(color: c.text),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (voucher != null)
            SliverToBoxAdapter(
              child: Section(
                header: const SectionHeader(title: 'Voucher event'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.screen,
                  ),
                  child: _PromoVoucher(event: event, offer: voucher),
                ),
              ),
            ),
          if (event.body.isNotEmpty)
            SliverToBoxAdapter(
              child: Section(
                header: const SectionHeader(title: 'Tentang event'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.screen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final paragraph in event.body)
                        Padding(
                          padding: const EdgeInsets.only(bottom: BpSpace.x2),
                          child: Text(
                            paragraph,
                            style: BpText.body.copyWith(color: c.text),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (event.terms.isNotEmpty)
            SliverToBoxAdapter(
              child: Section(
                header: const SectionHeader(title: 'Syarat dan ketentuan'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.screen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (var i = 0; i < event.terms.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: BpSpace.x2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${i + 1}.',
                                  style: BpText.bodyS.copyWith(
                                    color: c.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  event.terms[i],
                                  style: BpText.bodyS.copyWith(
                                    color: c.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (products.isNotEmpty) ...<Widget>[
            const SliverToBoxAdapter(
              child: Section(
                gap: false,
                padding: EdgeInsets.only(top: BpSpace.x1),
                header: SectionHeader(title: 'Produk pilihan event'),
                child: SizedBox.shrink(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: BpSpace.x2),
              sliver: SliverProductGrid(
                itemCount: products.length,
                itemBuilder: (context, index) =>
                    ShopProductCard(product: products[index]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: BpSpace.x4)),
        ],
      ),
      bottomNavigationBar: cta == null
          ? null
          : StickyBottomBar(
              child: PillButton(
                key: const ValueKey<String>('event-cta'),
                label: cta.label,
                expand: true,
                onPressed: () {
                  final route = cta.route;
                  final url = cta.url;
                  if (route != null) {
                    openAppLocation(context, route);
                  } else if (url != null) {
                    services.links.open(url);
                  }
                },
              ),
            ),
    );
  }
}

class _PromoVoucher extends StatefulWidget {
  const _PromoVoucher({required this.event, required this.offer});

  final PromoEvent event;
  final PromoVoucherOffer offer;

  @override
  State<_PromoVoucher> createState() => _PromoVoucherState();
}

class _PromoVoucherState extends State<_PromoVoucher> {
  bool _busy = false;

  Future<void> _claim() async {
    final services = AppScope.of(context);
    final offer = widget.offer;
    setState(() => _busy = true);
    final result = await services.rewards.claimPromoVoucher(
      promoId: widget.event.id,
      amount: offer.amount,
      minSpend: offer.minSpend,
      validDays: offer.validDays,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.ok) {
      services.haptics.success();
    } else {
      services.haptics.medium();
    }
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.ok
                ? 'Voucher ${formatRupiah(offer.amount)} masuk ke Voucher Saya.'
                : result.message ??
                      'Voucher belum bisa diklaim. Coba lagi, ya.',
          ),
          action: result.ok
              ? SnackBarAction(
                  label: 'Lihat',
                  onPressed: () =>
                      services.router.go(context, const VouchersRoute()),
                )
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final offer = widget.offer;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.auth,
        services.rewards,
      ]),
      builder: (context, _) {
        final claimDay = services.promo.isVoucherClaimDay(widget.event);
        final dayLabel =
            '${wibDayName(offer.claimDay)}, ${wibLongDate(offer.claimDay)}';
        String? action;
        VoidCallback? onAction;
        String? reason;
        var muted = false;
        if (!services.rewards.available) {
          muted = true;
          reason = 'Klaim voucher aktif saat Zona Hadiah tersambung.';
        } else if (!claimDay) {
          action = services.clock.today < offer.claimDay ? 'Segera' : 'Selesai';
          reason = services.clock.today < offer.claimDay
              ? 'Klaim dibuka $dayLabel (WIB).'
              : 'Masa klaim sudah lewat ($dayLabel).';
          muted = services.clock.today > offer.claimDay;
        } else if (!services.auth.isLoggedIn) {
          action = 'Masuk';
          reason = 'Masuk dulu untuk klaim voucher, Babes.';
          onAction = () => services.router.go(
            context,
            LoginRoute(next: EventRoute(widget.event.id).location),
          );
        } else if (services.rewards.canClaimPromoVoucher(widget.event.id)) {
          action = _busy ? 'Proses' : 'Klaim';
          onAction = _busy ? null : _claim;
        } else {
          action = 'Diklaim';
          reason = 'Voucher sudah ada di Voucher Saya.';
        }
        return VoucherTicket(
          key: const ValueKey<String>('event-voucher'),
          valueLabel: formatRupiah(offer.amount),
          title: 'Voucher ${widget.event.title}',
          condition: 'Min. belanja ${formatRupiah(offer.minSpend)}',
          expiry: 'Berlaku ${offer.validDays} hari setelah diklaim',
          actionLabel: action,
          onAction: onAction,
          muted: muted,
          reason: reason,
        );
      },
    );
  }
}
