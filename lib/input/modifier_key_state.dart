import 'dart:io' show Platform;

/// 安卓虚拟修饰键状态管理
///
/// 维护 ctrl/alt/shift 三个修饰键的锁定状态。
/// 单击锁定、再次点击解锁。
/// 页面失焦、APP切后台、输入法收起时调用 resetAll() 强制重置。
class ModifierKeyState {
  ModifierKeyState._();

  static final ModifierKeyState _instance = ModifierKeyState._();
  factory ModifierKeyState() => _instance;

  /// Ctrl 键状态
  bool _ctrl = false;

  /// Alt 键状态
  bool _alt = false;

  /// Shift 键状态
  bool _shift = false;

  /// 是否为 Android 平台
  bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  // ---- 状态读取 ----

  bool get ctrlDown => _isAndroid && _ctrl;
  bool get altDown => _isAndroid && _alt;
  bool get shiftDown => _isAndroid && _shift;

  // ---- 状态切换（单击锁定 / 再次点击解锁）----

  void toggleCtrl() => _ctrl = !_ctrl;
  void toggleAlt() => _alt = !_alt;
  void toggleShift() => _shift = !_shift;

  /// 强制设置（用于外部同步）
  void setCtrl(bool v) => _ctrl = v;
  void setAlt(bool v) => _alt = v;
  void setShift(bool v) => _shift = v;

  /// 一键重置全部修饰键状态
  void resetAll() {
    _ctrl = false;
    _alt = false;
    _shift = false;
  }

  /// 获取当前组合的调试描述
  String get debugLabel {
    final parts = <String>[];
    if (_ctrl) parts.add('Ctrl');
    if (_alt) parts.add('Alt');
    if (_shift) parts.add('Shift');
    return parts.isEmpty ? '无' : parts.join('+');
  }
}
