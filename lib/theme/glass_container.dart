import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_blur.dart';
import 'app_radius.dart';

/// 毛玻璃效果容器组件
/// PC 端自动使用 backdropFilter 模糊效果
/// Android 端自动降级为纯色半透明（sigma = 0），保障性能
/// 深色模式微微提亮，浅色模式微微变暗，并添加细边框
class GlassContainer extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 模糊强度（null 时使用 AppBlur.medium）
  final double? blur;

  /// 自定义背景色（null 时根据亮度自动选择）
  final Color? backgroundColor;

  /// 自定义边框色（null 时根据亮度自动选择）
  final Color? borderColor;

  /// 自定义圆角（null 时使用 AppRadius.mediumAll）
  final BorderRadius? borderRadius;

  /// 自定义内边距
  final EdgeInsetsGeometry? padding;

  /// 自定义外边距
  final EdgeInsetsGeometry? margin;

  /// 是否显示边框
  final bool showBorder;

  /// 边框宽度
  final double borderWidth;

  /// 自定义阴影
  final List<BoxShadow>? shadows;

  /// 内部透明度覆盖（用于 Android 降级）
  final double? fallbackOpacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.showBorder = true,
    this.borderWidth = 0.5,
    this.shadows,
    this.fallbackOpacity,
  });

  /// 创建毛玻璃背景栏（顶部工具栏、底部状态栏常用）
  factory GlassContainer.toolbar({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassContainer(
      blur: AppBlur.light,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: margin,
      showBorder: true,
      child: child,
    );
  }

  /// 创建毛玻璃侧边栏
  factory GlassContainer.sidebar({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassContainer(
      blur: AppBlur.medium,
      padding: padding,
      showBorder: true,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(AppRadius.large),
        bottomRight: Radius.circular(AppRadius.large),
      ),
      child: child,
    );
  }

  /// 创建毛玻璃右键菜单
  factory GlassContainer.contextMenu({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassContainer(
      blur: AppBlur.medium,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: child,
    );
  }

  /// 创建毛玻璃弹窗
  factory GlassContainer.dialog({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassContainer(
      blur: AppBlur.heavy,
      padding: padding ?? const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(AppRadius.large),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      child: child,
    );
  }

  /// 创建毛玻璃命令面板
  factory GlassContainer.commandPalette({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassContainer(
      blur: AppBlur.ultra,
      padding: padding ?? const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(AppRadius.large),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ],
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = backgroundColor ?? AppColors.glass(brightness);
    final bdrColor = borderColor ?? AppColors.glassBorder(brightness);
    final bRadius = borderRadius ?? AppRadius.mediumAll;
    final sigma = blur ?? AppBlur.medium;

    if (AppBlur.isSupported) {
      // PC 端：使用 BackdropFilter 实现真正的毛玻璃
      return ClipRRect(
        borderRadius: bRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            margin: margin,
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: bRadius,
              border: showBorder
                  ? Border.all(color: bdrColor, width: borderWidth)
                  : null,
              boxShadow: shadows,
            ),
            child: child,
          ),
        ),
      );
    }

    // Android 端：降级为纯色半透明，无模糊
    final fallbackBg = brightness == Brightness.light
        ? Colors.white.withOpacity(fallbackOpacity ?? AppBlur.fallbackOpacity)
        : const Color(0xFF1A1D22)
            .withOpacity(fallbackOpacity ?? AppBlur.fallbackOpacity);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? fallbackBg,
        borderRadius: bRadius,
        border: showBorder
            ? Border.all(color: bdrColor, width: borderWidth)
            : null,
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
