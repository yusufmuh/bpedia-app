/// Pemetaan keluaran sistem Kelopak ke layanan app: [KelopakEvent] ke
/// analitik dan kotak masuk, [GameCue] ke [SoundCue].
library;

import 'dart:async';

import 'package:kelopak_hub/kelopak_hub.dart'
    show
        GameCue,
        GiftAttachedEvent,
        GiftsReceivedEvent,
        GiftsShippedEvent,
        KelopakEvent,
        KelopakRedeemedEvent,
        MissionCompletedEvent,
        OrderRefundedEvent,
        VoucherRedeemedEvent;

import '../data/inbox/inbox_repository.dart';
import '../services/analytics/analytics.dart';
import '../services/sound/sound_service.dart';

/// Mencatat [event] ke [analytics] dan [inbox].
///
/// Peristiwa yang terikat pesanan (pemakaian voucher/Kelopak, hadiah
/// terlampir, dikirim, diterima, pengembalian) sudah dicatat
/// `OrderRepository` dengan nomor pesanan app, jadi tidak dicatat dua kali.
/// Misi tuntas masuk kotak masuk lewat pesan misi pesanan, jadi di sini
/// hanya analitiknya.
void recordKelopakEvent(
  KelopakEvent event, {
  required Analytics analytics,
  required InboxRepository inbox,
}) {
  final orderBound = switch (event) {
    VoucherRedeemedEvent() ||
    KelopakRedeemedEvent() ||
    GiftAttachedEvent() ||
    GiftsShippedEvent() ||
    GiftsReceivedEvent() ||
    OrderRefundedEvent() => true,
    _ => false,
  };
  if (orderBound) return;

  final name = event.analyticsName;
  if (name != null) {
    unawaited(analytics.logEvent(name, <String, Object?>{...event.parameters}));
  }
  if (event is MissionCompletedEvent) return;
  final notice = event.notice;
  if (notice != null) {
    inbox.add(
      kind: InboxKind.reward,
      title: notice.title,
      body: notice.body,
      route: notice.route,
    );
  }
}

/// Cue app untuk [cue] game, berurutan. Menang produk disusul jingle menang.
List<SoundCue> soundCuesFor(GameCue cue) => switch (cue) {
  GameCue.tap => const <SoundCue>[SoundCue.tap],
  GameCue.claim => const <SoundCue>[SoundCue.claim],
  GameCue.bonus => const <SoundCue>[SoundCue.bonus],
  GameCue.spinStart => const <SoundCue>[SoundCue.spinStart],
  GameCue.tick => const <SoundCue>[SoundCue.tick],
  GameCue.winKelopak => const <SoundCue>[SoundCue.winKelopak],
  GameCue.winProduct => const <SoundCue>[
    SoundCue.winProduct,
    SoundCue.winJingle,
  ],
  GameCue.missionDone => const <SoundCue>[SoundCue.missionDone],
  GameCue.softError => const <SoundCue>[SoundCue.softError],
};
