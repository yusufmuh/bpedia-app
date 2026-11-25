/// Alat Mode Demo untuk data hadiah. Gateway hadiah yang mendukung uji
/// (adaptor Kelopak milik integrasi) mengimplementasikan [DemoRewardsTools];
/// Mode Demo memeriksanya dengan `services.rewards is DemoRewardsTools`.
library;

/// Aksi uji tambahan dari gateway hadiah (mis. paksa hasil roda, isi kuota).
final class DemoRewardsAction {
  const DemoRewardsAction({
    required this.id,
    required this.label,
    required this.run,
    this.description,
  });

  /// ID stabil (kunci tes dan widget).
  final String id;

  /// Teks tombol, mis. "Isi kuota produk roda".
  final String label;

  /// Penjelasan singkat di bawah tombol.
  final String? description;

  /// Menjalankan aksi; mengembalikan pesan hasil untuk ditampilkan, atau
  /// null bila tidak ada yang perlu disampaikan.
  final Future<String?> Function() run;
}

/// Alat uji data Kelopak yang dipakai Mode Demo.
abstract interface class DemoRewardsTools {
  /// Menambah [amount] Kelopak ke saldo akun yang sedang masuk. False bila
  /// tidak bisa (mis. tamu).
  Future<bool> grantKelopak(int amount);

  /// Menghapus seluruh data hadiah (saldo, riwayat, voucher, hadiah
  /// menunggu, progres game).
  Future<void> resetRewards();

  /// Aksi uji lain yang ingin ditampilkan gateway.
  List<DemoRewardsAction> get demoActions;
}
