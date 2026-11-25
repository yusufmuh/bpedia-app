import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens.dart';
import 'brand_icon.dart';
import 'tappable.dart';

/// Lencana hitungan merah berbentuk pil (`7`, `99+`) dengan cincin `surface`
/// supaya terpisah dari ikon di bawahnya.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, this.ringColor});

  final int count;

  /// Bawaan: `surface`.
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.sale,
          borderRadius: BpRadius.pillAll,
          border: Border.all(color: ringColor ?? c.surface, width: 1.5),
        ),
        child: Text(
          formatBadgeCount(count),
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: BpText.label.copyWith(
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: c.onSale,
            fontFeatures: BpText.tabular,
          ),
        ),
      ),
    );
  }
}

/// Titik merah penanda "ada yang baru / bisa diklaim".
class DotBadge extends StatelessWidget {
  const DotBadge({super.key, this.size = 10, this.ringColor});

  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.sale,
          shape: BoxShape.circle,
          border: Border.all(color: ringColor ?? c.surface, width: 1.5),
        ),
      ),
    );
  }
}

/// Ikon aksi 48 × 48 dengan lencana hitungan atau titik di kanan atas.
/// Lencana membal saat hitungan bertambah.
class BadgeIcon extends StatefulWidget {
  const BadgeIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.count = 0,
    this.showDot = false,
    this.countNoun = 'baru',
  });

  /// Ikon 24 px.
  final Widget icon;

  /// Nama aksi untuk tooltip dan pembaca layar, mis. "Notifikasi".
  final String label;
  final VoidCallback? onPressed;
  final int count;

  /// Titik merah tanpa angka (diabaikan bila [count] > 0).
  final bool showDot;

  /// Kata setelah angka pada label pembaca layar: "3 baru", "2 produk".
  final String countNoun;

  @override
  State<BadgeIcon> createState() => _BadgeIconState();
}

class _BadgeIconState extends State<BadgeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: BpMotion.emphasis,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(BadgeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count && !BpMotion.reduced(context)) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final count = widget.count;
    final semantic = count > 0
        ? '${widget.label}, $count ${widget.countNoun}'
        : widget.label;
    return BpTappable(
      onTap: widget.onPressed,
      semanticLabel: semantic,
      tooltip: widget.label,
      builder: (context, states) {
        return SizedBox.square(
          dimension: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              IconTheme.merge(
                data: IconThemeData(color: c.text, size: BpSize.icon),
                child: widget.icon,
              ),
              if (count > 0)
                PositionedDirectional(
                  top: 0,
                  start: 21,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.4, end: 1).animate(
                      CurvedAnimation(
                        parent: _bounce,
                        curve: BpMotion.emphasisCurve,
                      ),
                    ),
                    child: CountBadge(count: count),
                  ),
                )
              else if (widget.showDot)
                const PositionedDirectional(top: 5, end: 5, child: DotBadge()),
            ],
          ),
        );
      },
    );
  }
}

/// Ikon keranjang (tas brand) berlencana jumlah.
class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({
    super.key,
    required this.count,
    required this.onPressed,
    this.color,
  });

  final int count;
  final VoidCallback? onPressed;

  /// Warna garis ikon; bawaan `text`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return BadgeIcon(
      icon: BrandIcon(BrandGlyph.bag, color: color ?? context.bp.text),
      label: 'Keranjang',
      count: count,
      countNoun: 'produk',
      onPressed: onPressed,
    );
  }
}
