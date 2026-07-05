import 'dart:io';
import 'package:flutter/foundation.dart';

/// 应用全局模糊参数定义
/// 包含 sigma 值、透明度参数
/// Android 端自动降级为无模糊（sigma = 0）
class AppBlur {
  AppBlur._();

  // ======================== 是否支持模糊 ========================

  /// 当前平台是否支持模糊效果
  /// PC 端 (Windows/macOS/Linux) 支持模糊
  /// Android 端降级为纯色半透明
  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  // ======================== 模糊 sigma 值 ========================

  /// 轻微模糊（顶部工具栏、底部状态栏）
  static double get light => isSupported ? 12.0 : 0.0;

  /// 中等模糊（侧边栏、右键菜单背景）
  static double get medium => isSupported ? 18.0 : 0.0;

  /// 较重模糊（弹窗遮罩、悬浮命令面板）
  static double get heavy => isSupported ? 24.0 : 0.0;

  /// 最重模糊（全屏模态遮罩）
  static double get ultra => isSupported ? 32.0 : 0.0;

  // ======================== 透明度 ========================

  /// 浅色模式下的毛玻璃底色透明度
  static const double lightOpacity = 0.65;

  /// 深色模式下的毛玻璃底色透明度
  static const double darkOpacity = 0.72;

  /// 浅色模式下边框透明度
  static const double lightBorderOpacity = 0.3;

  /// 深色模式下边框透明度
  static const double darkBorderOpacity = 0.08;

  /// Android 端降级时的纯色透明度（无模糊）
  static const double fallbackOpacity = 0.85;

  // ======================== 遮罩透明度 ========================

  /// 模态遮罩透明度
  static const double overlayOpacity = 0.45;

  /// 右键菜单遮罩透明度
  static const double contextMenuOverlayOpacity = 0.2;
}
