import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens.dart';
import 'discount_badge.dart';

enum PriceTextSize {
  /// Kartu produk dan baris keranjang ("Rp" 12 + angka 16/700).
  card,

  /// Blok harga detail produk dan total bayar (22/700).
  detail,
}

/// Harga akhir, harga coret, dan lencana diskon opsional.
class PriceText extends StatelessWidget {
  const PriceText(
    this.price, {
    super.key,
    this.strikePrice,
    this.discountPercent,
    this.size = PriceTextSize.card,
    this.stacked = false,
    this.color,
  });

  /// Harga akhir dalam rupiah.
  final int price;

  /// Harga sebelum diskon; diabaikan bila tidak lebih besar dari [price].
  final int? strikePrice;

  /// Bila diisi, lencana `-39%` tampil di samping harga coret.
  final int? discountPercent;
  final PriceTextSize size;

  /// Harga coret di baris sendiri di bawah harga (kartu produk sempit).
  final bool stacked;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final strike = strikePrice;
    final hasStrike = strike != null && strike > price;
    final percent = discountPercent;
    final detail = size == PriceTextSize.detail;

    final amountStyle = (detail ? BpText.priceL : BpText.price).copyWith(
      color: color ?? c.brandStrong,
    );
    final formatted = formatRupiah(price);
    final unitEnd = formatted.indexOf('Rp') + 2;
    final priceLabel = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: formatted.substring(0, unitEnd),
              style: TextStyle(
                fontSize: detail ? 14 : BpText.priceUnit.fontSize,
              ),
            ),
            TextSpan(text: formatted.substring(unitEnd)),
          ],
        ),
        style: amountStyle,
        maxLines: 1,
        softWrap: false,
      ),
    );
    final extras = <Widget>[
      if (hasStrike)
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            formatRupiah(strike),
            maxLines: 1,
            softWrap: false,
            style: (detail ? BpText.body : BpText.caption).copyWith(
              color: c.textFaint,
              decoration: TextDecoration.lineThrough,
              decorationColor: c.textFaint,
              fontFeatures: BpText.tabular,
            ),
          ),
        ),
      if (hasStrike && percent != null && percent > 0)
        DiscountBadge(percent: percent),
    ];

    final semantics = StringBuffer('Harga ${formatRupiah(price)}');
    if (hasStrike) {
      semantics.write(', harga sebelumnya ${formatRupiah(strike)}');
      if (percent != null && percent > 0) {
        semantics.write(', diskon $percent persen');
      }
    }

    final Widget layout;
    if (extras.isEmpty) {
      layout = priceLabel;
    } else if (stacked) {
      layout = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          priceLabel,
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: extras,
          ),
        ],
      );
    } else {
      layout = Wrap(
        spacing: BpSpace.x2,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[priceLabel, ...extras],
      );
    }
    return Semantics(
      label: semantics.toString(),
      excludeSemantics: true,
      child: layout,
    );
  }
}
