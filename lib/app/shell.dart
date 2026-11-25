/// Kerangka app: lima tab bawah (SPEC §3), halaman pengganti untuk tab yang
/// fiturnya belum terdaftar, dan aksi bilah atas yang siap dipakai layar.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/rewards/rewards_gateway.dart';
import '../design/design.dart';
import 'app_router.dart';
import 'app_scope.dart';
import 'app_services.dart';
import 'phone_frame.dart';

/// Kerangka lima tab: Beranda, Katalog, Hadiah, Transaksi, Akun.
///
/// Isi tab berasal dari `AppRouter.registerTab`; tab yang belum terdaftar
/// menampilkan [TabPlaceholderPage]. Tab dibangun saat pertama dibuka lalu
/// dipertahankan (posisi gulir tidak hilang), dan animasinya berhenti saat
/// tab tidak terlihat. Kerangka tidak punya bilah atas: tiap tab memasang
/// bilahnya sendiri, termasuk [ThemeToggleButton], [CartButton], dan
/// [LoginButton].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  final LayerLink _navLink = LayerLink();
  final Set<AppTab> _visited = <AppTab>{};
  final Map<AppTab, ScrollController> _scroll = <AppTab, ScrollController>{
    for (final tab in AppTab.values)
      tab: ScrollController(debugLabel: 'tab-${tab.name}'),
  };
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: BpMotion.micro,
    value: 1,
  );
  late final Animation<double> _fadeCurve = CurvedAnimation(
    parent: _fade,
    curve: BpMotion.microCurve,
  );

  AppServices? _services;
  AppTab _current = AppTab.home;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    if (identical(services, _services)) return;
    _services?.router.tabRoute.removeListener(_onTabRoute);
    _services = services;
    services.router.tabRoute.addListener(_onTabRoute);
    _current = services.router.currentTab;
    _visited.add(_current);
  }

  @override
  void dispose() {
    _services?.router.tabRoute.removeListener(_onTabRoute);
    _fade.dispose();
    for (final controller in _scroll.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabRoute() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _onTabRoute());
      return;
    }
    final services = _services;
    if (!mounted || services == null) return;
    final next = services.router.currentTab;
    if (next == _current) return;
    setState(() {
      _current = next;
      _visited.add(next);
    });
    if (BpMotion.reduced(context)) {
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  void _select(AppTab tab) {
    final services = _services;
    if (services == null) return;
    services.haptics.selection();
    if (tab != _current) {
      services.router.selectTab(tab);
      return;
    }
    final controller = _scroll[tab];
    if (controller == null || !controller.hasClients) return;
    if (BpMotion.reduced(context)) {
      controller.jumpTo(0);
    } else {
      controller.animateTo(
        0,
        duration: BpMotion.standard,
        curve: BpMotion.standardCurve,
      );
    }
  }

  Widget _tabContent(BuildContext context, AppRouter router, AppTab tab) {
    return router.canOpen(AppRoutes.tabRoot(tab))
        ? router.buildTab(context, tab)
        : TabPlaceholderPage(tab: tab);
  }

  @override
  Widget build(BuildContext context) {
    final services = _services!;
    final router = services.router;
    return PopScope<Object?>(
      canPop: _current == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) router.selectTab(AppTab.home);
      },
      child: Stack(
        children: <Widget>[
          Scaffold(
            backgroundColor: context.bp.canvas,
            body: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                for (final tab in AppTab.values)
                  if (_visited.contains(tab))
                    _TabHost(
                      key: ValueKey<AppTab>(tab),
                      active: tab == _current,
                      fade: _fadeCurve,
                      controller: _scroll[tab]!,
                      child: Builder(
                        builder: (context) => _tabContent(context, router, tab),
                      ),
                    ),
              ],
            ),
            bottomNavigationBar: CompositedTransformTarget(
              link: _navLink,
              child: ListenableBuilder(
                listenable: Listenable.merge(<Listenable>[
                  services.orders,
                  services.rewards,
                  services.auth,
                ]),
                builder: (context, _) {
                  final unpaid = services.auth.isLoggedIn
                      ? services.orders.unpaid.length
                      : 0;
                  return BpBottomNav(
                    currentIndex: _current.index,
                    onSelected: (index) => _select(AppTab.values[index]),
                    trailing: <BpNavItem>[
                      BpBottomNav.defaultTrailing[0].copyWith(
                        badgeCount: unpaid,
                      ),
                      BpBottomNav.defaultTrailing[1],
                    ],
                    rewardDot:
                        services.rewards.available &&
                        services.rewards.hasBadge(RewardsEntry.hub),
                  );
                },
              ),
            ),
          ),
          // Bagian tombol Hadiah yang menonjol di atas bilah berada di luar
          // batas bilah, jadi diberi area ketuk sendiri supaya ketukan tidak
          // jatuh ke isi tab di belakangnya.
          Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: _navLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              child: ExcludeSemantics(
                child: GestureDetector(
                  key: const ValueKey<String>('shell-reward-lift'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _select(AppTab.rewards),
                  child: const SizedBox(
                    width: BpSize.rewardButton,
                    height: BpSize.rewardLift,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu tab di dalam kerangka: tetap hidup saat tersembunyi, tanpa animasi
/// dan tanpa fokus, dengan pengendali gulir sendiri.
class _TabHost extends StatelessWidget {
  const _TabHost({
    required this.active,
    required this.fade,
    required this.controller,
    required this.child,
    super.key,
  });

  final bool active;
  final Animation<double> fade;
  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !active,
      child: TickerMode(
        enabled: active,
        child: ExcludeFocus(
          excluding: !active,
          child: FadeTransition(
            opacity: active ? fade : kAlwaysCompleteAnimation,
            child: PrimaryScrollController(
              controller: controller,
              automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- aksi bilah atas

/// Sakelar tema terang/gelap [K9]. Ikon berputar 180° saat berganti dan
/// pilihan disimpan lewat `AppScope.of(context).settings`.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.color});

  /// Warna ikon; bawaan mengikuti tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final reduce = BpMotion.reduced(context);
    return IconButton(
      tooltip: dark ? 'Ganti ke tema terang' : 'Ganti ke tema gelap',
      color: color,
      onPressed: () {
        services.haptics.selection();
        services.settings.toggleTheme(brightness);
      },
      icon: AnimatedRotation(
        turns: dark ? 0.5 : 0,
        duration: reduce ? Duration.zero : BpMotion.standard,
        curve: BpMotion.standardCurve,
        child: AnimatedSwitcher(
          duration: reduce ? Duration.zero : BpMotion.micro,
          child: Icon(
            dark ? LucideIcons.sun : LucideIcons.moon,
            key: ValueKey<bool>(dark),
          ),
        ),
      ),
    );
  }
}

/// Ikon keranjang berlencana jumlah barang; membuka `/keranjang`.
class CartButton extends StatelessWidget {
  const CartButton({super.key, this.color});

  /// Warna ikon; bawaan mengikuti tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.cart,
      builder: (context, _) => CartBadgeIcon(
        count: services.cart.count,
        color: color,
        onPressed: () => services.router.go(context, const CartRoute()),
      ),
    );
  }
}

/// Tombol "Masuk" untuk tamu [K10]; tidak tampil setelah masuk.
class LoginButton extends StatelessWidget {
  const LoginButton({super.key, this.next});

  /// Lokasi yang dibuka setelah berhasil masuk.
  final String? next;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.auth,
      builder: (context, _) {
        if (services.auth.isLoggedIn) return const SizedBox.shrink();
        return PillButton(
          label: 'Masuk',
          size: PillButtonSize.small,
          onPressed: () => services.router.go(context, LoginRoute(next: next)),
        );
      },
    );
  }
}

// ------------------------------------------------------ halaman pengganti tab

/// Isi sementara untuk tab yang fiturnya belum terdaftar di `AppRouter`.
///
/// Tetap punya bilah atas (sakelar tema, keranjang), ajakan masuk untuk tamu,
/// penjelasan apa yang akan tampil, dan satu aksi, supaya kerangka bisa
/// dijalankan sebelum semua fitur tersambung.
class TabPlaceholderPage extends StatelessWidget {
  const TabPlaceholderPage({required this.tab, super.key});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final services = AppScope.of(context);
    final spec = _PlaceholderSpec.of(tab, services);
    final home = tab == AppTab.home;
    const actions = <Widget>[ThemeToggleButton(), CartButton()];
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: home
          ? BpAppBar(
              showBack: false,
              titleWidget: Semantics(
                header: true,
                image: true,
                label: 'Bpedia',
                child: AssetPicture(
                  c.isDark
                      ? 'assets/images/logo_horizontal_reverse.webp'
                      : 'assets/images/logo_horizontal.webp',
                  width: 94,
                  height: 40,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  showSkeleton: false,
                ),
              ),
              actions: actions,
            )
          : BpAppBar(title: spec.barTitle, showBack: false, actions: actions),
      body: ListView(
        padding: const EdgeInsets.only(bottom: BpSpace.x6),
        children: <Widget>[
          if (home || tab == AppTab.account) const _GuestStrip(),
          Section(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.x6,
              BpSpace.x5,
              BpSpace.x6,
              BpSpace.x6,
            ),
            child: Column(
              children: <Widget>[
                _PoseStage(asset: spec.pose),
                const SizedBox(height: BpSpace.x4),
                const StatusChip(
                  label: 'Segera hadir',
                  tone: StatusTone.gold,
                  icon: Icon(LucideIcons.sparkles),
                ),
                const SizedBox(height: BpSpace.x3),
                Semantics(
                  header: true,
                  child: Text(
                    spec.headline,
                    textAlign: TextAlign.center,
                    style: BpText.titleL.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spec.message,
                  textAlign: TextAlign.center,
                  style: BpText.body.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Yang akan tampil di sini'),
            padding: const EdgeInsets.only(top: BpSpace.x1, bottom: BpSpace.x4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BpSpace.x3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final item in spec.upcoming)
                    Expanded(child: _UpcomingTile(item: item)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x2,
              BpSpace.screen,
              0,
            ),
            child: PillButton(
              label: spec.actionLabel,
              variant: PillButtonVariant.tonal,
              expand: true,
              onPressed: () => services.router.selectTab(spec.actionTab),
            ),
          ),
        ],
      ),
    );
  }
}

/// Strip tamu: sapaan singkat dan tombol Masuk [K10].
class _GuestStrip extends StatelessWidget {
  const _GuestStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.auth,
      builder: (context, _) {
        if (services.auth.isLoggedIn) return const SizedBox.shrink();
        return Section(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.screen,
            BpSpace.x3,
            BpSpace.screen,
            BpSpace.x3,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.brandTint,
              borderRadius: BpRadius.cardAll,
              border: Border.all(color: c.brandLine),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                children: <Widget>[
                  const AssetPicture(
                    'assets/bipy/bipy_wajah_senyum.webp',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    showSkeleton: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hai, Babes! Masuk untuk belanja dan kumpulkan Kelopak.',
                      style: BpText.bodyS.copyWith(
                        color: c.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: BpSpace.x2),
                  const LoginButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bipy di atas panggung pendar lembut.
class _PoseStage extends StatelessWidget {
  const _PoseStage({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return SizedBox(
      width: double.infinity,
      height: 196,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            bottom: 4,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    c.brandTint,
                    c.brandTint.withValues(alpha: 0),
                  ],
                  stops: const <double>[0.45, 1],
                ),
              ),
            ),
          ),
          BipyPose(asset, height: 176),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.item});

  final _Upcoming item;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final art = item.art;
    final glyph = item.glyph;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BpSpace.x1),
      child: Column(
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
            ),
            alignment: Alignment.center,
            child: art != null
                ? AssetPicture(
                    art,
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                    showSkeleton: false,
                  )
                : BrandIcon(
                    glyph ?? BrandGlyph.bag,
                    size: 30,
                    style: BrandIconStyle.color,
                  ),
          ),
          const SizedBox(height: BpSpace.x2),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BpText.caption.copyWith(
              color: c.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _Upcoming {
  const _Upcoming(this.label, {this.art, this.glyph})
    : assert(art != null || glyph != null);

  final String label;

  /// Ikon 3D (`assets/icons3d/*.webp`).
  final String? art;

  /// Ikon brand bila tidak ada ikon 3D yang cocok.
  final BrandGlyph? glyph;
}

@immutable
class _PlaceholderSpec {
  const _PlaceholderSpec({
    required this.barTitle,
    required this.headline,
    required this.message,
    required this.pose,
    required this.upcoming,
    this.actionLabel = 'Ke Beranda',
    this.actionTab = AppTab.home,
  });

  final String barTitle;
  final String headline;
  final String message;
  final String pose;
  final List<_Upcoming> upcoming;
  final String actionLabel;
  final AppTab actionTab;

  static _PlaceholderSpec of(AppTab tab, AppServices services) {
    switch (tab) {
      case AppTab.home:
        return const _PlaceholderSpec(
          barTitle: 'Beranda',
          headline: 'Beranda sedang disiapkan',
          message:
              'Banner Event Promo, Hot Item, dan rekomendasi produk akan '
              'tampil di sini.',
          pose: 'assets/bipy/bipy_pose_host.webp',
          upcoming: <_Upcoming>[
            _Upcoming('Event Promo', art: 'assets/icons3d/event.webp'),
            _Upcoming('Hot Item', art: 'assets/icons3d/hot.webp'),
            _Upcoming('Voucher', art: 'assets/icons3d/voucher.webp'),
          ],
          actionLabel: 'Lihat katalog',
          actionTab: AppTab.catalog,
        );
      case AppTab.catalog:
        final products = services.catalog.products.length;
        final categories = services.catalog.categories.length;
        return _PlaceholderSpec(
          barTitle: 'Katalog',
          headline: 'Katalog sedang disiapkan',
          message: products > 0 && categories > 0
              ? '$products produk asli Bpedia dari $categories kategori akan '
                    'tampil di sini, lengkap dengan cari dan filter.'
              : 'Produk asli Bpedia akan tampil di sini, lengkap dengan cari '
                    'dan filter.',
          pose: 'assets/bipy/bipy_pose_belanja.webp',
          upcoming: const <_Upcoming>[
            _Upcoming('Skincare', art: 'assets/icons3d/skincare.webp'),
            _Upcoming('Makeup', art: 'assets/icons3d/makeup.webp'),
            _Upcoming('Semua kategori', art: 'assets/icons3d/kategori.webp'),
          ],
        );
      case AppTab.rewards:
        return const _PlaceholderSpec(
          barTitle: 'Hadiah',
          headline: 'Zona Hadiah segera dibuka',
          message:
              'Kumpulkan Kelopak lewat tiga permainan Bipy, lalu pakai untuk '
              'potong harga saat checkout.',
          pose: 'assets/bipy/bipy_pose_lompat_bintang.webp',
          upcoming: <_Upcoming>[
            _Upcoming('Check-in Harian', art: 'assets/icons3d/checkin.webp'),
            _Upcoming('Roda Sabtu', art: 'assets/icons3d/roda.webp'),
            _Upcoming('Misi Belanja', art: 'assets/icons3d/misi.webp'),
          ],
        );
      case AppTab.orders:
        return const _PlaceholderSpec(
          barTitle: 'Transaksi',
          headline: 'Transaksi sedang disiapkan',
          message:
              'Pesanan yang kamu buat akan tampil di sini, lengkap dengan '
              'statusnya.',
          pose: 'assets/bipy/bipy_pose_semangat.webp',
          upcoming: <_Upcoming>[
            _Upcoming('Dikemas', glyph: BrandGlyph.bag),
            _Upcoming('Dikirim', glyph: BrandGlyph.ongkir),
            _Upcoming('Selesai', glyph: BrandGlyph.original),
          ],
        );
      case AppTab.account:
        return const _PlaceholderSpec(
          barTitle: 'Akun',
          headline: 'Akun sedang disiapkan',
          message:
              'Profil, buku alamat, saldo Kelopak, dan pengaturan akan '
              'tampil di sini.',
          pose: 'assets/bipy/bipy_menyapa.webp',
          upcoming: <_Upcoming>[
            _Upcoming('Saldo Kelopak', art: 'assets/icons3d/kelopak.webp'),
            _Upcoming('Voucher Saya', art: 'assets/icons3d/voucher.webp'),
            _Upcoming('Hadiah Saya', art: 'assets/icons3d/hadiah.webp'),
          ],
        );
    }
  }
}
