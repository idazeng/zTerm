import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/models.dart';

/// 文件列表项组件
class FileListTile extends StatelessWidget {
  /// 文件信息
  final SftpFile file;
  
  /// 是否选中
  final bool isSelected;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 长按回调
  final VoidCallback? onLongPress;
  
  /// 更多操作回调
  final Function(Offset)? onMorePressed;

  const FileListTile({
    super.key,
    required this.file,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingMedium,
            vertical: AppStyles.spacingSmall,
          ),
          child: Row(
            children: [
              // 文件图标
              _buildFileIcon(context),
              const SizedBox(width: AppStyles.spacingMedium),
              // 文件信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.isDirectory ? '目录' : file.readableSize,
                      style: AppStyles.caption,
                    ),
                  ],
                ),
              ),
              // 权限信息
              Text(
                file.permissionsString,
                style: AppStyles.caption,
              ),
              const SizedBox(width: AppStyles.spacingSmall),
              // 更多操作按钮
              if (onMorePressed != null)
                GestureDetector(
                  onTapDown: (details) {
                    onMorePressed!(details.globalPosition);
                  },
                  child: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建文件图标
  Widget _buildFileIcon(BuildContext context) {
    if (file.isSymbolicLink) {
      return Icon(
        Icons.link,
        color: AppColors.symlink,
        size: AppStyles.iconSizeLarge,
      );
    }
    
    if (file.isDirectory) {
      return Icon(
        Icons.folder,
        color: AppColors.folder,
        size: AppStyles.iconSizeLarge,
      );
    }
    
    // 根据文件类型返回不同图标
    final iconData = _getFileIcon(file.extension);
    final color = _getFileIconColor(file.extension);
    
    return Icon(
      iconData,
      color: color,
      size: AppStyles.iconSizeLarge,
    );
  }

  /// 根据扩展名获取文件图标
  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'txt':
      case 'log':
      case 'md':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'svg':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'cpp':
      case 'c':
      case 'h':
      case 'dart':
      case 'go':
      case 'rs':
        return Icons.code;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        return Icons.data_object;
      case 'sh':
      case 'bash':
      case 'zsh':
        return Icons.terminal;
      case 'conf':
      case 'cfg':
      case 'ini':
        return Icons.settings;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 根据扩展名获取图标颜色
  Color _getFileIconColor(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'svg':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Colors.orange;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Colors.red;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Colors.brown;
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'js':
      case 'ts':
        return Colors.yellow.shade700;
      case 'py':
        return Colors.blue;
      case 'dart':
        return Colors.cyan;
      case 'sh':
      case 'bash':
      case 'zsh':
        return Colors.green;
      default:
        return AppColors.file;
    }
  }
}
