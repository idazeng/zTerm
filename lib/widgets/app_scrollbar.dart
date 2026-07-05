import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// 统一滚动条组件
/// 统一宽度、颜色、圆角
/// 终端和文件列表保持一致
class AppScrollbar extends StatefulWidget {
  /// 滚动控制器
  final ScrollController? controller;

  /// 子组件
  final Widget child;

  /// 滚动条是否始终显示
  final bool alwaysShow;

  /// 滚动条厚度
  final double thickness;

  /// 滚动条是否显示在轨道上方
  final bool isAlwaysShown;

  /// 滚动方向
  final Axis scrollDirection;

  const AppScrollbar({
    super.key,
    this.controller,
    required this.child,
    this.alwaysShow = false,
    this.thickness = 6.0,
    this.isAlwaysShown = false,
    this.scrollDirection = Axis.vertical,
  });

  @override
  State<AppScrollbar> createState() => _AppScrollbarState();
}

class _AppScrollbarState extends State<AppScrollbar> {
  bool _showScrollbar = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _showScrollbar = widget.alwaysShow;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return MouseRegion(
      onEnter: (_) => setState(() {
        _showScrollbar = true;
        _isHovered = true;
      }),
      onExit: (_) => setState(() {
        _showScrollbar = widget.alwaysShow;
        _isHovered = false;
      }),
      child: RawScrollbar(
        controller: widget.controller,
        thumbVisibility: _showScrollbar || widget.isAlwaysShown,
        thickness: widget.thickness,
        radius: Radius.circular(AppRadius.full),
        trackBorderColor: Colors.transparent,
        trackColor: AppColors.divider(brightness).withOpacity(0.3),
        thumbColor: _isHovered
            ? AppColors.textSecondary(brightness).withOpacity(0.6)
            : AppColors.textSecondary(brightness).withOpacity(0.35),
        child: widget.child,
      ),
    );
  }
}

/// 终端专用滚动条包装器
/// 用于终端区域，保持与文件列表一致的滚动条样式
class TerminalScrollbar extends StatefulWidget {
  /// 子组件
  final Widget child;

  const TerminalScrollbar({
    super.key,
    required this.child,
  });

  @override
  State<TerminalScrollbar> createState() => _TerminalScrollbarState();
}

class _TerminalScrollbarState extends State<TerminalScrollbar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: RawScrollbar(
        thumbVisibility: true,
        thickness: 5,
        radius: Radius.circular(AppRadius.full),
        trackBorderColor: Colors.transparent,
        trackColor: AppColors.darkDivider.withOpacity(0.3),
        thumbColor: _isHovered
            ? AppColors.terminalForeground.withOpacity(0.5)
            : AppColors.terminalForeground.withOpacity(0.3),
        child: widget.child,
      ),
    );
  }
}
