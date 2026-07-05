import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// 按键转换器：将 Android 软键盘事件 + 修饰键状态 → SSH Uint8List
///
/// 转换规则：
/// - Ctrl+A → 0x01 (ASCII SOH)
/// - Ctrl+Shift+A → ESC A (VT100 转义)
/// - 方向键 → ESC [ A / ESC [ B / ESC [ C / ESC [ D
/// - Tab → 0x09
/// - Enter → 0x0D
/// - 普通字符 → UTF-8 编码
class KeyCodec {
  /// 唯一实例
  static final KeyCodec _instance = KeyCodec._();
  factory KeyCodec() => _instance;
  KeyCodec._();

  /// 获取修饰键状态引用（由外部注入）
  bool Function() getCtrl = () => false;
  bool Function() getAlt = () => false;
  bool Function() getShift = () => false;

  /// 是否为 Android 平台
  bool get _isAndroid {
    try { return Platform.isAndroid; } catch (_) { return false; }
  }

  /// 将 RawKeyEvent 转换为 SSH 可以发送的 Uint8List
  ///
  /// [event] RawKeyboardListener 捕获的原始按键事件
  /// 返回 Uint8List 字节流，可为空（表示不需要发送）
  Uint8List? handleKeyEvent(RawKeyEvent event) {
    if (!_isAndroid) return null; // 非 Android 不处理
    if (event is! RawKeyDownEvent) return null; // 仅按下事件

    final ctrl = getCtrl();
    final alt = getAlt();
    final shift = getShift();

    // 获取逻辑键
    final logicalKey = event.logicalKey;

    // ==== 方向键 ====
    if (logicalKey == LogicalKeyboardKey.arrowUp) {
      if (ctrl) return _toBytes('\x1b[1;5A'); // Ctrl+↑
      if (alt) return _toBytes('\x1b[1;3A'); // Alt+↑
      if (shift) return _toBytes('\x1b[1;2A'); // Shift+↑
      return _toBytes('\x1b[A'); // ↑
    }
    if (logicalKey == LogicalKeyboardKey.arrowDown) {
      if (ctrl) return _toBytes('\x1b[1;5B');
      if (alt) return _toBytes('\x1b[1;3B');
      if (shift) return _toBytes('\x1b[1;2B');
      return _toBytes('\x1b[B');
    }
    if (logicalKey == LogicalKeyboardKey.arrowRight) {
      if (ctrl) return _toBytes('\x1b[1;5C');
      if (alt) return _toBytes('\x1b[1;3C');
      if (shift) return _toBytes('\x1b[1;2C');
      return _toBytes('\x1b[C');
    }
    if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (ctrl) return _toBytes('\x1b[1;5D');
      if (alt) return _toBytes('\x1b[1;3D');
      if (shift) return _toBytes('\x1b[1;2D');
      return _toBytes('\x1b[D');
    }

    // ==== 功能键 ====
    if (logicalKey == LogicalKeyboardKey.f1) return _toBytes('\x1bOP');
    if (logicalKey == LogicalKeyboardKey.f2) return _toBytes('\x1bOQ');
    if (logicalKey == LogicalKeyboardKey.f3) return _toBytes('\x1bOR');
    if (logicalKey == LogicalKeyboardKey.f4) return _toBytes('\x1bOS');
    if (logicalKey == LogicalKeyboardKey.f5) return _toBytes('\x1b[15~');
    if (logicalKey == LogicalKeyboardKey.f6) return _toBytes('\x1b[17~');
    if (logicalKey == LogicalKeyboardKey.f7) return _toBytes('\x1b[18~');
    if (logicalKey == LogicalKeyboardKey.f8) return _toBytes('\x1b[19~');
    if (logicalKey == LogicalKeyboardKey.f9) return _toBytes('\x1b[20~');
    if (logicalKey == LogicalKeyboardKey.f10) return _toBytes('\x1b[21~');
    if (logicalKey == LogicalKeyboardKey.f11) return _toBytes('\x1b[23~');
    if (logicalKey == LogicalKeyboardKey.f12) return _toBytes('\x1b[24~');

