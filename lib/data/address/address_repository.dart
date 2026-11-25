/// Buku alamat: daftar, tambah, ubah, hapus, alamat utama (tanpa peta di demo).
library;

import 'package:kelopak_hub/kelopak_hub.dart'
    hide CheckoutQuote, CheckoutRequest, v2DocumentKey;

import '../auth/auth_validators.dart';
import '../storage/document_repository.dart';

/// Kolom formulir alamat.
enum AddressField { label, recipient, phone, street, district, city, province, postalCode }

/// Isian formulir alamat sebelum disimpan.
final class AddressDraft {
  const AddressDraft({
    required this.recipient,
    required this.phone,
    required this.street,
    required this.district,
    required this.city,
    required this.province,
    required this.postalCode,
    this.label = 'Rumah',
    this.note = '',
  });

  /// Label alamat ("Rumah", "Kantor").
  final String label;

  /// Nama penerima.
  final String recipient;

  /// Nomor HP penerima.
  final String phone;

  /// Jalan, nomor rumah, RT/RW.
  final String street;

  /// Kecamatan.
  final String district;

  /// Kota atau kabupaten.
  final String city;

  /// Provinsi.
  final String province;

  /// Kode pos (5 angka).
  final String postalCode;

  /// Patokan atau catatan untuk kurir.
  final String note;

  /// Pesan galat per kolom; kosong bila isian sah.
  Map<AddressField, String> validate() => <AddressField, String>{
    if (label.trim().isEmpty) AddressField.label: 'Isi label alamat.',
    AddressField.recipient: ?validateName(recipient),
    AddressField.phone: ?validatePhone(phone),
    if (street.trim().length < 5)
      AddressField.street: 'Isi alamat lengkap (jalan dan nomor rumah).',
    if (district.trim().isEmpty) AddressField.district: 'Isi kecamatan.',
    if (city.trim().isEmpty) AddressField.city: 'Isi kota atau kabupaten.',
    if (province.trim().isEmpty) AddressField.province: 'Isi provinsi.',
    if (!RegExp(r'^\d{5}$').hasMatch(postalCode.trim()))
      AddressField.postalCode: 'Kode pos harus 5 angka.',
  };
}

/// Alamat tersimpan.
final class Address {
  const Address({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.street,
    required this.district,
    required this.city,
    required this.province,
    required this.postalCode,
    this.note = '',
    this.isPrimary = false,
  });

  /// Membaca alamat tersimpan.
  factory Address.fromJson(Object? source) {
    final json = asJsonMap(source, 'alamat');
    final address = Address(
      id: readString(json, 'id'),
      label: readString(json, 'label'),
      recipient: readString(json, 'recipient'),
      phone: readString(json, 'phone'),
      street: readString(json, 'street'),
      district: readString(json, 'district'),
      city: readString(json, 'city'),
      province: readString(json, 'province'),
      postalCode: readString(json, 'postalCode'),
      note: readString(json, 'note', fallback: ''),
      isPrimary: readBool(json, 'isPrimary', fallback: false),
    );
    if (address.id.isEmpty) throw const FormatException('Alamat tanpa ID');
    return address;
  }

  /// ID alamat.
  final String id;

  /// Label alamat.
  final String label;

  /// Nama penerima.
  final String recipient;

  /// Nomor HP ternormalisasi (`628…`).
  final String phone;

  /// Jalan, nomor rumah, RT/RW.
  final String street;

  /// Kecamatan.
  final String district;

  /// Kota atau kabupaten.
  final String city;

  /// Provinsi.
  final String province;

  /// Kode pos.
  final String postalCode;

  /// Catatan untuk kurir.
  final String note;

  /// Apakah alamat utama.
  final bool isPrimary;

  /// Nomor HP untuk ditampilkan.
  String get phoneLabel => formatPhone(phone);

  /// Alamat satu baris: "Jl. Mawar 5, Coblong, Bandung, Jawa Barat 40132".
  String get fullAddress => '$street, $district, $city, $province $postalCode';

  /// Isian formulir untuk mengubah alamat ini.
  AddressDraft toDraft() => AddressDraft(
    label: label,
    recipient: recipient,
    phone: phoneLabel,
    street: street,
    district: district,
    city: city,
    province: province,
    postalCode: postalCode,
    note: note,
  );

  /// Salinan dengan status utama diganti.
  Address withPrimary(bool value) => Address(
    id: id,
    label: label,
    recipient: recipient,
    phone: phone,
    street: street,
    district: district,
    city: city,
    province: province,
    postalCode: postalCode,
    note: note,
    isPrimary: value,
  );

