/// Lembar pilih voucher dan lembar pilih metode pembayaran.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/payment/payment_catalog.dart';
import '../../../data/rewards/rewards_gateway.dart';
import '../../../design/design.dart';
import 'payment_summary.dart';

/// Hasil lembar voucher: [voucherId] null = tanpa voucher.
final class VoucherChoice {
  const VoucherChoice(this.voucherId);

  final String? voucherId;
}

/// Voucher sah dengan potongan terbesar; null bila tidak ada.
VoucherOption? bestUsableVoucher(List<VoucherOption> vouchers) {
  VoucherOption? best;
  for (final option in vouchers) {
    if (!option.usable) continue;
    if (best == null || option.amount > best.amount) best = option;
  }
  return best;
}

/// Mencari voucher dari kode yang diketik: cocok dengan ID atau judul,
/// tanpa membedakan huruf besar-kecil dan spasi di tepi.
VoucherOption? voucherByCode(List<VoucherOption> vouchers, String code) {
  final wanted = code.trim().toLowerCase();
  if (wanted.isEmpty) return null;
  for (final option in vouchers) {
    if (option.id.toLowerCase() == wanted ||
        option.title.toLowerCase() == wanted) {
      return option;
    }
  }
  return null;
}

/// Lembar pilih voucher: kolom kode, tiket voucher (yang belum memenuhi
/// syarat redup beserta alasannya dan masa berlaku), dan kaki ringkasan
/// "1 voucher dipakai · Hemat RpX" + "Pakai". Null bila ditutup tanpa memilih.
Future<VoucherChoice?> showVoucherSheet(
  BuildContext context, {
  required List<VoucherOption> vouchers,
  required String? selectedId,
}) {
  return showBpSheet<VoucherChoice>(
    context: context,
    builder: (context) =>
        _VoucherSheet(vouchers: vouchers, initialId: selectedId),
  );
}

class _VoucherSheet extends StatefulWidget {
  const _VoucherSheet({required this.vouchers, required this.initialId});

  final List<VoucherOption> vouchers;
  final String? initialId;

