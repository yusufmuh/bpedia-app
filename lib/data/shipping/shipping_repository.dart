/// Kurir dan ongkir demo. Nama kurir dari footer bpedia.id; tarif adalah
/// **nilai demo** dan selalu ditampilkan bertanda "(demo)".
library;

/// Satu pilihan kurir dengan ongkir yang sudah dihitung.
final class ShippingOption {
  const ShippingOption({
    required this.id,
    required this.name,
    required this.etaLabel,
    required this.fee,
    this.note,
  });

  /// ID kurir (tersimpan di pesanan).
  final String id;

  /// Nama kurir.
  final String name;

  /// Perkiraan tiba (demo).
  final String etaLabel;

  /// Ongkir (rupiah).
  final int fee;

  /// Keterangan tambahan, misalnya alasan gratis ongkir.
  final String? note;

  /// Apakah gratis.
  bool get isFree => fee == 0;
}

/// Tarif satu kurir (nilai demo).
final class CourierRate {
  const CourierRate({
    required this.id,
    required this.name,
    required this.etaLabel,
    required this.firstKgFee,
    required this.nextKgFee,
    this.freeFromSubtotal,
  });

  /// ID kurir.
  final String id;

  /// Nama kurir.
  final String name;

  /// Perkiraan tiba.
  final String etaLabel;

  /// Ongkir kilogram pertama (rupiah).
  final int firstKgFee;

  /// Ongkir tiap kilogram berikutnya (rupiah).
  final int nextKgFee;

  /// Subtotal barang minimal untuk gratis ongkir; null = tidak pernah gratis.
  final int? freeFromSubtotal;
}

/// Kurir yang tersedia dan hitung ongkir dari berat.
class ShippingRepository {
  /// Memakai [rates] atau tarif demo bawaan.
  const ShippingRepository({this.rates = demoRates});

  /// Tanda yang ditempel di samping ongkir dan estimasi.
  static const String demoTag = '(demo)';

  /// Tarif demo: Bpedia Express dan Wahana Express.
  static const List<CourierRate> demoRates = <CourierRate>[
    CourierRate(
      id: 'bpedia-express',
      name: 'Bpedia Express',
      etaLabel: 'Tiba 2 sampai 3 hari',
      firstKgFee: 8000,
      nextKgFee: 2000,
      freeFromSubtotal: 50000,
    ),
    CourierRate(
      id: 'wahana-express',
      name: 'Wahana Express',
      etaLabel: 'Tiba 3 sampai 5 hari',
      firstKgFee: 10000,
      nextKgFee: 3000,
    ),
  ];

  /// Tarif kurir.
  final List<CourierRate> rates;

  /// Berat tagih dalam kilogram: dibulatkan ke atas, minimal 1.
  static int billableKg(int weightGrams) {
    if (weightGrams <= 1000) return 1;
    return (weightGrams + 999) ~/ 1000;
  }

  /// Pilihan kurir untuk paket seberat [weightGrams] dengan subtotal barang
  /// [goodsSubtotal], urut seperti [rates].
  List<ShippingOption> options({
    required int weightGrams,
    required int goodsSubtotal,
  }) {
    final kg = billableKg(weightGrams);
    return <ShippingOption>[
      for (final rate in rates) _optionFor(rate, kg, goodsSubtotal),
    ];
  }

  /// Pilihan kurir ber-ID [id] untuk paket yang sama, atau null.
  ShippingOption? optionById(
    String id, {
    required int weightGrams,
    required int goodsSubtotal,
  }) {
    for (final option in options(
      weightGrams: weightGrams,
      goodsSubtotal: goodsSubtotal,
    )) {
      if (option.id == id) return option;
    }
    return null;
  }

  ShippingOption _optionFor(CourierRate rate, int kg, int goodsSubtotal) {
    final freeFrom = rate.freeFromSubtotal;
    final free = freeFrom != null && goodsSubtotal >= freeFrom;
    return ShippingOption(
      id: rate.id,
      name: rate.name,
      etaLabel: rate.etaLabel,
      fee: free ? 0 : rate.firstKgFee + (kg - 1) * rate.nextKgFee,
      note: free ? 'Gratis ongkir' : null,
    );
  }
}
