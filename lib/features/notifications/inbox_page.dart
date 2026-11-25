/// Kotak masuk notifikasi (FITUR #20): saring per jenis, belum dibaca
/// bertitik, tandai semua dibaca, geser untuk hapus, ketuk membuka rute.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/inbox/inbox_repository.dart';
import '../../data/wib_dates.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';

/// Halaman kotak masuk.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  InboxKind? _filter;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final inbox = services.inbox;
    final c = context.bp;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[inbox, services.auth]),
      builder: (context, _) {
        if (!services.auth.isLoggedIn) {
          return Scaffold(
            backgroundColor: c.surface,
            appBar: const BpAppBar(title: 'Notifikasi'),
            body: Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  imageAsset: 'assets/bipy/bipy_ngintip.webp',
                  title: 'Masuk untuk lihat notifikasi',
                  message:
                      'Kabar pesanan, Kelopak, dan promo tampil di sini setelah '
                      'kamu masuk.',
                  actionLabel: 'Masuk',
                  onAction: () => services.router.replace(
                    context,
                    const LoginRoute(next: AppRoutes.inbox),
                  ),
                ),
              ),
            ),
          );
        }
        final all = inbox.messages;
        final filter = _filter;
        final shown = filter == null
            ? all
            : all.where((message) => message.kind == filter).toList();
        final unread = inbox.unreadCount;
        return Scaffold(
          backgroundColor: c.canvas,
          appBar: BpAppBar(
            title: 'Notifikasi',
            actions: <Widget>[
              if (unread > 0 && MediaQuery.textScalerOf(context).scale(10) > 15)
                IconButton(
                  tooltip: 'Tandai semua dibaca',
                  icon: const Icon(LucideIcons.checkCheck),
                  onPressed: () => _markAll(context),
                )
              else if (unread > 0)
                PillButton(
                  label: 'Tandai dibaca',
                  variant: PillButtonVariant.text,
                  size: PillButtonSize.small,
                  icon: const Icon(LucideIcons.checkCheck),
                  onPressed: () => _markAll(context),
                ),
            ],
          ),
          body: Column(
            children: <Widget>[
              _FilterBar(
                selected: filter,
                counts: <InboxKind?, int>{
                  null: all.where((message) => !message.read).length,
                  for (final kind in InboxKind.values)
                    kind: all
                        .where(
                          (message) => message.kind == kind && !message.read,
                        )
                        .length,
                },
                onSelected: (kind) => setState(() => _filter = kind),
              ),
              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: EmptyState(
                            imageAsset: 'assets/bipy/bipy_pose_semangat.webp',
                            imageSize: 140,
                            title: filter == null
                                ? 'Belum ada notifikasi'
                                : 'Belum ada notifikasi ${_kindLabel(filter).toLowerCase()}',
                            message:
                                'Kabar pesanan, Kelopak, dan promo akan muncul di '
                                'sini, Babes.',
                            actionLabel: 'Mulai belanja',
                            onAction: () =>
                                services.router.go(context, const HomeRoute()),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: BpSpace.x6),
                        itemCount: shown.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, thickness: 1, color: c.line),
                        itemBuilder: (context, index) {
                          final message = shown[index];
                          return Dismissible(
                            key: ValueKey<String>('inbox-${message.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: c.dangerTint,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: BpSpace.x6),
                              child: Icon(LucideIcons.trash2, color: c.danger),
                            ),
                            onDismissed: (_) {
                              inbox.remove(message.id);
                              showAppSnack(context, 'Notifikasi dihapus.');
                            },
                            child: InboxTile(
                              message: message,
                              onTap: () => _open(context, message),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _markAll(BuildContext context) {
    AppScope.of(context).inbox.markAllRead();
    showAppSnack(context, 'Semua notifikasi sudah dibaca.');
  }

  void _open(BuildContext context, InboxMessage message) {
    final services = AppScope.of(context);
    services.inbox.markRead(message.id);
    final location = message.route;
    if (location == null) return;
    final route = parseAppRoute(location);
    if (route is NotFoundRoute) {
      showAppSnack(context, 'Halaman ini sudah tidak tersedia.');
      return;
    }
    services.router.go(context, route);
  }
}

String _kindLabel(InboxKind kind) => switch (kind) {
  InboxKind.order => 'Pesanan',
  InboxKind.reward => 'Hadiah',
  InboxKind.promo => 'Promo',
};

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final InboxKind? selected;
  final Map<InboxKind?, int> counts;
  final ValueChanged<InboxKind?> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final options = <InboxKind?>[null, ...InboxKind.values];
    return Container(
      color: c.surface,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: BpSpace.screen,
          vertical: BpSpace.x2,
        ),
        child: Row(
          children: <Widget>[
            for (final kind in options) ...<Widget>[
              BpChip(
                label: kind == null ? 'Semua' : _kindLabel(kind),
                selected: selected == kind,
                trailing: (counts[kind] ?? 0) > 0
                    ? CountBadge(count: counts[kind]!)
                    : null,
                onTap: () => onSelected(kind),
              ),
              const SizedBox(width: BpSpace.x2),
            ],
          ],
        ),
      ),
    );
  }
}

/// Satu baris notifikasi.
class InboxTile extends StatelessWidget {
  const InboxTile({super.key, required this.message, required this.onTap});

  final InboxMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final unread = !message.read;
    final (Widget icon, Color tint, Color tone) = switch (message.kind) {
      InboxKind.order => (const Icon(LucideIcons.package), c.infoTint, c.info),
      InboxKind.reward => (
        const Icon(LucideIcons.gift),
        c.goldTint,
        c.onGoldTint,
      ),
      InboxKind.promo => (
        const BrandIcon(BrandGlyph.promo),
        c.brandTint,
        c.brandStrong,
      ),
    };
    final time = _timeLabel(context, message.at);
    return Material(
      color: unread ? c.surface : c.surface.withValues(alpha: 0.6),
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          label:
              '${unread ? 'Belum dibaca. ' : ''}${_kindLabel(message.kind)}. '
              '${message.title}. ${message.body}. $time',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x3,
              BpSpace.screen,
              BpSpace.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconBubble(
                  icon: icon,
                  size: 40,
                  background: tint,
                  foreground: tone,
                ),
                const SizedBox(width: BpSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              message.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: BpText.subtitle.copyWith(
                                color: c.text,
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (unread)
                            const Padding(
                              padding: EdgeInsets.only(
                                left: BpSpace.x2,
                                top: 5,
                              ),
                              child: DotBadge(size: 9),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: BpText.bodyS.copyWith(color: c.textMuted),
                      ),
                      const SizedBox(height: BpSpace.x1),
                      Text(
                        '${_kindLabel(message.kind)} · $time',
                        style: BpText.caption.copyWith(color: c.textFaint),
                      ),
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

  String _timeLabel(BuildContext context, DateTime at) {
    final clock = AppScope.of(context).clock;
    final today = clock.today;
    final day = wibDayOfInstant(at);
    if (day == today) return 'Hari ini, ${wibClockLabel(at)} WIB';
    if (day == today - 1) return 'Kemarin, ${wibClockLabel(at)} WIB';
    return wibDateTimeLabel(at);
  }
}
