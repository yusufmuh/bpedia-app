import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

enum PillButtonVariant {
  /// Aksi utama: isi `brand`.
  filled,

  /// Aksi pendamping: isi `brandTint`.
  tonal,

  /// Aksi kedua di samping tombol isi: garis `brand`.
  outline,

  /// Aksi netral ("Atur ulang", "Masuk dengan Google"): garis abu.
  neutral,

  /// Aksi ringan tanpa bingkai.
  text,
}

enum PillButtonSize {
  /// Tinggi 48.
  large,

  /// Tinggi 40 (area sentuh tetap 48).
  small,
}

/// Tombol pil Bpedia.
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.filled,
    this.size = PillButtonSize.large,
    this.icon,
    this.trailing,
    this.busy = false,
    this.expand = false,
  });

  final String label;

  /// `null` menonaktifkan tombol.
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final PillButtonSize size;

  /// Ikon di kiri label; mengikuti warna dan ukuran ikon tombol.
  final Widget? icon;
  final Widget? trailing;

  /// Menampilkan pemutar dan menahan ketukan.
  final bool busy;

  /// Melebar memenuhi induk.
  final bool expand;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  final WidgetStatesController _states = WidgetStatesController();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_onStates);
  }

  void _onStates() {
    final pressed = _states.value.contains(WidgetState.pressed);
    if (pressed != _pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  void dispose() {
    _states
      ..removeListener(_onStates)
      ..dispose();
    super.dispose();
  }

  ButtonStyle _style(BpColors c) {
    final small = widget.size == PillButtonSize.small;
    final neutralLine = Color.lerp(c.line, c.textFaint, 0.45)!;
    final (
      Color background,
      Color foreground,
      BorderSide? side,
    ) = switch (widget.variant) {
      PillButtonVariant.filled => (c.brand, c.onBrand, null),
      PillButtonVariant.tonal => (c.brandTint, c.brandStrong, null),
      PillButtonVariant.outline => (
        Colors.transparent,
        c.brandStrong,
        BorderSide(color: c.brand),
      ),
      PillButtonVariant.neutral => (
        c.surface,
        c.text,
        BorderSide(color: neutralLine),
      ),
      PillButtonVariant.text => (Colors.transparent, c.brandStrong, null),
    };
    final solid =
        widget.variant == PillButtonVariant.filled ||
        widget.variant == PillButtonVariant.tonal;
    final disabledFill = c.isDark ? c.surfaceMuted : c.line;

    Color whenEnabled(Set<WidgetState> states, Color enabled, Color disabled) =>
        states.contains(WidgetState.disabled) ? disabled : enabled;

    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(64, small ? BpSize.buttonSmall : BpSize.buttonLarge),
      ),
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: widget.variant == PillButtonVariant.text
              ? BpSpace.x3
              : (small ? BpSpace.x4 : BpSpace.x5),
          vertical: small ? 8 : 10,
        ),
      ),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      textStyle: WidgetStatePropertyAll<TextStyle>(
        small ? BpText.button.copyWith(fontSize: 13) : BpText.button,
      ),
      iconSize: WidgetStatePropertyAll<double>(small ? 16 : 18),
      elevation: const WidgetStatePropertyAll<double>(0),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => whenEnabled(states, foreground, c.textFaint),
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => whenEnabled(states, foreground, c.textFaint),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            whenEnabled(states, background, solid ? disabledFill : background),
      ),
      side: side == null
          ? null
          : WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? BorderSide(color: c.line)
                  : side,
            ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return foreground.withValues(alpha: 0.08);
        }
        return null;
      }),
    );
  }

  static void _swallowTap() {}

  @override
  Widget build(BuildContext context) {
    final small = widget.size == PillButtonSize.small;
    final spinnerSize = small ? 14.0 : 16.0;
    final leading = widget.busy
        ? SizedBox.square(
            dimension: spinnerSize,
            child: Builder(
              builder: (context) => CircularProgressIndicator(
                strokeWidth: 2,
                color: IconTheme.of(context).color,
              ),
            ),
          )
        : widget.icon;
    final trailing = widget.trailing;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          leading,
          const SizedBox(width: BpSpace.x2),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: BpSpace.x1),
          trailing,
        ],
      ],
    );

    Widget button = TextButton(
      onPressed: widget.busy && widget.onPressed != null
          ? _swallowTap
          : widget.onPressed,
      statesController: _states,
      style: _style(context.bp),
      child: content,
    );
    if (widget.busy) {
      button = Semantics(
        value: 'Sedang diproses',
        child: AbsorbPointer(child: button),
      );
    }
    button = AnimatedScale(
      scale: _pressed && !BpMotion.reduced(context) ? BpMotion.pressScale : 1,
      duration: BpMotion.micro,
      curve: BpMotion.microCurve,
      child: button,
    );
    if (!widget.expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
