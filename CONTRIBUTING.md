# 贡献指南

感谢你考虑为 zTerm 做出贡献！

## 开发环境

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0
- Android Studio / VS Code
- Windows SDK（Windows 构建需要）
- Android SDK（Android 构建需要）

## 代码规范

- 遵循 [Dart 官方风格指南](https://dart.dev/guides/language/effective-dart/style)
- 使用 `flutter format` 格式化代码
- 新增文件需在对应 barrel 文件（`screens.dart`、`widgets.dart`）中导出
- 主题相关常量定义在 `lib/theme/` 下
- 不建议在业务组件中硬编码样式值

## 分支管理

- `main` — 稳定发布分支
- `dev` — 开发分支
- `feature/*` — 特性分支

## 提交流程

1. Fork 仓库并创建你的特性分支
2. 在本地进行开发
3. 确保代码通过编译：`flutter build windows --release`
4. 提交 Pull Request 到 `dev` 分支

## 功能测试

- SSH 连接测试（密码 + 密钥）
- SFTP 文件操作测试
- 双主题切换测试
- WebDAV 同步测试
- Android 移动端输入测试

## 问题反馈

请通过 GitHub Issues 提交 Bug 报告或功能建议。
