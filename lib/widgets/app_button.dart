import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_animations.dart';

/// 统一按钮组件
/// 预定义主按钮（filled）、次要按钮（outlined）、文本按钮（text）三种样式
/// 均支持 hover、pressed、disabled 状态
/// 点击时通过 AnimatedScale 缩放到 0.95，提供触感反馈
class AppButton extends StatefulWidget {
  /// 按钮文本
  final String label;

  /// 按钮点击回调
  final VoidCallback? onPressed;

  /// 按钮样式类型
  final AppButtonType type;

  /// 按钮图标
  final IconData? icon;

  /// 按钮图标大小
  final double? iconSize;

  /// 按钮是否紧凑
  final bool compact;

  /// 按钮是否全宽
  final bool fullWidth;

  /// 按钮是否显示加载状态
  final bool isLoading;

  /// 自定义颜色（覆盖主题色）
  final Color? color;

  /// 自定义前景色
  final Color? foregroundColor;

  /// 自定义内边距
  final EdgeInsetsGeometry? padding;

  /// 自定义圆角
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.filled,
    this.icon,
    this.iconSize,
    this.compact = false,
    this.fullWidth = false,
    this.isLoading = false,
    this.color,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  });

  /// 主按钮快捷构造
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconSize,
    this.compact = false,
    this.fullWidth = false,
    this.isLoading = false,
    this.color,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : type = AppButtonType.filled;

  /// 次要按钮快捷构造
  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconSize,
    this.compact = false,
    this.fullWidth = false,
    this.isLoading = false,
    this.color,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : type = AppButtonType.outlined;

  /// 文本按钮快捷构造
  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconSize,
    this.compact = false,
    this.fullWidth = false,
    this.isLoading = false,
    this.color,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : type = AppButtonType.text;

  @override
  State<AppButton> createState() => _AppButtonState();
}

enum AppButtonType { filled, outlined, text }

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppAnim.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: AppAnim.buttonScaleDown)
        .animate(CurvedAnimation(parent: _scaleController, curve: AppAnim.quick));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final primaryColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final effectiveOnPressed = widget.isLoading ? null : widget.onPressed;

    final contentPadding = widget.padding ??
        EdgeInsets.symmetric(
          horizontal: widget.compact ? AppSpacing.sm : AppSpacing.lg,
          vertical: widget.compact ? AppSpacing.xs : AppSpacing.md,
        );

    final bRadius =
        widget.borderRadius ?? BorderRadius.circular(AppRadius.small);

    Widget button;
    switch (widget.type) {
      case AppButtonType.filled:
        button = _buildFilledButton(
            context, primaryColor, effectiveOnPressed, contentPadding, bRadius);
        break;
      case AppButtonType.outlined:
        button = _buildOutlinedButton(
            context, primaryColor, effectiveOnPressed, contentPadding, bRadius);
        break;
      case AppButtonType.text:
        button = _buildTextButton(
            context, primaryColor, effectiveOnPressed, contentPadding, bRadius);
        break;
    }

    return AnimatedScale(
      scale: _scaleAnimation.value,
      duration: AppAnim.fast,
      child: GestureDetector(
        onTapDown: effectiveOnPressed != null ? _onTapDown : null,
        onTapUp: effectiveOnPressed != null ? _onTapUp : null,
        onTapCancel: effectiveOnPressed != null ? _onTapCancel : null,
        child: widget.fullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }

  Widget _buildFilledButton(BuildContext context, Color primaryColor,
      VoidCallback? onPressed, EdgeInsetsGeometry padding, BorderRadius radius) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: widget.foregroundColor ?? Colors.white,
        disabledBackgroundColor: AppColors.disabled(Theme.of(context).brightness),
        disabledForegroundColor: AppColors.textSecondary(Theme.of(context).brightness),
        padding: padding,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: AppTextStyles.labelLarge.copyWith(
          color: widget.foregroundColor ?? Colors.white,
        ),
      ),
      child: _buildChild(primaryColor),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, Color primaryColor,
      VoidCallback? onPressed, EdgeInsetsGeometry padding, BorderRadius radius) {
    final brightness = Theme.of(context).brightness;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.foregroundColor ?? primaryColor,
        side: BorderSide(
          color: onPressed != null
              ? primaryColor
              : AppColors.disabled(brightness),
          width: 1,
        ),
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: AppTextStyles.labelLarge.copyWith(
          color: widget.foregroundColor ?? primaryColor,
        ),
      ),
      child: _buildChild(widget.foregroundColor ?? primaryColor),
    );
  }

  Widget _buildTextButton(BuildContext context, Color primaryColor,
      VoidCallback? onPressed, EdgeInsetsGeometry padding, BorderRadius radius) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: widget.foregroundColor ?? primaryColor,
        disabledForegroundColor: AppColors.textSecondary(Theme.of(context).brightness),
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: AppTextStyles.labelLarge.copyWith(
          color: widget.foregroundColor ?? primaryColor,
        ),
      ),
      child: _buildChild(widget.foregroundColor ?? primaryColor),
    );
  }

  Widget _buildChild(Color color) {
    if (widget.isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.type == AppButtonType.filled
                ? Colors.white
                : color,
          ),
        ),
      );
    }

    final labelWidget = Text(widget.label);

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: widget.iconSize ?? 16),
          const SizedBox(width: AppSpacing.xs),
          labelWidget,
        ],
      );
    }

    return labelWidget;
  }
}
