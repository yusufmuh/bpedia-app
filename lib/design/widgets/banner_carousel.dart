import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'asset_picture.dart';

/// Satu banner pada [BannerCarousel].
@immutable
class BannerItem {
  const BannerItem({
    this.asset,
    this.image,
    required this.semanticLabel,
    this.onTap,
  }) : assert(
         (asset == null) != (image == null),
         'Isi tepat satu: asset atau image.',
       );

  /// Jalur aset, mis. `assets/promo/banner_1212.webp`.
  final String? asset;
  final ImageProvider? image;

  /// Dibacakan pembaca layar, mis. "Promo 12.12".
  final String semanticLabel;
  final VoidCallback? onTap;
}

/// Carousel banner Event Promo: rasio 3:1, radius 12, putar otomatis 4 detik
/// (jeda saat disentuh), titik indikator di dalam banner, dan hitungan "2/5".
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.items,
    this.aspectRatio = 3,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.margin = const EdgeInsets.symmetric(horizontal: BpSpace.screen),
    this.borderRadius = BpRadius.cardAll,
    this.showCounter = true,
    this.onPageChanged,
  });

  final List<BannerItem> items;
  final double aspectRatio;

  /// `Duration.zero` mematikan putar otomatis.
  final Duration autoPlayInterval;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final bool showCounter;
  final ValueChanged<int>? onPageChanged;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  /// Halaman awal jauh dari nol supaya bisa digeser ke kiri sejak awal.
  static const int _loopBase = 1000;

  late final PageController _controller = PageController(
    initialPage: widget.items.length > 1 ? _loopBase * widget.items.length : 0,
  );
  Timer? _timer;
  int _index = 0;
  bool _touching = false;

  bool get _loops => widget.items.length > 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _index = widget.items.isEmpty ? 0 : _index % widget.items.length;
    }
    _syncTimer();
  }

  void _syncTimer() {
    final shouldRun =
        _loops &&
        !_touching &&
        widget.autoPlayInterval > Duration.zero &&
        TickerMode.valuesOf(context).enabled;
    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(widget.autoPlayInterval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    final next = (_controller.page ?? 0).round() + 1;
    if (BpMotion.reduced(context)) {
      _controller.jumpToPage(next);
    } else {
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: BpMotion.standardCurve,
      );
    }
  }

  void _setTouching(bool value) {
    if (_touching == value) return;
    _touching = value;
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final c = context.bp;
    final count = items.length;

    return Padding(
      padding: widget.margin,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: ColoredBox(
            color: c.surfaceMuted,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Listener(
                  onPointerDown: (_) => _setTouching(true),
                  onPointerUp: (_) => _setTouching(false),
                  onPointerCancel: (_) => _setTouching(false),
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _loops ? null : 1,
                    onPageChanged: (page) {
                      final index = page % count;
                      setState(() => _index = index);
                      widget.onPageChanged?.call(index);
                    },
                    itemBuilder: (context, page) {
                      final index = page % count;
                      return _BannerSlide(
                        item: items[index],
                        position: index + 1,
                        count: count,
                      );
                    },
                  ),
                ),
                if (_loops)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: BpSpace.x2,
                    child: IgnorePointer(
                      child: _Dots(count: count, index: _index),
                    ),
                  ),
                if (_loops && widget.showCounter)
                  PositionedDirectional(
                    end: BpSpace.x2,
                    bottom: 6,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.scrim,
                            borderRadius: BpRadius.pillAll,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            child: Text(
                              '${_index + 1}/$count',
                              textScaler: TextScaler.noScaling,
                              style: BpText.label.copyWith(
                                fontSize: 10,
                                color: Colors.white,
                                fontFeatures: BpText.tabular,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({
    required this.item,
    required this.position,
    required this.count,
  });

  final BannerItem item;
  final int position;
  final int count;

  @override
  Widget build(BuildContext context) {
    final asset = item.asset;
    final picture = asset != null
        ? AssetPicture(asset, fit: BoxFit.cover)
        : AssetPicture.provider(item.image!, fit: BoxFit.cover);
    final tap = item.onTap;
    return Semantics(
      container: true,
      image: true,
      button: tap != null,
      label: '${item.semanticLabel}, banner $position dari $count',
      onTap: tap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        excludeFromSemantics: true,
        child: SizedBox.expand(child: picture),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final reduce = BpMotion.reduced(context);
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: reduce ? Duration.zero : BpMotion.standard,
              curve: BpMotion.standardCurve,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: i == index ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: i == index ? 1 : 0.6),
                borderRadius: BpRadius.pillAll,
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x33000000), blurRadius: 2),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
