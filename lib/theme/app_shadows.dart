import 'package:flutter/material.dart';

/// 应用全局阴影定义
/// 按层级定义：无、微弱、小、中、大、超大
class AppShadows {
  AppShadows._();

  // ======================== 阴影层级 ========================

  /// 无阴影
  static const List<BoxShadow> none = [];

  /// 微弱阴影（按钮 hover 等）
  static final List<BoxShadow> micro = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// 小阴影（卡片默认、下拉菜单）
  static final List<BoxShadow> small = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// 中阴影（悬浮卡片、弹出面板）
  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// 大阴影（对话框、模态弹窗）
  static final List<BoxShadow> large = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// 超大阴影（浮层、拖拽预览）
  static final List<BoxShadow> extraLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ======================== 终端凹陷阴影 ========================

  /// 终端内框凹陷阴影（inset 效果）
  static final List<BoxShadow> terminalInset = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, -1),
      spreadRadius: -1,
    ),
  ];

  // ======================== 拖拽高亮 ========================

  /// 拖拽悬浮高亮
  static final List<BoxShadow> dropHighlight = [
    BoxShadow(
      color: Colors.blue.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 0),
      spreadRadius: 2,
    ),
  ];
}
