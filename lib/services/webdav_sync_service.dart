import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../models/models.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';

/// WebDAV sync service - bidirectional merge sync
class WebdavSyncService {
  webdav.Client? _client;
  String _syncDir = 'zTerm';
  final DatabaseService _dbService;
  final SecureStorageService _secureStorage;
  
  /// AES 加密密钥（从主密码派生）
  encrypt_lib.Key? _encryptionKey;

  WebdavSyncService(this._dbService, this._secureStorage);

  String get _syncPath => '/$_syncDir';

  Future<void> initialize({
    required String url,
    required String username,
    required String password,
    String subdirectory = 'zTerm',
  }) async {
    try {
      _syncDir = subdirectory;
      _client = webdav.newClient(url, user: username, password: password);
      await _client!.ping();
      await _secureStorage.storeWebdavPassword(username, password);
      await _ensureSyncDirectory();
      // 初始化加密密钥
      await _initEncryptionKey();
    } catch (e) {
      throw Exception('初始化 WebDAV 连接失败: $e');
    }
  }

  /// 从主密码派生 AES 加密密钥
  Future<void> _initEncryptionKey() async {
    _encryptionKey = null;
    try {
      final h = await _secureStorage.getMasterPasswordHash();
      if (h != null && h.length >= 32) {
        // 使用 SHA-256 哈希的前 32 字符作为 AES-256 密钥
        final keyStr = h.substring(0, 32);
        _encryptionKey = encrypt_lib.Key.fromUtf8(keyStr);
      }
    } catch (_) {}
  }

  /// AES 加密密码（格式: AES:base64iv:base64data）
  String? _encryptPassword(String? plain) {
    if (plain == null || plain.isEmpty || _encryptionKey == null) return plain;
    try {
      final iv = encrypt_lib.IV.fromLength(16);
      final enc = encrypt_lib.Encrypter(encrypt_lib.AES(_encryptionKey!));
      final encrypted = enc.encrypt(plain, iv: iv);
      return 'AES:${iv.base64}:${encrypted.base64}';
    } catch (_) { return plain; }
  }

  /// AES 解密密码
  String? _decryptPassword(String? data) {
    if (data == null || data.isEmpty || !data.startsWith('AES:') || _encryptionKey == null) return data;
    try {
      final parts = data.split(':');
      if (parts.length != 3) return data;
      final iv = encrypt_lib.IV.fromBase64(parts[1]);
      final enc = encrypt_lib.Encrypter(encrypt_lib.AES(_encryptionKey!));
      return enc.decrypt(encrypt_lib.Encrypted.fromBase64(parts[2]), iv: iv);
    } catch (_) { return null; }
  }

