# zsshx 项目文件清单

## 核心文件

### 配置文件
- `pubspec.yaml` - 项目配置和依赖
- `README.md` - 项目说明文档

### 应用入口
- `lib/main.dart` - 应用主入口

### 数据模型 (`lib/models/`)
- `connection_profile.dart` - SSH 连接配置模型
- `snippet.dart` - 命令片段模型
- `sftp_file.dart` - SFTP 文件信息和传输任务模型
- `terminal_tab.dart` - 终端标签模型
- `app_settings.dart` - 应用设置模型
- `host_info.dart` - 主机信息模型
- `models.dart` - 模型导出文件

### 服务层 (`lib/services/`)
- `database_service.dart` - SQLite 数据库服务
- `secure_storage_service.dart` - 安全存储服务（加密）
- `ssh_service.dart` - SSH 连接服务
- `sftp_service.dart` - SFTP 文件操作服务
- `webdav_sync_service.dart` - WebDAV 同步服务
- `services.dart` - 服务导出文件

### 状态管理 (`lib/providers/`)
- `providers.dart` - Riverpod 状态管理

### 页面 (`lib/screens/`)
- `home_screen.dart` - 主页面（标签管理）
- `terminal_screen.dart` - 终端页面
- `sftp_screen.dart` - SFTP 文件管理页面
- `settings_screen.dart` - 设置页面
- `snippets_screen.dart` - 命令片段管理页面
- `about_screen.dart` - 关于页面
- `master_password_screen.dart` - 主密码设置对话框
- `screens.dart` - 页面导出文件

### 组件 (`lib/widgets/`)
- `host_info_bar.dart` - 主机信息条组件
- `virtual_keyboard_bar.dart` - 虚拟键盘条组件
- `file_list_tile.dart` - 文件列表项组件
- `connection_edit_dialog.dart` - 连接编辑对话框
- `widgets.dart` - 组件导出文件

### 常量 (`lib/constants/`)
- `colors.dart` - 颜色定义
- `styles.dart` - 样式定义
- `constants.dart` - 常量导出文件

### 工具类 (`lib/utils/`)
- `theme.dart` - 主题配置
- `file_utils.dart` - 文件工具类
- `utils.dart` - 工具导出文件

### Android 配置
- `android/app/src/main/AndroidManifest.xml` - Android 清单文件

## 功能实现状态

### ✅ 已实现
- 数据模型设计
- 数据库服务
- 安全存储服务
- SSH 服务基础框架
- SFTP 文件操作
- WebDAV 同步逻辑
- 状态管理架构
- 主题系统
- 页面布局框架
- 基础 UI 组件

### 🚧 待完善
- 拖拽上传/下载（需 desktop_drop）
- 终端选中复制/右键粘贴（需 xterm 集成）
- 命令广播功能
- 导入/导出功能
- WebDAV 完整同步测试
- Android 快捷键支持
- 更多终端模拟功能

## 下一步

1. 安装依赖：`flutter pub get`
2. 运行应用：`flutter run`
3. 测试基本功能
4. 完善终端模拟集成
5. 添加拖拽功能
6. 测试 WebDAV 同步
7. 优化 Android 适配
