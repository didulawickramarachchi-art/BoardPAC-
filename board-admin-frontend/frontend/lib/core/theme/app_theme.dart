import 'package:flutter/material.dart';

/// The single source of truth for colours used throughout the admin app.
abstract final class AppColors {
  static const navy = Color(0xFF12275B);
  static const navyDark = Color(0xFF00184A);
  static const blue = Color(0xFF233E8B);
  static const gold = Color(0xFFFFB52E);

  static const background = Color(0xFFF6F7FB);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF0F3F8);
  static const border = Color(0xFFE1E6F0);
  static const text = Color(0xFF061B4E);
  static const textMuted = Color(0xFF7D8CB2);

  static const success = Color(0xFF168A45);
  static const successSurface = Color(0xFFE8F7EE);
  static const warning = Color(0xFFC88824);
  static const warningSurface = Color(0xFFFFF3DC);
  static const danger = Color(0xFFD64545);
  static const dangerSurface = Color(0xFFFFECEC);
}

class AppTheme {
  // Backwards-compatible names for screens which already consume AppTheme.
  static const Color primary = AppColors.navy;
  static const Color secondary = AppColors.gold;
  static const Color background = AppColors.background;
  static const Color card = AppColors.surface;

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.navyDark,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      outline: AppColors.border,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      // Use the bundled platform font. Runtime font downloads can stall app
      // startup and rebuilds on restricted or offline Android devices.
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
          .copyWith(
            headlineSmall: const TextStyle(
              color: AppColors.navyDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            titleLarge: const TextStyle(
              color: AppColors.navyDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            titleMedium: const TextStyle(
              color: AppColors.navyDark,
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
            bodyMedium: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.45,
            ),
            bodySmall: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
            labelMedium: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        actionsPadding: EdgeInsets.only(right: 8),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navyDark,
        elevation: 2,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.navy,
        textColor: AppColors.text,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.gold.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.gold.withValues(alpha: 0.22),
        selectedIconTheme: const IconThemeData(color: AppColors.navy),
        unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.navy,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.gold,
        dividerColor: AppColors.border,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(AppColors.surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.border),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        hintStyle: WidgetStateProperty.all(
          const TextStyle(color: AppColors.textMuted),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          AppColors.navy.withValues(alpha: 0.24),
        ),
        radius: const Radius.circular(20),
        thickness: WidgetStateProperty.all(4),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navyDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = lightTheme;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
      primary: AppColors.gold,
      onPrimary: AppColors.navyDark,
      secondary: const Color(0xFF91AFFF),
      surface: const Color(0xFF17213A),
      onSurface: const Color(0xFFF1F4FC),
      error: const Color(0xFFFFB4AB),
      outline: const Color(0xFF3D4963),
    );
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0C1426),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF202B44),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.outline,
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurface),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: base.navigationRailTheme.copyWith(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.20),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outline,
      ),
      searchBarTheme: base.searchBarTheme.copyWith(
        backgroundColor: WidgetStateProperty.all(scheme.surface),
        side: WidgetStateProperty.all(BorderSide(color: scheme.outline)),
        hintStyle: WidgetStateProperty.all(
          TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outline,
      ),
    );
  }
}
