import 'package:flutter/material.dart';

/// 应用全局圆角常量
/// 统一定义小/中/大/超大圆角半径
class AppRadius {
  AppRadius._();

  // ======================== 圆角半径值 ========================

  /// 极小圆角（标签、芯片等）
  static const double tiny = 4.0;

  /// 小圆角（按钮、输入框等）
  static const double small = 6.0;

  /// 中圆角（卡片、对话框等）
  static const double medium = 10.0;

  /// 大圆角（大卡片、面板等）
  static const double large = 14.0;

  /// 超大圆角（全屏弹窗、底部弹窗等）
  static const double extraLarge = 20.0;

  /// 全圆角
  static const double full = 999.0;

  // ======================== BorderRadius 实例 ========================

  static const BorderRadius tinyAll = BorderRadius.all(Radius.circular(tiny));
  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumAll = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeAll = BorderRadius.all(Radius.circular(large));
  static const BorderRadius extraLargeAll = BorderRadius.all(Radius.circular(extraLarge));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  // ======================== 按需组合 ========================

  /// 顶部圆角（底部弹窗用）
  static const BorderRadius topLarge = BorderRadius.vertical(top: Radius.circular(large));
  static const BorderRadius topExtraLarge = BorderRadius.vertical(top: Radius.circular(extraLarge));

  /// 底部圆角（顶部工具栏用）
  static const BorderRadius bottomLarge = BorderRadius.vertical(bottom: Radius.circular(large));

  /// 左侧圆角（侧边栏用）
  static const BorderRadius leftLarge = BorderRadius.horizontal(left: Radius.circular(large));

  /// 右侧圆角（侧边栏用）
  static const BorderRadius rightLarge = BorderRadius.horizontal(right: Radius.circular(large));
}
