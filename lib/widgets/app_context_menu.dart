import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/glass_container.dart';

/// 统一右键菜单组件
/// 统一背景（毛玻璃）、圆角、阴影、菜单项高度和字号
class AppContextMenu {
  /// 显示右键菜单（静态方法）
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required List<AppContextMenuItem> items,
    double? width,
  }) async {
    final brightness = Theme.of(context).brightness;

    final overlay = Overlay.of(context);
    final overlaySize = Overlay.of(context).context.size ?? Size.zero;

    // 计算菜单位置，确保不超出屏幕
    double left = position.dx;
    double top = position.dy;
    final menuWidth = width ?? 220.0;
    final menuHeight = items.length * 48.0 + 16.0;

    if (left + menuWidth > overlaySize.width) {
      left = overlaySize.width - menuWidth - 8;
    }
    if (top + menuHeight > overlaySize.height) {
      top = overlaySize.height - menuHeight - 8;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 半透明遮罩，点击关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // 菜单内容
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: _ContextMenuWidget(
                items: items,
                menuWidth: menuWidth,
                onClose: () => entry.remove(),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }
}

/// 菜单项数据模型
class AppContextMenuItem {
  /// 菜单项文本
  final String label;

  /// 菜单项图标
  final IconData? icon;

  /// 图标颜色
  final Color? iconColor;

  /// 是否为危险操作（红色文字）
  final bool isDestructive;

  /// 是否禁用
  final bool isDisabled;

  /// 是否显示快捷键提示
  final String? shortcut;

  /// 菜单项点击回调
  final VoidCallback? onTap;

  const AppContextMenuItem({
    required this.label,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
    this.isDisabled = false,
    this.shortcut,
    this.onTap,
  });
}

/// 右键菜单内部组件
class _ContextMenuWidget extends StatefulWidget {
  final List<AppContextMenuItem> items;
  final double menuWidth;
  final VoidCallback onClose;

  const _ContextMenuWidget({
    required this.items,
    required this.menuWidth,
    required this.onClose,
  });

  @override
  State<_ContextMenuWidget> createState() => _ContextMenuWidgetState();
}

class _ContextMenuWidgetState extends State<_ContextMenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
      child: GlassContainer.contextMenu(
        child: SizedBox(
          width: widget.menuWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == widget.items.length - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ContextMenuItemWidget(
                    item: item,
                    onTap: () {
                      widget.onClose();
                      item.onTap?.call();
                    },
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.divider(Theme.of(context).brightness),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// 单个菜单项组件
class _ContextMenuItemWidget extends StatefulWidget {
  final AppContextMenuItem item;
  final VoidCallback? onTap;

  const _ContextMenuItemWidget({required this.item, this.onTap});

  @override
  State<_ContextMenuItemWidget> createState() => _ContextMenuItemWidgetState();
}

class _ContextMenuItemWidgetState extends State<_ContextMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final textColor = widget.item.isDestructive
        ? AppColors.error
        : widget.item.isDisabled
            ? AppColors.textTertiary(brightness)
            : AppColors.text(brightness);

    final iconColor = widget.item.isDestructive
        ? AppColors.error
        : widget.item.iconColor ??
            (widget.item.isDisabled
                ? AppColors.textTertiary(brightness)
                : AppColors.icon(brightness));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _isHovered && !widget.item.isDisabled
              ? AppColors.hover(brightness).withOpacity(0.5)
              : Colors.transparent,
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 16, color: iconColor),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (widget.item.shortcut != null)
                Text(
                  widget.item.shortcut!,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary(brightness),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
