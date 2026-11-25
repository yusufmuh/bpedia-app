/// Mode Demo (SPEC §4.8): geser hari WIB, akun contoh, isi saldo Kelopak
/// lewat gateway hadiah, App Flyer, deep link tiruan, log analitik dan status
/// AppsFlyer, atur ulang data, galeri desain, dan info build.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../config/app_config.dart';
import '../../data/storage/app_document.dart';
import '../../data/wib_dates.dart';
import '../../design/design.dart';
import '../../services/analytics/analytics.dart';
import '../account/account_ui.dart';
import 'demo_flyer.dart';
import 'demo_rewards_tools.dart';

/// Deep link contoh untuk uji OneLink (`deep_link_value`).
const List<(String, String)> demoDeepLinks = <(String, String)>[
  ('Roda Sabtu', 'hadiah/roda'),
  ('Produk', 'produk/P39A06S01000021'),
  ('Event Black Friday', 'event/black-friday'),
  ('Keranjang', 'keranjang'),
];

/// Jumlah Kelopak pada tombol isi saldo.
const List<int> demoGrantAmounts = <int>[10, 100, 1000];

/// Angka dengan titik ribuan: `1.000`.
String formatThousands(int value) => formatRupiah(value).replaceFirst('Rp', '');

/// Halaman Mode Demo.
class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(title: 'Mode Demo'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: BpSpace.x6),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x3,
              BpSpace.screen,
              BpSpace.x3,
            ),
            child: NoteBox(
              tone: StatusTone.gold,
              icon: LucideIcons.flaskConical,
              title: 'Khusus uji',
              message:
                  'Alat di halaman ini hanya untuk demo. Nilai kampanye seperti '
                  'peluang roda, ongkir, dan masa berlaku voucher adalah contoh '
                  '(demo).',
            ),
          ),
          _ClockSection(services: services),
          _AccountSection(services: services),
          _RewardsSection(services: services),
          _PromoSection(services: services),
          _AnalyticsSection(services: services),
          _DataSection(services: services),
          _BuildSection(services: services),
        ],
      ),
    );
  }
}

