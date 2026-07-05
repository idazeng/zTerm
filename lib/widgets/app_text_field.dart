import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 统一输入框组件
/// 统一边框样式（正常/焦点/错误）、背景色、内边距、圆角
/// 支持清除按钮、前缀/后缀图标
class AppTextField extends StatefulWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 标签文本
  final String? labelText;

  /// 提示文本
  final String? hintText;

  /// 错误文本
  final String? errorText;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 后缀图标
  final IconData? suffixIcon;

  /// 后缀图标点击回调
  final VoidCallback? onSuffixTap;

  /// 是否显示清除按钮
  final bool showClear;

  /// 是否密码模式
  final bool obscureText;

  /// 是否只读
  final bool readOnly;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 文本输入格式化器
  final List<TextInputFormatter>? inputFormatters;

  /// 最大行数
  final int? maxLines;

  /// 最大长度
  final int? maxLength;

  /// 文本变更回调
  final ValueChanged<String>? onChanged;

  /// 提交回调
  final ValueChanged<String>? onSubmitted;

  /// 聚焦节点
  final FocusNode? focusNode;

  /// 自动获取焦点
  final bool autofocus;

  /// 自定义内边距
  final EdgeInsetsGeometry? contentPadding;

  /// 自定义圆角
  final BorderRadius? borderRadius;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.showClear = false,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.contentPadding,
    this.borderRadius,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureVisible = !widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.labelMedium.copyWith(
              color: _isFocused
                  ? primaryColor
                  : AppColors.textSecondary(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: !_obscureVisible && widget.obscureText,
          readOnly: widget.readOnly,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          autofocus: widget.autofocus,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.text(brightness),
          ),
          cursorColor: primaryColor,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary(brightness),
            ),
            errorText: widget.errorText,
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 18,
                    color: _isFocused
                        ? primaryColor
                        : AppColors.textSecondary(brightness),
                  )
                : null,
            suffixIcon: _buildSuffixIcon(brightness, primaryColor),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(AppRadius.small),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border(brightness),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(AppRadius.small),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border(brightness),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(AppRadius.small),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(AppRadius.small),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(AppRadius.small),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(AppRadius.small),
              borderSide: BorderSide(
                color: AppColors.disabled(brightness),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(Brightness brightness, Color primaryColor) {
    // 密码模式：显示可见性切换
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureVisible ? Icons.visibility_off : Icons.visibility,
          size: 18,
          color: AppColors.textSecondary(brightness),
        ),
        onPressed: () => setState(() => _obscureVisible = !_obscureVisible),
      );
    }

    // 清除按钮
    if (widget.showClear && widget.controller != null) {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller!,
        builder: (context, value, _) {
          if (value.text.isEmpty) return const SizedBox.shrink();
          return IconButton(
            icon: Icon(
              Icons.clear,
              size: 16,
              color: AppColors.textSecondary(brightness),
            ),
            onPressed: () => widget.controller!.clear(),
          );
        },
      );
    }

    // 自定义后缀图标
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          size: 18,
          color: _isFocused
              ? primaryColor
              : AppColors.textSecondary(brightness),
        ),
        onPressed: widget.onSuffixTap,
      );
    }

    return null;
  }
}
