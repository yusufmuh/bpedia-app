/// Tab Akun (SPEC §4.8): kepala profil atau ajakan masuk, dompet Kelopak,
/// ringkasan pesanan per status, dan menu berkelompok.
library;

import 'package:flutter/material.dart';
import 'package:kelopak_hub/kit.dart' show BipySprite, BipySprites;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/shell.dart' show CartButton;
import '../../config/app_config.dart';
import '../../data/orders/order.dart';
import '../../data/rewards/rewards_gateway.dart';
import '../../design/design.dart';
import 'account_ui.dart';

/// ID event Komunitas WhatsApp di `assets/promo/promo.json`.
const String communityEventId = 'komunitas-whatsapp';

/// Isi tab Akun.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: BpAppBar(
        title: 'Akun',
        showBack: false,
        actions: <Widget>[
          ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              services.inbox,
              services.auth,
            ]),
            builder: (context, _) => BadgeIcon(
              icon: const BrandIcon(BrandGlyph.notif),
              label: 'Notifikasi',
              count: services.auth.isLoggedIn ? services.inbox.unreadCount : 0,
              onPressed: () => services.router.go(context, const InboxRoute()),
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(LucideIcons.settings),
            onPressed: () => services.router.go(context, const SettingsRoute()),
          ),
          const CartButton(),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          services.auth,
          services.orders,
          services.rewards,
          services.inbox,
          services.addresses,
          services.wishlist,
          services.settings,
        ]),
        builder: (context, _) => _AccountBody(services: services),
      ),
    );
  }
}

