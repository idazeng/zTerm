import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../theme/glass_container.dart';

/// 主机信息条组件 - 显示在终端上方
class HostInfoBar extends StatelessWidget {
  final HostInfo hostInfo;

  const HostInfoBar({
    super.key,
    required this.hostInfo,
  });

  /// 获取系统显示名称（如 "Debian 13 (Trixie)"）
  String _getSystemDisplayName() {
    final parts = <String>[];
    if (hostInfo.systemType.isNotEmpty) parts.add(hostInfo.systemType);
    // 从内核版本中提取主版本号
    final versionMatch = RegExp(r'(\d+)').firstMatch(hostInfo.systemVersion);
    if (versionMatch != null) parts.add(versionMatch.group(1)!);
    if (hostInfo.systemCodename.isNotEmpty) {
      parts.add('(${hostInfo.systemCodename})');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHostInfoDetails(context),
      child: GlassContainer.toolbar(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingMedium,
          vertical: AppStyles.spacingExtraSmall,
        ),
        child: Row(
          children: [
            // 连接图标
            Icon(
              Icons.circle,
              size: 8,
              color: AppColors.success,
            ),
            const SizedBox(width: AppStyles.spacingSmall),
            // 系统名称（如 Debian 13 (Trixie)）
            Expanded(
              child: Text(
                _getSystemDisplayName(),
                style: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppStyles.spacingSmall),
            // 在线时长
            Text(
              hostInfo.uptime,
              style: AppStyles.caption,
            ),
            const SizedBox(width: AppStyles.spacingSmall),
            // 详情按钮
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  /// 显示主机信息详情
  void _showHostInfoDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('操作系统信息'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('操作系统', '${hostInfo.systemType} ${hostInfo.systemVersion}${hostInfo.systemCodename.isNotEmpty ? " (${hostInfo.systemCodename})" : ""}'),
              _buildInfoRow('主机名', hostInfo.hostname),
              // IP 地址（点击复制）
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        'IP 地址:',
                        style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: hostInfo.ipAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('IP ${hostInfo.ipAddress} 已复制'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                hostInfo.ipAddress,
                                style: AppStyles.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy, size: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildInfoRow('在线时长', hostInfo.uptime),
              const Divider(),
              _buildInfoRow('CPU 使用率', '${(hostInfo.cpuUsage * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('内存', hostInfo.memoryDisplay),
              _buildInfoRow('磁盘', hostInfo.diskDisplay),
              _buildInfoRow('系统负载', hostInfo.loadDisplay),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              final info = '''
操作系统: ${hostInfo.systemType} ${hostInfo.systemVersion}${hostInfo.systemCodename.isNotEmpty ? " (${hostInfo.systemCodename})" : ""}
主机名: ${hostInfo.hostname}
IP: ${hostInfo.ipAddress}
在线: ${hostInfo.uptime}
CPU: ${(hostInfo.cpuUsage * 100).toStringAsFixed(1)}%
内存: ${hostInfo.memoryDisplay}
磁盘: ${hostInfo.diskDisplay}
负载: ${hostInfo.loadDisplay}
''';
              Clipboard.setData(ClipboardData(text: info));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: AppStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}
