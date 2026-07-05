import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/models.dart';
import 'secure_storage_service.dart';

/// SSH 服务类 - 管理 SSH 连接和会话
class SshService {
  /// 当前 SSH 客户端实例
  SSHClient? _client;
  
  /// 当前 SFTP 客户端实例
  SftpClient? _sftpClient;
  
  /// 当前连接配置
  ConnectionProfile? _currentProfile;
  
  /// 连接状态
  bool _isConnected = false;

  /// 获取当前连接状态
  bool get isConnected => _isConnected;

  /// 获取当前连接配置
  ConnectionProfile? get currentProfile => _currentProfile;

  /// 获取当前 SSH 客户端
  SSHClient? get client => _client;

  /// 获取当前 SFTP 客户端
  SftpClient? get sftpClient => _sftpClient;

  /// 建立 SSH 连接
  Future<SSHClient> connect(ConnectionProfile profile) async {
    _currentProfile = profile;
    
    try {
      // 获取认证凭据
      String? password;
      String? passphrase;
      Uint8List? privateKeyBytes;
      
      final secureStorage = SecureStorageService();
      
      if (profile.authType == AuthType.password) {
        password = await secureStorage.getPassword(profile.id);
        if (password == null || password.isEmpty) {
          throw Exception('密码未存储');
        }
      } else {
        // 密钥认证
        privateKeyBytes = await secureStorage.getPrivateKey(profile.id);
        passphrase = await secureStorage.getPassphrase(profile.id);
        
        if (privateKeyBytes == null) {
          throw Exception('私钥未存储');
        }
      }

      // 创建 SSH 客户端
      final socket = await SSHSocket.connect(profile.host, profile.port);
      
      _client = SSHClient(
        socket,
        username: profile.username,
        onPasswordRequest: () => password ?? '',
      );

      _isConnected = true;
      
      // 更新最后连接时间
      await _updateLastConnected(profile.id);
      
      return _client!;
    } catch (e) {
      _isConnected = false;
      _client = null;
      rethrow;
    }
  }

  /// 建立 SFTP 连接
  Future<SftpClient> connectSftp() async {
    if (_client == null) {
      throw Exception('SSH 未连接');
    }
    
    _sftpClient = await _client!.sftp();
    return _sftpClient!;
  }

  /// 执行 SSH 命令
  Future<String> executeCommand(String command) async {
    if (_client == null) {
      throw Exception('SSH 未连接');
    }
    
    final result = await _client!.run(command);
    return String.fromCharCodes(result);
  }

  /// 获取终端 Shell
  Future<SSHSession> getShell() async {
    if (_client == null) {
      throw Exception('SSH 未连接');
    }
    
    return await _client!.shell();
  }

  /// 获取主机信息
  Future<HostInfo> getHostInfo() async {
    if (_client == null) {
      throw Exception('SSH 未连接');
    }
    
    try {
      // 获取主机名
      final hostname = (await executeCommand('hostname')).trim();
      
      // 获取系统信息
      final unameResult = await executeCommand('uname -s');
      final systemType = unameResult.trim();
      
      // 获取版本信息
      final versionResult = await executeCommand('uname -r');
      final systemVersion = versionResult.trim();
      
      // 获取 IP 地址
      final ipResult = await executeCommand("hostname -I | awk '{print \$1}'");
      final ipAddress = ipResult.trim();
      
      // 获取在线时长
      final uptimeResult = await executeCommand('uptime -p');
      final uptime = uptimeResult.trim();
      
      // 获取 CPU 使用率
      final cpuResult = await executeCommand(
        "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}'"
      );
      final cpuUsage = double.tryParse(cpuResult.trim()) ?? 0.0;
      
      // 获取内存信息
      final memResult = await executeCommand(
        "free -m | awk '/Mem:/ {print \$2, \$3}'"
      );
      final memParts = memResult.trim().split(' ');
      final memoryTotal = int.tryParse(memParts.isNotEmpty ? memParts[0] : '') ?? 0;
      final memoryUsed = int.tryParse(memParts.length > 1 ? memParts[1] : '') ?? 0;
      final memoryUsage = memoryTotal > 0 ? memoryUsed / memoryTotal : 0.0;
      
      // 获取磁盘信息
      final diskResult = await executeCommand(
        "df -BG / | awk 'NR==2 {print \$2, \$3}'"
      );
      final diskParts = diskResult.trim().replaceAll('G', '').split(' ');
      final diskTotal = int.tryParse(diskParts.isNotEmpty ? diskParts[0] : '') ?? 0;
      final diskUsed = int.tryParse(diskParts.length > 1 ? diskParts[1] : '') ?? 0;
      final diskUsage = diskTotal > 0 ? diskUsed / diskTotal : 0.0;
      
      // 获取系统负载
      final loadResult = await executeCommand('cat /proc/loadavg');
      final loadParts = loadResult.trim().split(' ');
      final loadAverage = loadParts
          .take(3)
          .map((e) => double.tryParse(e) ?? 0.0)
          .toList();
      
      return HostInfo(
        hostname: hostname,
        ipAddress: ipAddress,
        systemType: systemType,
        systemVersion: systemVersion,
        uptime: uptime,
        cpuUsage: cpuUsage / 100,
        memoryUsage: memoryUsage,
        memoryTotal: memoryTotal,
        memoryUsed: memoryUsed,
        diskUsage: diskUsage,
        diskTotal: diskTotal,
        diskUsed: diskUsed,
        loadAverage: loadAverage,
      );
    } catch (e) {
      // 返回默认信息
      return HostInfo(
        hostname: _currentProfile?.host ?? '',
        ipAddress: _currentProfile?.host ?? '',
      );
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      _sftpClient?.close();
      _client?.close();
    } catch (e) {
      // 忽略断开连接时的错误
    } finally {
      _client = null;
      _sftpClient = null;
      _isConnected = false;
      _currentProfile = null;
    }
  }

  /// 更新最后连接时间
  Future<void> _updateLastConnected(String connectionId) async {
    // 这里应该更新数据库中的最后连接时间
    // 由调用方负责
  }

  /// 检查连接是否仍然有效
  Future<bool> checkConnection() async {
    if (_client == null) return false;
    
    try {
      await executeCommand('echo ok');
      return true;
    } catch (e) {
      return false;
    }
  }
}
