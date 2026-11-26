/// Buku alamat (FITUR #16): daftar, alamat utama, ubah, tambah. Dalam mode
/// pilih (dibuka dari checkout) ketukan kartu menjadikan alamat itu alamat
/// kirim (alamat utama) lalu kembali.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/address/address_repository.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';

/// Halaman buku alamat.
class AddressBookPage extends StatelessWidget {
  const AddressBookPage({super.key, this.selecting = false});

  /// Mode pilih alamat kirim.
  final bool selecting;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final repository = services.addresses;
    final router = services.router;
    final c = context.bp;
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final addresses = repository.addresses;
        return Scaffold(
          backgroundColor: c.canvas,
          appBar: BpAppBar(
            title: selecting ? 'Pilih alamat kirim' : 'Alamat saya',
          ),
          bottomNavigationBar: addresses.isEmpty
              ? null
              : StickyBottomBar(
                  child: PillButton(
                    label: 'Tambah alamat baru',
                    icon: const Icon(LucideIcons.plus),
                    expand: true,
                    onPressed: () =>
                        router.go(context, const AddressFormRoute()),
                  ),
                ),
          body: addresses.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: EmptyState(
                      imageAsset: 'assets/bipy/bipy_pose_belanja.webp',
                      imageSize: 148,
                      title: 'Belum ada alamat',
                      message:
                          'Simpan alamat rumah atau kantor supaya checkout '
                          'lebih cepat, Babes.',
                      actionLabel: 'Tambah alamat',
                      onAction: () =>
                          router.go(context, const AddressFormRoute()),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: BpSpace.x4),
                  children: <Widget>[
                    if (selecting)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          BpSpace.screen,
                          BpSpace.x3,
                          BpSpace.screen,
                          0,
                        ),
                        child: Text(
                          'Ketuk alamat untuk dipakai sebagai alamat kirim.',
                          style: BpText.bodyS.copyWith(color: c.textMuted),
                        ),
                      ),
                    if (!selecting)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          BpSpace.screen,
                          BpSpace.x3,
                          BpSpace.screen,
                          0,
                        ),
                        child: NoteBox(
                          tone: StatusTone.info,
                          message:
                              'Alamat utama otomatis dipakai saat checkout. '
                              'Kamu tetap bisa memilih alamat lain di sana.',
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BpSpace.screen,
                        BpSpace.x4,
                        BpSpace.screen,
                        0,
                      ),
                      child: Semantics(
                        header: true,
                        child: Text(
                          '${addresses.length} alamat tersimpan',
                          style: BpText.bodyS.copyWith(
                            color: c.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    for (final address in addresses)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          BpSpace.screen,
                          BpSpace.x3,
                          BpSpace.screen,
                          0,
                        ),
                        child: AddressCard(
                          address: address,
                          selecting: selecting,
                          onTap: selecting
                              ? () => _choose(context, address)
                              : () => router.go(
                                  context,
                                  AddressFormRoute(addressId: address.id),
                                ),
                          onEdit: () => router.go(
                            context,
                            AddressFormRoute(addressId: address.id),
                          ),
                          onDelete: address.isPrimary || selecting
                              ? null
                              : () =>
                                    deleteAddressWithConfirm(context, address),
                          onMakePrimary: address.isPrimary
                              ? null
                              : () {
                                  repository.setPrimary(address.id);
                                  services.haptics.selection();
                                  showAppSnack(
                                    context,
                                    'Alamat ${address.label} jadi alamat utama.',
                                  );
                                },
                        ),
                      ),
                    if (!selecting)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          BpSpace.screen,
                          BpSpace.x4,
                          BpSpace.screen,
                          0,
                        ),
                        child: NoteBox(
                          icon: LucideIcons.mapPin,
                          message:
                              'Demo: alamat disimpan di perangkat ini saja. '
                              'Pilih titik peta belum tersedia di demo.',
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  void _choose(BuildContext context, Address address) {
    final services = AppScope.of(context);
    services.addresses.setPrimary(address.id);
    services.haptics.selection();
    showAppSnack(context, 'Dikirim ke ${address.label}, ${address.recipient}.');
    services.router.back(context);
  }
}

