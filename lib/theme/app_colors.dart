import 'package:flutter/material.dart';

/// 应用全局颜色定义
/// 包含 Light/Dark 两套完整配色，以及多套主题色
class AppColors {
  AppColors._();

  // ======================== 多套主题色 ========================

  /// 预定义主题色列表（蓝、靛蓝、紫、深紫、青绿、绿、橙、红、粉、青、棕、灰）
  static const List<Color> accentPalette = [
    Color(0xFF2196F3), // 蓝
    Color(0xFF3F51B5), // 靛蓝
    Color(0xFF9C27B0), // 紫
    Color(0xFF673AB7), // 深紫
    Color(0xFF009688), // 青绿
    Color(0xFF4CAF50), // 绿
    Color(0xFFFF9800), // 橙
    Color(0xFFF44336), // 红
    Color(0xFFE91E63), // 粉
    Color(0xFF00BCD4), // 青
    Color(0xFF795548), // 棕
    Color(0xFF607D8B), // 蓝灰
  ];

  // ======================== 浅色主题 ========================

  static const Color lightBackground = Color(0xFFF4F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1C1E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightBorder = Color(0xFFD1D5DB);
  static const Color lightBorderFocused = Color(0xFF2196F3);
  static const Color lightIcon = Color(0xFF4B5563);
  static const Color lightHover = Color(0xFFF3F4F6);
  static const Color lightPressed = Color(0xFFE5E7EB);
  static const Color lightDisabled = Color(0xFFD1D5DB);
  static const Color lightDisabledText = Color(0xFF9CA3AF);

  // ======================== 深色主题 ========================

  static const Color darkBackground = Color(0xFF0F1114);
  static const Color darkSurface = Color(0xFF1A1D22);
  static const Color darkCard = Color(0xFF22262C);
  static const Color darkText = Color(0xFFE8EAED);
  static const Color darkTextSecondary = Color(0xFF9AA0A6);
  static const Color darkTextTertiary = Color(0xFF6B7280);
  static const Color darkDivider = Color(0xFF2D3135);
  static const Color darkBorder = Color(0xFF3C4043);
  static const Color darkBorderFocused = Color(0xFF2196F3);
  static const Color darkIcon = Color(0xFFBDC1C6);
  static const Color darkHover = Color(0xFF282C31);
  static const Color darkPressed = Color(0xFF32363B);
  static const Color darkDisabled = Color(0xFF3C4043);
  static const Color darkDisabledText = Color(0xFF5F6368);

  // ======================== 终端颜色 ========================

  static const Color terminalBackground = Color(0xFF121416);
  static const Color terminalForeground = Color(0xFFD4D4D4);
  static const Color terminalCursor = Color(0xFFA0A0A0);
  static const Color terminalSelection = Color(0xFF264F78);

  // ======================== 状态颜色 ========================

  static const Color success = Color(0xFF34D399);
  static const Color successDark = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFEF4444);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF3B82F6);

  // ======================== SFTP 文件类型颜色 ========================

  static const Color folder = Color(0xFFFBBF24);
  static const Color folderDark = Color(0xFFF59E0B);
  static const Color file = Color(0xFF9CA3AF);
  static const Color fileDark = Color(0xFF6B7280);
  static const Color executable = Color(0xFF34D399);
  static const Color symlink = Color(0xFF60A5FA);

  // ======================== 毛玻璃颜色 ========================

  static Color glassLight = Colors.white.withOpacity(0.65);
  static Color glassDark = const Color(0xFF1A1D22).withOpacity(0.72);
  static Color glassLightBorder = Colors.white.withOpacity(0.3);
  static Color glassDarkBorder = Colors.white.withOpacity(0.08);

  // ======================== 辅助方法 ========================

  /// 根据亮度获取背景色
  static Color background(Brightness brightness) =>
      brightness == Brightness.light ? lightBackground : darkBackground;

  /// 根据亮度获取表面色
  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? lightSurface : darkSurface;

  /// 根据亮度获取卡片色
  static Color card(Brightness brightness) =>
      brightness == Brightness.light ? lightCard : darkCard;

  /// 根据亮度获取文本色
  static Color text(Brightness brightness) =>
      brightness == Brightness.light ? lightText : darkText;

  /// 根据亮度获取次要文本色
  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.light ? lightTextSecondary : darkTextSecondary;

  /// 根据亮度获取三级文本色
  static Color textTertiary(Brightness brightness) =>
      brightness == Brightness.light ? lightTextTertiary : darkTextTertiary;

  /// 根据亮度获取分割线色
  static Color divider(Brightness brightness) =>
      brightness == Brightness.light ? lightDivider : darkDivider;

  /// 根据亮度获取边框色
  static Color border(Brightness brightness) =>
      brightness == Brightness.light ? lightBorder : darkBorder;

  /// 根据亮度获取悬停色
  static Color hover(Brightness brightness) =>
      brightness == Brightness.light ? lightHover : darkHover;

  /// 根据亮度获取按下色
  static Color pressed(Brightness brightness) =>
      brightness == Brightness.light ? lightPressed : darkPressed;

  /// 根据亮度获取禁用色
  static Color disabled(Brightness brightness) =>
      brightness == Brightness.light ? lightDisabled : darkDisabled;

  /// 根据亮度获取图标色
  static Color icon(Brightness brightness) =>
      brightness == Brightness.light ? lightIcon : darkIcon;

  /// 根据亮度获取毛玻璃颜色
  static Color glass(Brightness brightness) =>
      brightness == Brightness.light ? glassLight : glassDark;

  /// 根据亮度获取毛玻璃边框色
  static Color glassBorder(Brightness brightness) =>
      brightness == Brightness.light ? glassLightBorder : glassDarkBorder;
}
