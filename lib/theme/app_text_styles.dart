import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 全局文本样式定义
///
/// 【字体策略】
/// - UI 文本：不指定 fontFamily，由 ThemeData 中的
///   Typography.material2021(platform) 提供平台默认字体
///   Windows → Segoe UI / Android → Roboto / macOS → SF Pro
/// - 终端文本：指定 'monospace' 通用字体族，自动匹配各平台等宽字体
///     Windows → Consolas / macOS → Menlo / Linux → Monospace
/// - 所有字体配置仅在此文件中，其他地方禁止单独设置 fontFamily
class AppTextStyles {
  AppTextStyles._();

  // ======================== UI 文本样式（不指定 fontFamily）========================

  static TextStyle headingExtraLarge = const TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.5,
  );
  static TextStyle headingLarge = const TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.3,
  );
  static TextStyle headingMedium = const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, height: 1.4,
  );
  static TextStyle headingSmall = const TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600, height: 1.4,
  );
  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
  );
  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
  );
  static TextStyle bodySmall = const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.4,
  );
  static TextStyle labelLarge = const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, height: 1.4,
  );
  static TextStyle labelMedium = const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, height: 1.3,
  );
  static TextStyle labelSmall = const TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.5,
  );

  // ======================== 终端等宽字体样式 ========================

  /// 终端标准文字
  /// fontFamily: 'monospace' → Windows Consolas / macOS Menlo / Linux Monospace
  static TextStyle terminalBase({
    double fontSize = 14,
    Color? color,
  }) =>
      const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ).copyWith(
        fontSize: fontSize,
        color: color ?? AppColors.terminalForeground,
      );

  /// 终端粗体文字
  static TextStyle terminalBold({
    double fontSize = 14,
    Color? color,
  }) =>
      terminalBase(fontSize: fontSize, color: color)
          .copyWith(fontWeight: FontWeight.w700);

  // ======================== 辅助方法 ========================

  static TextStyle headingLargeWithColor(Brightness brightness) =>
      headingLarge.copyWith(color: AppColors.text(brightness));
  static TextStyle headingMediumWithColor(Brightness brightness) =>
      headingMedium.copyWith(color: AppColors.text(brightness));
  static TextStyle bodyLargeWithColor(Brightness brightness) =>
      bodyLarge.copyWith(color: AppColors.text(brightness));
  static TextStyle bodyMediumWithColor(Brightness brightness) =>
      bodyMedium.copyWith(color: AppColors.text(brightness));
  static TextStyle bodySmallWithColor(Brightness brightness) =>
      bodySmall.copyWith(color: AppColors.textSecondary(brightness));
  static TextStyle labelMediumWithColor(Brightness brightness) =>
      labelMedium.copyWith(color: AppColors.textSecondary(brightness));
}
