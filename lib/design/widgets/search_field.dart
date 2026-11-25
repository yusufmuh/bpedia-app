import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import '../tokens.dart';
import 'brand_icon.dart';
import 'tappable.dart';

/// Kolom cari pil berlatar `surfaceMuted`.
///
/// [SearchField] bisa diketik; [SearchField.button] hanya tampilan yang
/// membuka halaman cari saat diketuk, dengan petunjuk yang bisa bergantian.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = 'Cari di Bpedia',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.trailing,
  }) : onTap = null,
       hints = const <String>[];

  const SearchField.button({
    super.key,
    required VoidCallback this.onTap,
    this.hint = 'Cari di Bpedia',
    this.hints = const <String>[],
    this.trailing,
  }) : controller = null,
       focusNode = null,
       onChanged = null,
       onSubmitted = null,
       autofocus = false;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;

  /// Petunjuk yang bergantian tiap 3 detik (hanya [SearchField.button]).
  /// Kosong = pakai [hint].
  final List<String> hints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final VoidCallback? onTap;

  /// Widget kecil di ujung kanan (mis. ikon kamera atau filter).
  final Widget? trailing;

  static const Duration hintInterval = Duration(seconds: 3);

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;
  Timer? _hintTimer;
  int _hintIndex = 0;

  bool get _isButton => widget.onTap != null;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    if (!_isButton) {
      _controller.addListener(_refresh);
      _focusNode.addListener(_refresh);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHintTimer();
  }

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_refresh);
      if (!_isButton) _controller.addListener(_refresh);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_refresh);
      if (!_isButton) _focusNode.addListener(_refresh);
    }
    if (_hintIndex >= widget.hints.length) _hintIndex = 0;
    _syncHintTimer();
  }

  void _syncHintTimer() {
    final rotate =
        _isButton && widget.hints.length > 1 && !BpMotion.reduced(context);
    if (!rotate) {
      _hintTimer?.cancel();
      _hintTimer = null;
      return;
    }
    _hintTimer ??= Timer.periodic(SearchField.hintInterval, (_) {
      if (!mounted || widget.hints.isEmpty) return;
      setState(() => _hintIndex = (_hintIndex + 1) % widget.hints.length);
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    widget.controller?.removeListener(_refresh);
    widget.focusNode?.removeListener(_refresh);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  Widget _shell(
    BuildContext context, {
    required Widget child,
    bool focused = false,
  }) {
    final c = context.bp;
    final trailing = widget.trailing;
    return AnimatedContainer(
      duration: BpMotion.micro,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: ShapeDecoration(
        color: c.surfaceMuted,
        shape: StadiumBorder(
          side: BorderSide(
            color: focused ? c.brand : Colors.transparent,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          BrandIcon(BrandGlyph.search, size: 20, color: c.textMuted),
          const SizedBox(width: BpSpace.x2),
          Expanded(child: child),
          if (trailing != null)
            IconTheme.merge(
              data: IconThemeData(color: c.textMuted, size: 20),
              child: trailing,
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final hintStyle = BpText.body.copyWith(color: c.textMuted);

    if (_isButton) {
      final hint = widget.hints.isEmpty
          ? widget.hint
          : widget.hints[_hintIndex % widget.hints.length];
      return BpTappable(
        onTap: widget.onTap,
        semanticLabel: 'Cari produk',
        pressScale: false,
        minWidth: 0,
        builder: (context, states) => _shell(
          context,
          child: AnimatedSwitcher(
            duration: BpMotion.standard,
            switchInCurve: BpMotion.standardCurve,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[...previous, ?current],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.6),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              hint,
              key: ValueKey<String>(hint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hintStyle,
            ),
          ),
        ),
      );
    }

    final hasText = _controller.text.isNotEmpty;
    return _shell(
      context,
      focused: _focusNode.hasFocus,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              style: BpText.body.copyWith(color: c.text),
              cursorColor: c.brand,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: widget.hint,
                hintStyle: hintStyle,
              ),
            ),
          ),
          if (hasText)
            BpTappable(
              onTap: () {
                _controller.clear();
                widget.onChanged?.call('');
                _focusNode.requestFocus();
              },
              semanticLabel: 'Hapus teks pencarian',
              tooltip: 'Hapus teks',
              minWidth: 40,
              minHeight: 44,
              builder: (context, states) => DecoratedBox(
                decoration: ShapeDecoration(
                  color: c.textFaint.withValues(alpha: 0.28),
                  shape: const CircleBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(LucideIcons.x, size: 12, color: c.text),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
