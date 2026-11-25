import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Area ketuk minimal 48 × 48 dengan umpan balik milik komponen sendiri.
///
/// Tanpa riak Material: [builder] menerima status (ditekan, fokus, hover) dan
/// menggambar tampilannya. Cincin fokus papan ketik digambar di sini.
class BpTappable extends StatefulWidget {
  const BpTappable({
    super.key,
    required this.onTap,
    required this.builder,
    this.onLongPress,
    this.minWidth = BpSize.touch,
    this.minHeight = BpSize.touch,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.tooltip,
    this.selected,
    this.focusRadius = BpRadius.pillAll,
    this.pressScale = true,
    this.isButton = true,
  });

  /// `null` menonaktifkan.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;
  final double minWidth;
  final double minHeight;
  final AlignmentGeometry alignment;

  /// Mengganti semantik anak dengan satu label tombol.
  final String? semanticLabel;
  final String? tooltip;
  final bool? selected;
  final BorderRadius focusRadius;
  final bool pressScale;
  final bool isButton;

  @override
  State<BpTappable> createState() => _BpTappableState();
}

class _BpTappableState extends State<BpTappable> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    _states.addListener(_onStates);
  }

  static const Set<WidgetState> _tracked = <WidgetState>{
    WidgetState.pressed,
    WidgetState.hovered,
    WidgetState.focused,
  };

  Set<WidgetState> _interaction = const <WidgetState>{};

  /// `InkWell` menulis status nonaktif ke pengendali saat build; hanya
  /// perubahan interaksi yang memicu gambar ulang.
  void _onStates() {
    final next = _states.value.intersection(_tracked);
    if (next.length == _interaction.length && next.containsAll(_interaction)) {
      return;
    }
    _interaction = next;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _states
      ..removeListener(_onStates)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final states = <WidgetState>{
      ..._interaction,
      if (widget.onTap == null) WidgetState.disabled,
      if (widget.selected ?? false) WidgetState.selected,
    };
    final pressed = states.contains(WidgetState.pressed);
    final focused = states.contains(WidgetState.focused);

    Widget child = widget.builder(context, states);
    if (focused) {
      child = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.focusRadius,
          border: Border.all(color: context.bp.brand, width: 2),
        ),
        child: child,
      );
    }
    if (widget.pressScale) {
      child = AnimatedScale(
        scale: pressed && !BpMotion.reduced(context) ? BpMotion.pressScale : 1,
        duration: BpMotion.micro,
        curve: BpMotion.microCurve,
        child: child,
      );
    }
    child = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.minWidth,
        minHeight: widget.minHeight,
      ),
      child: Align(
        alignment: widget.alignment,
        widthFactor: 1,
        heightFactor: 1,
        child: child,
      ),
    );
    child = InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      statesController: _states,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      excludeFromSemantics: true,
      child: child,
    );
    final label = widget.semanticLabel;
    child = Semantics(
      container: true,
      button: widget.isButton,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: label,
      excludeSemantics: label != null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: child,
    );
    final tooltip = widget.tooltip;
    if (tooltip == null) return child;
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: label != null,
      child: child,
    );
  }
}
