import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// 安全存储服务 - 使用 flutter_secure_storage 加密存储敏感信息
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 存储主密码哈希
  static const _masterPasswordHashKey = 'master_password_hash';
  
  /// 存储加密密钥
  static const _encryptionKeyKey = 'encryption_key';
  
  /// 密码前缀
  static const _passwordPrefix = 'password_';
  
  /// 密钥口令前缀
  static const _passphrasePrefix = 'passphrase_';
  
  /// 私钥内容前缀
  static const _privateKeyPrefix = 'private_key_';
  
  /// WebDAV 密码前缀
  static const _webdavPasswordPrefix = 'webdav_password_';

  /// 检查主密码是否已设置
  Future<bool> isMasterPasswordSet() async {
    final hash = await _storage.read(key: _masterPasswordHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// 获取主密码哈希
  Future<String?> getMasterPasswordHash() async {
    return await _storage.read(key: _masterPasswordHashKey);
  }

  /// 设置主密码
  /// 返回派生的加密密钥
  Future<String> setMasterPassword(String password) async {
    // 生成密码哈希
    final hash = _hashPassword(password);
    await _storage.write(key: _masterPasswordHashKey, value: hash);
    
    // 生成并存储加密密钥
    final key = _deriveEncryptionKey(password);
    await _storage.write(key: _encryptionKeyKey, value: key);
    
    return key;
  }

  /// 验证主密码
  Future<bool> verifyMasterPassword(String password) async {
    final storedHash = await _storage.read(key: _masterPasswordHashKey);
    if (storedHash == null) return false;
    
    return _hashPassword(password) == storedHash;
  }

  /// 更新主密码
  Future<void> updateMasterPassword(String oldPassword, String newPassword) async {
    // 验证旧密码
    final isValid = await verifyMasterPassword(oldPassword);
    if (!isValid) {
      throw Exception('旧密码验证失败');
    }
    
    // 设置新密码
    await setMasterPassword(newPassword);
  }

  /// 获取加密密钥
  Future<String?> _getEncryptionKey() async {
    return await _storage.read(key: _encryptionKeyKey);
  }

  /// 加密数据
  Future<String> encryptData(String plainText) async {
    final keyString = await _getEncryptionKey();
    if (keyString == null) {
      throw Exception('未设置主密码');
    }
    
    final key = encrypt.Key.fromBase64(keyString);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// 解密数据
  Future<String> decryptData(String cipherText) async {
    final keyString = await _getEncryptionKey();
    if (keyString == null) {
      throw Exception('未设置主密码');
    }
    
    final parts = cipherText.split(':');
    if (parts.length != 2) {
      throw Exception('无效的加密数据格式');
    }
    
    final key = encrypt.Key.fromBase64(keyString);
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  /// 存储连接密码
  Future<void> storePassword(String connectionId, String password) async {
    final encrypted = await encryptData(password);
    await _storage.write(
      key: '$_passwordPrefix$connectionId',
      value: encrypted,
    );
  }

  /// 获取连接密码
  Future<String?> getPassword(String connectionId) async {
    final encrypted = await _storage.read(key: '$_passwordPrefix$connectionId');
    if (encrypted == null) return null;
    
    try {
      return await decryptData(encrypted);
    } catch (e) {
      return null;
    }
  }

  /// 删除连接密码
  Future<void> deletePassword(String connectionId) async {
    await _storage.delete(key: '$_passwordPrefix$connectionId');
  }

  /// 存储密钥口令
  Future<void> storePassphrase(String connectionId, String passphrase) async {
    final encrypted = await encryptData(passphrase);
    await _storage.write(
      key: '$_passphrasePrefix$connectionId',
      value: encrypted,
    );
  }

  /// 获取密钥口令
  Future<String?> getPassphrase(String connectionId) async {
    final encrypted = await _storage.read(key: '$_passphrasePrefix$connectionId');
    if (encrypted == null) return null;
    
    try {
      return await decryptData(encrypted);
    } catch (e) {
      return null;
    }
  }

  /// 删除密钥口令
  Future<void> deletePassphrase(String connectionId) async {
    await _storage.delete(key: '$_passphrasePrefix$connectionId');
  }

  /// 存储私钥内容
  Future<void> storePrivateKey(String connectionId, Uint8List keyBytes) async {
    final base64Key = base64Encode(keyBytes);
    final encrypted = await encryptData(base64Key);
    await _storage.write(
      key: '$_privateKeyPrefix$connectionId',
      value: encrypted,
    );
  }

  /// 获取私钥内容
  Future<Uint8List?> getPrivateKey(String connectionId) async {
    final encrypted = await _storage.read(key: '$_privateKeyPrefix$connectionId');
    if (encrypted == null) return null;
    
    try {
      final base64Key = await decryptData(encrypted);
      return base64Decode(base64Key);
    } catch (e) {
      return null;
    }
  }

  /// 删除私钥
  Future<void> deletePrivateKey(String connectionId) async {
    await _storage.delete(key: '$_privateKeyPrefix$connectionId');
  }

  /// 存储 WebDAV 密码
  Future<void> storeWebdavPassword(String userId, String password) async {
    final encrypted = await encryptData(password);
    await _storage.write(
      key: '$_webdavPasswordPrefix$userId',
      value: encrypted,
    );
  }

  /// 获取 WebDAV 密码
  Future<String?> getWebdavPassword(String userId) async {
    final encrypted = await _storage.read(key: '$_webdavPasswordPrefix$userId');
    if (encrypted == null) return null;
    
    try {
      return await decryptData(encrypted);
    } catch (e) {
      return null;
    }
  }

  /// 删除 WebDAV 密码
  Future<void> deleteWebdavPassword(String userId) async {
    await _storage.delete(key: '$_webdavPasswordPrefix$userId');
  }

  /// 清除所有安全存储
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// 生成密码哈希
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 从密码派生加密密钥
  String _deriveEncryptionKey(String password) {
    // 使用 PBKDF2 类似的方式派生密钥
    final keyMaterial = utf8.encode('$password-zTerm-encryption-key');
    final bytes = sha256.convert(keyMaterial);
    return base64Encode(bytes.bytes);
  }
}
