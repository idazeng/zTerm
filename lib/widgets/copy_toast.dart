import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_blur.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/glass_container.dart';

/// 复制成功提示组件
/// 在鼠标附近短暂浮现半透明毛玻璃提示"已复制 ✓"
/// 2 秒后自动消失
class CopyToast {
  static OverlayEntry? _currentEntry;

  /// 在指定位置显示复制提示
  static void show(BuildContext context, {Offset? position}) {
    // 移除已有的提示
    dismiss();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlaySize = Overlay.of(context).context.size ?? Size.zero;

    // 计算提示位置（默认在屏幕中央偏上）
    Offset toastPosition;
    if (position != null) {
      toastPosition = position;
    } else if (renderBox != null) {
      final boxCenter = renderBox.size.center(Offset.zero);
      final boxPosition = renderBox.localToGlobal(boxCenter);
      toastPosition = boxPosition + const Offset(0, -40);
    } else {
      toastPosition = Offset(
        overlaySize.width / 2,
        overlaySize.height / 2 - 40,
      );
    }

    // 确保不超出屏幕边界
    final safeX = toastPosition.dx.clamp(80.0, overlaySize.width - 80.0);
    final safeY = toastPosition.dy.clamp(40.0, overlaySize.height - 40.0);

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: safeX - 50,
        top: safeY,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -8 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: GlassContainer(
              blur: AppBlur.medium,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '已复制',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.text(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);

    // 2 秒后自动消失
    Future.delayed(const Duration(seconds: 2), () {
      dismiss();
    });
  }

  /// 移除提示
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
