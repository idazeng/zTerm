import 'package:flutter/material.dart';
import 'colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

/// 统一样式定义（向后兼容层）
/// 新代码请使用 lib/theme/ 下的专用常量类
class AppStyles {
  // ======== 圆角（指向 AppRadius）========
  static const double borderRadiusSmall = AppRadius.small;
  static const double borderRadiusMedium = AppRadius.medium;
  static const double borderRadiusLarge = AppRadius.large;
  static const double borderRadiusExtraLarge = AppRadius.extraLarge;

  // ======== 间距（指向 AppSpacing）========
  static const double spacingExtraSmall = AppSpacing.xs;
  static const double spacingSmall = AppSpacing.sm;
  static const double spacingMedium = AppSpacing.md;
  static const double spacingLarge = AppSpacing.lg;
  static const double spacingExtraLarge = AppSpacing.xl;

  // ======== 阴影（指向 AppShadows）========
  static List<BoxShadow> get shadowSmall => AppShadows.small;
  static List<BoxShadow> get shadowMedium => AppShadows.medium;
  static List<BoxShadow> get shadowLarge => AppShadows.large;

  // ======== 文本样式（指向 AppTextStyles）========
  static TextStyle get titleLarge => AppTextStyles.headingLarge;
  static TextStyle get titleMedium => AppTextStyles.headingMedium;
  static TextStyle get titleSmall => AppTextStyles.headingSmall;
  static TextStyle get bodyLarge => AppTextStyles.bodyLarge;
  static TextStyle get bodyMedium => AppTextStyles.bodyMedium;
  static TextStyle get bodySmall => AppTextStyles.bodySmall;
  static TextStyle get caption => AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextSecondary);

  // ======== 图标大小 ========
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double minTapTarget = 44.0;

  // ======== 按钮样式 ========
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusMedium)),
      );
  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusMedium)),
      );
  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
      );

  // ======== 卡片样式 ========
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(borderRadiusMedium), boxShadow: shadowSmall,
      );

  // ======== 分割线 ========
  static Divider get divider => Divider(height: 1, thickness: 1, color: AppColors.lightDivider);
}
