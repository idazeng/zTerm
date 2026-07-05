import 'package:flutter/material.dart';
import '../theme/app_animations.dart';

/// 呼吸灯/脉冲指示器组件
/// 用于终端连接状态显示（小圆点呼吸灯）
/// 使用 AnimatedContainer 循环透明度/颜色
class BreathingDot extends StatefulWidget {
  /// 指示器颜色
  final Color color;

  /// 指示器大小
  final double size;

  /// 是否启用呼吸动画
  final bool animate;

  const BreathingDot({
    super.key,
    this.color = Colors.green,
    this.size = 8.0,
    this.animate = true,
  });

  @override
  State<BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnim.breathe,
    );
    _opacityAnimation = Tween<double>(
      begin: AppAnim.breatheMinOpacity,
      end: AppAnim.breatheMaxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnim.linear,
    ));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BreathingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_opacityAnimation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_opacityAnimation.value * 0.4),
                blurRadius: widget.size * 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 连接状态指示器
/// 组合呼吸灯和状态文本
class ConnectionStatusIndicator extends StatelessWidget {
  /// 连接状态
  final ConnectionStatus status;

  /// 状态文本（可选，null 时自动根据状态生成）
  final String? statusText;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
    this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (status) {
      ConnectionStatus.connected => (Colors.green, statusText ?? '已连接'),
      ConnectionStatus.connecting => (Colors.orange, statusText ?? '连接中'),
      ConnectionStatus.disconnected => (Colors.grey, statusText ?? '未连接'),
      ConnectionStatus.error => (Colors.red, statusText ?? '连接错误'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BreathingDot(
          color: color,
          size: 8,
          animate: status == ConnectionStatus.connecting,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

enum ConnectionStatus { connected, connecting, disconnected, error }