    // ==== 特殊键 ====
    if (logicalKey == LogicalKeyboardKey.tab) {
      if (shift) return _toBytes('\x1b[Z'); // Shift+Tab
      return _toBytes('\x09'); // Tab
    }
    if (logicalKey == LogicalKeyboardKey.enter) {
      return _toBytes('\x0d'); // Enter → CR
    }
    if (logicalKey == LogicalKeyboardKey.backspace) {
      if (alt) return _toBytes('\x1b\x7f'); // Alt+Backspace
      return _toBytes('\x7f'); // Backspace → DEL
    }
    if (logicalKey == LogicalKeyboardKey.delete) {
      return _toBytes('\x1b[3~'); // Delete
    }
    if (logicalKey == LogicalKeyboardKey.escape) {
      return _toBytes('\x1b'); // Escape
    }
    if (logicalKey == LogicalKeyboardKey.home) {
      if (ctrl) return _toBytes('\x1b[1;5H');
      return _toBytes('\x1b[H');
    }
    if (logicalKey == LogicalKeyboardKey.end) {
      if (ctrl) return _toBytes('\x1b[1;5F');
      return _toBytes('\x1b[F');
    }
    if (logicalKey == LogicalKeyboardKey.pageUp) return _toBytes('\x1b[5~');
    if (logicalKey == LogicalKeyboardKey.pageDown) return _toBytes('\x1b[6~');

    // ==== 字母键（Ctrl 组合）====
    // 从 logicalKey 获取字符
    final keyId = logicalKey.keyId;
    if (keyId >= 0x61 && keyId <= 0x7A) {
      // a-z
      final char = keyId - 0x61 + (shift ? 0 : 0);
      if (ctrl) {
        // Ctrl+A..Z → 0x01..0x1A
        return _toBytesFromList([keyId - 0x61 + 1]);
      }
      if (alt) {
        // Alt+A → ESC a
        return _toBytes('\x1b${shift ? String.fromCharCode(keyId - 0x20) : String.fromCharCode(keyId)}');
      }
      return _toBytes(String.fromCharCode(shift ? keyId - 0x20 : keyId));
    }

    // ==== 数字和符号键 ====
    if (keyId >= 0x30 && keyId <= 0x39) {
      // 0-9
      if (ctrl) {
        // Ctrl+数字 → 特殊控制字符
        // Ctrl+2 → 0x00, Ctrl+3 → 0x1B, Ctrl+4 → 0x1C, Ctrl+5 → 0x1D
        // Ctrl+6 → 0x1E, Ctrl+7 → 0x1F, Ctrl+8 → 0x7F
        const ctrlTable = {0x30: 0, 0x31: 0, 0x32: 0x00, 0x33: 0x1B, 0x34: 0x1C,
                           0x35: 0x1D, 0x36: 0x1E, 0x37: 0x1F, 0x38: 0x7F, 0x39: 0};
        final code = ctrlTable[keyId] ?? 0;
        return code > 0 ? _toBytesFromList([code]) : null;
      }
      return _toBytes(String.fromCharCode(keyId));
    }

    // ==== 标点符号（按 Shift 有不同字符）====
    // 空格
    if (logicalKey == LogicalKeyboardKey.space) {
      return _toBytes(' ');
    }

    return null; // 未识别的按键
  }

  /// 将按键产生的字符转换为 SSH 字节流
  ///
  /// 当 TextInput 通道接收到普通文本字符时，
  /// 结合当前修饰键状态做转换。
  ///
  /// [char] 输入法给出的字符
  Uint8List? handleTextInput(String char) {
    if (char.isEmpty) return null;

    final ctrl = getCtrl();
    final alt = getAlt();

    // Ctrl 按下时，将字母转为控制字符
    if (ctrl && char.length == 1) {
      final code = char.codeUnitAt(0);
      if (code >= 0x61 && code <= 0x7A) {
        // a-z → 0x01..0x1A
        return _toBytesFromList([code - 0x61 + 1]);
      }
    }

    // Alt 按下时，添加 ESC 前缀
    if (alt) {
      return _toBytes('\x1b$char');
    }

    return _toBytes(char);
  }

  /// 工具：String → Uint8List
  Uint8List _toBytes(String str) => Uint8List.fromList(utf8.encode(str));

  /// 工具：int list → Uint8List
  Uint8List _toBytesFromList(List<int> bytes) => Uint8List.fromList(bytes);
}