  @override
  State<_VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends State<_VoucherSheet> {
  final TextEditingController _code = TextEditingController();
  late String? _selectedId = widget.initialId;
  String? _codeError;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  VoucherOption? get _selected {
    for (final option in widget.vouchers) {
      if (option.id == _selectedId && option.usable) return option;
    }
    return null;
  }

  void _toggle(VoucherOption voucher) {
    setState(() {
      _selectedId = _selectedId == voucher.id ? null : voucher.id;
      _codeError = null;
    });
  }

  void _applyCode() {
    final code = _code.text.trim();
    final String? error;
    if (code.isEmpty) {
      error = 'Masukkan kode voucher dulu.';
    } else {
      final match = voucherByCode(widget.vouchers, code);
      if (match == null) {
        error = 'Kode "$code" tidak dikenal. Periksa lagi penulisannya.';
      } else if (!match.usable) {
        error = match.reason ?? 'Voucher ini belum bisa dipakai.';
      } else {
        error = null;
        _selectedId = match.id;
        FocusScope.of(context).unfocus();
      }
    }
    setState(() => _codeError = error);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final vouchers = widget.vouchers;
    final usable = vouchers.where((v) => v.usable).toList();
    final locked = vouchers.where((v) => !v.usable).toList();
    final chosen = _selected;
    return BpSheet(
      title: 'Pilih voucher',
      footer: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    chosen == null
                        ? 'Belum ada voucher dipilih'
                        : '1 voucher dipakai',
                    style: BpText.caption.copyWith(color: c.textMuted),
                  ),
                  if (chosen != null)
                    Text(
                      'Hemat ${formatRupiah(chosen.amount)}',
                      style: BpText.subtitle.copyWith(
                        color: c.success,
                        fontFeatures: BpText.tabular,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: BpSpace.x3),
          PillButton(
            key: const ValueKey<String>('voucher-konfirmasi'),
            label: chosen == null ? 'Tanpa voucher' : 'Pakai',
            variant: chosen == null
                ? PillButtonVariant.outline
                : PillButtonVariant.filled,
            onPressed: () =>
                Navigator.of(context).pop(VoucherChoice(chosen?.id)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('voucher-kode'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _applyCode(),
                  onChanged: (_) {
                    if (_codeError != null) setState(() => _codeError = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'Masukkan kode voucher',
                    errorText: _codeError,
                    errorMaxLines: 2,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(BpSpace.x3),
                      child: BrandIcon(
                        BrandGlyph.voucher,
                        size: BpSize.iconDense,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: BpSpace.x2),
              PillButton(
                key: const ValueKey<String>('voucher-pakai-kode'),
                label: 'Pakai',
                variant: PillButtonVariant.outline,
                onPressed: _applyCode,
              ),
            ],
          ),
          const SizedBox(height: BpSpace.x3),
          if (vouchers.isEmpty)
            const EmptyState(
              compact: true,
              imageAsset: 'assets/icons3d/voucher.webp',
              imageSize: 88,
              title: 'Belum ada voucher',
              message:
                  'Selesaikan Misi Belanja atau klaim voucher di Event Promo.',
            )
          else
            for (final voucher in <VoucherOption>[...usable, ...locked])
              Padding(
                padding: const EdgeInsets.only(bottom: BpSpace.x2),
                child: VoucherTicket(
                  key: ValueKey<String>('voucher-${voucher.id}'),
                  valueLabel: formatRupiah(voucher.amount),
                  title: voucher.title,
                  condition: voucher.usable
                      ? 'Min. belanja ${formatRupiah(voucher.minSpend)}'
                      : 'Min. belanja ${formatRupiah(voucher.minSpend)}\n'
                            '${voucher.expiresLabel}',
                  expiry: voucher.expiresLabel,
                  muted: !voucher.usable,
                  reason: voucher.reason,
                  selected: voucher.id == _selectedId,
                  actionLabel: voucher.usable
                      ? (voucher.id == _selectedId ? 'Dipakai' : 'Pakai')
                      : null,
                  onAction: voucher.usable ? () => _toggle(voucher) : null,
                ),
              ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(LucideIcons.info, size: 16, color: c.textMuted),
              ),
              const SizedBox(width: BpSpace.x2),
              Expanded(
                child: Text(
                  'Satu voucher per pesanan. Syarat minimum dihitung dari '
                  'subtotal produk sebelum potongan Kelopak.',
                  style: BpText.caption.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lembar pilih metode pembayaran (semua simulasi), dikelompokkan per jenis.
/// Dengan [kind], hanya metode jenis itu (mis. daftar bank virtual account).
Future<String?> showPaymentMethodSheet(
  BuildContext context, {
  required String selectedId,
  PaymentKind? kind,
}) {
  return showBpSheet<String>(
    context: context,
    builder: (context) {
      final c = context.bp;
      return BpSheet(
        title: kind == null ? 'Metode pembayaran' : kind.title,
        padding: const EdgeInsets.only(bottom: BpSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BpSpace.screen,
                0,
                BpSpace.screen,
                BpSpace.x2,
              ),
              child: Text(
                PaymentCatalog.demoNote,
                style: BpText.caption.copyWith(color: c.textMuted),
              ),
            ),
            for (final entry in PaymentCatalog.grouped.entries)
              if (kind == null || entry.key == kind) ...<Widget>[
                if (kind == null && entry.value.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BpSpace.screen,
                      BpSpace.x3,
                      BpSpace.screen,
                      BpSpace.x1,
                    ),
                    child: Text(
                      entry.key.title,
                      style: BpText.label.copyWith(color: c.textMuted),
                    ),
                  ),
                for (final method in entry.value)
                  ChoiceTile(
                    title: method.name,
                    selected: method.id == selectedId,
                    leading: PaymentMethodBadge(kind: method.kind),
                    onTap: () => Navigator.of(context).pop(method.id),
                  ),
              ],
          ],
        ),
      );
    },
  );
}

/// Ikon garis untuk jenis pembayaran.
IconData paymentKindIcon(PaymentKind kind) => switch (kind) {
  PaymentKind.qris => LucideIcons.qrCode,
  PaymentKind.virtualAccount => LucideIcons.creditCard,
  PaymentKind.retail => LucideIcons.store,
  PaymentKind.ewallet => LucideIcons.wallet,
  PaymentKind.cod => LucideIcons.banknote,
};

/// Lencana jenis pembayaran: kotak kecil berisi singkatan.
class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({super.key, required this.kind});

  final PaymentKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final text = switch (kind) {
      PaymentKind.qris => 'QRIS',
      PaymentKind.virtualAccount => 'VA',
      PaymentKind.retail => 'Gerai',
      PaymentKind.ewallet => 'Dompet',
      PaymentKind.cod => 'COD',
    };
    return Container(
      width: 52,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BpRadius.badgeAll,
        border: Border.all(color: c.line),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            text,
            style: BpText.label.copyWith(
              color: c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
