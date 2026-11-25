import 'package:flutter/material.dart';

import '../../../data/orders/order_repository.dart';
import '../../../data/wib_dates.dart';
import '../../../design/design.dart';

/// Satu langkah garis waktu.
final class TimelineStep {
  const TimelineStep({
    required this.title,
    required this.done,
    this.detail,
    this.at,
    this.danger = false,
  });

  final String title;
  final String? detail;
  final DateTime? at;
  final bool done;

  /// Langkah batal (merah).
  final bool danger;
}

/// Langkah garis waktu untuk [order] (KEPUTUSAN §6).
List<TimelineStep> timelineOf(Order order) {
  DateTime? at(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  final paidTitle =
      order.paidNote ??
      (order.isCod ? 'Bayar di tempat (COD)' : 'Pembayaran diterima');
  final steps = <TimelineStep>[
    TimelineStep(
      title: 'Pesanan dibuat',
      detail: order.paymentMethodName == null
          ? null
          : 'Metode bayar ${order.paymentMethodName}',
      at: order.placedAt,
      done: true,
    ),
  ];
  if (order.status == OrderStatus.cancelled) {
    if (order.paidAtMs != null) {
      steps.add(
        TimelineStep(title: paidTitle, at: at(order.paidAtMs), done: true),
      );
    }
    steps.add(
      TimelineStep(
        title: 'Dibatalkan',
        detail:
            order.cancelReason ??
            'Kelopak, voucher, dan hadiah dikembalikan ke akunmu.',
        at: at(order.cancelledAtMs),
        done: true,
        danger: true,
      ),
    );
    return steps;
  }
  steps
    ..add(
      TimelineStep(
        title: order.paidAtMs == null ? 'Pembayaran diterima' : paidTitle,
        detail: order.paidAtMs == null ? null : 'Pesanan dikemas penjual',
        at: at(order.paidAtMs),
        done: order.paidAtMs != null,
      ),
    )
    ..add(
      TimelineStep(
        title: 'Dikirim',
        detail: '${order.courierName} · ${order.courierEta} (demo)',
        at: at(order.shippedAtMs),
        done: order.shippedAtMs != null,
      ),
    )
    ..add(
      TimelineStep(
        title: 'Pesanan diterima',
        detail: order.gifts.isEmpty ? null : 'Hadiah gratis ikut diterima',
        at: at(order.completedAtMs),
        done: order.completedAtMs != null,
      ),
    );
  return steps;
}

/// Garis waktu status vertikal.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    var current = steps.lastIndexWhere((step) => step.done);
    if (current < 0) current = 0;
    return Column(
      children: <Widget>[
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            isCurrent: i == current,
            isLast: i == steps.length - 1,
            lineDone: i < current,
            colors: c,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isCurrent,
    required this.isLast,
    required this.lineDone,
    required this.colors,
  });

  final TimelineStep step;
  final bool isCurrent;
  final bool isLast;
  final bool lineDone;
  final BpColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final accent = step.danger ? c.danger : c.brand;
    final dotColor = step.done ? accent : c.surface;
    final at = step.at;
    final detail = step.detail;
    final titleColor = step.done
        ? (isCurrent ? (step.danger ? c.danger : c.brandStrong) : c.text)
        : c.textFaint;
    return MergeSemantics(
      child: Semantics(
        label: step.done ? 'Selesai' : 'Belum',
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 24,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 2),
                    Container(
                      width: isCurrent ? 16 : 12,
                      height: isCurrent ? 16 : 12,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.done ? accent : c.textFaint,
                          width: 2,
                        ),
                        boxShadow: isCurrent
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.25),
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: lineDone ? c.brand : c.line,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: BpSpace.x3),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : BpSpace.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.title,
                        style: BpText.subtitle.copyWith(color: titleColor),
                      ),
                      if (detail != null && detail.isNotEmpty)
                        Text(
                          detail,
                          style: BpText.caption.copyWith(color: c.textMuted),
                        ),
                      if (at != null)
                        Text(
                          wibDateTimeLabel(at),
                          style: BpText.caption.copyWith(color: c.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
