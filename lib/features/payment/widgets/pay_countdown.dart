import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../data/wib_dates.dart';
import '../../../design/design.dart';

const List<String> _weekdays = <String>[
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// "Kamis, 26 Nov 2026, 10.00 WIB".
String wibDeadlineLabel(DateTime instant) {
  final weekday = dateOfWibDay(wibDayOfInstant(instant)).weekday;
  return '${_weekdays[weekday - 1]}, ${wibDateTimeLabel(instant)}';
}

/// Hitung mundur batas bayar: "Selesaikan pembayaran dalam", tiga
/// ubin jam:menit:detik, lalu "Batas …". Sisa dihitung dari jam app
/// (`services.clock`) setiap detik, bukan angka tetap.
class PayCountdown extends StatefulWidget {
  const PayCountdown({super.key, required this.payBy});

  final DateTime payBy;

  @override
  State<PayCountdown> createState() => _PayCountdownState();
}

class _PayCountdownState extends State<PayCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final now = AppScope.of(context).clock.instant;
    final raw = widget.payBy.difference(now);
    final left = raw.isNegative ? Duration.zero : raw;
    final hours = left.inHours;
    final minutes = left.inMinutes.remainder(60);
    final seconds = left.inSeconds.remainder(60);
    String two(int value) => value.toString().padLeft(2, '0');
    final expired = left == Duration.zero;
    return Column(
      children: <Widget>[
        Text(
          expired
              ? 'Batas pembayaran sudah lewat'
              : 'Selesaikan pembayaran dalam',
          textAlign: TextAlign.center,
          style: BpText.bodyS.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: BpSpace.x2),
        Semantics(
          label: 'Sisa waktu $hours jam $minutes menit $seconds detik',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Tile(value: two(hours), label: 'Jam'),
              const _Colon(),
              _Tile(value: two(minutes), label: 'Menit'),
              const _Colon(),
              _Tile(value: two(seconds), label: 'Detik'),
            ],
          ),
        ),
        const SizedBox(height: BpSpace.x2),
        Text(
          'Batas ${wibDeadlineLabel(widget.payBy)}',
          textAlign: TextAlign.center,
          style: BpText.bodyS.copyWith(
            color: c.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Column(
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.brand,
            borderRadius: BpRadius.badgeAll,
          ),
          child: Text(
            value,
            style: BpText.subtitle.copyWith(
              fontSize: 16,
              color: c.onBrand,
              fontWeight: FontWeight.w700,
              fontFeatures: BpText.tabular,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: BpText.label.copyWith(fontSize: 11, color: c.textMuted),
        ),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 32,
      child: Center(
        child: Text(
          ':',
          style: BpText.subtitle.copyWith(
            color: context.bp.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
