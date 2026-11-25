/// Aksi pesanan yang dipakai daftar dan detail pesanan: batal dengan
/// konfirmasi pengembalian, pesanan diterima (+ perayaan misi), kirim dan
/// bayar simulasi, beli lagi.
library;

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/orders/order_repository.dart';
import '../../design/design.dart';
import '../../services/sound/sound_service.dart';

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _failed(BuildContext context, OrderResult result) {
  AppScope.of(context).sound.play(SoundCue.softError, withHaptic: false);
  _toast(context, result.message ?? 'Aksi gagal. Coba lagi, Babes.');
}

/// Konfirmasi batal yang menyebut Kelopak, voucher, dan hadiah yang kembali,
/// lalu membatalkan pesanan.
Future<void> confirmCancelOrder(BuildContext context, Order order) async {
  final services = AppScope.of(context);
  final summary = services.orders.cancelSummary(order);
  final confirmed = await showBpSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final c = sheetContext.bp;
      return BpSheet(
        title: 'Batalkan pesanan?',
        footer: Row(
          children: <Widget>[
            Expanded(
              child: PillButton(
                label: 'Kembali',
                variant: PillButtonVariant.neutral,
                expand: true,
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ),
            const SizedBox(width: BpSpace.x3),
            Expanded(
              child: PillButton(
                label: 'Ya, batalkan',
                expand: true,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(summary, style: BpText.body.copyWith(color: c.text)),
            const SizedBox(height: BpSpace.x2),
            Text(
              'Pembatalan tidak bisa diurungkan. Produk tidak masuk lagi ke '
              'keranjang secara otomatis.',
              style: BpText.caption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      );
    },
  );
  if (confirmed != true || !context.mounted) return;
  final result = await services.orders.cancel(order.id);
  if (!context.mounted) return;
  if (!result.ok) {
    _failed(context, result);
    return;
  }
  services.haptics.medium();
  final cancelled = result.order!;
  final back = <String>[
    if (cancelled.kelopakUsed > 0) 'Kelopak',
    if (cancelled.voucherAmount > 0) 'voucher',
    if (cancelled.gifts.isNotEmpty) 'hadiah gratis',
  ];
  _toast(
    context,
    back.isEmpty
        ? 'Pesanan #${cancelled.id} dibatalkan.'
        : 'Pesanan dibatalkan. ${back.join(', ')} sudah kembali ke akunmu.',
  );
}

/// "Pesanan diterima": status Selesai, lalu perayaan misi bila tuntas.
Future<void> completeOrder(BuildContext context, Order order) async {
  final services = AppScope.of(context);
  final result = await services.orders.complete(order.id);
  if (!context.mounted) return;
  if (!result.ok) {
    _failed(context, result);
    return;
  }
  services.haptics.success();
  final completion = result.completion;
  final celebrate = completion?.celebrate;
  if (celebrate != null) {
    await celebrate(context);
    return;
  }
  final mission = completion?.missionMessage;
  _toast(
    context,
    mission != null && mission.isNotEmpty
        ? mission
        : 'Pesanan selesai. Terima kasih sudah belanja, Babes.',
  );
}

/// Kontrol simulasi: tandai dibayar.
Future<void> simulatePayment(BuildContext context, Order order) async {
  final services = AppScope.of(context);
  final result = await services.orders.pay(order.id);
  if (!context.mounted) return;
  if (!result.ok) {
    _failed(context, result);
    return;
  }
  services.haptics.success();
  _toast(context, 'Pembayaran diterima (DEMO). Pesanan sedang dikemas.');
}

/// Kontrol simulasi: tandai dikirim.
Future<void> simulateShipping(BuildContext context, Order order) async {
  final services = AppScope.of(context);
  final result = await services.orders.ship(order.id);
  if (!context.mounted) return;
  if (!result.ok) {
    _failed(context, result);
    return;
  }
  services.haptics.light();
  _toast(context, 'Pesanan dikirim (DEMO) dengan ${order.courierName}.');
}

/// "Beli lagi": barang pesanan masuk keranjang, lalu buka keranjang.
void buyAgain(BuildContext context, Order order) {
  final services = AppScope.of(context);
  final added = services.orders.buyAgain(order.id);
  if (added == 0) {
    _toast(context, 'Produk pesanan ini sedang tidak tersedia.');
    return;
  }
  services.haptics.light();
  services.router.go(context, const CartRoute());
}
