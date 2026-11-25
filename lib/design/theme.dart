import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// `context.bp` → token warna tema aktif.
extension BpThemeContext on BuildContext {
  BpColors get bp =>
      Theme.of(this).extension<BpColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? BpColors.dark
          : BpColors.light);
}

/// Tema Material 3 Bpedia: kanvas netral, pink sebagai sinyal.
abstract final class BpTheme {
  static ThemeData light() => _build(BpColors.light);

  static ThemeData dark() => _build(BpColors.dark);

  static ThemeData _build(BpColors c) {
    final scheme = _scheme(c);
    final textTheme = _textTheme(c);
    const pill = StadiumBorder();
    final fieldBorder = OutlineInputBorder(
      borderRadius: BpRadius.tileAll,
      borderSide: BorderSide(color: c.line),
    );
    final disabledFill = c.isDark ? c.surfaceMuted : c.line;

    WidgetStateProperty<Color?> overlay(Color base) {
      return WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return base.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return base.withValues(alpha: 0.08);
        }
        return null;
      });
    }

    ButtonStyle buttonBase({
      required Color foreground,
      Color? background,
      BorderSide? side,
    }) {
      return ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(64, BpSize.buttonLarge),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: BpSpace.x5, vertical: 10),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(pill),
        textStyle: const WidgetStatePropertyAll<TextStyle>(BpText.button),
        elevation: const WidgetStatePropertyAll<double>(0),
        shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? c.textFaint
              : foreground;
        }),
        iconColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? c.textFaint
              : foreground;
        }),
        backgroundColor: background == null
            ? const WidgetStatePropertyAll<Color>(Colors.transparent)
            : WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.disabled)
                    ? disabledFill
                    : background;
              }),
        side: side == null
            ? null
            : WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.disabled)
                    ? BorderSide(color: c.line)
                    : side;
              }),
        overlayColor: overlay(foreground),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[c],
      fontFamily: BpText.family,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.surface,
      dividerColor: c.line,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: c.text.withValues(alpha: 0.06),
      hoverColor: c.text.withValues(alpha: 0.04),
      focusColor: c.brand.withValues(alpha: 0.12),
      disabledColor: c.textFaint,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: IconThemeData(color: c.text, size: BpSize.icon),
      primaryIconTheme: IconThemeData(color: c.text, size: BpSize.icon),
      appBarTheme: AppBarThemeData(
        backgroundColor: c.surface,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: BpSpace.x1,
        toolbarHeight: BpSize.appBar,
        titleTextStyle: BpText.appBarTitle.copyWith(color: c.text),
        iconTheme: IconThemeData(color: c.text, size: BpSize.icon),
        actionsIconTheme: IconThemeData(color: c.text, size: BpSize.icon),
        systemOverlayStyle: c.isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: c.surface,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: c.surface,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: buttonBase(foreground: c.onBrand, background: c.brand),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttonBase(foreground: c.brandStrong, background: c.brandTint),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonBase(
          foreground: c.brandStrong,
          side: BorderSide(color: c.brand),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: buttonBase(foreground: c.brandStrong).copyWith(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(BpSize.touch, BpSize.touch),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: BpSpace.x3, vertical: BpSpace.x2),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(BpSize.touch, BpSize.touch),
          ),
          iconSize: const WidgetStatePropertyAll<double>(BpSize.icon),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled) ? c.textFaint : c.text;
          }),
          overlayColor: overlay(c.text),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        elevation: 2,
        highlightElevation: 2,
        shape: const CircleBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll<TextStyle>(BpText.subtitle),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? c.brandStrong
                : c.textMuted;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? c.brandTint
                : c.surface;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color: states.contains(WidgetState.selected)
                  ? c.brandLine
                  : c.line,
            );
          }),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(BpSize.touch, BpSize.buttonSmall),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: BpText.body.copyWith(color: c.textMuted),
        labelStyle: BpText.body.copyWith(color: c.textMuted),
        floatingLabelStyle: BpText.body.copyWith(color: c.brandStrong),
        helperStyle: BpText.caption.copyWith(color: c.textMuted),
        errorStyle: BpText.caption.copyWith(color: c.danger),
        helperMaxLines: 3,
        errorMaxLines: 3,
        prefixIconColor: c.textMuted,
        suffixIconColor: c.textMuted,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.brand, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.brand,
        selectionColor: c.brand.withValues(alpha: 0.24),
        selectionHandleColor: c.brand,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.brandTint,
        disabledColor: c.surfaceMuted,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        side: BorderSide(color: c.line),
        shape: pill,
        showCheckmark: false,
        labelStyle: BpText.bodyS.copyWith(color: c.text),
        secondaryLabelStyle: BpText.bodyS.copyWith(
          color: c.brandStrong,
          fontWeight: FontWeight.w600,
        ),
        deleteIconColor: c.textMuted,
        iconTheme: IconThemeData(color: c.textMuted, size: 18),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BpRadius.cardAll,
          side: BorderSide(color: c.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.text,
        textColor: c.text,
        titleTextStyle: BpText.body.copyWith(color: c.text),
        subtitleTextStyle: BpText.caption.copyWith(color: c.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
        horizontalTitleGap: BpSpace.x3,
        minVerticalPadding: BpSpace.x3,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: c.text,
        collapsedIconColor: c.textMuted,
        textColor: c.text,
        collapsedTextColor: c.text,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: BpSpace.screen),
        childrenPadding: const EdgeInsets.fromLTRB(
          BpSpace.screen,
          0,
          BpSpace.screen,
          BpSpace.x4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: const Color(0x8A000000),
        clipBehavior: Clip.antiAlias,
        showDragHandle: false,
        dragHandleColor: c.line,
        shape: const RoundedRectangleBorder(borderRadius: BpRadius.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: c.isDark ? 0 : 6,
        barrierColor: const Color(0x8A000000),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: BpSpace.x6,
          vertical: BpSpace.x6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BpRadius.dialog),
          side: c.isDark ? BorderSide(color: c.line) : BorderSide.none,
        ),
        titleTextStyle: BpText.titleL.copyWith(color: c.text),
        contentTextStyle: BpText.body.copyWith(color: c.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.isDark ? c.surfaceRaised : c.text,
        contentTextStyle: BpText.body.copyWith(
          color: c.isDark ? c.text : c.surface,
        ),
        actionTextColor: c.isDark ? c.brandStrong : BpFest.festTop,
        elevation: c.isDark ? 0 : 4,
        insetPadding: const EdgeInsets.fromLTRB(
          BpSpace.screen,
          0,
          BpSpace.screen,
          BpSpace.x3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BpRadius.cardAll,
          side: c.isDark ? BorderSide(color: c.line) : BorderSide.none,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: c.isDark ? 0 : 4,
        textStyle: BpText.body.copyWith(color: c.text),
        shape: RoundedRectangleBorder(
          borderRadius: BpRadius.cardAll,
          side: BorderSide(color: c.line),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 600),
        textStyle: BpText.caption.copyWith(
          color: c.isDark ? c.canvas : c.surface,
        ),
        decoration: BoxDecoration(
          color: c.isDark ? c.text : const Color(0xE61F1A1D),
          borderRadius: BpRadius.badgeAll,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.sale,
        textColor: c.onSale,
        textStyle: BpText.label,
        smallSize: 8,
        largeSize: 16,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: c.brandTint,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return BpText.label.copyWith(
            color: states.contains(WidgetState.selected)
                ? c.brandStrong
                : c.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: BpSize.icon,
            color: states.contains(WidgetState.selected)
                ? c.brandStrong
                : c.textMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: c.surface,
        elevation: 0,
        selectedItemColor: c.brandStrong,
        unselectedItemColor: c.textMuted,
        selectedLabelStyle: BpText.label,
        unselectedLabelStyle: BpText.label,
        showUnselectedLabels: true,
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.brandStrong,
        unselectedLabelColor: c.textMuted,
        labelStyle: BpText.subtitle,
        unselectedLabelStyle: BpText.body,
        indicatorColor: c.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.line,
        dividerHeight: 1,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: BpSpace.x3),
        overlayColor: overlay(c.text),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return c.textFaint;
          return states.contains(WidgetState.selected) ? c.onBrand : c.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledFill;
          return states.contains(WidgetState.selected) ? c.brand : c.textFaint;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        overlayColor: overlay(c.brand),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledFill;
          return states.contains(WidgetState.selected)
              ? c.brand
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll<Color>(c.onBrand),
        side: BorderSide(color: c.textFaint, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        overlayColor: overlay(c.brand),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return c.textFaint;
          return states.contains(WidgetState.selected) ? c.brand : c.textFaint;
        }),
        overlayColor: overlay(c.brand),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.brand,
        linearTrackColor: c.surfaceMuted,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
        borderRadius: BpRadius.pillAll,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.brand,
        inactiveTrackColor: c.surfaceMuted,
        thumbColor: c.brand,
        overlayColor: c.brand.withValues(alpha: 0.12),
      ),
    );
  }

  static ColorScheme _scheme(BpColors c) {
    return ColorScheme(
      brightness: c.brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      primaryContainer: c.brandTint,
      onPrimaryContainer: c.brandStrong,
      secondary: c.brandStrong,
      onSecondary: c.isDark ? c.onBrand : c.surface,
      secondaryContainer: c.brandTint,
      onSecondaryContainer: c.brandStrong,
      tertiary: c.onGoldTint,
      onTertiary: c.isDark ? c.goldTint : c.surface,
      tertiaryContainer: c.goldTint,
      onTertiaryContainer: c.onGoldTint,
      error: c.danger,
      onError: c.isDark ? c.dangerTint : c.surface,
      errorContainer: c.dangerTint,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceDim: c.canvas,
      surfaceBright: c.surfaceRaised,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surfaceMuted,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.textFaint,
      outlineVariant: c.line,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: c.isDark ? c.text : const Color(0xFF1F1A1D),
      onInverseSurface: c.isDark ? c.canvas : const Color(0xFFFFFFFF),
      inversePrimary: c.isDark ? BpColors.light.brand : BpColors.dark.brand,
      surfaceTint: Colors.transparent,
    );
  }

  static TextTheme _textTheme(BpColors c) {
    TextStyle on(TextStyle style, [Color? color]) =>
        style.copyWith(color: color ?? c.text);
    return TextTheme(
      displayLarge: on(BpText.display),
      displayMedium: on(BpText.display),
      displaySmall: on(BpText.display),
      headlineLarge: on(BpText.display),
      headlineMedium: on(BpText.titleL),
      headlineSmall: on(BpText.titleL),
      titleLarge: on(BpText.titleL),
      titleMedium: on(BpText.title),
      titleSmall: on(BpText.subtitle),
      bodyLarge: on(BpText.body),
      bodyMedium: on(BpText.body),
      bodySmall: on(BpText.caption, c.textMuted),
      labelLarge: on(BpText.button),
      labelMedium: on(BpText.caption.copyWith(fontWeight: FontWeight.w500)),
      labelSmall: on(BpText.label),
    );
  }
}
