/// Blok-blok Beranda (SPEC §4.1 butir 2-11).
library;

import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/rewards/rewards_gateway.dart';
import '../../data/wib_dates.dart';
import '../../design/design.dart';
import '../catalog/catalog_page.dart' show CategoryTile;
import '../catalog/shop_common.dart';
import '../hot/hot_deal_view.dart';

// ------------------------------------------------------------- strip akun

/// Strip akun: tamu melihat sapaan Bipy + tombol Masuk; setelah masuk tampil
/// strip dompet dari gateway hadiah, atau sapaan bila hadiah tidak tersedia.
class HomeAccountStrip extends StatelessWidget {
  const HomeAccountStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.auth,
        services.rewards,
      ]),
      builder: (context, _) {
        final profile = services.auth.profile;
        if (!services.auth.isLoggedIn || profile == null) {
          return const _GuestStrip();
        }
        final wallet = services.rewards.available
            ? services.rewards.buildWalletStrip(context)
            : null;
        if (wallet != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
            child: wallet,
          );
        }
        return _GreetingStrip(name: profile.name);
      },
    );
  }
}

class _GuestStrip extends StatefulWidget {
  const _GuestStrip();

  @override
  State<_GuestStrip> createState() => _GuestStripState();
}

class _GuestStripState extends State<_GuestStrip> {
  bool _waved = false;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Container(
      key: const ValueKey<String>('beranda-strip-tamu'),
      margin: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
      padding: const EdgeInsets.fromLTRB(
        BpSpace.x2,
        BpSpace.x1,
        BpSpace.x3,
        BpSpace.x1,
      ),
      decoration: BoxDecoration(
        color: c.brandTint,
        borderRadius: BpRadius.cardAll,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            height: 60,
            child: OverflowBox(
              maxWidth: 80,
              alignment: Alignment.bottomCenter,
              child: BipySprite(
                _waved ? BipySprites.idle : BipySprites.wave,
                height: 60,
                onCompleted: () => setState(() => _waved = true),
              ),
            ),
          ),
          const SizedBox(width: BpSpace.x2),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: 'Hai, Babes! ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: c.brandStrong,
                    ),
                  ),
                  const TextSpan(
                    text: 'Masuk untuk belanja dan kumpulkan Kelopak.',
                  ),
                ],
              ),
              style: BpText.bodyS.copyWith(color: c.text),
            ),
          ),
          const SizedBox(width: BpSpace.x2),
          PillButton(
            key: const ValueKey<String>('beranda-masuk'),
            label: 'Masuk',
            size: PillButtonSize.small,
            variant: PillButtonVariant.outline,
            onPressed: () => services.router.go(context, const LoginRoute()),
          ),
        ],
      ),
    );
  }
}

