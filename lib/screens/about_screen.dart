import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/constants.dart';

/// 关于页面
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 应用图标和名称
            const SizedBox(height: AppStyles.spacingExtraLarge * 2),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
              ),
              child: Icon(
                Icons.computer,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppStyles.spacingLarge),
            Text(
              '终端',
              style: AppStyles.titleLarge,
            ),
            Text(
              'zTerm v1.0.0',
              style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: AppStyles.spacingExtraLarge * 2),
            
            // 功能介绍
            _buildSection(
              context,
              title: '应用介绍',
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.spacingLarge),
                child: Text(
                  'zTerm 是一款跨平台的 SSH + SFTP 客户端应用，'
                  '支持 Windows 和 Android 平台。提供完整的终端模拟、'
                  '文件管理、多标签页、命令片段库等功能。',
                  style: AppStyles.bodyMedium,
                ),
              ),
            ),
            
            // 主要功能
            _buildSection(
              context,
              title: '主要功能',
              child: Column(
                children: [
                  _buildFeatureItem(
                    Icons.terminal,
                    'SSH 终端',
                    '支持密码和密钥认证，完整终端模拟',
                  ),
                  _buildFeatureItem(
                    Icons.folder,
                    'SFTP 文件管理',
                    '浏览、上传、下载、删除、重命名文件',
                  ),
                  _buildFeatureItem(
                    Icons.tab,
                    '多标签页',
                    '同时管理多个 SSH 连接',
                  ),
                  _buildFeatureItem(
                    Icons.code,
                    '命令片段库',
                    '保存常用命令，快速插入',
                  ),
                  _buildFeatureItem(
                    Icons.sync,
                    'WebDAV 同步',
                    '跨设备同步连接和命令片段',
                  ),
                  _buildFeatureItem(
                    Icons.phone_android,
                    '双端支持',
                    'Windows 桌面端和 Android 移动端',
                  ),
                ],
              ),
            ),
            
            // 技术信息
            _buildSection(
              context,
              title: '技术信息',
              child: Column(
                children: [
                  _buildInfoItem('版本号', '1.0.0'),
                  _buildInfoItem('框架', 'Flutter'),
                  _buildInfoItem('包名', 'love.zeng.zterm'),
                  _buildInfoItem('目标平台', 'Windows, Android'),
                ],
              ),
            ),
            
            // 开源许可
            _buildSection(
              context,
              title: '开源许可',
              child: ListTile(
                leading: const Icon(Icons.code),
                title: const Text('查看开源许可'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'zTerm',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
            ),
            
            // 联系方式
            _buildSection(
              context,
              title: '联系方式',
              child: Column(
                children: [
                  _buildContactItem(
                    Icons.email,
                    '邮箱',
                    'zapps@zeng.love',
                    () => _launchUrl('mailto:zapps@zeng.love'),
                  ),
                  _buildContactItem(
                    Icons.language,
                    '网站',
                    'https://zapps.zeng.love',
                    () => _launchUrl('https://zapps.zeng.love'),
                  ),
                  _buildContactItem(
                    Icons.code,
                    'GitHub',
                    'https://github.com/idazeng/zTerm',
                    () => _launchUrl('https://github.com/idazeng/zTerm'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppStyles.spacingExtraLarge * 2),
            
            // 版权信息
            Padding(
              padding: const EdgeInsets.all(AppStyles.spacingLarge),
              child: Text(
                '© 2024 zTerm. All rights reserved.',
                style: AppStyles.bodySmall.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: AppStyles.spacingLarge),
          ],
        ),
      ),
    );
  }

  /// 构建分组
  Widget _buildSection(BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingLarge,
        vertical: AppStyles.spacingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppStyles.spacingLarge,
              AppStyles.spacingLarge,
              AppStyles.spacingLarge,
              AppStyles.spacingSmall,
            ),
            child: Text(
              title,
              style: AppStyles.titleSmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// 构建功能项
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingLarge,
        vertical: AppStyles.spacingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyMedium),
          Text(value, style: AppStyles.bodyMedium.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  /// 构建联系方式项
  Widget _buildContactItem(
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      onTap: onTap,
    );
  }

  /// 打开链接
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
