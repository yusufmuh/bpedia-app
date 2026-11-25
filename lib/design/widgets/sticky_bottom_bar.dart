import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens.dart';
import 'pill_button.dart';

/// Bar aksi yang menempel di bawah layar (detail produk, keranjang,
/// checkout): `surface`, garis atas, bayangan tipis, dan area aman bawah.
class StickyBottomBar extends StatelessWidget {
  const StickyBottomBar({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(
      BpSpace.screen,
      BpSpace.x2,
      BpSpace.screen,
      BpSpace.x2,
    ),
  });

  /// Pola keranjang dan checkout: total di kiri, tombol pil di kanan.
  factory StickyBottomBar.total({
    Key? key,
    required int total,
    required String actionLabel,
    required VoidCallback? onAction,
    String label = 'Total',
    String? caption,
    Widget? leading,
    Widget? header,
    bool busy = false,
  }) {
    return StickyBottomBar(
      key: key,
      header: header,
      child: _TotalRow(
        total: total,
        label: label,
        caption: caption,
        leading: leading,
        actionLabel: actionLabel,
        onAction: onAction,
        busy: busy,
      ),
    );
  }

  final Widget child;

  /// Strip di atas baris aksi (mis. ringkasan penghematan atau pengingat).
  final Widget? header;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final head = header;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
        boxShadow: BpShadows.stickyBar(c),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ?head,
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.total,
    required this.label,
    required this.caption,
    required this.leading,
    required this.actionLabel,
    required this.onAction,
    required this.busy,
  });

  final int total;
  final String label;
  final String? caption;
  final Widget? leading;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final note = caption;
    final lead = leading;
    return Row(
      children: <Widget>[
        if (lead != null) ...<Widget>[lead, const SizedBox(width: BpSpace.x2)],
        Expanded(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: '$label ${formatRupiah(total)}',
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: BpText.caption.copyWith(color: c.textMuted)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    formatRupiah(total),
                    maxLines: 1,
                    style: BpText.titleL.copyWith(
                      fontSize: 18,
                      height: 24 / 18,
                      color: c.text,
                      fontFeatures: BpText.tabular,
                    ),
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: BpText.label.copyWith(
                      color: c.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: BpSpace.x3),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.52,
          ),
          child: PillButton(
            label: actionLabel,
            onPressed: onAction,
            busy: busy,
          ),
        ),
      ],
    );
  }
}
