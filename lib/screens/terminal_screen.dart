import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../input/input.dart';
import '../widgets/android_terminal_input_bar.dart';
import '../widgets/widgets.dart';
import 'sftp_screen.dart';

/// 终端主页面 - 包含终端和 SFTP 面板
class TerminalScaffold extends ConsumerStatefulWidget {
  final TerminalTab tab;

  const TerminalScaffold({
    super.key,
    required this.tab,
  });

  @override
  ConsumerState<TerminalScaffold> createState() => _TerminalScaffoldState();
}

class _TerminalScaffoldState extends ConsumerState<TerminalScaffold> {
  late Terminal _terminal;
  SSHSession? _sshSession;
  HostInfo? _hostInfo;
  bool _isConnecting = true;
  String? _errorMessage;
  SSHClient? _sshClient;
  final FocusNode _terminalFocusNode = FocusNode();
  final TerminalController _terminalController = TerminalController();
  String? _lastCopiedText;
  final GlobalKey _splitAreaKey = GlobalKey();
  bool _waitingForDir = false;
  String _pwdOutputBuffer = '';

  @override
  void initState() {
    super.initState();
    TextInputInterceptor.initialize();
    _terminal = Terminal(maxLines: 10000);
    _terminalController.addListener(_onSelectionChange);
    _terminalFocusNode.addListener(_onFocusChange);
    _pendingCommandCancel = ref.listenManual<String?>(pendingCommandProvider, (previous, next) {
      if (next != null && _sshSession != null) {
        _sshSession!.write(utf8.encode(next));
        ref.read(pendingCommandProvider.notifier).state = null;
      }
    });
    _connect();
  }

  ProviderSubscription<String?>? _pendingCommandCancel;

