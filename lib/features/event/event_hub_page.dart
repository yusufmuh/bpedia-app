/// Hub Event Promo (`/event`, FITUR #8 dan #23): kartu banner besar tiap event
/// dari `assets/promo/promo.json`.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/shell.dart' show CartButton;
import '../../data/promo/promo_repository.dart';
import '../../design/design.dart';

/// Daftar event promo.
class EventHubPage extends StatelessWidget {
  const EventHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final events = services.promo.events;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(
        title: 'Event Promo',
        actions: <Widget>[CartButton()],
      ),
      body: events.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  imageAsset: 'assets/bipy/bipy_pose_semangat.webp',
                  title: 'Belum ada event, Babes',
                  message:
                      'Event promo baru akan tampil di sini. Sementara itu, '
                      'lihat Hot Item hari ini.',
                  actionLabel: 'Lihat Hot Item',
                  onAction: () =>
                      services.router.go(context, const HotItemsRoute()),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                BpSpace.gridMargin,
                BpSpace.x3,
                BpSpace.gridMargin,
                BpSpace.x6,
              ),
              itemCount: events.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: BpSpace.x3),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    '${events.length} event berjalan dan akan datang',
                    style: BpText.bodyS.copyWith(color: c.textMuted),
                  );
                }
                final event = events[index - 1];
                return EventCard(
                  event: event,
                  onTap: () =>
                      services.router.go(context, EventRoute(event.id)),
                );
              },
            ),
    );
  }
}

/// Kartu event: banner 3:1, judul, periode, ringkasan.
class EventCard extends StatelessWidget {
  const EventCard({required this.event, required this.onTap, super.key});

  final PromoEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpTappable(
      key: ValueKey<String>('event-${event.id}'),
      onTap: onTap,
      semanticLabel: '${event.title}. ${event.period}',
      minWidth: 0,
      focusRadius: BpRadius.cardAll,
      builder: (context, states) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BpRadius.cardAll,
          border: Border.all(color: c.line),
          boxShadow: BpShadows.floating(c),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(BpRadius.card - 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AspectRatio(aspectRatio: 3, child: AssetPicture(event.banner)),
              Padding(
                padding: const EdgeInsets.all(BpSpace.card),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            event.title,
                            style: BpText.subtitle.copyWith(color: c.text),
                          ),
                          if (event.period.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 2),
                            Row(
                              children: <Widget>[
                                Icon(
                                  LucideIcons.calendar,
                                  size: 14,
                                  color: c.brandStrong,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.period,
                                    style: BpText.caption.copyWith(
                                      color: c.brandStrong,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (event.summary.isNotEmpty) ...<Widget>[
                            const SizedBox(height: BpSpace.x1),
                            Text(
                              event.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: BpText.bodyS.copyWith(color: c.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: BpSpace.x2),
                    Icon(LucideIcons.chevronRight, color: c.textMuted),
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
