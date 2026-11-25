/// Pengaturan: tema terang/gelap/sistem, suara, musik, getar, kurangi gerak,
/// dan pengingat Roda Sabtu.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../services/reminders/reminder_service.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';

/// Halaman pengaturan.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    final c = context.bp;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(title: 'Pengaturan'),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: BpSpace.x6),
          children: <Widget>[
            Section(
              header: const SectionHeader(
                title: 'Tampilan',
                subtitle: 'Pilihan tersimpan di perangkat ini.',
              ),
              inset: true,
              child: ThemeModePicker(
                value: settings.themeMode,
                onChanged: (mode) {
                  services.haptics.selection();
                  settings.setThemeMode(mode);
                },
              ),
            ),
            Section(
              header: const SectionHeader(title: 'Suara dan getar'),
              padding: const EdgeInsets.only(bottom: BpSpace.x2),
              child: Column(
                children: <Widget>[
                  BpSwitchTile(
                    title: 'Efek suara',
                    subtitle: 'Bunyi klaim, putar roda, dan tombol.',
                    leading: const Icon(LucideIcons.volume2),
                    value: settings.soundOn,
                    onChanged: settings.setSoundOn,
                  ),
                  BpSwitchTile(
                    title: 'Musik latar',
                    subtitle: 'Jingle Bipy di Zona Hadiah dan Roda Sabtu.',
                    leading: const Icon(LucideIcons.music),
                    value: settings.musicOn,
                    onChanged: settings.setMusicOn,
                  ),
                  BpSwitchTile(
                    title: 'Getar',
                    subtitle: 'Getar halus saat menang dan menekan tombol.',
                    leading: const Icon(LucideIcons.vibrate),
                    value: settings.hapticsOn,
                    onChanged: (value) {
                      settings.setHapticsOn(value);
                      if (value) services.haptics.light();
                    },
                  ),
                ],
              ),
            ),
            Section(
              header: const SectionHeader(title: 'Gerak'),
              padding: const EdgeInsets.only(bottom: BpSpace.x2),
              child: BpSwitchTile(
                title: 'Kurangi gerak',
                subtitle:
                    'Animasi diganti pudar singkat, Bipy diam, roda langsung '
                    'ke hasil.',
                leading: const Icon(LucideIcons.wind),
                value: settings.reduceMotion,
                onChanged: settings.setReduceMotion,
              ),
            ),
            Section(
              header: const SectionHeader(title: 'Pengingat'),
              padding: const EdgeInsets.only(bottom: BpSpace.x2),
              child: WheelReminderTile(services: services),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilihan tema: tiga kartu pratinjau mini.
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <(ThemeMode, String)>[
      (ThemeMode.light, 'Terang'),
      (ThemeMode.dark, 'Gelap'),
      (ThemeMode.system, 'Ikuti sistem'),
    ];
    final large = MediaQuery.textScalerOf(context).scale(10) > 15;
    final tiles = <Widget>[
      for (final (mode, label) in options)
        _ThemeOption(
          mode: mode,
          label: label,
          selected: value == mode,
          onTap: () => onChanged(mode),
        ),
    ];
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < tiles.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: BpSpace.x2),
            tiles[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = 0; i < tiles.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: BpSpace.x2),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      onTap: onTap,
      selected: selected,
      semanticLabel: 'Tema $label',
      focusRadius: BpRadius.cardAll,
      builder: (context, states) => AnimatedContainer(
        duration: BpMotion.micro,
        padding: const EdgeInsets.all(BpSpace.x2),
        decoration: BoxDecoration(
          color: selected ? c.brandTint : c.surface,
          borderRadius: BpRadius.cardAll,
          border: Border.all(
            color: selected ? c.brand : c.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 64,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BpRadius.tileAll,
                child: switch (mode) {
                  ThemeMode.light => const _MiniPreview(colors: BpColors.light),
                  ThemeMode.dark => const _MiniPreview(colors: BpColors.dark),
                  ThemeMode.system => const Row(
                    children: <Widget>[
                      Expanded(child: _MiniPreview(colors: BpColors.light)),
                      Expanded(child: _MiniPreview(colors: BpColors.dark)),
                    ],
                  ),
                },
              ),
            ),
            const SizedBox(height: BpSpace.x2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  selected ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: 16,
                  color: selected ? c.brand : c.textFaint,
                ),
                const SizedBox(width: BpSpace.x1),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: BpText.bodyS.copyWith(
                      color: selected ? c.brandStrong : c.text,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Layar mini: bilah atas, pil cari, dua kartu, dengan warna tema [colors].
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.colors});

  final BpColors colors;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        color: colors.canvas,
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 9,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BpRadius.pillAll,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Row(
                children: <Widget>[
                  for (var i = 0; i < 2; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.line),
                        ),
                        padding: const EdgeInsets.all(3),
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          width: 14,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.brand,
                            borderRadius: BpRadius.pillAll,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sakelar "Ingatkan Roda Sabtu" (Sabtu 09.00 WIB). Status awal dibaca
/// asinkron dari layanan pengingat.
class WheelReminderTile extends StatefulWidget {
  const WheelReminderTile({super.key, required this.services});

  final AppServices services;

  @override
  State<WheelReminderTile> createState() => _WheelReminderTileState();
}

class _WheelReminderTileState extends State<WheelReminderTile> {
  bool? _scheduled;
  bool _busy = false;

  ReminderService get _reminders => widget.services.reminders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_reminders.isSupported) {
      setState(() => _scheduled = false);
      return;
    }
    final scheduled = await _reminders.isScheduled(wheelReminder.id);
    if (mounted) setState(() => _scheduled = scheduled);
  }

  Future<void> _toggle(bool on) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (on) {
      final result = await _reminders.scheduleWeekly(wheelReminder);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scheduled = result == ReminderResult.scheduled;
      });
      showAppSnack(context, result.message);
    } else {
      await _reminders.cancel(wheelReminder.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scheduled = false;
      });
      showAppSnack(context, 'Pengingat Roda Sabtu dimatikan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduled = _scheduled;
    if (scheduled == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: BpSpace.screen,
          vertical: BpSpace.x3,
        ),
        child: Row(
          children: <Widget>[
            Skeleton(width: 24, height: 24, radius: 6),
            SizedBox(width: BpSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Skeleton.line(width: 160),
                  SizedBox(height: 6),
                  Skeleton.line(width: 220, height: 10),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final supported = _reminders.isSupported;
    return BpSwitchTile(
      title: 'Ingatkan Roda Sabtu',
      subtitle: supported
          ? 'Notifikasi tiap Sabtu pukul 09.00 WIB.'
          : 'Tersedia di aplikasi Android dan iOS.',
      leading: const Icon(LucideIcons.bellRing),
      value: scheduled,
      onChanged: supported && !_busy ? _toggle : null,
    );
  }
}
