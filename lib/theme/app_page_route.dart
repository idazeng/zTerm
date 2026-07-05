import 'package:flutter/material.dart';
import 'app_animations.dart';

/// 自定义页面路由过渡动画
/// 统一使用滑动（轻微上移）+ 淡入过渡
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRoute({
    required this.page,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnim.routeTransitionDuration,
          reverseTransitionDuration: AppAnim.routePopDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 淡入过渡
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: AppAnim.routeCurve,
              reverseCurve: AppAnim.standardOut,
            );

            // 滑动过渡（轻微上移）
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnim.routeCurve,
              reverseCurve: AppAnim.standardOut,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

/// 替换式页面路由（无返回动画）
class AppPageRouteReplace<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRouteReplace({
    required this.page,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnim.routeTransitionDuration,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: AppAnim.routeCurve,
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
        );
}