  @override
  void didUpdateWidget(TerminalScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.id != oldWidget.tab.id) {
      _disconnect(oldTabId: oldWidget.tab.id);
      _connect();
    }
  }

  void _disconnect({String? oldTabId}) {
    final tabId = oldTabId ?? widget.tab.id;
    ref.read(activeSessionsProvider).unregister(tabId);
    _sshSession?.close();
    _sshSession = null;
    _sshClient?.close();
    _sshClient = null;
    _hostInfo = null;
    _terminal = Terminal(maxLines: 10000);
  }

  @override
  void dispose() {
    _pendingCommandCancel?.close();
    ref.read(activeSessionsProvider).unregister(widget.tab.id);
    _terminalController.removeListener(_onSelectionChange);
    _terminalController.dispose();
    _terminalFocusNode.dispose();
    _sshSession?.close();
    _sshClient?.close();
    super.dispose();
  }

  void _onSelectionChange() {
    final selection = _terminalController.selection;
    if (selection == null) return;
    final text = _terminal.buffer.getText(selection);
    if (text.isNotEmpty && text != _lastCopiedText) {
      _lastCopiedText = text;
      Clipboard.setData(ClipboardData(text: text));
    }
  }

  void _requestTerminalFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _terminalFocusNode.requestFocus();
    });
  }

  /// 焦点变化监听：失焦时重置 Android 修饰键状态
  void _onFocusChange() {
    if (!_terminalFocusNode.hasFocus) {
      ModifierKeyState().resetAll();
    }
  }

  /// 当检测到 pwd 输出时，设置 sshDirectoryProvider
  void _onPwdOutput(String path) {
    if (mounted) {
      ref.read(terminalTabsProvider.notifier).updateCurrentDirectory(widget.tab.id, path);
      ref.read(sshDirectoryProvider.notifier).state = path;
    }
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });
    try {
      final connections = ref.read(connectionsProvider);
      final connection = connections.firstWhere(
        (c) => c.id == widget.tab.connectionId,
        orElse: () => throw Exception('连接不存在'),
      );
      final secureStorage = ref.read(secureStorageServiceProvider);
      String? password;
      List<SSHKeyPair>? identities;
      if (connection.authType == AuthType.key) {
        final privateKeyBytes = await secureStorage.getPrivateKey(connection.id);
        if (privateKeyBytes == null) throw Exception('私钥未存储');
        final passphrase = await secureStorage.getPassphrase(connection.id);
        final pemText = utf8.decode(privateKeyBytes);
        identities = SSHKeyPair.fromPem(pemText, passphrase);
      } else {
        password = await secureStorage.getPassword(connection.id);
      }
      final socket = await SSHSocket.connect(connection.host, connection.port);
      _sshClient = SSHClient(
        socket,
        username: connection.username,
        identities: identities,
        onPasswordRequest: () => password ?? '',
      );
      _sshSession = await _sshClient!.shell(
        pty: SSHPtyConfig(width: _terminal.viewWidth, height: _terminal.viewHeight),
      );

      // ---- stdout 监听：解析 pwd 输出 ----
      _sshSession!.stdout.cast<List<int>>().transform(Utf8Decoder()).listen((data) {
        _terminal.write(data);
        if (!_waitingForDir) return;

        _pwdOutputBuffer += data;

        // 清除 ANSI 转义序列后再解析
        final cleanBuffer = _pwdOutputBuffer
            .replaceAll(RegExp(r'\x1b\[[0-9;]*[a-zA-Z]'), '')
            .replaceAll(RegExp(r'\x1b\[\?[0-9;]*[a-zA-Z]'), '')
            .replaceAll(RegExp(r'\x1b\][^\x07\x1b]*(?:\x07|\x1b\\\\)'), '')
            .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

        // 按换行符分割，逐行检测绝对路径
        final lines = cleanBuffer.split('\n');
        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.startsWith('/') && line.length > 1 &&
              !line.contains(' ') && !line.contains('#')) {
            _waitingForDir = false;
            _pwdOutputBuffer = '';
            _onPwdOutput(line);
            return;
          }
        }

        if (_pwdOutputBuffer.length > 5120) {
          _pwdOutputBuffer = '';
          _waitingForDir = false;
        }
      });

      _sshSession!.stderr.cast<List<int>>().transform(Utf8Decoder()).listen(_terminal.write);

      // ---- onOutput：检测用户输入的 pwd 命令 ----
      String inputBuf = '';
      _terminal.onOutput = (data) {
        _sshSession?.write(utf8.encode(data));
        inputBuf += data;
        if (data.contains('\n') || data.contains('\r')) {
          final cmd = inputBuf.trim().toLowerCase();
          // Broadcast the complete command to other tabs
          _broadcastCommand(inputBuf);
          inputBuf = '';
          final clean = cmd.replaceAll(RegExp(r'\x1b\[[0-9;]*[a-zA-Z]'), '').trim();
          if (clean == 'pwd' || clean.startsWith('pwd ')) {
            _waitingForDir = true;
            _pwdOutputBuffer = '';
          }
        }
      };

      _terminal.onResize = (w, h, pw, ph) {
        _sshSession?.resizeTerminal(w, h, pw, ph);
      };

      if (mounted) setState(() { _isConnecting = false; });
      _requestTerminalFocus();
      _getHostInfo(connection).then((info) {
        if (mounted) setState(() { _hostInfo = info; });
      });
      ref.read(connectionsProvider.notifier).updateLastConnected(connection.id);
      ref.read(activeSessionsProvider).register(widget.tab.id, _sshSession!);
    } catch (e) {
      if (mounted) setState(() { _isConnecting = false; _errorMessage = e.toString(); });
    }
  }

  Future<HostInfo> _getHostInfo(ConnectionProfile connection) async {
    try {
      final hostname = utf8.decode(await _sshClient!.run('hostname')).trim();
      String systemType = '', systemVersion = '', systemCodename = '';
      try {
        final osText = utf8.decode(await _sshClient!.run('cat /etc/os-release 2>/dev/null')).trim();
        for (final line in osText.split('\n')) {
          if (line.startsWith('ID=')) systemType = line.substring(3).replaceAll('"', '');
          if (line.startsWith('VERSION_ID=')) systemVersion = line.substring(11).replaceAll('"', '');
          if (line.startsWith('VERSION_CODENAME=')) systemCodename = line.substring(17).replaceAll('"', '');
        }
        if (systemCodename.isEmpty) {
          try { systemCodename = utf8.decode(await _sshClient!.run('lsb_release -cs 2>/dev/null')).trim(); } catch (_) {}
        }
        if (systemType.isNotEmpty) systemType = systemType[0].toUpperCase() + systemType.substring(1);
      } catch (_) {
        systemType = utf8.decode(await _sshClient!.run('uname -s')).trim();
        systemVersion = utf8.decode(await _sshClient!.run('uname -r')).trim();
      }
      String ipAddress = connection.host;
      // 如果连接使用的是域名，解析为 IP
      if (!RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(connection.host)) {
        try {
          final addresses = await InternetAddress.lookup(connection.host);
          if (addresses.isNotEmpty) {
            ipAddress = addresses.first.address;
          }
        } catch (_) {
          // 解析失败，使用 hostname -I 作为后备
          try {
            final ip = utf8.decode(await _sshClient!.run("hostname -I | awk '{print \$1}'")).trim();
            if (ip.isNotEmpty && ip.contains('.')) ipAddress = ip;
          } catch (_) {}
        }
      }
      final rawUptime = utf8.decode(await _sshClient!.run('uptime -p')).trim();
      final cpuUsage = double.tryParse(utf8.decode(await _sshClient!.run("top -bn1 | grep 'Cpu(s)' | awk '{print \$2}'")).trim()) ?? 0.0;
      final memParts = utf8.decode(await _sshClient!.run("free -m | awk '/Mem:/ {print \$2, \$3}'")).trim().split(' ');
      final memTotal = int.tryParse(memParts.isNotEmpty ? memParts[0] : '') ?? 0;
      final memUsed = int.tryParse(memParts.length > 1 ? memParts[1] : '') ?? 0;
      final diskParts = utf8.decode(await _sshClient!.run("df -BG / | awk 'NR==2 {print \$2, \$3}'")).trim().replaceAll('G', '').split(' ');
      final diskTotal = int.tryParse(diskParts.isNotEmpty ? diskParts[0] : '') ?? 0;
      final diskUsed = int.tryParse(diskParts.length > 1 ? diskParts[1] : '') ?? 0;
      final loadParts = utf8.decode(await _sshClient!.run('cat /proc/loadavg')).trim().split(' ');
      return HostInfo(
        hostname: hostname, ipAddress: ipAddress,
        systemType: systemType, systemVersion: systemVersion, systemCodename: systemCodename,
        uptime: _parseUptime(rawUptime),
        cpuUsage: cpuUsage / 100,
        memoryUsage: memTotal > 0 ? memUsed / memTotal : 0.0, memoryTotal: memTotal, memoryUsed: memUsed,
        diskUsage: diskTotal > 0 ? diskUsed / diskTotal : 0.0, diskTotal: diskTotal, diskUsed: diskUsed,
        loadAverage: loadParts.take(3).map((e) => double.tryParse(e) ?? 0.0).toList(),
      );
    } catch (_) {
      return HostInfo(hostname: connection.host, ipAddress: connection.host);
    }
  }

  String _parseUptime(String raw) {
    int d = 0, h = 0, m = 0;
    final dm = RegExp(r'(\d+)\s*day').firstMatch(raw);
    if (dm != null) d = int.parse(dm.group(1)!);
    final hm = RegExp(r'(\d+)\s*hour').firstMatch(raw);
    if (hm != null) h = int.parse(hm.group(1)!);
    final mm = RegExp(r'(\d+)\s*min').firstMatch(raw);
    if (mm != null) m = int.parse(mm.group(1)!);
    if (d == 0 && h == 0 && m == 0) {
      final tm = RegExp(r'(\d+):(\d+)').firstMatch(raw);
      if (tm != null) { h = int.parse(tm.group(1)!); m = int.parse(tm.group(2)!); }
    }
    final parts = <String>[];
    if (d > 0) parts.add('${d}天');
    if (h > 0) parts.add('${h}时');
    if (m > 0) parts.add('${m}分');
    return parts.isEmpty ? raw : parts.join('');
  }

  void _broadcastCommand(String command) {
    final settings = ref.read(appSettingsProvider);
    if (!settings.commandBroadcastEnabled) return;
    final tabs = ref.read(terminalTabsProvider);
    final activeTabId = ref.read(activeTabIdProvider);
    final sessions = ref.read(activeSessionsProvider);
    for (final tab in tabs) {
      if (tab.id != activeTabId) {
        sessions.getSession(tab.id)?.write(utf8.encode(command));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    if (_isConnecting) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(), SizedBox(height: AppStyles.spacingLarge), Text('正在连接...'),
      ]));
    }
    if (_errorMessage != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: AppStyles.spacingLarge),
        Text('连接失败', style: AppStyles.titleLarge),
        const SizedBox(height: AppStyles.spacingSmall),
        Text(_errorMessage!, style: AppStyles.bodyMedium.copyWith(color: Colors.red), textAlign: TextAlign.center),
        const SizedBox(height: AppStyles.spacingLarge),
        ElevatedButton.icon(onPressed: _connect, icon: const Icon(Icons.refresh), label: const Text('重试')),
      ]));
    }
    if (isWideScreen) {
      return Row(key: _splitAreaKey, children: [
        if (settings.sftpPanelVisible)
          Expanded(flex: (settings.splitRatio * 100).toInt(), child: SftpPanel(tab: widget.tab, sshClient: _sshClient)),
        if (settings.sftpPanelVisible)
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              final rb = _splitAreaKey.currentContext?.findRenderObject() as RenderBox?;
              if (rb == null) return;
              final ratio = (details.globalPosition.dx / rb.size.width).clamp(0.15, 0.85);
              ref.read(appSettingsProvider.notifier).setSplitRatio(ratio);
            },
            child: MouseRegion(cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 4, color: Theme.of(context).dividerColor,
                // 桌面端 4px 窄条，触摸友好靠两端的内边距
              ),
            ),
          ),
        Expanded(flex: settings.sftpPanelVisible ? ((1 - settings.splitRatio) * 100).toInt() : 100, child: _buildTerminalPanel()),
      ]);
    }
    return Column(key: _splitAreaKey, children: [
      Expanded(flex: settings.sftpPanelVisible ? (settings.splitRatio * 100).toInt() : 100, child: _buildTerminalPanel()),
      if (settings.sftpPanelVisible)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) {},
          onVerticalDragUpdate: (details) {
            final rb = _splitAreaKey.currentContext?.findRenderObject() as RenderBox?;
            if (rb == null) return;
            final ratio = (details.globalPosition.dy / rb.size.height).clamp(0.15, 0.85);
            ref.read(appSettingsProvider.notifier).setSplitRatio(ratio);
          },
          child: Container(
            height: 24,
            alignment: Alignment.center,
            color: Colors.transparent,
            child: Container(
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      if (settings.sftpPanelVisible)
        Expanded(flex: ((1 - settings.splitRatio) * 100).toInt(), child: SftpPanel(tab: widget.tab, sshClient: _sshClient)),
    ]);
  }

  Widget _buildTerminalPanel() {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return Column(children: [
      if (_hostInfo != null) HostInfoBar(hostInfo: _hostInfo!),
      Expanded(
        child: isDesktop
            ? TerminalView(
                _terminal, controller: _terminalController, focusNode: _terminalFocusNode,
                autofocus: true, deleteDetection: true, hardwareKeyboardOnly: true,
                onSecondaryTapUp: (details, cellOffset) async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null && mounted) _sshSession?.write(utf8.encode(data!.text!));
                },
              )
            // Android 移动端：RawKeyboardListener + TextInputInterceptor
            : RawKeyboardListener(
                focusNode: _terminalFocusNode,
                onKey: (event) {
                  final codec = KeyCodec();
                  codec.getCtrl = () => ModifierKeyState().ctrlDown;
                  codec.getAlt = () => ModifierKeyState().altDown;
                  codec.getShift = () => ModifierKeyState().shiftDown;
                  final bytes = codec.handleKeyEvent(event);
                  if (bytes != null && _sshSession != null && mounted) {
                    _sshSession!.write(bytes);
                  }
                },
                child: TerminalView(
                  _terminal, controller: _terminalController,
                  autofocus: false, hardwareKeyboardOnly: true,
                  onSecondaryTapUp: (details, cellOffset) async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && mounted) _sshSession?.write(utf8.encode(data!.text!));
                  },
                ),
              ),
      ),
      if (!isDesktop)
        AndroidTerminalInputBar(
          onSshWrite: (bytes) {
            if (_sshSession != null && mounted) {
              _sshSession!.write(bytes);
            }
          },
          onBroadcast: (data) {
            if (data.contains('cd ')) {
              _waitingForDir = true;
              _pwdOutputBuffer = '';
            }
            _broadcastCommand(data);
          },
          inputFocusNode: _terminalFocusNode,
        ),
    ]);
  }
}
