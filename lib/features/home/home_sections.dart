/// Blok-blok Beranda (SPEC §4.1 butir 2-11).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../data/rewards/rewards_gateway.dart';
import '../../design/design.dart';
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
      constraints: const BoxConstraints(minHeight: 56),
      margin: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
      padding: const EdgeInsets.fromLTRB(BpSpace.x3, 4, BpSpace.x2, 4),
      decoration: BoxDecoration(
        color: c.brandTint,
        borderRadius: BpRadius.cardAll,
        border: Border.all(color: c.brandLine),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28,
            height: 40,
            child: OverflowBox(
              maxWidth: 56,
              alignment: Alignment.bottomCenter,
              child: BipySprite(
                _waved ? BipySprites.idle : BipySprites.wave,
                height: 40,
                onCompleted: () => setState(() => _waved = true),
              ),
            ),
          ),
          const SizedBox(width: BpSpace.x2),
          const Expanded(child: _OneLine(text: 'Masuk dan kumpulkan Kelopak')),
          const SizedBox(width: BpSpace.x2),
          PillButton(
            key: const ValueKey<String>('beranda-masuk'),
            label: 'Masuk',
            size: PillButtonSize.small,
            onPressed: () => services.router.go(context, const LoginRoute()),
          ),
        ],
      ),
    );
  }
}

/// Teks satu baris yang mengecil bila sempit pada skala huruf normal; pada
/// huruf besar boleh dua baris supaya tetap terbaca.
class _OneLine extends StatelessWidget {
  const _OneLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final style = BpText.bodyS.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: c.text,
    );
    if (MediaQuery.textScalerOf(context).scale(10) > 11.5) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, maxLines: 1, style: style),
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
    required this.route,
    this.entry,
  });

  final String label;

  /// Nama ikon 3D di `assets/icons3d/`.
  final String icon;
  final AppRoute route;

  /// Pintu hadiah untuk titik merah.
  final RewardsEntry? entry;
}

/// Sepuluh pintasan SPEC §4.1 butir 4, urut tampil.
final List<HomeShortcut> homeShortcuts = <HomeShortcut>[
  const HomeShortcut(
    label: 'Check-in',
    icon: 'checkin',
    route: CheckInRoute(),
    entry: RewardsEntry.checkIn,
  ),
  const HomeShortcut(
    label: 'Roda Sabtu',
    icon: 'roda',
    route: WheelRoute(),
    entry: RewardsEntry.wheel,
  ),
  const HomeShortcut(
    label: 'Misi Belanja',
    icon: 'misi',
    route: MissionRoute(),
    entry: RewardsEntry.mission,
  ),
  const HomeShortcut(label: 'Voucher', icon: 'voucher', route: VouchersRoute()),
  const HomeShortcut(label: 'Hot Item', icon: 'hot', route: HotItemsRoute()),
  const HomeShortcut(
    label: 'Event Promo',
    icon: 'event',
    route: EventHubRoute(),
  ),
  const HomeShortcut(
    label: 'Komunitas',
    icon: 'komunitas',
    route: EventRoute('komunitas-whatsapp'),
  ),
  const HomeShortcut(
    label: 'Skincare',
    icon: 'skincare',
    route: CatalogRoute(category: 'skincare'),
  ),
  const HomeShortcut(
    label: 'Makeup',
    icon: 'makeup',
    route: CatalogRoute(category: 'makeup'),
  ),
  const HomeShortcut(
    label: 'Semua kategori',
    icon: 'kategori',
    route: CatalogRoute(),
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
          final claimable =
              entry != null && rewards.available && rewards.hasBadge(entry);
          return _ShortcutTile(
            item: item,
            dot: claimable && entry != RewardsEntry.wheel,
            freeTag: claimable && entry == RewardsEntry.wheel,
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
              const SizedBox(height: BpSpace.x2),
              const _GridIndicator(),
            ],
          ),
        );
      },
    );
  }
}