  /// Bentuk JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'label': label,
    'recipient': recipient,
    'phone': phone,
    'street': street,
    'district': district,
    'city': city,
    'province': province,
    'postalCode': postalCode,
    'note': note,
    'isPrimary': isPrimary,
  };
}

/// Buku alamat tersimpan. Selalu ada tepat satu alamat utama selama daftar
/// tidak kosong.
class AddressRepository extends DocumentRepository {
  List<Address> _addresses = const <Address>[];
  int _seq = 0;

  @override
  String get sectionKey => 'addresses';

  /// Alamat; alamat utama lebih dulu.
  List<Address> get addresses => _addresses;

  /// Apakah belum ada alamat.
  bool get isEmpty => _addresses.isEmpty;

  /// Alamat utama, atau null bila daftar kosong.
  Address? get primary {
    for (final address in _addresses) {
      if (address.isPrimary) return address;
    }
    return null;
  }

  /// Alamat ber-ID [id], atau null.
  Address? byId(String? id) {
    for (final address in _addresses) {
      if (address.id == id) return address;
    }
    return null;
  }

  /// Menambah alamat. Alamat pertama otomatis menjadi utama. Melempar
  /// [ArgumentError] bila [draft] tidak sah (panggil [AddressDraft.validate]
  /// lebih dulu).
  Address add(AddressDraft draft, {bool makePrimary = false}) {
    _check(draft);
    _seq++;
    final address = _fromDraft('A$_seq', draft, isPrimary: false);
    _commit(
      <Address>[..._addresses, address],
      primaryId: makePrimary || _addresses.isEmpty ? address.id : null,
    );
    return byId(address.id)!;
  }

  /// Mengubah alamat [id]; mengembalikan null bila tidak ada.
  Address? update(String id, AddressDraft draft) {
    final current = byId(id);
    if (current == null) return null;
    _check(draft);
    final updated = _fromDraft(id, draft, isPrimary: current.isPrimary);
    _commit(<Address>[
      for (final address in _addresses) address.id == id ? updated : address,
    ]);
    return updated;
  }

  /// Menghapus alamat [id]. Bila yang dihapus alamat utama, alamat pertama
  /// yang tersisa menjadi utama.
  bool remove(String id) {
    if (byId(id) == null) return false;
    _commit(_addresses.where((address) => address.id != id).toList());
    return true;
  }

  /// Menjadikan alamat [id] sebagai alamat utama.
  bool setPrimary(String id) {
    if (byId(id) == null) return false;
    _commit(_addresses, primaryId: id);
    return true;
  }

  void _commit(List<Address> next, {String? primaryId}) {
    _addresses = _normalize(next, primaryId: primaryId);
    changed();
  }

  static List<Address> _normalize(List<Address> list, {String? primaryId}) {
    if (list.isEmpty) return const <Address>[];
    var id = primaryId;
    if (id == null) {
      for (final address in list) {
        if (address.isPrimary) {
          id = address.id;
          break;
        }
      }
    }
    id ??= list.first.id;
    final marked = <Address>[
      for (final address in list) address.withPrimary(address.id == id),
    ];
    return List<Address>.unmodifiable(<Address>[
      ...marked.where((address) => address.isPrimary),
      ...marked.where((address) => !address.isPrimary),
    ]);
  }

  static void _check(AddressDraft draft) {
    final errors = draft.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError.value(draft, 'draft', errors.values.first);
    }
  }

  static Address _fromDraft(
    String id,
    AddressDraft draft, {
    required bool isPrimary,
  }) => Address(
    id: id,
    label: draft.label.trim(),
    recipient: draft.recipient.trim(),
    phone: normalizePhone(draft.phone)!,
    street: draft.street.trim(),
    district: draft.district.trim(),
    city: draft.city.trim(),
    province: draft.province.trim(),
    postalCode: draft.postalCode.trim(),
    note: draft.note.trim(),
    isPrimary: isPrimary,
  );

  @override
  Object? toJson() => <String, Object?>{
    'seq': _seq,
    'items': <Object?>[for (final address in _addresses) address.toJson()],
  };

  @override
  void restoreState(Object? json) {
    if (json == null) {
      _addresses = const <Address>[];
      _seq = 0;
      return;
    }
    final map = asJsonMap(json, 'buku alamat');
    final items = readList(map, 'items', Address.fromJson);
    final seq = readInt(map, 'seq', fallback: items.length);
    final ids = <String>{for (final address in items) address.id};
    if (seq < 0 || ids.length != items.length) {
      throw const FormatException('Buku alamat tidak sah');
    }
    _addresses = _normalize(items);
    _seq = seq;
  }
}
