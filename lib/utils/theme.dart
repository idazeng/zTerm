import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';

/// 应用主题配置
class AppTheme {
  static String? get _uiFont {
    try { if (Platform.isWindows) return 'Microsoft YaHei'; } catch (_) {}
    return null;
  }

  static TextTheme _buildTextTheme() {
    final base = Typography.material2021(platform: defaultTargetPlatform).black;
    final font = _uiFont;
    if (font == null) return base;
    return base.copyWith(
      displayLarge:base.displayLarge?.copyWith(fontFamily:font),displayMedium:base.displayMedium?.copyWith(fontFamily:font),
      displaySmall:base.displaySmall?.copyWith(fontFamily:font),headlineLarge:base.headlineLarge?.copyWith(fontFamily:font),
      headlineMedium:base.headlineMedium?.copyWith(fontFamily:font),headlineSmall:base.headlineSmall?.copyWith(fontFamily:font),
      titleLarge:base.titleLarge?.copyWith(fontFamily:font),titleMedium:base.titleMedium?.copyWith(fontFamily:font),
      titleSmall:base.titleSmall?.copyWith(fontFamily:font),bodyLarge:base.bodyLarge?.copyWith(fontFamily:font),
      bodyMedium:base.bodyMedium?.copyWith(fontFamily:font),bodySmall:base.bodySmall?.copyWith(fontFamily:font),
      labelLarge:base.labelLarge?.copyWith(fontFamily:font),labelMedium:base.labelMedium?.copyWith(fontFamily:font),
      labelSmall:base.labelSmall?.copyWith(fontFamily:font),
    );
  }

  /// 构建浅色主题
  static ThemeData getLightTheme(int themeColorIndex) {
    final c = AppColors.accentPalette[themeColorIndex % AppColors.accentPalette.length];
    final t = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: t,
      primaryColor: c,
      colorScheme: ColorScheme.light(
        primary: c, secondary: c.withOpacity(0.7),
        surface: AppColors.lightSurface, onPrimary: Colors.white,
        onSecondary: Colors.white, onSurface: AppColors.lightText,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardTheme: CardThemeData(
        color: AppColors.lightCard, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c, foregroundColor: Colors.white,
        elevation: 0, centerTitle: false, scrolledUnderElevation: 1,
        titleTextStyle: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withOpacity(0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        shadowColor: Colors.black.withOpacity(0.15),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.extraLarge)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface.withOpacity(0.95),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        shadowColor: Colors.black.withOpacity(0.12),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.lightText.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppRadius.tiny),
        ),
        textStyle: t.bodySmall?.copyWith(color: AppColors.lightSurface),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      dialogBackgroundColor: Colors.white.withOpacity(0.92),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: c, unselectedItemColor: AppColors.lightTextSecondary,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedIconTheme: IconThemeData(color: c),
        unselectedIconTheme: IconThemeData(color: AppColors.lightTextSecondary),
        selectedLabelTextStyle: TextStyle(color: c),
        unselectedLabelTextStyle: TextStyle(color: AppColors.lightTextSecondary),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: AppColors.lightSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.lightSurface.withOpacity(0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: AppColors.lightBorder.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: AppColors.lightBorder.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: c, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
          textStyle: t.labelLarge?.copyWith(color: Colors.white),
          shadowColor: c.withOpacity(0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c, side: BorderSide(color: c.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
          textStyle: t.labelLarge?.copyWith(color: c),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          textStyle: t.labelLarge?.copyWith(color: c),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.lightIcon),
      dividerTheme: DividerThemeData(
        color: AppColors.lightDivider.withOpacity(0.6),
        thickness: 0.5, space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        elevation: 4,
      ),
    );
  }

  /// 构建深色主题
  static ThemeData getDarkTheme(int themeColorIndex) {
    final c = AppColors.accentPalette[themeColorIndex % AppColors.accentPalette.length];
    final t = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: t,
      primaryColor: c,
      colorScheme: ColorScheme.dark(
        primary: c, secondary: c.withOpacity(0.7),
        surface: AppColors.darkSurface, onPrimary: Colors.white,
        onSecondary: Colors.white, onSurface: AppColors.darkText,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardTheme: CardThemeData(
        color: AppColors.darkCard, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface, foregroundColor: AppColors.darkText,
        elevation: 0, centerTitle: false, scrolledUnderElevation: 1,
        titleTextStyle: t.titleLarge?.copyWith(color: AppColors.darkText, fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1D22).withOpacity(0.94),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        shadowColor: Colors.black.withOpacity(0.4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.extraLarge)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface.withOpacity(0.95),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkText.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppRadius.tiny),
        ),
        textStyle: t.bodySmall?.copyWith(color: AppColors.darkBackground),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      dialogBackgroundColor: const Color(0xFF1A1D22).withOpacity(0.94),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: c, unselectedItemColor: AppColors.darkTextSecondary,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedIconTheme: IconThemeData(color: c),
        unselectedIconTheme: IconThemeData(color: AppColors.darkTextSecondary),
        selectedLabelTextStyle: TextStyle(color: c),
        unselectedLabelTextStyle: TextStyle(color: AppColors.darkTextSecondary),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: AppColors.darkSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.darkCard.withOpacity(0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: AppColors.darkBorder.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: AppColors.darkBorder.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: c, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
          textStyle: t.labelLarge?.copyWith(color: Colors.white),
          shadowColor: c.withOpacity(0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c, side: BorderSide(color: c.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
          textStyle: t.labelLarge?.copyWith(color: c),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          textStyle: t.labelLarge?.copyWith(color: c),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.darkIcon),
      dividerTheme: DividerThemeData(
        color: AppColors.darkDivider.withOpacity(0.6),
        thickness: 0.5, space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        elevation: 4,
      ),
    );
  }
}
