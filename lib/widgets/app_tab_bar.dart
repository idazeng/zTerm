import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 统一标签栏组件
/// 统一激活态指示器颜色、背景、关闭按钮样式
class AppTabBar extends StatelessWidget {
  /// 标签列表
  final List<AppTab> tabs;

  /// 当前激活的标签索引
  final int selectedIndex;

  /// 标签切换回调
  final ValueChanged<int> onTabSelected;

  /// 标签关闭回调
  final ValueChanged<int>? onTabClose;

  /// 是否显示关闭按钮
  final bool showClose;

  /// 标签栏背景色（null 时使用主题默认）
  final Color? backgroundColor;

  /// 标签栏高度
  final double height;

  /// 是否在底部
  final bool isBottom;

  const AppTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onTabClose,
    this.showClose = true,
    this.backgroundColor,
    this.height = AppSpacing.tabBarHeight,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = backgroundColor ?? AppColors.surface(brightness);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: isBottom
              ? BorderSide.none
              : BorderSide(color: AppColors.divider(brightness), width: 0.5),
          top: isBottom
              ? BorderSide(color: AppColors.divider(brightness), width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = index == selectedIndex;
          return _TabItem(
            tab: tab,
            isActive: isActive,
            primaryColor: primaryColor,
            brightness: brightness,
            showClose: showClose,
            onTap: () => onTabSelected(index),
            onClose: onTabClose != null ? () => onTabClose!(index) : null,
          );
        },
      ),
    );
  }
}

/// 标签数据模型
class AppTab {
  /// 标签标题
  final String title;

  /// 标签图标
  final IconData? icon;

  /// 是否显示警告标识
  final bool hasWarning;

  const AppTab({
    required this.title,
    this.icon,
    this.hasWarning = false,
  });
}

/// 单个标签项组件
class _TabItem extends StatelessWidget {
  final AppTab tab;
  final bool isActive;
  final Color primaryColor;
  final Brightness brightness;
  final bool showClose;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.primaryColor,
    required this.brightness,
    required this.showClose,
    required this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 180),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xxs,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.background(brightness)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: isActive
              ? Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 0.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.icon != null) ...[
              Icon(
                tab.icon,
                size: 14,
                color: isActive
                    ? primaryColor
                    : AppColors.textSecondary(brightness),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            if (tab.hasWarning)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: AppSpacing.xs),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                tab.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isActive
                      ? AppColors.text(brightness)
                      : AppColors.textSecondary(brightness),
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (showClose && onClose != null) ...[
              const SizedBox(width: AppSpacing.xxs),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.tiny),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: AppColors.textTertiary(brightness),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
