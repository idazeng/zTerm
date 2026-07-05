import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';
import '../input/input.dart';

/// Android 移动端终端输入栏
class AndroidTerminalInputBar extends StatefulWidget {
  final Function(Uint8List) onSshWrite;
  final Function(String)? onBroadcast;
  final FocusNode inputFocusNode;

  const AndroidTerminalInputBar({
    super.key,
    required this.onSshWrite,
    this.onBroadcast,
    required this.inputFocusNode,
  });

  @override
  State<AndroidTerminalInputBar> createState() => _AndroidTerminalInputBarState();
}

class _AndroidTerminalInputBarState extends State<AndroidTerminalInputBar> {
  final ModifierKeyState _modState = ModifierKeyState();
  final KeyCodec _codec = KeyCodec();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _codec.getCtrl = () => _modState.ctrlDown;
    _codec.getAlt = () => _modState.altDown;
    _codec.getShift = () => _modState.shiftDown;
    _keyboardFocusNode.addListener(_onKeyboardFocusChange);
  }

  // 已处理过的字符长度
  int _lastProcessedLen = 0;

  /// 消费 text 中新增的字符
  void _consumeNewChars() {
    final text = _textController.text;
    final currentLen = text.length;

    if (currentLen < _lastProcessedLen) {
      // 文本变短 → 退格键被按下
      final deletedCount = _lastProcessedLen - currentLen;
      for (int i = 0; i < deletedCount; i++) {
        _sendString('\x7f'); // DEL / Backspace
      }
      _lastProcessedLen = currentLen;
      if (currentLen == 0) return;
    }

    if (currentLen <= _lastProcessedLen) return;

    // 提取新增字符
    final newStr = text.substring(_lastProcessedLen);
    _lastProcessedLen = currentLen;

    for (final char in newStr.split('')) {
      if (char == '\n') {
        _sendString('\x0d'); // Enter → CR
      } else {
        final encoded = _codec.handleTextInput(char);
        if (encoded != null) _send(encoded);
      }
    }
  }

  /// 主动提交（回车 / 发送）
  void _onSubmit(String value) {
    _sendString('\x0d');
  }

  void _onKeyboardFocusChange() {
    if (!_keyboardFocusNode.hasFocus) {
      _modState.resetAll();
      _textController.clear();
      _lastProcessedLen = 0;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _keyboardFocusNode.removeListener(_onKeyboardFocusChange);
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _send(Uint8List data) => widget.onSshWrite(data);
  void _sendString(String str) => _send(Uint8List.fromList(str.codeUnits));

  void _showSystemKeyboard() {
    _keyboardFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 隐藏 TextField：供系统键盘附着
          // 不主动清除 text，让系统键盘自然管理光标/退格
          SizedBox(
            width: 0, height: 0,
            child: TextField(
              controller: _textController,
              focusNode: _keyboardFocusNode,
              autofocus: false,
              keyboardType: TextInputType.visiblePassword,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const [],
              style: const TextStyle(fontSize: 1, color: Colors.transparent),
              decoration: const InputDecoration(border: InputBorder.none),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onChanged: (_) => _consumeNewChars(),
              onSubmitted: _onSubmit,
            ),
          ),
          Row(children: [
            _buildModifierKey('Ctrl', _modState.ctrlDown, () { _modState.toggleCtrl(); setState(() {}); }),
            const SizedBox(width: 4),
            _buildModifierKey('Alt', _modState.altDown, () { _modState.toggleAlt(); setState(() {}); }),
            const SizedBox(width: 4),
            _buildModifierKey('Shift', _modState.shiftDown, () { _modState.toggleShift(); setState(() {}); }),
            const Spacer(),
            _buildActionKey(Icons.keyboard, 'Keyboard', _showSystemKeyboard),
          ]),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _buildKey('Tab', () => _sendString('\x09')),
              _buildKey('Esc', () => _sendString('\x1b')),
              const SizedBox(width: 2),
              _buildKey('\u2190', () => _sendString('\x1b[D')),
              _buildKey('\u2192', () => _sendString('\x1b[C')),
              _buildKey('\u2191', () => _sendString('\x1b[A')),
              _buildKey('\u2193', () => _sendString('\x1b[B')),
              const SizedBox(width: 2),
              _buildKey('Del', () => _sendString('\x1b[3~')),
              _buildKey('BS', () => _sendString('\x7f')),
              const SizedBox(width: 2),
              _buildKey('Home', () => _sendString('\x1b[H')),
              _buildKey('End', () => _sendString('\x1b[F')),
              const SizedBox(width: 2),
              _buildKey('PgUp', () => _sendString('\x1b[5~')),
              _buildKey('PgDn', () => _sendString('\x1b[6~')),
              const SizedBox(width: 2),
              _buildKey('F1', () => _sendString('\x1bOP')),
              _buildKey('F2', () => _sendString('\x1bOQ')),
              _buildKey('F3', () => _sendString('\x1bOR')),
              _buildKey('F4', () => _sendString('\x1bOS')),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierKey(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: active ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5) : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? Theme.of(context).colorScheme.onPrimary : null,
        )),
      ),
    );
  }

  Widget _buildKey(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 20), tooltip: tooltip, onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero,
    );
  }
}
