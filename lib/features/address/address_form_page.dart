/// Formulir alamat: tambah, ubah, hapus, jadikan utama. Demo tanpa titik peta.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_scope.dart';
import '../../data/address/address_repository.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';
import 'address_book_page.dart';

/// Label alamat yang bisa dipilih.
const List<String> addressLabels = <String>[
  'Rumah',
  'Kantor',
  'Kos',
  'Apartemen',
];

/// Formulir alamat. [addressId] null = alamat baru.
class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key, this.addressId});

  final String? addressId;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final TextEditingController _recipient = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _street = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _province = TextEditingController();
  final TextEditingController _postal = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String _label = addressLabels.first;
  bool _makePrimary = false;
  bool _filled = false;
  bool _submitted = false;
  Map<AddressField, String> _errors = const <AddressField, String>{};

  bool get _editing => widget.addressId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final services = AppScope.of(context);
    final existing = services.addresses.byId(widget.addressId);
    if (existing != null) {
      final draft = existing.toDraft();
      _label = draft.label;
      _recipient.text = draft.recipient;
      _phone.text = draft.phone;
      _street.text = draft.street;
      _district.text = draft.district;
      _city.text = draft.city;
      _province.text = draft.province;
      _postal.text = draft.postalCode;
      _note.text = draft.note;
      _makePrimary = existing.isPrimary;
      return;
    }
    final profile = services.auth.profile;
    _recipient.text = profile?.name ?? '';
    _phone.text = profile?.phoneLabel ?? '';
    _makePrimary = services.addresses.isEmpty;
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _recipient,
      _phone,
      _street,
      _district,
      _city,
      _province,
      _postal,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  AddressDraft get _draft => AddressDraft(
    label: _label,
    recipient: _recipient.text,
    phone: _phone.text,
    street: _street.text,
    district: _district.text,
    city: _city.text,
    province: _province.text,
    postalCode: _postal.text,
    note: _note.text,
  );

  void _revalidate() {
    if (_submitted) setState(() => _errors = _draft.validate());
  }

  void _save() {
    final services = AppScope.of(context);
    final repository = services.addresses;
    final draft = _draft;
    final errors = draft.validate();
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.isNotEmpty) {
      services.haptics.light();
      showAppSnack(context, 'Periksa lagi isian yang ditandai merah, Babes.');
      return;
    }
    final id = widget.addressId;
    if (id == null) {
      repository.add(draft, makePrimary: _makePrimary);
    } else {
      repository.update(id, draft);
      if (_makePrimary) repository.setPrimary(id);
    }
    services.haptics.success();
    showAppSnack(
      context,
      _editing ? 'Alamat diperbarui.' : 'Alamat tersimpan.',
    );
    services.router.back(context);
  }

  Future<void> _delete() async {
    final services = AppScope.of(context);
    final id = widget.addressId;
    if (id == null) return;
    final address = services.addresses.byId(id);
    if (address == null) return;
    final deleted = await deleteAddressWithConfirm(context, address);
    if (deleted && mounted) services.router.back(context);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    final missing =
        _editing && services.addresses.byId(widget.addressId) == null;
    if (missing) {
      return Scaffold(
        backgroundColor: c.surface,
        appBar: const BpAppBar(title: 'Ubah alamat'),
        body: Center(
          child: SingleChildScrollView(
            child: EmptyState(
              imageAsset: 'assets/bipy/bipy_ngintip.webp',
              title: 'Alamat tidak ditemukan',
              message: 'Alamat ini mungkin sudah dihapus.',
              actionLabel: 'Kembali ke buku alamat',
              onAction: () => services.router.back(context),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: BpAppBar(
        title: _editing ? 'Ubah alamat' : 'Tambah alamat',
        actions: <Widget>[
          if (_editing)
            IconButton(
              tooltip: 'Hapus alamat',
              icon: Icon(LucideIcons.trash2, color: c.danger),
              onPressed: _delete,
            ),
        ],
      ),
      bottomNavigationBar: StickyBottomBar(
        child: PillButton(
          label: 'Simpan alamat',
          expand: true,
          onPressed: _save,
        ),
      ),
      body: ListView(
        children: <Widget>[
          Section(
            header: const SectionHeader(title: 'Label alamat'),
            inset: true,
            padding: const EdgeInsets.only(bottom: BpSpace.x4),
            child: Wrap(
              spacing: BpSpace.x2,
              runSpacing: BpSpace.x2,
              children: <Widget>[
                for (final label in addressLabels)
                  BpChip(
                    label: label,
                    selected: _label == label,
                    onTap: () => setState(() => _label = label),
                  ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Penerima'),
            inset: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                LabeledField(
                  fieldKey: const ValueKey<String>('address-recipient'),
                  label: 'Nama penerima',
                  controller: _recipient,
                  textInputAction: TextInputAction.next,
                  errorText: _errors[AddressField.recipient],
                  onChanged: (_) => _revalidate(),
                ),
                const SizedBox(height: BpSpace.x4),
                LabeledField(
                  fieldKey: const ValueKey<String>('address-phone'),
                  label: 'Nomor HP',
                  controller: _phone,
                  hint: '0812 3456 7890',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                  ],
                  maxLength: 18,
                  errorText: _errors[AddressField.phone],
                  onChanged: (_) => _revalidate(),
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Alamat'),
            inset: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                LabeledField(
                  fieldKey: const ValueKey<String>('address-street'),
                  label: 'Alamat lengkap',
                  controller: _street,
                  hint: 'Nama jalan, nomor rumah, RT/RW',
                  maxLines: 3,
                  maxLength: 200,
                  showCounter: true,
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _errors[AddressField.street],
                  onChanged: (_) => _revalidate(),
                ),
                const SizedBox(height: BpSpace.x4),
                LabeledField(
                  fieldKey: const ValueKey<String>('address-district'),
                  label: 'Kecamatan',
                  controller: _district,
                  hint: 'Contoh: Kebayoran Baru',
                  textInputAction: TextInputAction.next,
                  errorText: _errors[AddressField.district],
                  onChanged: (_) => _revalidate(),
                ),
                const SizedBox(height: BpSpace.x4),
                LabeledField(
                  fieldKey: const ValueKey<String>('address-city'),
                  label: 'Kota atau kabupaten',
                  controller: _city,
                  hint: 'Contoh: Jakarta Selatan',
                  textInputAction: TextInputAction.next,
                  errorText: _errors[AddressField.city],
                  onChanged: (_) => _revalidate(),
                ),
                const SizedBox(height: BpSpace.x4),
                LabeledField(
                  fieldKey: const ValueKey<String>('address-province'),
                  label: 'Provinsi',
                  controller: _province,
                  hint: 'Contoh: DKI Jakarta',
                  textInputAction: TextInputAction.next,
                  errorText: _errors[AddressField.province],
                  onChanged: (_) => _revalidate(),
                ),
                const SizedBox(height: BpSpace.x4),
                LabeledField(
                  fieldKey: const ValueKey<String>('address-postal'),
                  label: 'Kode pos',
                  controller: _postal,
                  hint: '5 angka',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 5,
                  errorText: _errors[AddressField.postalCode],
                  onChanged: (_) => _revalidate(),
                ),
                const SizedBox(height: BpSpace.x4),
                LabeledField(
                  fieldKey: const ValueKey<String>('address-note'),
                  label: 'Catatan untuk kurir',
                  optional: true,
                  controller: _note,
                  hint: 'Contoh: pagar hitam, dekat masjid',
                  maxLength: 120,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          Section(
            padding: const EdgeInsets.symmetric(vertical: BpSpace.x1),
            child: BpSwitchTile(
              title: 'Jadikan alamat utama',
              subtitle: 'Dipakai otomatis saat checkout.',
              value: _makePrimary,
              onChanged:
                  _editing &&
                      (services.addresses.byId(widget.addressId)?.isPrimary ??
                          false)
                  ? null
                  : (value) => setState(() => _makePrimary = value),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              BpSpace.screen,
              0,
              BpSpace.screen,
              BpSpace.x4,
            ),
            child: NoteBox(
              icon: LucideIcons.map,
              message:
                  'Demo: titik lokasi di peta belum tersedia. Di app Bpedia, '
                  'pin lokasi membantu kurir menemukan alamatmu.',
            ),
          ),
        ],
      ),
    );
  }
}
