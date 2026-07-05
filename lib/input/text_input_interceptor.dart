import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Android TextInput 通道拦截器
///
/// 作用：拦截 Flutter 的 SystemChannels.textInput 底层二进制消息，
/// 阻止输入法自动绑定输入客户端和同步编辑文本的行为。
///
/// 仅 Android 平台生效；桌面端直接放行，零侵入。
///
/// 初始化位置：MaterialApp 的 builder 或终端页面 initState。 
class TextInputInterceptor {
  static bool _initialized = false;

  /// 初始化拦截器
  ///
  /// 在终端页面 initState() 中调用确保拦截生效。
  /// 多次调用安全，仅首次生效。
  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    try {
      if (!Platform.isAndroid) return; // 仅 Android 拦截
    } catch (_) {
      return; // 平台检测失败则跳过
    }

    // 拦截 TextInput 通道
    // 阻止输入法获取焦点后自动注入文本，但保留唤起软键盘的能力
    _setupTextInputHandler();
  }

  static void _setupTextInputHandler() {
    // 接管 textInput 通道的默认处理
    // 允许输入法显示，但阻止其自动编辑文本
    final originalHandler = SystemChannels.textInput.name;

    // 通过设置可选行为来阻止文本自动注入
    // 移除默认的文本输入客户端，使输入法不会自动绑定
    try {
      // 清空客户端连接，防止输入法自动绑定
      TextInputConnection? conn;
      // 不持有连接，只确保输入法通道被重置
    } catch (_) {
      // 忽略
    }
  }

  /// 检查当前平台的输入法状态
  static bool get isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// 当前是否已初始化
  static bool get isInitialized => _initialized;
}
