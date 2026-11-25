/// Potongan tampilan yang dipakai bersama layar akun (F3): kolom isian
/// berlabel, catatan demo, kelompok menu, gelembung ikon, dialog konfirmasi,
/// dan pesan singkat.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';

/// Menampilkan pesan singkat di bawah layar, menggantikan pesan sebelumnya.
void showAppSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Dialog konfirmasi dua tombol. Mengembalikan true bila [confirmLabel]
/// dipilih.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final c = context.bp;
      return AlertDialog(
        title: Text(title, style: BpText.title.copyWith(color: c.text)),
        content: SingleChildScrollView(
          child: Text(message, style: BpText.body.copyWith(color: c.textMuted)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          BpSpace.x4,
          0,
          BpSpace.x4,
          BpSpace.x4,
        ),
        actions: <Widget>[
          Wrap(
            alignment: WrapAlignment.end,
            spacing: BpSpace.x2,
            runSpacing: BpSpace.x2,
            children: <Widget>[
              PillButton(
                label: cancelLabel,
                variant: PillButtonVariant.neutral,
                size: PillButtonSize.small,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              _DangerAwareButton(
                label: confirmLabel,
                destructive: destructive,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _DangerAwareButton extends StatelessWidget {
  const _DangerAwareButton({
    required this.label,
    required this.destructive,
    required this.onPressed,
  });

  final String label;
  final bool destructive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = PillButton(
      label: label,
      size: PillButtonSize.small,
      onPressed: onPressed,
    );
    if (!destructive) return button;
    final c = context.bp;
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          c.copyWith(brand: c.danger, onBrand: c.isDark ? c.canvas : c.surface),
        ],
      ),
      child: button,
    );
  }
}

/// Ikon dalam kotak bundar kecil berlatar lembut (baris menu, kotak masuk).
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    this.size = 36,
    this.background,
    this.foreground,
  });

  /// Ikon (Lucide atau `BrandIcon`).
  final Widget icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? c.surfaceMuted,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground ?? c.text, size: size * 0.56),
        child: icon,
      ),
    );
  }
}

/// Satu entri menu: ikon, label, keterangan/lencana, chevron.
class MenuEntry {
  const MenuEntry({
    required this.label,
    required this.icon,
    required this.onTap,
    this.helper,
    this.value,
    this.badgeCount = 0,
    this.showDot = false,
    this.tag,
    this.labelColor,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  /// Keterangan kecil di bawah label.
  final String? helper;

  /// Keterangan pendek rata kanan ("2 alamat", "Terang").
  final String? value;

  /// Lencana angka merah sebelum chevron.
  final int badgeCount;

  /// Titik merah sebelum chevron (diabaikan bila [badgeCount] > 0).
  final bool showDot;

  /// Lencana kecil di samping nilai, mis. `StatusChip` "Demo".
  final Widget? tag;

  /// Warna label khusus (mis. "Keluar").
  final Color? labelColor;
}

/// Kelompok menu dalam satu seksi `surface`, dipisah garis tipis.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.entries, this.title});

  final String? title;
  final List<MenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final heading = title;
    return Section(
      padding: EdgeInsets.only(
        top: heading == null ? BpSpace.x1 : 0,
        bottom: BpSpace.x1,
      ),
      header: heading == null ? null : SectionHeader(title: heading),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < entries.length; i++) ...<Widget>[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: BpSpace.screen + 36 + BpSpace.x3,
                color: c.line,
              ),
            _MenuTile(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.entry});

  final MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final value = entry.value;
    final tag = entry.tag;
    final trailingParts = <Widget>[
      ?tag,
      if (value != null)
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: BpText.bodyS.copyWith(color: c.textMuted),
          ),
        ),
      if (entry.badgeCount > 0)
        Semantics(
          label: '${entry.badgeCount} baru',
          child: CountBadge(count: entry.badgeCount),
        )
      else if (entry.showDot)
        Semantics(label: 'ada yang baru', child: const DotBadge()),
    ];
    return InfoRow(
      label: entry.label,
      helper: entry.helper,
      leading: IconBubble(icon: entry.icon, foreground: entry.labelColor),
      valueWidget: trailingParts.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < trailingParts.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: BpSpace.x2),
                  trailingParts[i],
                ],
              ],
            ),
      valueColor: entry.labelColor,
      onTap: entry.onTap,
    );
  }
}

/// Kotak keterangan kecil (catatan demo, petunjuk). [tone] memilih warna.
class NoteBox extends StatelessWidget {
  const NoteBox({
    super.key,
    required this.message,
    this.tone = StatusTone.neutral,
    this.icon,
    this.title,
  });

  final String message;
  final String? title;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final (Color background, Color foreground) = switch (tone) {
      StatusTone.gold => (c.goldTint, c.onGoldTint),
      StatusTone.brand => (c.brandTint, c.brandStrong),
      StatusTone.success => (c.successTint, c.success),
      StatusTone.warning => (c.warningTint, c.warning),
      StatusTone.danger => (c.dangerTint, c.danger),
      StatusTone.info => (c.infoTint, c.info),
      StatusTone.neutral => (c.surfaceMuted, c.textMuted),
    };
    final heading = title;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BpSpace.card),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BpRadius.cardAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon ?? LucideIcons.info, size: 18, color: foreground),
          ),
          const SizedBox(width: BpSpace.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (heading != null)
                  Text(
                    heading,
                    style: BpText.subtitle.copyWith(color: foreground),
                  ),
                Text(
                  message,
                  style: BpText.caption.copyWith(
                    color: tone == StatusTone.neutral ? c.textMuted : c.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolom isian dengan label di atas (pola formulir marketplace).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.obscureText = false,
    this.suffix,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.optional = false,
    this.focusNode,
    this.enabled = true,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffix;
  final IconData? prefixIcon;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Menambah keterangan "(opsional)" pada label.
  final bool optional;
  final FocusNode? focusNode;
  final bool enabled;

  /// Kunci untuk `TextField` (dipakai tes).
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final icon = prefixIcon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          TextSpan(
            text: label,
            children: <InlineSpan>[
              if (optional)
                TextSpan(
                  text: ' (opsional)',
                  style: BpText.caption.copyWith(color: c.textMuted),
                ),
            ],
          ),
          style: BpText.subtitle.copyWith(color: c.text),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          enableSuggestions: !obscureText,
          autocorrect: !obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          maxLines: obscureText ? 1 : maxLines,
          minLines: 1,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: BpText.body.copyWith(color: c.text),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            helperText: helperText,
            counterText: '',
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Kolom kata sandi dengan tombol mata (tampilkan/sembunyikan).
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = 'Minimal 6 karakter',
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.fieldKey,
    this.newPassword = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;

  /// Petunjuk isi-otomatis kata sandi baru (daftar, ubah sandi).
  final bool newPassword;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: widget.label,
      controller: widget.controller,
      fieldKey: widget.fieldKey,
      hint: widget.hint,
      errorText: widget.errorText,
      obscureText: !_visible,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autofillHints: <String>[
        widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      prefixIcon: LucideIcons.lock,
      suffix: IconButton(
        tooltip: _visible ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
        onPressed: () => setState(() => _visible = !_visible),
        icon: Icon(_visible ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
      ),
    );
  }
}

/// Avatar bulat berisi inisial.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, this.size = 56});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.brandTint,
        border: Border.all(color: c.surface, width: 3),
        boxShadow: BpShadows.floating(c),
      ),
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              initials.isEmpty ? 'B' : initials,
              style: BpText.titleL.copyWith(
                color: c.brandStrong,
                fontSize: size * 0.36,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
