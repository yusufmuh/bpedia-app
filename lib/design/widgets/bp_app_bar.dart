import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import '../tokens.dart';

/// App bar datar berlatar `surface` dengan garis bawah tipis.
///
/// Judul teks ([title]) atau widget ([titleWidget], mis. `SearchField`).
/// Tombol kembali muncul otomatis bila rute bisa ditutup.
class BpAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BpAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.showBack,
    this.onBack,
    this.actions = const <Widget>[],
    this.bottom,
    this.divider = true,
    this.backgroundColor,
  }) : assert(
         title == null || titleWidget == null,
         'Isi title atau titleWidget, bukan keduanya.',
       );

  final String? title;
  final Widget? titleWidget;

  /// Mengganti tombol kembali.
  final Widget? leading;

  /// `null` = ikuti rute (tampil bila bisa kembali).
  final bool? showBack;

  /// Bawaan: `Navigator.maybePop`.
  final VoidCallback? onBack;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final bool divider;
  final Color? backgroundColor;

  @override
  Size get preferredSize =>
      Size.fromHeight(BpSize.appBar + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final Widget? lead =
        leading ??
        ((showBack ?? canPop) ? BpBackButton(onPressed: onBack) : null);
    final text = title;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      leading: lead,
      leadingWidth: BpSize.touch + BpSpace.x1,
      titleSpacing: lead == null ? BpSpace.screen : 0,
      title:
          titleWidget ??
          (text == null
              ? null
              : Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
      actions: actions.isEmpty
          ? null
          : <Widget>[...actions, const SizedBox(width: BpSpace.x1)],
      bottom: bottom,
      shape: divider ? Border(bottom: BorderSide(color: c.line)) : null,
    );
  }
}

/// Tombol kembali (panah kiri Lucide, area sentuh 48).
class BpBackButton extends StatelessWidget {
  const BpBackButton({super.key, this.onPressed, this.color});

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Kembali',
      color: color,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: const Icon(LucideIcons.arrowLeft),
    );
  }
}
