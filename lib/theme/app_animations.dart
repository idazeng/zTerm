import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 应用全局动画参数定义
/// 统一定义动画时长、曲线
/// Android 端适当缩短动画时长
class AppAnim {
  AppAnim._();

  // ======================== 平台检测 ========================

  /// 是否为移动端（Android/iOS）
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // ======================== 动画时长 ========================

  /// 快速过渡（150ms）—— 按钮缩放、hover 状态变化
  static Duration get fast {
    return Duration(milliseconds: isMobile ? 100 : 150);
  }

  /// 正常过渡（300ms）—— 路由切换、面板展开
  static Duration get normal {
    return Duration(milliseconds: isMobile ? 200 : 300);
  }

  /// 缓慢过渡（500ms）—— 页面入场动画、复杂过渡
  static Duration get slow {
    return Duration(milliseconds: isMobile ? 350 : 500);
  }

  /// 呼吸灯周期（2000ms）
  static Duration get breathe => const Duration(milliseconds: 2000);

  /// 终端脉冲闪烁时长（200ms）
  static Duration get pulse => const Duration(milliseconds: 200);

  // ======================== 动画曲线 ========================

  /// 标准曲线 —— 通用场景
  static const Curve standard = Curves.easeOutCubic;

  /// 标准加速曲线 —— 元素出场
  static const Curve standardIn = Curves.easeOutCubic;

  /// 标准减速曲线 —— 元素入场
  static const Curve standardOut = Curves.easeInCubic;

  /// 弹性曲线 —— 按钮缩放、拖拽释放
  static const Curve elastic = Curves.elasticOut;

  /// 快速曲线 —— hover、focus 等微交互
  static const Curve quick = Curves.easeOutQuad;

  /// 线性曲线 —— 进度条、呼吸灯
  static const Curve linear = Curves.linear;

  // ======================== 路由过渡 ========================

  /// 路由切换持续时间
  static Duration get routeTransitionDuration => normal;

  /// 路由返回持续时间
  static Duration get routePopDuration => fast;

  /// 路由过渡曲线
  static const Curve routeCurve = standard;

  // ======================== 组件动画 ========================

  /// AnimatedSwitcher 持续时间
  static Duration get switcherDuration => normal;

  /// 按钮缩放持续时间
  static Duration get buttonScaleDuration => fast;

  /// 按钮缩放目标值
  static const double buttonScaleDown = 0.95;

  /// 拖拽高亮过渡时长
  static Duration get dropHighlightDuration => fast;

  // ======================== 呼吸灯动画 ========================

  /// 呼吸灯透明度起始值
  static const double breatheMinOpacity = 0.4;

  /// 呼吸灯透明度结束值
  static const double breatheMaxOpacity = 1.0;
}
