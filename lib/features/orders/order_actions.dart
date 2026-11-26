/// Aksi pesanan yang dipakai daftar dan detail pesanan: batal dengan
/// konfirmasi pengembalian, pesanan diterima (+ perayaan misi), kirim dan
/// bayar simulasi, beli lagi.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../config/app_config.dart';
import '../../app/app_scope.dart';
import '../../data/orders/order_repository.dart';
import '../../design/design.dart';
import '../../services/sound/sound_service.dart';
import '../info/info_widgets.dart' show openExternal;
import 'order_format.dart';

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _failed(BuildContext context, OrderResult result) {
  AppScope.of(context).sound.play(SoundCue.softError, withHaptic: false);
  _toast(context, result.message ?? 'Aksi gagal. Coba lagi, Babes.');
}

/// Satu butir yang kembali saat pesanan dibatalkan.
final class CancelRefundLine {
  const CancelRefundLine(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// Butir pengembalian yang berlaku untuk [order]: Kelopak, voucher, hadiah,
/// dan dana (hanya bila sudah dibayar non-COD).
List<CancelRefundLine> cancelRefundLines(Order order) {
  final voucher = order.voucherTitle;
  return <CancelRefundLine>[
    if (order.kelopakUsed > 0)
      CancelRefundLine(
        LucideIcons.refreshCw,
        '${kelopakAmountLabel(order.kelopakUsed)} kembali ke saldo',
      ),
    if (order.voucherAmount > 0)
      CancelRefundLine(
        LucideIcons.ticket,
        voucher == null
            ? 'Voucher ${formatRupiah(order.voucherAmount)} bisa dipakai lagi'
            : '$voucher bisa dipakai lagi',
      ),
    if (order.gifts.isNotEmpty)
      CancelRefundLine(
        LucideIcons.gift,
        order.gifts.length == 1
            ? 'Hadiah gratis kembali menunggu di keranjang'
            : '${order.gifts.length} hadiah gratis kembali menunggu di '
                  'keranjang',
      ),
    if (order.paidAtMs != null && !order.isCod && order.total > 0)
      CancelRefundLine(
        LucideIcons.banknote,
        'Dana ${formatRupiah(order.total)} dikembalikan (simulasi)',
      ),
  ];
}

/// Konfirmasi batal yang merinci per butir apa saja yang kembali (Kelopak,
/// voucher, hadiah, dana), lalu membatalkan pesanan.
Future<void> confirmCancelOrder(BuildContext context, Order order) async {
  final services = AppScope.of(context);
  final lines = cancelRefundLines(order);
  final confirmed = await showBpSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final c = sheetContext.bp;
      return BpSheet(
        title: 'Batalkan pesanan ini?',
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
            Text(
              lines.isEmpty
                  ? 'Pesanan #${order.id} akan dibatalkan.'
                  : 'Pesanan #${order.id} belum dikirim, jadi masih bisa '
                        'dibatalkan. Yang kembali ke akunmu:',
              style: BpText.body.copyWith(color: c.textMuted),
            ),
            if (lines.isNotEmpty) ...<Widget>[
              const SizedBox(height: BpSpace.x3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BpSpace.x3,
                  vertical: BpSpace.x2,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BpRadius.cardAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final line in lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.successTint,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                line.icon,
                                size: 18,
                                color: c.success,
                              ),
                            ),
                            const SizedBox(width: BpSpace.x3),
                            Expanded(
                              child: Text(
                                line.text,
                                style: BpText.body.copyWith(color: c.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: BpSpace.x3),
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

/// "Hubungi CS": WhatsApp Bpedia Care dengan nomor pesanan terisi.
Future<void> contactCare(BuildContext context, Order order) {
  final services = AppScope.of(context);
  return openExternal(
    context,
    () => services.links.openWhatsAppCare(
      'Halo Bpedia Care, saya butuh bantuan untuk pesanan #${order.id}.',
    ),
    fallback:
        'WhatsApp belum bisa dibuka. Hubungi ${AppConfig.whatsAppDisplay}.',
  );
}
