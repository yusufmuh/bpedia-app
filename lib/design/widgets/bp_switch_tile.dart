import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Baris sakelar: judul, keterangan, dan sakelar di kanan. Seluruh baris
/// bisa diketuk.
class BpSwitchTile extends StatelessWidget {
  const BpSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.padding = const EdgeInsets.symmetric(
      horizontal: BpSpace.screen,
      vertical: BpSpace.x2,
    ),
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// `null` menonaktifkan.
  final ValueChanged<bool>? onChanged;

  /// Ikon 24 px di kiri judul.
  final Widget? leading;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final change = onChanged;
    final sub = subtitle;
    final lead = leading;
    final enabled = change != null;
    return MergeSemantics(
      child: InkWell(
        onTap: enabled ? () => change(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BpSize.touch),
          child: Padding(
            padding: padding,
            child: Row(
              children: <Widget>[
                if (lead != null) ...<Widget>[
                  IconTheme.merge(
                    data: IconThemeData(
                      color: enabled ? c.text : c.textFaint,
                      size: BpSize.icon,
                    ),
                    child: lead,
                  ),
                  const SizedBox(width: BpSpace.x3),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: BpText.subtitle.copyWith(
                          color: enabled ? c.text : c.textFaint,
                        ),
                      ),
                      if (sub != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            sub,
                            style: BpText.caption.copyWith(color: c.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: BpSpace.x3),
                Switch(value: value, onChanged: change),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