class _GreetingStrip extends StatelessWidget {
  const _GreetingStrip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final first = name.trim().split(RegExp(r'\s+')).first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: 'Hai, $first! ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: c.brandStrong,
                    ),
                  ),
                  const TextSpan(text: 'Selamat belanja, Babes.'),
                ],
              ),
              style: BpText.bodyS.copyWith(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- pintasan

/// Satu pintasan Beranda.
class HomeShortcut {
  const HomeShortcut({
    required this.label,
    required this.icon,
    required this.tint,
    required this.route,
    this.entry,
  });

  final String label;

  /// Nama ikon 3D di `assets/icons3d/`.
  final String icon;
  final Color Function(BpColors colors) tint;
  final AppRoute route;

  /// Pintu hadiah untuk titik merah.
  final RewardsEntry? entry;
}

/// Sepuluh pintasan SPEC §4.1 butir 4, urut tampil.
final List<HomeShortcut> homeShortcuts = <HomeShortcut>[
  HomeShortcut(
    label: 'Check-in',
    icon: 'checkin',
    tint: (c) => c.brandTint,
    route: const CheckInRoute(),
    entry: RewardsEntry.checkIn,
  ),
  HomeShortcut(
    label: 'Roda Sabtu',
    icon: 'roda',
    tint: (c) => c.goldTint,
    route: const WheelRoute(),
    entry: RewardsEntry.wheel,
  ),
  HomeShortcut(
    label: 'Misi Belanja',
    icon: 'misi',
    tint: (c) => c.successTint,
    route: const MissionRoute(),
    entry: RewardsEntry.mission,
  ),
  HomeShortcut(
    label: 'Voucher',
    icon: 'voucher',
    tint: (c) => c.warningTint,
    route: const VouchersRoute(),
  ),
  HomeShortcut(
    label: 'Hot Item',
    icon: 'hot',
    tint: (c) => c.dangerTint,
    route: const HotItemsRoute(),
  ),
  HomeShortcut(
    label: 'Event Promo',
    icon: 'event',
    tint: (c) => c.infoTint,
    route: const EventHubRoute(),
  ),
  HomeShortcut(
    label: 'Komunitas',
    icon: 'komunitas',
    tint: (c) => c.successTint,
    route: const EventRoute('komunitas-whatsapp'),
  ),
  HomeShortcut(
    label: 'Skincare',
    icon: 'skincare',
    tint: (c) => c.brandTint,
    route: const CatalogRoute(category: 'skincare'),
  ),
  HomeShortcut(
    label: 'Makeup',
    icon: 'makeup',
    tint: (c) => c.goldTint,
    route: const CatalogRoute(category: 'makeup'),
  ),
  HomeShortcut(
    label: 'Semua kategori',
    icon: 'kategori',
    tint: (c) => c.infoTint,
    route: const CatalogRoute(),
  ),
];

/// Grid pintasan 2 x 5: ikon 3D di atas ubin berwarna. Pada huruf besar
/// menjadi dua baris gulir horizontal supaya label tetap utuh.
class HomeShortcutGrid extends StatelessWidget {
  const HomeShortcutGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final large = MediaQuery.textScalerOf(context).scale(10) > 13;
    return ListenableBuilder(
      listenable: services.rewards,
      builder: (context, _) {
        Widget tile(HomeShortcut item) {
          final entry = item.entry;
          final rewards = services.rewards;
          return _ShortcutTile(
            item: item,
            dot: entry != null && rewards.available && rewards.hasBadge(entry),
            onTap: () => services.router.go(context, item.route),
          );
        }

        final half = (homeShortcuts.length / 2).ceil();
        final rows = <List<HomeShortcut>>[
          homeShortcuts.sublist(0, half),
          homeShortcuts.sublist(half),
        ];
        if (large) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final row in rows)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final item in row)
                        SizedBox(width: 108, child: tile(item)),
                    ],
                  ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: BpSpace.x1),
          child: Column(
            children: <Widget>[
              for (final row in rows)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final item in row) Expanded(child: tile(item)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.item,
    required this.dot,
    required this.onTap,
  });

  final HomeShortcut item;
  final bool dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      key: ValueKey<String>('pintasan-${item.icon}'),
      onTap: onTap,
      semanticLabel: dot ? '${item.label}, bisa diklaim' : item.label,
      focusRadius: BpRadius.tileAll,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.tint(c),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  alignment: Alignment.center,
                  child: AssetPicture(
                    'assets/icons3d/${item.icon}.webp',
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                    showSkeleton: false,
                  ),
                ),
                if (dot)
                  const Positioned(top: -2, right: -2, child: DotBadge()),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: BpText.label.copyWith(
                color: c.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------- pengingat bayar

/// Pengingat pesanan Menunggu pembayaran (SPEC §4.1 butir 6).
class HomeUnpaidReminder extends StatelessWidget {
  const HomeUnpaidReminder({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.orders,
        services.auth,
      ]),
      builder: (context, _) {
        if (!services.auth.isLoggedIn) return const SizedBox.shrink();
        final unpaid = services.orders.unpaid;
        if (unpaid.isEmpty) return const SizedBox.shrink();
        final order = unpaid.first;
        final payBy = order.payByMs;
        final more = unpaid.length - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: BpSpace.sectionGap),
          child: Container(
            key: const ValueKey<String>('beranda-bayar'),
            color: c.warningTint,
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x2,
              BpSpace.x3,
              BpSpace.x2,
            ),
            child: Row(
              children: <Widget>[
                Icon(LucideIcons.clock, color: c.warning),
                const SizedBox(width: BpSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Selesaikan pembayaran pesanan #${order.id}',
                        style: BpText.bodyS.copyWith(
                          color: c.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        <String>[
                          if (payBy != null)
                            'Bayar sebelum ${wibDateTimeLabel(DateTime.fromMillisecondsSinceEpoch(payBy, isUtc: true))}',
                          if (more > 0) '$more pesanan lain menunggu',
                        ].join(' · '),
                        style: BpText.caption.copyWith(color: c.warning),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BpSpace.x2),
                PillButton(
                  label: 'Bayar',
                  size: PillButtonSize.small,
                  onPressed: () =>
                      services.router.go(context, PaymentRoute(order.id)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- Hot Item

/// Seksi Hot Item [K8]: seni judul, hitung mundur periode yang paling cepat
/// berakhir, rel kartu gambar highlight asli.
class HomeHotSection extends StatelessWidget {
  const HomeHotSection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final items = services.catalog.hotItems;
    if (items.isEmpty) return const SizedBox.shrink();
    final soonest = soonestRunning(items, services.clock.today);
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = ((width - BpSpace.screen * 2 - BpSpace.grid) / 2.25)
        .clamp(136.0, 200.0);
    return Section(
      header: SectionHeader(
        title: 'Hot Item',
        titleWidget: Wrap(
          spacing: BpSpace.x2,
          runSpacing: BpSpace.x1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const HotItemTitle(),
            if (soonest != null) HotCountdown(deal: soonest),
          ],
        ),
        onAction: () => services.router.go(context, const HotItemsRoute()),
      ),
      child: ProductRail(
        itemCount: items.length,
        itemWidth: cardWidth,
        itemBuilder: (context, index) => HotItemCard(product: items[index]),
      ),
    );
  }
}

// ------------------------------------------------------- kategori dan brand

/// Seksi Kategori: enam ubin ikon brand.
class HomeCategorySection extends StatelessWidget {
  const HomeCategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Section(
      header: SectionHeader(
        title: 'Kategori',
        onAction: () => services.router.go(context, const CatalogRoute()),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final category in services.catalog.categories)
              CategoryTile(
                label: category.name,
                icon: category.icon,
                onTap: () => services.router.go(
                  context,
                  CatalogRoute(category: category.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Seksi Brand pilihan: chip brand bergulir.
class HomeBrandSection extends StatelessWidget {
  const HomeBrandSection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final brands = popularBrands(services, limit: 14);
    return Section(
      header: const SectionHeader(title: 'Brand pilihan'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
        child: Row(
          children: <Widget>[
            for (final brand in brands) ...<Widget>[
              BpChip(
                label: brand,
                onTap: () => services.router.go(
                  context,
                  CatalogRoute(brands: <String>[brand]),
                ),
              ),
              const SizedBox(width: BpSpace.x2),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- kepercayaan

/// Baris kepercayaan (SPEC §4.1 butir 11).
class HomeTrustRow extends StatelessWidget {
  const HomeTrustRow({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    Widget cell(BrandGlyph glyph, String label) => Expanded(
      child: Column(
        children: <Widget>[
          BrandIcon(glyph, size: 28, style: BrandIconStyle.color),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: BpText.caption.copyWith(
              color: c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return Section(
      gap: false,
      padding: const EdgeInsets.fromLTRB(
        BpSpace.x2,
        BpSpace.x4,
        BpSpace.x2,
        BpSpace.x2,
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              cell(BrandGlyph.original, '100% Original'),
              cell(BrandGlyph.best, 'BPOM terverifikasi'),
              cell(BrandGlyph.ongkir, 'Gratis ongkir*'),
            ],
          ),
          const SizedBox(height: BpSpace.x2),
          PillButton(
            label: '*Syarat gratis ongkir ada di Bantuan',
            variant: PillButtonVariant.text,
            size: PillButtonSize.small,
            onPressed: () => services.router.go(context, const HelpRoute()),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- Bipy mengambang

/// Bipy mengintip dari tas di pojok kanan bawah, pintu ke zona Hadiah.
/// Hanya tampil bila hadiah tersedia.
class HomeBipyButton extends StatelessWidget {
  const HomeBipyButton({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return ListenableBuilder(
      listenable: services.rewards,
      builder: (context, _) {
        final rewards = services.rewards;
        if (!rewards.available) return const SizedBox.shrink();
        final dot = rewards.hasBadge(RewardsEntry.hub);
        return BpTappable(
          key: const ValueKey<String>('beranda-bipy'),
          onTap: () => services.router.go(context, const RewardsRoute()),
          semanticLabel: dot
              ? 'Zona Hadiah, ada yang bisa diklaim'
              : 'Zona Hadiah',
          tooltip: 'Main bareng Bipy',
          builder: (context, states) => Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surface,
                  border: Border.all(color: c.brandLine, width: 2),
                  boxShadow: BpShadows.floating(c),
                ),
                child: const ClipOval(
                  child: OverflowBox(
                    maxWidth: 90,
                    maxHeight: 90,
                    alignment: Alignment(0, 0.6),
                    child: BipySprite(BipySprites.peek, height: 78),
                  ),
                ),
              ),
              if (dot) const Positioned(top: 2, right: 2, child: DotBadge()),
            ],
          ),
        );
      },
    );
  }
}
