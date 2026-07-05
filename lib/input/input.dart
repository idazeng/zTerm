/// 终端输入模块（Android 移动端专属）
///
/// 负责 Android 平台的输入事件处理链路，包括：
/// 1. 修饰键状态管理（ModifierKeyState）
/// 2. TextInput 通道拦截（TextInputInterceptor）
/// 3. 按键 → SSH 字节流转换（KeyCodec）
///
/// 桌面端（Windows/Linux/macOS）零侵入，不影响原有键盘输入逻辑。
export 'modifier_key_state.dart';
export 'text_input_interceptor.dart';
export 'key_codec.dart';
