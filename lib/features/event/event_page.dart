/// Halaman event (`/event/:id`, PERBAIKAN event_*): banner bermargin, chip
/// periode, judul, produk event tepat di bawah judul, voucher event (klaim
/// 12.12 lewat port hadiah), detail bernomor, syarat, event lainnya, dan
/// tombol aksi.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Event hadiah produk Roda Sabtu: tombol aksinya membuka Roda Sabtu.
  bool get _wheelPrize => event.cta?.route == const WheelRoute().location;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final products = services.catalog.byCodes(event.productCodes);
    final others = <PromoEvent>[
      for (final other in services.promo.events)
        if (other.id != event.id) other,
    ];
    final cta = event.cta;
    final voucher = event.voucher;
    final wheel = _wheelPrize;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: BpAppBar(
        title: event.title,
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('event-bagikan'),
            tooltip: 'Bagikan',
            onPressed: () => _shareEvent(context, event),
            icon: Icon(LucideIcons.share2, color: c.text),
          ),
          const CartButton(),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Section(
              padding: const EdgeInsets.all(BpSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BpRadius.cardAll,
                    child: AspectRatio(
                      aspectRatio: 3,
                      child: AssetPicture(
                        event.banner,
                        semanticLabel: event.title,
                      ),
                    ),
                  ),
                  if (event.period.isNotEmpty) ...<Widget>[
                    const SizedBox(height: BpSpace.x3),
                    StatusChip(
                      label: event.period,
                      tone: StatusTone.brand,
                      icon: const Icon(LucideIcons.calendar),
                    ),
                  ],
                  const SizedBox(height: BpSpace.x2),
                  Semantics(
                    header: true,
                    child: Text(
                      event.title,
                      style: BpText.titleL.copyWith(color: c.text),
                    ),
                  ),
                  if (event.summary.isNotEmpty) ...<Widget>[
                    const SizedBox(height: BpSpace.x2),
                    Text(
                      event.summary,
                      style: BpText.body.copyWith(color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (products.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(
              child: Section(
                gap: false,
                padding: const EdgeInsets.only(top: BpSpace.x1),
                header: SectionHeader(
                  title: wheel
                      ? 'Hadiah produk Roda Sabtu'
                      : 'Produk pilihan event',
                ),
                child: const SizedBox.shrink(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                top: BpSpace.x2,
                bottom: BpSpace.sectionGap,
              ),
              sliver: SliverProductGrid(
                itemCount: products.length,
                itemBuilder: (context, index) => ShopProductCard(
                  product: products[index],
                  ribbon: wheel ? 'Hadiah Roda' : null,
                ),
              ),
            ),
          ],
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
                header: SectionHeader(
                  title: wheel ? 'Cara ikut' : 'Detail event',
                ),
                child: _NumberedList(
                  key: const ValueKey<String>('event-detail'),
                  items: event.body,
                  style: BpText.body.copyWith(color: c.text),
                ),
              ),
            ),
          if (event.terms.isNotEmpty)
            SliverToBoxAdapter(
              child: Section(
                header: const SectionHeader(title: 'Syarat dan ketentuan'),
                child: _NumberedList(
                  key: const ValueKey<String>('event-syarat'),
                  items: event.terms,
                  style: BpText.bodyS.copyWith(color: c.textMuted),
                ),
              ),
            ),
          if (others.isNotEmpty)
            SliverToBoxAdapter(
              child: Section(
                header: const SectionHeader(title: 'Event lainnya'),
                child: _OtherEvents(events: others),
              ),
            ),
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
                icon: cta.url == null
                    ? null
                    : const BrandIcon(BrandGlyph.chat, size: 20),
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

/// Menyalin tautan event ke papan klip.
Future<void> _shareEvent(BuildContext context, PromoEvent event) async {
  final services = AppScope.of(context);
  await Clipboard.setData(
    ClipboardData(text: 'https://bpedia.id${EventRoute(event.id).location}'),
  );
  services.haptics.selection();
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Tautan event disalin. Tinggal tempel, Babes.'),
      ),
    );
}

/// Daftar bernomor lingkaran 20 dp; satu butir saja tampil sebagai paragraf.
class _NumberedList extends StatelessWidget {
  const _NumberedList({required this.items, required this.style, super.key});

  final List<String> items;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    if (items.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
        child: Text(items.single, style: style),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: BpSpace.x3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.brandTint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      textScaler: TextScaler.noScaling,
                      style: BpText.label.copyWith(
                        color: c.brandStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: BpSpace.x3),
                  Expanded(child: Text(items[i], style: style)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Rel "Event lainnya": banner 3:1 + judul + periode.
class _OtherEvents extends StatelessWidget {
  const _OtherEvents({required this.events});

  final List<PromoEvent> events;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final width = (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 320.0);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final other in events) ...<Widget>[
            SizedBox(
              width: width,
              child: BpTappable(
                key: ValueKey<String>('event-lain-${other.id}'),
                onTap: () => services.router.go(context, EventRoute(other.id)),
                semanticLabel: '${other.title}, ${other.period}',
                minWidth: 0,
                minHeight: 0,
                focusRadius: BpRadius.cardAll,
                builder: (context, states) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BpRadius.cardAll,
                      child: AspectRatio(
                        aspectRatio: 3,
                        child: AssetPicture(other.banner),
                      ),
                    ),
                    const SizedBox(height: BpSpace.x2),
                    Text(
                      other.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BpText.bodyS.copyWith(
                        color: c.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (other.period.isNotEmpty)
                      Text(
                        other.period,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                  ],
                ),
              ),
            ),
            if (other != events.last) const SizedBox(width: BpSpace.x3),
          ],
        ],
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
