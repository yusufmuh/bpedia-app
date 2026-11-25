/// Event Promo: banner, App Flyer, dan halaman event dari
/// `assets/promo/promo.json`.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;
import 'package:kelopak_hub/kelopak_hub.dart';

import '../storage/document_repository.dart';
import '../wib_dates.dart';

/// Jalur aset promo.
const String promoAsset = 'assets/promo/promo.json';

/// Banner carousel Event Promo (rasio 3:1).
final class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.image,
    required this.title,
    required this.route,
  });

  /// Membaca banner dari JSON promo.
  factory PromoBanner.fromJson(Object? source) {
    final json = asJsonMap(source, 'banner');
    return PromoBanner(
      id: readString(json, 'id'),
      image: readString(json, 'image'),
      title: readString(json, 'title'),
      route: readString(json, 'route'),
    );
  }

  /// ID banner.
  final String id;

  /// Jalur aset gambar.
  final String image;

  /// Judul (label aksesibilitas).
  final String title;

  /// Lokasi rute tujuan saat diketuk.
  final String route;
}

/// App Flyer (pop-up promo 1:1) dengan jendela tanggal WIB opsional.
final class PromoFlyer {
  const PromoFlyer({
    required this.id,
    required this.image,
    required this.title,
    required this.route,
    this.fromDay,
    this.toDay,
  });

  /// Membaca flyer dari JSON promo.
  factory PromoFlyer.fromJson(Object? source) {
    final json = asJsonMap(source, 'flyer');
    final from = readOptionalString(json, 'from');
    final to = readOptionalString(json, 'to');
    return PromoFlyer(
      id: readString(json, 'id'),
      image: readString(json, 'image'),
      title: readString(json, 'title'),
      route: readString(json, 'route'),
      fromDay: from == null ? null : parseWibDay(from),
      toDay: to == null ? null : parseWibDay(to),
    );
  }

  /// ID flyer.
  final String id;

  /// Jalur aset gambar.
  final String image;

  /// Judul (label aksesibilitas).
  final String title;

  /// Lokasi rute tombol "Lihat promo".
  final String route;

  /// Hari WIB pertama flyer aktif; null = tanpa batas awal.
  final int? fromDay;

  /// Hari WIB terakhir flyer aktif; null = tanpa batas akhir.
  final int? toDay;

  /// Apakah flyer aktif pada hari WIB [day].
  bool isActiveOn(int day) {
    final from = fromDay;
    final to = toDay;
    return (from == null || day >= from) && (to == null || day <= to);
  }
}

/// Tombol aksi halaman event: ke rute app atau ke tautan luar.
final class PromoCta {
  const PromoCta({required this.label, this.route, this.url});

  /// Membaca tombol aksi dari JSON promo.
  factory PromoCta.fromJson(Object? source) {
    final json = asJsonMap(source, 'cta');
    final cta = PromoCta(
      label: readString(json, 'label'),
      route: readOptionalString(json, 'route'),
      url: readOptionalString(json, 'url'),
    );
    if (cta.route == null && cta.url == null) {
      throw const FormatException('CTA tanpa tujuan');
    }
    return cta;
  }

  /// Teks tombol.
  final String label;

  /// Lokasi rute app, bila tujuan di dalam app.
  final String? route;

  /// Tautan luar (misalnya WhatsApp), bila tujuan di luar app.
  final String? url;
}

/// Tawaran voucher sebuah event (misalnya 12.12).
final class PromoVoucherOffer {
  const PromoVoucherOffer({
    required this.amount,
    required this.minSpend,
    required this.validDays,
    required this.claimDay,
  });

  /// Membaca tawaran voucher dari JSON promo.
  factory PromoVoucherOffer.fromJson(Object? source) {
    final json = asJsonMap(source, 'voucher');
    final offer = PromoVoucherOffer(
      amount: readInt(json, 'amount'),
      minSpend: readInt(json, 'minSpend'),
      validDays: readInt(json, 'validDays'),
      claimDay: parseWibDay(readString(json, 'claimDate')),
    );
    if (offer.amount <= 0 || offer.minSpend < 0 || offer.validDays < 1) {
      throw const FormatException('Voucher event tidak sah');
    }
    return offer;
  }

  /// Nilai voucher (rupiah).
  final int amount;

  /// Minimal belanja (rupiah).
  final int minSpend;

  /// Masa berlaku sejak diklaim (hari).
  final int validDays;

  /// Satu-satunya hari WIB voucher bisa diklaim.
  final int claimDay;
}

/// Halaman event di hub Event Promo.
final class PromoEvent {
  PromoEvent({
    required this.id,
    required this.title,
    required this.banner,
    required this.period,
    required this.summary,
    required List<String> body,
    required List<String> terms,
    required List<String> productCodes,
    this.cta,
    this.voucher,
  }) : body = List<String>.unmodifiable(body),
       terms = List<String>.unmodifiable(terms),
       productCodes = List<String>.unmodifiable(productCodes);