/// Meminta konfirmasi lalu menghapus [address]. True bila terhapus.
Future<bool> deleteAddressWithConfirm(
  BuildContext context,
  Address address,
) async {
  final services = AppScope.of(context);
  final confirmed = await confirmAction(
    context,
    title: 'Hapus alamat ${address.label}?',
    message:
        '${address.recipient}, ${address.fullAddress} akan dihapus dari buku '
        'alamat.',
    confirmLabel: 'Hapus',
    destructive: true,
  );
  if (!confirmed || !context.mounted) return false;
  services.addresses.remove(address.id);
  showAppSnack(context, 'Alamat ${address.label} dihapus.');
  return true;
}

/// Nomor HP tersamar: "0812 **** 4417".
String maskPhoneLabel(String phoneLabel) {
  final digits = phoneLabel.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8) return phoneLabel;
  return '${digits.substring(0, 4)} **** ${digits.substring(digits.length - 4)}';
}

/// Ikon label alamat: rumah, kantor, kos, atau penanda peta.
IconData addressLabelIcon(String label) {
  final name = label.toLowerCase();
  if (name.contains('rumah')) return LucideIcons.house;
  if (name.contains('kantor')) return LucideIcons.building2;
  if (name.contains('kos') || name.contains('apartemen')) {
    return LucideIcons.bedDouble;
  }
  return LucideIcons.mapPin;
}

/// Kartu satu alamat.
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.onTap,
    required this.onEdit,
    this.onMakePrimary,
    this.onDelete,
    this.selecting = false,
  });

  final Address address;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  /// Null bila alamat tidak boleh dihapus dari kartu (alamat utama).
  final VoidCallback? onDelete;

  /// Null bila alamat sudah utama.
  final VoidCallback? onMakePrimary;
  final bool selecting;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final primary = address.isPrimary;
    final note = address.note;
    final makePrimary = onMakePrimary;
    final delete = onDelete;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BpRadius.cardAll,
        side: BorderSide(
          color: primary ? c.brandLine : c.line,
          width: primary ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.card,
            BpSpace.card,
            BpSpace.card,
            BpSpace.x2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      addressLabelIcon(address.label),
                      size: BpSize.iconDense,
                      color: primary ? c.brand : c.textMuted,
                    ),
                  ),
                  const SizedBox(width: BpSpace.x2),
                  Expanded(
                    child: Wrap(
                      spacing: BpSpace.x2,
                      runSpacing: BpSpace.x1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          address.label,
                          style: BpText.subtitle.copyWith(color: c.text),
                        ),
                        if (primary)
                          const StatusChip(
                            label: 'Utama',
                            tone: StatusTone.brand,
                          ),
                      ],
                    ),
                  ),
                  if (selecting)
                    Icon(
                      primary ? LucideIcons.circleCheck : LucideIcons.circle,
                      color: primary ? c.brand : c.textFaint,
                      semanticLabel: primary ? 'Terpilih' : 'Belum dipilih',
                    ),
                ],
              ),
              const SizedBox(height: BpSpace.x2),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${address.recipient} · '
                      '${maskPhoneLabel(address.phoneLabel)}',
                      style: BpText.bodyS.copyWith(
                        color: c.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.fullAddress,
                      style: BpText.bodyS.copyWith(color: c.textMuted),
                    ),
                    if (note.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        'Catatan: $note',
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: BpSpace.x1),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: BpSpace.x1,
                  children: <Widget>[
                    if (delete != null)
                      PillButton(
                        label: 'Hapus',
                        variant: PillButtonVariant.neutral,
                        size: PillButtonSize.small,
                        icon: Icon(LucideIcons.trash2, color: c.danger),
                        onPressed: delete,
                      ),
                    if (makePrimary != null)
                      PillButton(
                        label: 'Jadikan utama',
                        variant: PillButtonVariant.text,
                        size: PillButtonSize.small,
                        onPressed: makePrimary,
                      ),
                    PillButton(
                      label: 'Ubah',
                      variant: PillButtonVariant.text,
                      size: PillButtonSize.small,
                      icon: const Icon(LucideIcons.pencil),
                      onPressed: onEdit,
                    ),
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