/// Garis indikator di bawah grid pintasan.
class _GridIndicator extends StatelessWidget {
  const _GridIndicator();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return ExcludeSemantics(
      child: Container(
        width: 28,
        height: 3,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: c.line,
          borderRadius: BpRadius.pillAll,
        ),
        child: Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: c.brand,
            borderRadius: BpRadius.pillAll,
          ),
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.item,
    required this.dot,
    required this.onTap,
    this.freeTag = false,
  });

  final HomeShortcut item;
  final bool dot;
  final VoidCallback onTap;

  /// Lencana pita "Gratis" saat putaran Roda Sabtu gratis tersedia.
  final bool freeTag;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      key: ValueKey<String>('pintasan-${item.icon}'),
      onTap: onTap,
      semanticLabel: dot || freeTag
          ? '${item.label}, bisa diklaim'
          : item.label,
      focusRadius: BpRadius.tileAll,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  alignment: Alignment.center,
                  child: AssetPicture(
                    'assets/icons3d/${item.icon}.webp',
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                    showSkeleton: false,
                  ),
                ),
                if (dot)
                  const Positioned(top: -2, right: -2, child: DotBadge()),
                if (freeTag)
                  Positioned(
                    top: -8,
                    left: -6,
                    right: -6,
                    child: Center(
                      child: Container(
                        key: ValueKey<String>('pintasan-${item.icon}-gratis'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: c.sale,
                          borderRadius: BpRadius.badgeAll,
                        ),
                        child: Text(
                          'Gratis',
                          textScaler: TextScaler.noScaling,
                          style: BpText.label.copyWith(
                            fontSize: 9,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: c.onSale,
                          ),
                        ),
                      ),
                    ),
                  ),
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

// ---------------------------------------------------------------- Hot Item

/// Seksi Hot Item [K8]: seni judul + hitung mundur sebaris, lalu hanya
/// kampanye yang sedang berjalan. Dua kartu atau kurang tampil berdampingan
/// selebar layar; lebih dari dua menjadi rel. Tersembunyi bila tidak ada
/// kampanye berjalan.
class HomeHotSection extends StatelessWidget {
  const HomeHotSection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final today = services.clock.today;
    final items = <Product>[
      for (final product in services.catalog.hotItems)
        if (hotPhaseOf(product.hot!, today) == HotPhase.running) product,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    final soonest = soonestRunning(items, today);
    final width = MediaQuery.sizeOf(context).width;
    final half = (width - BpSpace.screen * 2 - BpSpace.grid) / 2;
    final Widget cards;
    if (items.length <= 2) {
      cards = Padding(
        padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: HotItemCard(product: items.first)),
              const SizedBox(width: BpSpace.grid),
              Expanded(
                child: items.length > 1
                    ? HotItemCard(product: items[1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    } else {
      cards = ProductRail(
        itemCount: items.length,
        itemWidth: math.max(160, half * 0.9),
        itemBuilder: (context, index) => HotItemCard(product: items[index]),
      );
    }
    return Section(
      header: SectionHeader(
        title: 'Hot Item',
        titleWidget: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.58,
                ),
                child: const HotItemTitle(size: 18),
              ),
              if (soonest != null) ...<Widget>[
                const SizedBox(width: 6),
                Flexible(child: HotCountdown(deal: soonest, dense: true)),
              ],
            ],
          ),
        ),
        onAction: () => services.router.go(context, const HotItemsRoute()),
      ),
      child: cards,
    );
  }
}

// ------------------------------------------------------------------ brand

/// Seksi Brand pilihan: chip brand bergulir; "Semua brand" membuka Katalog.
class HomeBrandSection extends StatelessWidget {
  const HomeBrandSection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final brands = popularBrands(services, limit: 14);
    return Section(
      header: SectionHeader(
        title: 'Brand pilihan',
        actionLabel: 'Semua brand',
        onAction: () => services.router.go(context, const CatalogRoute()),
      ),
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

// ------------------------------------------------------------ rekomendasi

/// Baris tab teks rekomendasi: "Untukmu" (semua) lalu kategori katalog.
class HomeRecommendTabs extends StatelessWidget {
  const HomeRecommendTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// ID kategori terpilih; null = Untukmu.
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    Widget tab(String? id, String label) {
      final active = id == selected;
      return BpTappable(
        key: ValueKey<String>('rekomendasi-tab-${id ?? 'untukmu'}'),
        onTap: () => onSelected(id),
        semanticLabel: active ? '$label, terpilih' : label,
        minWidth: 0,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: BpText.bodyS.copyWith(
                  color: active ? c.brandStrong : c.textMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: active ? 28 : 0,
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: BpRadius.pillAll,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
      child: Row(
        children: <Widget>[
          tab(null, 'Untukmu'),
          for (final category in services.catalog.categories)
            tab(category.id, category.name),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- kepercayaan

/// Baris kepercayaan Beranda tepat di bawah carousel (SPEC §4.1 butir 11).
class HomeTrustRow extends StatelessWidget {
  const HomeTrustRow({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    key: ValueKey<String>('beranda-kepercayaan'),
    padding: EdgeInsets.symmetric(horizontal: BpSpace.screen),
    child: TrustBadgeRow(),
  );
}