  /// Membaca event dari JSON promo.
  factory PromoEvent.fromJson(Object? source) {
    final json = asJsonMap(source, 'event');
    return PromoEvent(
      id: readString(json, 'id'),
      title: readString(json, 'title'),
      banner: readString(json, 'banner'),
      period: readString(json, 'period', fallback: ''),
      summary: readString(json, 'summary', fallback: ''),
      body: readStringList(json, 'body'),
      terms: readStringList(json, 'terms'),
      productCodes: readStringList(json, 'productCodes'),
      cta: json['cta'] == null ? null : PromoCta.fromJson(json['cta']),
      voucher: json['voucher'] == null
          ? null
          : PromoVoucherOffer.fromJson(json['voucher']),
    );
  }

  /// ID event (dipakai di rute `/event/:id` dan sebagai `promoId` voucher).
  final String id;

  /// Judul event.
  final String title;

  /// Jalur aset banner (rasio 3:1).
  final String banner;

  /// Keterangan periode.
  final String period;

  /// Ringkasan satu kalimat.
  final String summary;

  /// Paragraf penjelasan.
  final List<String> body;

  /// Syarat dan ketentuan.
  final List<String> terms;

  /// Kode produk terkait (bisa kosong).
  final List<String> productCodes;

  /// Tombol aksi, bila ada.
  final PromoCta? cta;

  /// Tawaran voucher, bila ada.
  final PromoVoucherOffer? voucher;
}

/// Banner, flyer, dan event promo; mengingat hari terakhir flyer ditampilkan.
class PromoRepository extends DocumentRepository {
  PromoRepository({required WibClock clock}) : _clock = clock;

  final WibClock _clock;
  List<PromoBanner> _banners = const <PromoBanner>[];
  List<PromoFlyer> _flyers = const <PromoFlyer>[];
  List<PromoEvent> _events = const <PromoEvent>[];
  Object? _loadError;
  int? _flyerShownDay;

  @override
  String get sectionKey => 'promo';

  /// Galat pemuatan terakhir; null bila berhasil.
  Object? get loadError => _loadError;

  /// Banner carousel Event Promo.
  List<PromoBanner> get banners => _banners;

  /// Semua flyer (aktif maupun tidak).
  List<PromoFlyer> get flyers => _flyers;

  /// Halaman event, urut tampil di hub.
  List<PromoEvent> get events => _events;

  /// Flyer pertama yang aktif hari ini (WIB), atau null.
  PromoFlyer? get activeFlyer {
    final today = _clock.today;
    for (final flyer in _flyers) {
      if (flyer.isActiveOn(today)) return flyer;
    }
    return null;
  }

  /// Memuat promo dari [bundle]. Tidak melempar: kegagalan tercatat di
  /// [loadError] dan daftar tetap kosong.
  Future<void> load(AssetBundle bundle) async {
    try {
      loadFromJson(await bundle.loadString(promoAsset));
    } on Object catch (error) {
      _loadError = error;
    }
  }

  /// Memuat promo dari teks JSON. Tidak melempar (lihat [load]).
  void loadFromJson(String source) {
    try {
      final json = asJsonMap(jsonDecode(source), 'promo');
      final banners = readList(json, 'banners', PromoBanner.fromJson);
      final flyers = readList(json, 'flyers', PromoFlyer.fromJson);
      final events = readList(json, 'events', PromoEvent.fromJson);
      _banners = List<PromoBanner>.unmodifiable(banners);
      _flyers = List<PromoFlyer>.unmodifiable(flyers);
      _events = List<PromoEvent>.unmodifiable(events);
      _loadError = null;
      if (!isDisposed) notifyListeners();
    } on FormatException catch (error) {
      _loadError = error;
    }
  }

  /// Event ber-ID [id], atau null.
  PromoEvent? eventById(String id) {
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  /// Apakah voucher [event] bisa diklaim hari ini (hanya pada hari klaimnya).
  bool isVoucherClaimDay(PromoEvent event) =>
      event.voucher?.claimDay == _clock.today;

  /// Apakah App Flyer perlu tampil: ada flyer aktif dan belum ditampilkan pada
  /// hari WIB ini.
  bool shouldShowFlyerToday() =>
      activeFlyer != null && _flyerShownDay != _clock.today;

  /// Mencatat bahwa flyer sudah tampil hari ini.
  void markFlyerShown() {
    if (_flyerShownDay == _clock.today) return;
    _flyerShownDay = _clock.today;
    changed();
  }

  @override
  Object? toJson() => <String, Object?>{'flyerShownDay': _flyerShownDay};

  @override
  void restoreState(Object? json) {
    _flyerShownDay = json == null
        ? null
        : readOptionalInt(asJsonMap(json, 'promo'), 'flyerShownDay');
  }
}
