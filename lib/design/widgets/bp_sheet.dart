import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import '../tokens.dart';

/// Isi lembar bawah: pegangan, judul + tombol tutup, isi yang bisa digulir,
/// dan kaki aksi opsional yang tetap terlihat.
class BpSheet extends StatelessWidget {
  const BpSheet({
    super.key,
    required this.child,
    this.title,
    this.footer,
    this.showClose = true,
    this.showHandle = true,
    this.padding = const EdgeInsets.fromLTRB(
      BpSpace.screen,
      0,
      BpSpace.screen,
      BpSpace.x4,
    ),
  });

  final String? title;
  final Widget child;

  /// Baris aksi di dasar lembar (mis. "Atur ulang" + "Terapkan").
  final Widget? footer;
  final bool showClose;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final heading = title;
    final foot = footer;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showHandle)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: BpSpace.x2),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BpRadius.pillAll,
                ),
              ),
            ),
          if (heading != null || showClose)
            Padding(
              padding: const EdgeInsets.only(
                left: BpSpace.screen,
                right: BpSpace.x1,
                top: BpSpace.x1,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: heading == null
                        ? const SizedBox.shrink()
                        : Semantics(
                            header: true,
                            child: Text(
                              heading,
                              style: BpText.title.copyWith(color: c.text),
                            ),
                          ),
                  ),
                  if (showClose)
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(LucideIcons.x),
                    )
                  else
                    const SizedBox(height: BpSize.touch),
                ],
              ),
            )
          else
            const SizedBox(height: BpSpace.x4),
          Flexible(
            child: SingleChildScrollView(padding: padding, child: child),
          ),
          if (foot != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BpSpace.screen,
                    BpSpace.x3,
                    BpSpace.screen,
                    BpSpace.x3,
                  ),
                  child: foot,
                ),
              ),
            )
          else
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

/// Membuka lembar bawah bergaya Bpedia.
///
/// [maxHeightFactor] membatasi tinggi lembar terhadap layar (lembar Filter
/// memakai 0,85). [builder] biasanya mengembalikan [BpSheet].
Future<T?> showBpSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightFactor = 0.85,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
}) {
  assert(maxHeightFactor > 0 && maxHeightFactor <= 1);
  final c = context.bp;
  final screen = MediaQuery.sizeOf(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: c.surface,
    barrierColor: c.scrim,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: BpRadius.sheetTop),
    constraints: BoxConstraints(
      maxWidth: 520,
      maxHeight: screen.height * maxHeightFactor,
    ),
    builder: builder,
  );
}