class _AccountBody extends StatelessWidget {
  const _AccountBody({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final router = services.router;
    final auth = services.auth;
    final loggedIn = auth.isLoggedIn;
    final rewards = services.rewards;
    void go(AppRoute route) => router.go(context, route);

    return ListView(
      padding: const EdgeInsets.only(bottom: BpSpace.x6),
      children: <Widget>[
        if (loggedIn)
          _ProfileHeader(services: services)
        else
          const _GuestHeader(),
        _OrderSummary(services: services),
        MenuGroup(
          title: 'Hadiah dan belanja',
          entries: <MenuEntry>[
            if (rewards.available) ...<MenuEntry>[
              MenuEntry(
                label: 'Zona Hadiah',
                helper: 'Check-in, Roda Sabtu, Misi',
                icon: const BrandIcon(BrandGlyph.reward, size: 20),
                showDot: rewards.hasBadge(RewardsEntry.hub),
                onTap: () => go(const RewardsRoute()),
              ),
              MenuEntry(
                label: 'Riwayat Kelopak',
                icon: const Icon(LucideIcons.history),
                value: loggedIn ? '${rewards.kelopakBalance} Kelopak' : null,
                onTap: () => go(const LedgerRoute()),
              ),
              MenuEntry(
                label: 'Voucher saya',
                icon: const BrandIcon(BrandGlyph.voucher, size: 20),
                value: loggedIn
                    ? _countLabel(rewards.voucherCount, 'voucher')
                    : null,
                onTap: () => go(const VouchersRoute()),
              ),
              MenuEntry(
                label: 'Hadiahku',
                helper: 'Produk gratis untukmu',
                icon: const Icon(LucideIcons.gift),
                value: loggedIn && rewards.pendingGifts.isNotEmpty
                    ? '${rewards.pendingGifts.length} menunggu'
                    : null,
                onTap: () => go(const MyGiftsRoute()),
              ),
            ],
            MenuEntry(
              label: 'Wishlist',
              icon: const BrandIcon(BrandGlyph.wishlist, size: 20),
              value: _countLabel(services.wishlist.count, 'produk'),
              onTap: () => go(const WishlistRoute()),
            ),
          ],
        ),
        MenuGroup(
          title: 'Akun saya',
          entries: <MenuEntry>[
            if (loggedIn)
              MenuEntry(
                label: 'Profil',
                icon: const BrandIcon(BrandGlyph.akun, size: 20),
                value: auth.profile?.name,
                onTap: () => go(const ProfileRoute()),
              ),
            MenuEntry(
              label: 'Alamat',
              icon: const Icon(LucideIcons.mapPin),
              value: loggedIn
                  ? (services.addresses.isEmpty
                        ? 'Belum ada'
                        : '${services.addresses.addresses.length} alamat')
                  : null,
              onTap: () => go(const AddressesRoute()),
            ),
            if (loggedIn)
              MenuEntry(
                label: 'Ubah kata sandi',
                icon: const Icon(LucideIcons.lock),
                onTap: () => go(const ChangePasswordRoute()),
              ),
            MenuEntry(
              label: 'Notifikasi',
              icon: const BrandIcon(BrandGlyph.notif, size: 20),
              badgeCount: loggedIn ? services.inbox.unreadCount : 0,
              onTap: () => go(const InboxRoute()),
            ),
            MenuEntry(
              label: 'Pengaturan',
              helper: 'Tema, suara, getar, pengingat',
              icon: const Icon(LucideIcons.settings),
              value: themeModeLabel(services.settings.themeMode),
              onTap: () => go(const SettingsRoute()),
            ),
          ],
        ),
        MenuGroup(
          title: 'Bantuan dan info',
          entries: <MenuEntry>[
            MenuEntry(
              label: 'Bantuan Bpedia Care',
              helper: 'Chat lewat WhatsApp',
              icon: const BrandIcon(BrandGlyph.chat, size: 20),
              onTap: () => go(const HelpRoute()),
            ),
            MenuEntry(
              label: 'Komunitas WhatsApp',
              icon: const Icon(LucideIcons.usersRound),
              onTap: () => go(const EventRoute(communityEventId)),
            ),
            MenuEntry(
              label: 'Tentang Bpedia',
              icon: const Icon(LucideIcons.info),
              value: 'Versi ${AppConfig.appVersion}',
              onTap: () => go(const AboutRoute()),
            ),
            MenuEntry(
              label: 'Syarat & Ketentuan',
              icon: const Icon(LucideIcons.fileText),
              onTap: () => go(const TermsRoute()),
            ),
            MenuEntry(
              label: 'Kebijakan Privasi',
              icon: const Icon(LucideIcons.shieldCheck),
              onTap: () => go(const PrivacyRoute()),
            ),
          ],
        ),
        MenuGroup(
          entries: <MenuEntry>[
            MenuEntry(
              label: 'Mode Demo',
              helper: 'Geser hari, isi saldo, log analitik',
              icon: const Icon(LucideIcons.flaskConical),
              tag: const StatusChip(label: 'Demo', tone: StatusTone.gold),
              onTap: () => go(const DemoRoute()),
            ),
          ],
        ),
        if (loggedIn)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x2,
              BpSpace.screen,
              0,
            ),
            child: PillButton(
              label: 'Keluar',
              variant: PillButtonVariant.neutral,
              icon: Icon(LucideIcons.logOut, color: c.danger),
              expand: true,
              onPressed: () => _signOut(context),
            ),
          ),
        const _VersionFooter(),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Keluar dari akun?',
      message:
          'Keranjang tetap tersimpan di perangkat ini. Masuk lagi kapan saja '
          'untuk lanjut kumpulkan Kelopak.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await services.auth.signOut();
    if (context.mounted) {
      showAppSnack(context, 'Kamu sudah keluar. Sampai jumpa, Babes!');
    }
  }

  static String _countLabel(int count, String noun) =>
      count == 0 ? 'Belum ada' : '$count $noun';
}

/// Nama tampil [ThemeMode].
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'Terang',
  ThemeMode.dark => 'Gelap',
  ThemeMode.system => 'Ikuti sistem',
};

