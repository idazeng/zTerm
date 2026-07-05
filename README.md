# zTerm

一款跨平台的 SSH + SFTP 客户端应用，支持 Windows、Linux、Android 三大平台。本项目在 Dazeng 的指导下在 AI 的加成下由工具 Reasonix 完成，目的是方便 Dazeng 对 vps 进行维护，目前只能说，能用。

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📸 截图

> （截图待添加）

---

## ✨ 功能特性

### SSH 终端
- 密码和密钥两种认证方式
- 完整终端模拟：颜色、光标样式、回滚缓冲区
- 选中即复制：鼠标划选文本后自动写入系统剪贴板
- 右键直接粘贴
- 主机概要信息条：系统名称/版本、在线时长
- 点击弹出详情窗口：CPU、内存、磁盘使用率、系统负载

### SFTP 文件管理
- 全功能文件操作：浏览、上传、下载、删除、重命名、新建
- 权限修改（chmod）
- 拖拽上传/下载（桌面端）
- 在线编辑文件（带语言标签）
- 终端工作目录同步

### 多标签与命令管理
- 多标签页，独立 SSH + SFTP 会话
- 命令片段库
- 命令广播：一键同步到所有标签

### WebDAV 同步
- 跨设备同步连接列表和命令片段
- 双向合并：相同 ID 保留最新版本
- 密码同步：一次配置，多端可用
- 支持备份与恢复

### 主机导入导出
- JSON 标准备份
- TXT 文本格式（可编辑、可导入）
- 支持明文密码导入/导出

### Android 移动端专属
- 虚拟修饰键（Ctrl/Alt/Shift）
- 系统键盘输入支持
- 英文安全键盘适配
- 分屏可拖拽

---

## 🎨 主题与样式

- Light / Dark 双主题
- 12 套主题色自由切换
- 毛玻璃（Frosted Glass）效果
- 精致圆角、弥散阴影
- 无缝平滑动画过渡
- Android 端自动降级保障性能

---

## 🛠 技术栈

| 技术 | 用途 |
|---|---|
| **Flutter** | 跨平台框架 |
| **Riverpod** | 状态管理 |
| **dartssh2** | SSH/SFTP 协议 |
| **xterm.dart** | 终端模拟 UI |
| **sqflite** | 本地数据库 |
| **flutter_secure_storage** | 加密安全存储 |
| **webdav_client** | WebDAV 同步 |

---

## 📁 项目结构

```
lib/
├── constants/        # 常量
├── input/            # Android 输入模块
├── models/           # 数据模型
├── providers/        # Riverpod 状态管理
├── screens/          # 页面
├── services/         # 服务层
├── theme/            # 全局主题样式
├── utils/            # 工具类
├── widgets/          # 可复用组件
└── main.dart         # 应用入口
```

---

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0

### 安装

```bash
git clone https://github.com/idazeng/zTerm.git
cd zTerm
flutter pub get
```

### 运行

```bash
# Windows
flutter run -d windows

# Android
flutter run -d android

# Linux
flutter run -d linux
```

### 构建发布版本

```bash
# Windows
flutter build windows --release

# Android (分架构)
flutter build apk --release --split-per-abi

# Linux
flutter build linux --release
```

---

## ⚙️ 配置说明

### 主密码
首次使用需设置主密码，用于加密保护敏感信息。

### WebDAV 同步
1. 打开设置 → WebDAV
2. 配置服务器地址、用户名、密码
3. 设置同步目录名（默认 zTerm）
4. 点击同步按钮或等待自动同步

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交改动 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 发起 Pull Request

---

## 📄 许可证

本项目基于 MIT 许可证开源，详见 [LICENSE](LICENSE) 文件。

---

## 📬 联系方式

- 邮箱：zapps@zeng.love
- 网站：https://zapps.zeng.love
- GitHub：https://github.com/idazeng/zTerm
