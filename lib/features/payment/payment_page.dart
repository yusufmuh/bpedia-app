import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../data/orders/order_repository.dart';
import '../../data/payment/payment_catalog.dart';
import '../../data/wib_dates.dart';
import '../../design/design.dart';
import '../../services/sound/sound_service.dart';
import '../cart/widgets/line_parts.dart';
import '../checkout/widgets/checkout_sheets.dart';
import '../orders/order_format.dart';
import 'widgets/qr_demo.dart';

/// `/bayar/:orderId`: pembayaran simulasi. Menampilkan total, batas bayar,
/// instruksi sesuai metode (QRIS contoh, nomor VA atau kode gerai demo), dan
/// tombol "Simulasikan pembayaran (DEMO)".
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.orders,
      builder: (context, _) {
        final c = context.bp;
        final order = services.orders.byId(widget.orderId);
        final Widget body;
        Widget? bottom;
        if (order == null) {
          body = _Notice(
            pose: 'pose_semangat',
            title: 'Pesanan tidak ditemukan',
            message: 'Nomor pesanan ${widget.orderId} tidak ada di akun ini.',
            actionLabel: 'Lihat transaksi',
            onAction: () => services.router.go(context, const OrdersRoute()),
          );
        } else if (order.status != OrderStatus.awaitingPayment) {
          body = _Notice(
            pose: order.status == OrderStatus.cancelled
                ? 'pose_semangat'
                : 'pose_belanja',
            title: order.status == OrderStatus.cancelled
                ? 'Pesanan sudah dibatalkan'
                : 'Pesanan ini sudah dibayar',
            message: orderStatusDescription(order),
            actionLabel: 'Lihat pesanan',
            onAction: () =>
                services.router.replace(context, OrderDetailRoute(order.id)),
          );
        } else {
          final busy = services.orders.isBusy(order.id);
          body = _PaymentBody(order: order, services: services);
          bottom = StickyBottomBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PillButton(
                  label: 'Simulasikan pembayaran (DEMO)',
                  expand: true,
                  busy: busy,
                  onPressed: () => _pay(services, order),
                ),
                PillButton(
                  label: 'Bayar nanti, lihat pesanan',
                  variant: PillButtonVariant.text,
                  size: PillButtonSize.small,
                  onPressed: () => services.router.replace(
                    context,
                    OrderDetailRoute(order.id),
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: c.canvas,
          appBar: const BpAppBar(title: 'Pembayaran'),
          body: body,
          bottomNavigationBar: bottom,
        );
      },
    );
  }

  Future<void> _pay(AppServices services, Order order) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await services.orders.pay(order.id);
    if (!mounted) return;
    if (!result.ok) {
      services.sound.play(SoundCue.softError, withHaptic: false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(result.message ?? 'Pembayaran gagal.')),
        );
      return;
    }
    services.haptics.success();
    await services.router.replace(context, OrderSuccessRoute(order.id));
  }
}

class _PaymentBody extends StatelessWidget {
  const _PaymentBody({required this.order, required this.services});