  Future<bool> restoreConnection() async {
    try {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _ensureSyncDirectory() async {
    try {
      await _client!.mkdir(_syncPath);
    } catch (e) {
      // directory may already exist
    }
  }

  /// Bidirectional sync: download → merge → save locally → upload merged
  Future<String> sync() async {
    if (_client == null) throw Exception('WebDAV 未连接');
    // 确保密钥已初始化
    if (_encryptionKey == null) await _initEncryptionKey();

    // 1. Get local data (password not stored in db, load from secure storage)
    final localConnections = await _dbService.getAllConnections();
    // 补充密码：从 secure storage 加载
    for (final conn in localConnections) {
      if (conn.authType == AuthType.password) {
        try {
          final pwd = await _secureStorage.getPassword(conn.id);
          if (pwd != null && pwd.isNotEmpty) {
            // 如果密码是 AES 加密的，尝试解密
            final decrypted = _decryptPassword(pwd);
            final finalPwd = decrypted ?? pwd;
            localConnections[localConnections.indexOf(conn)] = conn.copyWith(password: finalPwd);
          }
        } catch (_) {}
      }
    }
    final localSnippets = await _dbService.getAllSnippets();

    // 2. Try to download remote data
    List<ConnectionProfile> remoteConnections = [];
    List<Snippet> remoteSnippets = [];
    bool hasRemoteData = false;

    try {
      final connectionsResponse = await _client!.read('$_syncPath/connections.json');
      final connectionsData = utf8.decode(connectionsResponse as List<int>);
      final connectionsJson = jsonDecode(connectionsData) as List;
      remoteConnections = connectionsJson.map((j) {
        final conn = ConnectionProfile.fromJson(Map<String, dynamic>.from(j));
        if (conn.password != null && conn.password!.isNotEmpty) {
          return conn.copyWith(password: _decryptPassword(conn.password));
        }
        return conn;
      }).toList();
      hasRemoteData = true;
    } catch (e) {
      // No remote data yet, will upload local
    }

    try {
      final snippetsResponse = await _client!.read('$_syncPath/snippets.json');
      final snippetsData = utf8.decode(snippetsResponse as List<int>);
      final snippetsJson = jsonDecode(snippetsData) as List;
      remoteSnippets = snippetsJson.map((j) => Snippet.fromJson(Map<String, dynamic>.from(j))).toList();
    } catch (e) {
      // No remote data yet
    }

    // 3. Merge: same ID → keep latest updatedAt; different IDs → union
    final mergedConnections = _mergeConnections(localConnections, remoteConnections);
    final mergedSnippets = _mergeSnippets(localSnippets, remoteSnippets);

    // 4. Save merged data locally
    await _dbService.importConnections(mergedConnections);
    await _dbService.importSnippets(mergedSnippets);

    // 4.5. Store passwords in secure storage for cross-device access
    for (final conn in mergedConnections) {
      if (conn.password != null && conn.password!.isNotEmpty) {
        final toStore = _decryptPassword(conn.password) ?? conn.password!;
        await _secureStorage.storePassword(conn.id, toStore);
      }
    }

    // 5. Upload merged data back to WebDAV (encrypt passwords)
    final connectionsJson = mergedConnections.map((c) {
      final json = c.toJson(includePassword: true);
      if (json.containsKey('password') && json['password'] != null && (json['password'] as String).isNotEmpty) {
        json['password'] = _encryptPassword(json['password'] as String);
      }
      return json;
    }).toList();
    final snippetsJson = mergedSnippets.map((s) => s.toJson()).toList();

    await _client!.write('$_syncPath/connections.json', utf8.encode(jsonEncode(connectionsJson)));
    await _client!.write('$_syncPath/snippets.json', utf8.encode(jsonEncode(snippetsJson)));

    final syncInfo = {
      'lastSync': DateTime.now().toIso8601String(),
      'connectionsCount': mergedConnections.length,
      'snippetsCount': mergedSnippets.length,
    };
    await _client!.write('$_syncPath/sync_info.json', utf8.encode(jsonEncode(syncInfo)));

    // Build summary
    final parts = <String>[];
    parts.add('${mergedConnections.length} 连接');
    parts.add('${mergedSnippets.length} 片段');
    if (!hasRemoteData) parts.add('首次上传');
    return parts.join('，');
  }

  /// Merge connections: same ID → keep latest updatedAt; different IDs → union
  List<ConnectionProfile> _mergeConnections(
    List<ConnectionProfile> local,
    List<ConnectionProfile> remote,
  ) {
    final merged = <String, ConnectionProfile>{};

    // Add all local
    for (final conn in local) {
      merged[conn.id] = conn;
    }

    // Merge remote
    for (final conn in remote) {
      final localConn = merged[conn.id];
      if (localConn == null) {
        // Remote-only: add it (with password from remote)
        merged[conn.id] = conn;
      } else {
        // Same ID: keep the one with latest updatedAt
        if (conn.updatedAt.isAfter(localConn.updatedAt)) {
          // Remote is newer: use remote data, prefer local password if available
          final localPwd = localConn.password;
          final remotePwd = conn.password;
          merged[conn.id] = conn.copyWith(
            password: (localPwd != null && localPwd.isNotEmpty) ? localPwd : remotePwd,
            passphrase: (localConn.passphrase != null && localConn.passphrase!.isNotEmpty) ? localConn.passphrase : conn.passphrase,
          );
        }
        // else: local is newer, keep local (already in map)
      }
    }

    return merged.values.toList();
  }

  /// Merge snippets: same ID → keep latest updatedAt; different IDs → union
  List<Snippet> _mergeSnippets(
    List<Snippet> local,
    List<Snippet> remote,
  ) {
    final merged = <String, Snippet>{};

    for (final snippet in local) {
      merged[snippet.id] = snippet;
    }

    for (final snippet in remote) {
      final localSnippet = merged[snippet.id];
      if (localSnippet == null) {
        merged[snippet.id] = snippet;
      } else {
        if (snippet.updatedAt.isAfter(localSnippet.updatedAt)) {
          merged[snippet.id] = snippet;
        }
      }
    }

    return merged.values.toList();
  }

  /// Upload to cloud (for backward compatibility, calls sync)
  Future<void> syncToCloud() async {
    await sync();
  }

  /// Download from cloud (for backward compatibility, calls sync)
  Future<void> syncFromCloud() async {
    await sync();
  }

  Future<void> backupToLocal(String backupPath) async {
    try {
      final connections = await _dbService.getAllConnections();
      final snippets = await _dbService.getAllSnippets();
      final backupData = {
        'version': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'connections': connections.map((c) => c.toJson(includePassword: true)).toList(),
        'snippets': snippets.map((s) => s.toJson()).toList(),
      };
      final file = File(backupPath);
      await file.writeAsString(jsonEncode(backupData));
    } catch (e) {
      throw Exception('备份失败: $e');
    }
  }

  Future<void> restoreFromLocal(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) throw Exception('备份文件不存在');
      final backupData = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final connectionsJson = backupData['connections'] as List? ?? [];
      final connections = connectionsJson.map((j) => ConnectionProfile.fromJson(Map<String, dynamic>.from(j))).toList();
      final snippetsJson = backupData['snippets'] as List? ?? [];
      final snippets = snippetsJson.map((j) => Snippet.fromJson(Map<String, dynamic>.from(j))).toList();
      await _dbService.clearAll();
      await _dbService.importConnections(connections);
      await _dbService.importSnippets(snippets);
      final secureStorage = SecureStorageService();
      for (final conn in connections) {
        if (conn.password != null && conn.password!.isNotEmpty) {
          await secureStorage.storePassword(conn.id, conn.password!);
        }
      }
    } catch (e) {
      throw Exception('恢复失败: $e');
    }
  }

  bool get isConnected => _client != null;
  void disconnect() { _client = null; }
}