/// Latar kepala Akun: pendar `brandTint` lembut di atas `surface`.
BoxDecoration _headerDecoration(BpColors c) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[c.brandTint, c.surface],
    stops: const <double>[0, 0.85],
  ),
);

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final profile = services.auth.profile!;
    final rewards = services.rewards;
    final router = services.router;
    return Padding(
      padding: const EdgeInsets.only(bottom: BpSpace.sectionGap),
      child: DecoratedBox(
        decoration: _headerDecoration(c),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.screen,
            BpSpace.x4,
            BpSpace.screen,
            BpSpace.x4,
          ),
          child: Column(
            children: <Widget>[
              BpTappable(
                onTap: () => router.go(context, const ProfileRoute()),
                semanticLabel:
                    '${profile.name}, ${profile.contactLabel}. Ubah profil',
                focusRadius: BpRadius.cardAll,
                pressScale: false,
                alignment: Alignment.centerLeft,
                builder: (context, states) => Row(
                  children: <Widget>[
                    InitialsAvatar(initials: profile.initials, size: 60),
                    const SizedBox(width: BpSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            profile.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BpText.titleL.copyWith(color: c.text),
                          ),
                          if (profile.contactLabel.isNotEmpty)
                            Text(
                              profile.contactLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BpText.bodyS.copyWith(color: c.textMuted),
                            ),
                          const SizedBox(height: BpSpace.x1),
                          Wrap(
                            spacing: BpSpace.x1,
                            runSpacing: BpSpace.x1,
                            children: <Widget>[
                              if (profile.viaGoogle)
                                const StatusChip(label: 'Google (demo)')
                              else
                                const StatusChip(label: 'Akun demo'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Ubah',
                      style: BpText.bodyS.copyWith(
                        color: c.brandStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: BpSize.iconDense,
                      color: c.brandStrong,
                    ),
                  ],
                ),
              ),
              if (rewards.available) ...<Widget>[
                const SizedBox(height: BpSpace.x4),
                _WalletPanel(services: services),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel dompet tiga sel: Kelopak, voucher, hadiah menunggu.
class _WalletPanel extends StatelessWidget {
  const _WalletPanel({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final rewards = services.rewards;
    final router = services.router;
    final balance = rewards.kelopakBalance;
    final vouchers = rewards.voucherCount;
    final gifts = rewards.pendingGifts.length;
    final cells = <Widget>[
      _WalletCell(
        art: 'assets/icons3d/kelopak.webp',
        value: '$balance',
        unit: 'Kelopak',
        caption: balance == 0
            ? 'Kumpulkan Kelopak'
            : formatRupiah(balance * 100),
        onTap: () => router.go(context, const LedgerRoute()),
      ),
      _WalletCell(
        art: 'assets/icons3d/voucher.webp',
        value: '$vouchers',
        unit: 'Voucher',
        caption: vouchers == 0 ? 'Cari voucher' : 'siap dipakai',
        onTap: () => router.go(context, const VouchersRoute()),
      ),
      _WalletCell(
        art: 'assets/icons3d/hadiah.webp',
        value: '$gifts',
        unit: 'Hadiah',
        caption: gifts == 0 ? 'Main dan menang' : 'ikut pesanan',
        highlight: gifts > 0,
        onTap: () => router.go(context, const MyGiftsRoute()),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BpRadius.cardAll,
        border: Border.all(color: c.line),
        boxShadow: BpShadows.floating(c),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var i = 0; i < cells.length; i++) ...<Widget>[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: BpSpace.x3,
                  endIndent: BpSpace.x3,
                  color: c.line,
                ),
              Expanded(child: cells[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _WalletCell extends StatelessWidget {
  const _WalletCell({
    required this.art,
    required this.value,
    required this.unit,
    required this.caption,
    required this.onTap,
    this.highlight = false,
  });

  final String art;
  final String value;
  final String unit;
  final String caption;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      onTap: onTap,
      semanticLabel: '$value $unit, $caption',
      focusRadius: BpRadius.cardAll,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.x2,
          vertical: BpSpace.x3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AssetPicture(
              art,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              cacheWidth: 96,
              showSkeleton: false,
            ),
            const SizedBox(height: BpSpace.x1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: value,
                  style: BpText.title.copyWith(
                    color: highlight ? c.brandStrong : c.text,
                    fontFeatures: BpText.tabular,
                  ),
                  children: <InlineSpan>[
                    TextSpan(
                      text: ' $unit',
                      style: BpText.caption.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
                maxLines: 1,
              ),
            ),
            Text(
              caption,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: BpText.caption.copyWith(
                color: highlight ? c.brandStrong : c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final router = AppScope.of(context).router;
    return Padding(
      padding: const EdgeInsets.only(bottom: BpSpace.sectionGap),
      child: DecoratedBox(
        decoration: _headerDecoration(c),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.screen,
            BpSpace.x3,
            BpSpace.screen,
            BpSpace.x4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const BipySprite(
                BipySprites.wave,
                height: 112,
                semanticLabel: 'Bipy menyapa',
              ),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        'Hai, Babes!',
                        style: BpText.titleL.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Masuk untuk pantau pesanan, simpan alamat, dan '
                      'kumpulkan Kelopak.',
                      style: BpText.bodyS.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: BpSpace.x3),
                    Wrap(
                      spacing: BpSpace.x2,
                      runSpacing: BpSpace.x2,
                      children: <Widget>[
                        PillButton(
                          label: 'Masuk',
                          size: PillButtonSize.small,
                          onPressed: () =>
                              router.go(context, const LoginRoute()),
                        ),
                        PillButton(
                          label: 'Daftar',
                          variant: PillButtonVariant.outline,
                          size: PillButtonSize.small,
                          onPressed: () =>
                              router.go(context, const RegisterRoute()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ringkasan pesanan: empat status berlencana jumlah.
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final orders = services.orders;
    final router = services.router;
    final loggedIn = services.auth.isLoggedIn;
    final tiles = <(OrderStatus, String, IconData)>[
      (OrderStatus.awaitingPayment, 'Belum bayar', LucideIcons.wallet),
      (OrderStatus.packing, 'Dikemas', LucideIcons.package),
      (OrderStatus.shipped, 'Dikirim', LucideIcons.truck),
      (OrderStatus.completed, 'Selesai', LucideIcons.packageCheck),
    ];
    return Section(
      header: SectionHeader(
        title: 'Pesanan saya',
        onAction: () => router.go(context, const OrdersRoute()),
      ),
      padding: const EdgeInsets.only(top: BpSpace.x1, bottom: BpSpace.x3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BpSpace.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final (status, label, icon) in tiles)
              Expanded(
                child: _OrderStatusTile(
                  label: label,
                  icon: icon,
                  count: loggedIn && status.isActive
                      ? orders.countOf(status)
                      : 0,
                  onTap: () =>
                      router.go(context, OrdersRoute(status: status.param)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusTile extends StatelessWidget {
  const _OrderStatusTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      onTap: onTap,
      semanticLabel: count > 0 ? '$label, $count pesanan' : label,
      focusRadius: BpRadius.cardAll,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(vertical: BpSpace.x2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 40,
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(icon, size: 26, color: c.text),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -2,
                      child: CountBadge(count: count),
                    ),
                ],
              ),
            ),
            const SizedBox(height: BpSpace.x1),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: BpText.caption.copyWith(color: c.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Padding(
      padding: const EdgeInsets.only(top: BpSpace.x4),
      child: Column(
        children: <Widget>[
          AssetPicture(
            c.isDark
                ? 'assets/images/logo_horizontal_reverse.webp'
                : 'assets/images/logo_horizontal.webp',
            width: 80,
            height: 28,
            fit: BoxFit.contain,
            showSkeleton: false,
            semanticLabel: 'Bpedia',
          ),
          const SizedBox(height: BpSpace.x1),
          Text(
            '${AppConfig.appName} ${AppConfig.appVersion} '
            '(${AppConfig.buildNumber})',
            style: BpText.caption.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