  final Order order;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final method = PaymentCatalog.byId(order.paymentMethodId);
    final payBy = order.payBy;
    final left = remainingPayLabel(order, services.clock.instant);
    return ListView(
      padding: const EdgeInsets.only(top: BpSpace.sectionGap),
      children: <Widget>[
        Section(
          inset: true,
          child: Column(
            children: <Widget>[
              Text(
                'Total pembayaran',
                style: BpText.bodyS.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 2),
              Semantics(
                label: 'Total pembayaran ${formatRupiah(order.total)}',
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatRupiah(order.total),
                    style: BpText.display.copyWith(
                      color: c.brandStrong,
                      fontFeatures: BpText.tabular,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: BpSpace.x3),
              if (payBy != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.x3,
                    vertical: BpSpace.x2,
                  ),
                  decoration: BoxDecoration(
                    color: c.warningTint,
                    borderRadius: BpRadius.tileAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(LucideIcons.clock, size: 18, color: c.warning),
                      const SizedBox(width: BpSpace.x2),
                      Flexible(
                        child: Text(
                          'Bayar sebelum ${wibDateTimeLabel(payBy)}'
                          '${left == null ? '' : ' · $left'}',
                          style: BpText.caption.copyWith(
                            color: c.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: BpSpace.x3),
              _CopyRow(label: 'Nomor pesanan', value: order.id),
            ],
          ),
        ),
        Section(
          header: SectionHeader(
            title: method?.name ?? 'Metode pembayaran',
            leading: method == null
                ? null
                : PaymentMethodBadge(kind: method.kind),
          ),
          inset: true,
          child: _Instructions(order: order, method: method),
        ),
        Section(
          header: const SectionHeader(title: 'Cara bayar'),
          inset: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final (index, step) in _steps(method).indexed)
                _Step(number: index + 1, text: step),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BpSpace.screen,
            0,
            BpSpace.screen,
            BpSpace.x6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(LucideIcons.info, size: 16, color: c.textMuted),
              const SizedBox(width: BpSpace.x2),
              Expanded(
                child: Text(
                  '${PaymentCatalog.demoNote} Tekan tombol di bawah untuk '
                  'menandai pesanan sudah dibayar.',
                  style: BpText.caption.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<String> _steps(PaymentMethod? method) {
    switch (method?.kind) {
      case PaymentKind.qris:
        return const <String>[
          'Buka aplikasi bank atau dompet digital yang mendukung QRIS.',
          'Pindai kode QR di atas, lalu periksa nama merchant dan jumlahnya.',
          'Konfirmasi pembayaran. Status pesanan berubah otomatis.',
        ];
      case PaymentKind.virtualAccount:
        return const <String>[
          'Buka m-banking atau ATM bank yang sama dengan virtual account.',
          'Pilih menu transfer ke virtual account, lalu masukkan nomornya.',
          'Pastikan jumlah sesuai, lalu konfirmasi transfer.',
        ];
      case PaymentKind.retail:
        return const <String>[
          'Datangi kasir gerai terdekat.',
          'Sebutkan pembayaran Bpedia dan tunjukkan kode pembayaran.',
          'Bayar sesuai jumlah dan simpan struknya.',
        ];
      case PaymentKind.ewallet:
      case PaymentKind.cod:
      case null:
        return <String>[
          method?.hint ?? 'Ikuti petunjuk di aplikasi pembayaranmu.',
          'Periksa jumlah pembayaran sebelum konfirmasi.',
          'Status pesanan berubah otomatis setelah pembayaran diterima.',
        ];
    }
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({required this.order, required this.method});

  final Order order;
  final PaymentMethod? method;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final kind = method?.kind;
    if (kind == PaymentKind.qris) {
      return Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(BpSpace.x4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BpRadius.cardAll,
              border: Border.all(color: c.line),
            ),
            child: QrDemo(seed: order.id, size: 184),
          ),
          const SizedBox(height: BpSpace.x2),
          Text(
            'Kode QR contoh (DEMO), tidak bisa dipindai.',
            textAlign: TextAlign.center,
            style: BpText.caption.copyWith(color: c.textMuted),
          ),
        ],
      );
    }
    if (kind == PaymentKind.virtualAccount || kind == PaymentKind.retail) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CopyRow(
            label: kind == PaymentKind.virtualAccount
                ? 'Nomor virtual account (demo)'
                : 'Kode pembayaran (demo)',
            value: demoPaymentCode(
              order.id,
              retail: kind == PaymentKind.retail,
            ),
            large: true,
          ),
          const SizedBox(height: BpSpace.x2),
          Text(
            method!.hint,
            style: BpText.caption.copyWith(color: c.textMuted),
          ),
        ],
      );
    }
    return Text(
      method?.hint ?? 'Selesaikan pembayaran di aplikasi pembayaranmu.',
      style: BpText.body.copyWith(color: c.text),
    );
  }
}

/// Nomor VA atau kode gerai contoh yang tetap untuk satu pesanan: diturunkan
/// dari angka di nomor pesanan, dikelompokkan empat-empat.
String demoPaymentCode(String orderId, {bool retail = false}) {
  final digits = orderId.replaceAll(RegExp(r'\D'), '');
  final raw = '${retail ? '77' : '8808'}$digits';
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(raw[i]);
  }
  return buffer.toString();
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    this.large = false,
  });

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      padding: const EdgeInsets.only(left: BpSpace.x3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BpRadius.tileAll,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: BpText.caption.copyWith(color: c.textMuted)),
                Text(
                  value,
                  style: (large ? BpText.title : BpText.subtitle).copyWith(
                    color: c.text,
                    fontFeatures: BpText.tabular,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Salin $label',
            icon: Icon(LucideIcons.copy, size: 18, color: c.brandStrong),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(
                ClipboardData(text: value.replaceAll(' ', '')),
              );
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('$label disalin')));
            },
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Padding(
      padding: const EdgeInsets.only(bottom: BpSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brandTint,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: BpText.label.copyWith(color: c.brandStrong),
            ),
          ),
          const SizedBox(width: BpSpace.x3),
          Expanded(
            child: Text(text, style: BpText.bodyS.copyWith(color: c.text)),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.pose,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String pose;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: EmptyState(
          illustration: FloatingBipy(pose: pose, height: 140),
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }
}