class _ClockSection extends StatelessWidget {
  const _ClockSection({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final clock = services.demoClock;
    return ListenableBuilder(
      listenable: clock,
      builder: (context, _) {
        final offset = clock.offsetDays;
        void advance(int days) {
          clock.advanceDays(days);
          services.haptics.selection();
          showAppSnack(context, 'Hari ini menjadi ${clock.todayLabel}.');
        }

        return Section(
          header: const SectionHeader(
            title: 'Tanggal WIB',
            subtitle: 'Uji Sabtu untuk roda dan streak check-in.',
          ),
          inset: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(BpSpace.card),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BpRadius.cardAll,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(LucideIcons.calendarDays, color: c.brand),
                    const SizedBox(width: BpSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            clock.todayLabel,
                            key: const ValueKey<String>('demo-today'),
                            style: BpText.title.copyWith(color: c.text),
                          ),
                          Text(
                            offset == 0
                                ? 'Tanggal nyata'
                                : 'Digeser $offset hari dari tanggal nyata',
                            style: BpText.caption.copyWith(color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (offset > 0)
                      StatusChip(label: '+$offset hari', tone: StatusTone.gold),
                  ],
                ),
              ),
              const SizedBox(height: BpSpace.x3),
              Wrap(
                spacing: BpSpace.x2,
                runSpacing: BpSpace.x2,
                children: <Widget>[
                  PillButton(
                    label: '+1 hari',
                    variant: PillButtonVariant.tonal,
                    size: PillButtonSize.small,
                    onPressed: () => advance(1),
                  ),
                  PillButton(
                    label: '+7 hari',
                    variant: PillButtonVariant.tonal,
                    size: PillButtonSize.small,
                    onPressed: () => advance(7),
                  ),
                  PillButton(
                    label: 'Ke Sabtu berikutnya',
                    variant: PillButtonVariant.tonal,
                    size: PillButtonSize.small,
                    onPressed: () {
                      clock.jumpToNextSaturday();
                      services.haptics.selection();
                      showAppSnack(
                        context,
                        'Hari ini menjadi ${clock.todayLabel}.',
                      );
                    },
                  ),
                  PillButton(
                    label: 'Kembali ke hari ini',
                    variant: PillButtonVariant.neutral,
                    size: PillButtonSize.small,
                    onPressed: offset == 0
                        ? null
                        : () {
                            clock.reset();
                            showAppSnack(context, 'Kembali ke tanggal nyata.');
                          },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return ListenableBuilder(
      listenable: services.auth,
      builder: (context, _) {
        final profile = services.auth.profile;
        return Section(
          header: const SectionHeader(title: 'Akun'),
          inset: true,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  profile == null
                      ? 'Sedang sebagai tamu.'
                      : 'Masuk sebagai ${profile.name} '
                            '(${profile.contactLabel}).',
                  style: BpText.body.copyWith(color: c.text),
                ),
              ),
              const SizedBox(width: BpSpace.x2),
              if (profile == null)
                PillButton(
                  label: 'Masuk akun demo',
                  size: PillButtonSize.small,
                  onPressed: () {
                    services.signInAsDemo();
                    showAppSnack(context, 'Masuk sebagai akun demo.');
                  },
                )
              else
                PillButton(
                  label: 'Keluar',
                  variant: PillButtonVariant.neutral,
                  size: PillButtonSize.small,
                  onPressed: () async {
                    await services.auth.signOut();
                    if (context.mounted) {
                      showAppSnack(context, 'Kamu sudah keluar.');
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardsSection extends StatefulWidget {
  const _RewardsSection({required this.services});

  final AppServices services;

  @override
  State<_RewardsSection> createState() => _RewardsSectionState();
}

class _RewardsSectionState extends State<_RewardsSection> {
  String? _running;

  Future<void> _run(String id, Future<String?> Function() action) async {
    if (_running != null) return;
    setState(() => _running = id);
    String? message;
    try {
      message = await action();
    } on Object catch (error) {
      message = 'Aksi gagal: $error';
    }
    if (!mounted) return;
    setState(() => _running = null);
    if (message != null) showAppSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    final rewards = services.rewards;
    final c = context.bp;
    final tools = switch (rewards) {
      final DemoRewardsTools demoTools => demoTools,
      _ => null,
    };
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[rewards, services.auth]),
      builder: (context, _) {
        if (tools == null) {
          return const Section(
            header: SectionHeader(title: 'Kelopak'),
            inset: true,
            child: NoteBox(
              icon: LucideIcons.plugZap,
              message:
                  'Zona Hadiah belum tersambung di build ini, jadi saldo dan '
                  'hasil roda tidak bisa diatur dari sini.',
            ),
          );
        }
        final loggedIn = services.auth.isLoggedIn;
        return Section(
          header: SectionHeader(
            title: 'Kelopak',
            subtitle: loggedIn
                ? 'Saldo ${rewards.kelopakBalance} Kelopak · '
                      '${formatRupiah(rewards.kelopakBalance * 100)}'
                : 'Masuk dulu untuk mengisi saldo.',
          ),
          inset: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: BpSpace.x2,
                runSpacing: BpSpace.x2,
                children: <Widget>[
                  for (final amount in demoGrantAmounts)
                    PillButton(
                      key: ValueKey<String>('demo-grant-$amount'),
                      label: '+${formatThousands(amount)} Kelopak',
                      variant: PillButtonVariant.tonal,
                      size: PillButtonSize.small,
                      busy: _running == 'grant-$amount',
                      onPressed: loggedIn
                          ? () => _run('grant-$amount', () async {
                              final ok = await tools.grantKelopak(amount);
                              return ok
                                  ? '${formatThousands(amount)} Kelopak ditambahkan.'
                                  : 'Saldo belum bisa diisi.';
                            })
                          : null,
                    ),
                ],
              ),
              for (final action in tools.demoActions) ...<Widget>[
                const SizedBox(height: BpSpace.x3),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            action.label,
                            style: BpText.subtitle.copyWith(color: c.text),
                          ),
                          if (action.description case final String text)
                            Text(
                              text,
                              style: BpText.caption.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: BpSpace.x2),
                    PillButton(
                      key: ValueKey<String>('demo-action-${action.id}'),
                      label: 'Jalankan',
                      variant: PillButtonVariant.neutral,
                      size: PillButtonSize.small,
                      busy: _running == action.id,
                      onPressed: () => _run(action.id, action.run),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PromoSection extends StatelessWidget {
  const _PromoSection({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final flyer =
        services.promo.activeFlyer ??
        (services.promo.flyers.isEmpty ? null : services.promo.flyers.first);
    return Section(
      header: const SectionHeader(
        title: 'Promo dan tautan',
        subtitle: 'App Flyer dan deep link OneLink.',
      ),
      inset: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PillButton(
            label: 'Tampilkan App Flyer',
            variant: PillButtonVariant.tonal,
            icon: const Icon(LucideIcons.image),
            onPressed: flyer == null
                ? null
                : () => showDemoFlyer(context, flyer),
          ),
          if (flyer == null) ...<Widget>[
            const SizedBox(height: BpSpace.x1),
            Text(
              'Tidak ada flyer di promo.json.',
              style: BpText.caption.copyWith(color: c.textMuted),
            ),
          ],
          const SizedBox(height: BpSpace.x4),
          Text(
            'Simulasikan deep link',
            style: BpText.subtitle.copyWith(color: c.text),
          ),
          const SizedBox(height: BpSpace.x2),
          Wrap(
            spacing: BpSpace.x2,
            runSpacing: BpSpace.x2,
            children: <Widget>[
              for (final (label, value) in demoDeepLinks)
                BpChip(
                  label: label,
                  leading: const Icon(LucideIcons.link2, size: 16),
                  onTap: () => services.analyticsLog.simulateDeepLink(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({required this.services});

  /// Event terbaru yang ditampilkan.
  static const int visibleEvents = 20;

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final log = services.analyticsLog;
    final (
      String status,
      StatusTone tone,
      String detail,
    ) = services.appsFlyerEnabled
        ? (
            'AppsFlyer aktif',
            StatusTone.success,
            'Event dikirim ke AppsFlyer dan dicatat lokal.',
          )
        : services.appsFlyerConfigured
        ? (
            'AppsFlyer menunggu',
            StatusTone.warning,
            'Kunci tersedia; SDK belum selesai dimulai.',
          )
        : (
            'AppsFlyer nonaktif',
            StatusTone.neutral,
            'Build ini tanpa AF_DEV_KEY atau bukan Android/iOS. Event hanya '
                'dicatat di perangkat.',
          );
    return ListenableBuilder(
      listenable: log,
      builder: (context, _) {
        final records = log.records.take(visibleEvents).toList();
        return Section(
          header: SectionHeader(
            title: 'Analitik',
            subtitle: '${log.records.length} event tercatat',
            trailing: log.records.isEmpty
                ? null
                : PillButton(
                    label: 'Kosongkan',
                    variant: PillButtonVariant.text,
                    size: PillButtonSize.small,
                    onPressed: log.clear,
                  ),
          ),
          padding: const EdgeInsets.only(bottom: BpSpace.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    StatusChip(label: status, tone: tone),
                    const SizedBox(height: BpSpace.x1),
                    Text(
                      detail,
                      style: BpText.caption.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BpSpace.x3),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.screen,
                  ),
                  child: Text(
                    'Belum ada event. Coba cari produk atau tambah ke '
                    'keranjang, lalu kembali ke sini.',
                    style: BpText.bodyS.copyWith(color: c.textMuted),
                  ),
                )
              else
                for (final record in records) _EventRow(record: record),
            ],
          ),
        );
      },
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.record});

  final AnalyticsRecord record;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final params = record.values.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' · ');
    return Container(
      margin: const EdgeInsets.fromLTRB(BpSpace.screen, 0, BpSpace.screen, 6),
      padding: const EdgeInsets.symmetric(
        horizontal: BpSpace.x3,
        vertical: BpSpace.x2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BpRadius.tileAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  record.name,
                  style: BpText.bodyS.copyWith(
                    color: c.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${wibClockLabel(record.at)} WIB',
                style: BpText.caption.copyWith(color: c.textMuted),
              ),
            ],
          ),
          if (params.isNotEmpty)
            Text(
              params,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: BpText.caption.copyWith(color: c.textMuted),
            ),
        ],
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection({required this.services});

  final AppServices services;

  Future<void> _reset(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Atur ulang semua data?',
      message:
          'Akun, keranjang, alamat, pesanan, notifikasi, pengaturan, dan data '
          'Kelopak di perangkat ini kembali ke awal. Tindakan ini tidak bisa '
          'dibatalkan.',
      confirmLabel: 'Atur ulang',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    if (services.rewards case final DemoRewardsTools tools) {
      await tools.resetRewards();
    }
    if (!context.mounted) return;
    showAppSnack(context, 'Semua data demo sudah diatur ulang.');
    await services.resetData();
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      header: const SectionHeader(title: 'Data dan desain'),
      padding: const EdgeInsets.only(bottom: BpSpace.x2),
      child: Column(
        children: <Widget>[
          InfoRow(
            label: 'Galeri komponen desain',
            helper: 'Token, tombol, kartu, dan widget bersama',
            leading: const Icon(LucideIcons.palette),
            onTap: () => services.router.go(context, const GalleryRoute()),
          ),
          InfoRow(
            label: 'Atur ulang semua data',
            helper: 'Kembali seperti baru dipasang',
            leading: Icon(LucideIcons.rotateCcw, color: context.bp.danger),
            valueColor: context.bp.danger,
            onTap: () => _reset(context),
          ),
        ],
      ),
    );
  }
}

class _BuildSection extends StatelessWidget {
  const _BuildSection({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    const mode = kReleaseMode
        ? 'Rilis'
        : kProfileMode
        ? 'Profil'
        : 'Debug';
    final platform = kIsWeb
        ? 'Web'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'Android',
            TargetPlatform.iOS => 'iOS',
            TargetPlatform.macOS => 'macOS',
            TargetPlatform.windows => 'Windows',
            TargetPlatform.linux => 'Linux',
            TargetPlatform.fuchsia => 'Fuchsia',
          };
    final origin = switch (services.origin) {
      DocumentOrigin.fresh => 'Baru dipasang',
      DocumentOrigin.loaded => 'Dimuat dari perangkat',
      DocumentOrigin.migratedV2 => 'Dibawa dari v2',
      DocumentOrigin.corrupt => 'Rusak, dimulai bersih',
    };
    return Section(
      header: const SectionHeader(title: 'Info build'),
      padding: const EdgeInsets.only(bottom: BpSpace.x2),
      child: Column(
        children: <Widget>[
          const InfoRow(label: 'Versi', value: AppConfig.appVersion),
          const InfoRow(
            label: 'Nomor build',
            value: '${AppConfig.buildNumber}',
          ),
          const InfoRow(label: 'ID aplikasi', value: AppConfig.applicationId),
          InfoRow(label: 'Platform', value: platform),
          const InfoRow(label: 'Mode', value: mode),
          InfoRow(label: 'Data', value: origin),
          InfoRow(
            label: 'Pengingat lokal',
            value: services.reminders.isSupported
                ? 'Didukung'
                : 'Tidak didukung',
          ),
        ],
      ),
    );
  }
}
