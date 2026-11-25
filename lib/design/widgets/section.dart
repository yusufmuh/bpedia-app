import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import '../tokens.dart';
import 'tappable.dart';

/// Blok `surface` selebar layar. Antarblok dipisah celah `canvas` 8 px,
/// bukan kartu berbayang.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.header,
    this.inset = false,
    this.gap = true,
    this.padding,
  });

  final Widget child;

  /// Biasanya [SectionHeader].
  final Widget? header;

  /// Memberi margin layar (16) kiri-kanan pada [child]. Biarkan `false`
  /// untuk rel gulir horizontal yang menyentuh tepi.
  final bool inset;

  /// Celah 8 px di bawah blok.
  final bool gap;

  /// Bawaan: 16 atas-bawah; dengan [header] bagian atas 4 karena kepala
  /// seksi sudah setinggi 48.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final head = header;
    final resolved =
        padding ??
        EdgeInsets.only(
          top: head == null ? BpSpace.section : BpSpace.x1,
          bottom: BpSpace.section,
        );
    return Padding(
      padding: EdgeInsets.only(bottom: gap ? BpSpace.sectionGap : 0),
      child: ColoredBox(
        color: context.bp.surface,
        child: Padding(
          padding: resolved,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ?head,
              if (inset)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.screen,
                  ),
                  child: child,
                )
              else
                child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Kepala seksi: judul + tautan "Lihat semua".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.titleWidget,
    this.actionLabel = 'Lihat semua',
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Ikon atau seni kecil di kiri judul.
  final Widget? leading;

  /// Mengganti teks judul (mis. seni judul "HOT ITEM"); [title] tetap
  /// dipakai pembaca layar.
  final Widget? titleWidget;
  final String actionLabel;

  /// `null` menyembunyikan tautan.
  final VoidCallback? onAction;

  /// Mengganti tautan (mis. chip status).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final sub = subtitle;
    final lead = leading;
    final action = onAction;
    final art = titleWidget;
    // Pada huruf sangat besar tautan cukup berupa chevron supaya judul tidak
    // terpenggal di tengah kata; labelnya tetap dibaca pembaca layar.
    final compactAction = MediaQuery.textScalerOf(context).scale(10) > 15;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BpSize.touch),
      child: Padding(
        padding: const EdgeInsets.only(left: BpSpace.screen),
        child: Row(
          children: <Widget>[
            if (lead != null) ...<Widget>[
              lead,
              const SizedBox(width: BpSpace.x2),
            ],
            Expanded(
              child: Semantics(
                header: true,
                label: art == null ? null : title,
                excludeSemantics: art != null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    art ??
                        Text(
                          title,
                          style: BpText.title.copyWith(color: c.text),
                        ),
                    if (sub != null)
                      Text(
                        sub,
                        style: BpText.caption.copyWith(color: c.textMuted),
                      ),
                  ],
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: BpSpace.x2,
                  right: BpSpace.screen,
                ),
                child: trailing,
              )
            else if (action != null)
              BpTappable(
                onTap: action,
                semanticLabel: '$actionLabel $title',
                builder: (context, states) => Padding(
                  padding: const EdgeInsets.only(
                    left: BpSpace.x3,
                    right: BpSpace.x3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (!compactAction)
                        Text(
                          actionLabel,
                          style: BpText.bodyS.copyWith(
                            color: c.brandStrong,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: compactAction ? 24 : 16,
                        color: c.brandStrong,
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(width: BpSpace.screen),
          ],
        ),
      ),
    );
  }
}
