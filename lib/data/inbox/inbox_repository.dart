/// Kotak masuk notifikasi lokal (pesanan, hadiah, promo).
library;

import 'package:kelopak_hub/kelopak_hub.dart';

import '../storage/document_repository.dart';

/// Jenis notifikasi; menentukan ikon di daftar.
enum InboxKind {
  /// Status pesanan.
  order,

  /// Kelopak, voucher, dan hadiah.
  reward,

  /// Event dan promo.
  promo,
}

/// Satu notifikasi.
final class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.atMs,
    this.route,
    this.read = false,
  });

  /// Membaca notifikasi tersimpan.
  factory InboxMessage.fromJson(Object? source) {
    final json = asJsonMap(source, 'notifikasi');
    return InboxMessage(
      id: readString(json, 'id'),
      kind: readEnum(json, 'kind', InboxKind.values),
      title: readString(json, 'title'),
      body: readString(json, 'body'),
      route: readOptionalString(json, 'route'),
      atMs: readInt(json, 'atMs'),
      read: readBool(json, 'read', fallback: false),
    );
  }

  /// ID notifikasi.
  final String id;

  /// Jenis.
  final InboxKind kind;

  /// Judul.
  final String title;

  /// Isi.
  final String body;

  /// Lokasi rute yang dibuka saat diketuk, bila ada.
  final String? route;

  /// Waktu notifikasi (milidetik sejak epoch).
  final int atMs;

  /// Sudah dibaca.
  final bool read;

  /// Waktu notifikasi.
  DateTime get at => DateTime.fromMillisecondsSinceEpoch(atMs, isUtc: true);

  /// Salinan bertanda sudah dibaca.
  InboxMessage asRead() => InboxMessage(
    id: id,
    kind: kind,
    title: title,
    body: body,
    route: route,
    atMs: atMs,
    read: true,
  );

  /// Bentuk JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'title': title,
    'body': body,
    'route': route,
    'atMs': atMs,
    'read': read,
  };
}

/// Notifikasi lokal tersimpan, terbaru lebih dulu.
class InboxRepository extends DocumentRepository {
  InboxRepository({required WibClock clock}) : _clock = clock;

  /// Jumlah notifikasi yang disimpan.
  static const int capacity = 100;

  final WibClock _clock;
  List<InboxMessage> _messages = const <InboxMessage>[];
  int _seq = 0;

  @override
  String get sectionKey => 'inbox';

  /// Notifikasi, terbaru lebih dulu.
  List<InboxMessage> get messages => _messages;

  /// Jumlah yang belum dibaca (lencana lonceng).
  int get unreadCount => _messages.where((message) => !message.read).length;

  /// Menambah notifikasi baru di paling atas.
  InboxMessage add({
    required InboxKind kind,
    required String title,
    required String body,
    String? route,
  }) {
    _seq++;
    final message = InboxMessage(
      id: 'N$_seq',
      kind: kind,
      title: title,
      body: body,
      route: route,
      atMs: _clock.instant.toUtc().millisecondsSinceEpoch,
    );
    _messages = List<InboxMessage>.unmodifiable(
      <InboxMessage>[message, ..._messages].take(capacity),
    );
    changed();
    return message;
  }

  /// Menandai satu notifikasi sudah dibaca.
  void markRead(String id) {
    if (!_messages.any((message) => message.id == id && !message.read)) return;
    _messages = List<InboxMessage>.unmodifiable(<InboxMessage>[
      for (final message in _messages)
        message.id == id ? message.asRead() : message,
    ]);
    changed();
  }

  /// "Tandai semua dibaca".
  void markAllRead() {
    if (unreadCount == 0) return;
    _messages = List<InboxMessage>.unmodifiable(<InboxMessage>[
      for (final message in _messages) message.read ? message : message.asRead(),
    ]);
    changed();
  }

  /// Menghapus satu notifikasi.
  void remove(String id) {
    if (!_messages.any((message) => message.id == id)) return;
    _messages = List<InboxMessage>.unmodifiable(
      _messages.where((message) => message.id != id),
    );
    changed();
  }

  @override
  Object? toJson() => <String, Object?>{
    'seq': _seq,
    'items': <Object?>[for (final message in _messages) message.toJson()],
  };

  @override
  void restoreState(Object? json) {
    if (json == null) {
      _messages = const <InboxMessage>[];
      _seq = 0;
      return;
    }
    final map = asJsonMap(json, 'kotak masuk');
    final items = readList(map, 'items', InboxMessage.fromJson);
    final seq = readInt(map, 'seq', fallback: items.length);
    if (seq < 0) throw const FormatException('Nomor notifikasi negatif');
    _messages = List<InboxMessage>.unmodifiable(items.take(capacity));
    _seq = seq;
  }
}
