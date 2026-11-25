/// Metode pembayaran (FITUR #18). Semua simulasi: tidak ada uang sungguhan.
library;

/// Kelompok metode pembayaran.
enum PaymentKind {
  /// QRIS.
  qris('QRIS'),

  /// Transfer bank lewat virtual account.
  virtualAccount('Transfer bank (virtual account)'),

  /// Bayar di gerai.
  retail('Gerai'),

  /// Dompet digital.
  ewallet('Dompet digital'),

  /// Bayar di tempat.
  cod('Bayar di tempat (COD)');

  const PaymentKind(this.title);

  /// Judul kelompok.
  final String title;
}

/// Satu metode pembayaran.
final class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.kind,
    required this.hint,
  });

  /// ID metode (tersimpan di pesanan).
  final String id;

  /// Nama tampil.
  final String name;

  /// Kelompok.
  final PaymentKind kind;

  /// Petunjuk singkat di halaman pembayaran simulasi.
  final String hint;

  /// Apakah bayar di tempat (pesanan langsung dikemas).
  bool get isCod => kind == PaymentKind.cod;
}

/// Daftar metode pembayaran yang tampil di footer bpedia.id.
abstract final class PaymentCatalog {
  /// Tanda yang ditempel pada semua layar pembayaran.
  static const String demoNote =
      'Simulasi pembayaran. Tidak ada uang sungguhan yang berpindah.';

  /// Metode bawaan saat checkout dibuka.
  static const String defaultMethodId = 'qris';

  /// Semua metode, urut tampil.
  static const List<PaymentMethod> methods = <PaymentMethod>[
    PaymentMethod(
      id: 'qris',
      name: 'QRIS',
      kind: PaymentKind.qris,
      hint: 'Pindai kode QR dengan aplikasi bank atau dompet digitalmu.',
    ),
    PaymentMethod(
      id: 'va-bca',
      name: 'BCA Virtual Account',
      kind: PaymentKind.virtualAccount,
      hint: _vaHint,
    ),
    PaymentMethod(
      id: 'va-mandiri',
      name: 'Mandiri Virtual Account',
      kind: PaymentKind.virtualAccount,
      hint: _vaHint,
    ),
    PaymentMethod(
      id: 'va-bni',
      name: 'BNI Virtual Account',
      kind: PaymentKind.virtualAccount,
      hint: _vaHint,
    ),
    PaymentMethod(
      id: 'va-bri',
      name: 'BRI Virtual Account',
      kind: PaymentKind.virtualAccount,
      hint: _vaHint,
    ),
    PaymentMethod(
      id: 'va-cimb',
      name: 'CIMB Niaga Virtual Account',
      kind: PaymentKind.virtualAccount,
      hint: _vaHint,
    ),
    PaymentMethod(
      id: 'va-bsi',
      name: 'BSI Virtual Account',
      kind: PaymentKind.virtualAccount,
      hint: _vaHint,
    ),
    PaymentMethod(
      id: 'va-permata',
      name: 'Permata Virtual Account',
      kind: PaymentKind.virtualAccount,
      hint: _vaHint,
    ),
    PaymentMethod(
      id: 'va-bjb',
      name: 'bank bjb Virtual Account',
      kind: PaymentKind.virtualAccount,
      hint: _vaHint,
    ),
    PaymentMethod(
      id: 'retail-alfamart',
      name: 'Alfamart',
      kind: PaymentKind.retail,
      hint: _retailHint,
    ),
    PaymentMethod(
      id: 'retail-indomaret',
      name: 'Indomaret',
      kind: PaymentKind.retail,
      hint: _retailHint,
    ),
    PaymentMethod(
      id: 'ewallet',
      name: 'Dompet digital',
      kind: PaymentKind.ewallet,
      hint: 'Selesaikan pembayaran di aplikasi dompet digitalmu.',
    ),
    PaymentMethod(
      id: 'cod',
      name: 'Bayar di tempat (COD)',
      kind: PaymentKind.cod,
      hint: 'Bayar tunai ke kurir saat paket tiba.',
    ),
  ];

  static const String _vaHint =
      'Transfer ke nomor virtual account yang tampil sebelum batas waktu.';
  static const String _retailHint =
      'Tunjukkan kode pembayaran ke kasir sebelum batas waktu.';

  /// Metode ber-ID [id], atau null.
  static PaymentMethod? byId(String? id) {
    for (final method in methods) {
      if (method.id == id) return method;
    }
    return null;
  }

  /// Metode dikelompokkan per [PaymentKind], urut tampil.
  static Map<PaymentKind, List<PaymentMethod>> get grouped {
    final groups = <PaymentKind, List<PaymentMethod>>{};
    for (final method in methods) {
      (groups[method.kind] ??= <PaymentMethod>[]).add(method);
    }
    return groups;
  }
}
