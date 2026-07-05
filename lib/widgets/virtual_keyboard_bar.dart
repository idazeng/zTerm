import 'package:flutter/material.dart';
import '../constants/constants.dart';

/// 虚拟键盘条组件 - 用于移动端输入快捷键
class VirtualKeyboardBar extends StatelessWidget {
  /// 输入回调
  final Function(String) onInput;

  const VirtualKeyboardBar({
    super.key,
    required this.onInput,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingSmall,
        vertical: AppStyles.spacingExtraSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 功能键区
            _buildKey('Tab', '\t'),
            _buildKey('Esc', '\x1b'),
            _buildKey('Ctrl', null),
            _buildKey('Alt', null),
            _buildKey('Shift', null),
            const VerticalDivider(width: 1),
            // 常用快捷键
            _buildKey('←', '\x1b[D'),
            _buildKey('→', '\x1b[C'),
            _buildKey('↑', '\x1b[A'),
            _buildKey('↓', '\x1b[B'),
            const VerticalDivider(width: 1),
            // 常用命令
            _buildKey('Ctrl+C', '\x03'),
            _buildKey('Ctrl+D', '\x04'),
            _buildKey('Ctrl+Z', '\x1a'),
            _buildKey('Ctrl+L', '\x0c'),
            const VerticalDivider(width: 1),
            // 特殊字符
            _buildKey('|', '|'),
            _buildKey('>', '>'),
            _buildKey('<', '<'),
            _buildKey('~', '~'),
            _buildKey('/', '/'),
          ],
        ),
      ),
    );
  }

  /// 构建按键
  Widget _buildKey(String label, [String? value, bool isModifier = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
        child: InkWell(
          onTap: () {
            if (value != null) {
              onInput(value);
            }
          },
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spacingSmall,
              vertical: AppStyles.spacingExtraSmall,
            ),
            child: Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
