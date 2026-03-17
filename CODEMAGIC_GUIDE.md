# Codemagic iOS 编译专属指南

## 🚀 零配置快速开始

你无需修改任何代码，直接按照以下步骤操作即可完成编译：

### 第一步：准备工作
1. ✅ 项目根目录已经包含 `codemagic.yaml` 配置文件（我已经为你创建好了）
2. ✅ 项目已经完全配置好，无需修改任何代码
3. ✅ 最低支持 iOS 12.0，已包含所有必要权限配置

### 第二步：上传代码到 GitHub
1. 如果你还没有 GitHub 账号，先注册一个：https://github.com/
2. 创建一个新的仓库（建议设为私有）
3. 将你的 ebook_converter 项目推送到 GitHub 仓库

```bash
# 示例命令（替换为你自己的仓库地址）
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/your-username/ebook_converter.git
git push -u origin main
```

### 第三步：配置 Codemagic
1. 访问 Codemagic 官网：https://codemagic.io/start/
2. 使用 GitHub 账号注册/登录
3. 在控制台点击 "Add application"
4. 选择 GitHub 作为源代码提供商
5. 选择你刚刚上传的 ebook_converter 仓库
6. 项目类型选择 "Flutter"，点击 "Finish"

### 第四步：开始编译
1. Codemagic 会自动识别项目根目录下的 `codemagic.yaml` 配置文件
2. 点击 "Start new build" 按钮
3. 选择工作流："flutter-ios-build"
4. 点击 "Start new build" 开始编译

### 第五步：下载 IPA
- 编译过程大约需要 10-15 分钟
- 编译完成后，在 "Artifacts" 标签页可以下载生成的 IPA 文件
- 你注册的邮箱也会收到编译完成的通知邮件

---

## 📝 配置说明

### 默认配置（无需修改即可使用）
- 自动使用最新稳定版 Flutter SDK
- 自动使用最新版 Xcode
- 自动安装所有依赖
- 编译 Release 版本的 IPA 包
- 编译成功后自动发送邮件通知

### 高级配置（可选）
如果你需要自动上传到 App Store Connect 或 TestFlight，可以按照以下步骤配置：

1. **获取 App Store Connect API 密钥**
   - 登录 App Store Connect：https://appstoreconnect.apple.com/
   - 进入 "用户和访问" → "密钥" → "生成密钥"
   - 下载 `.p8` 私钥文件，保存好 Key ID 和 Issuer ID

2. **在 Codemagic 中配置环境变量**
   - 进入项目设置 → "Environment variables"
   - 添加以下变量（勾选 "Secure" 选项加密存储）：
     - `APP_STORE_CONNECT_ISSUER_ID`: 你的 Issuer ID
     - `APP_STORE_CONNECT_KEY_IDENTIFIER`: 你的 Key ID
     - `APP_STORE_CONNECT_PRIVATE_KEY`: `.p8` 文件的全部内容
     - `CERTIFICATE_PRIVATE_KEY`: 证书私钥密码（如果有）

3. **启用自动上传**
   - 编辑 `codemagic.yaml` 文件，取消注释末尾的 `app_store_connect` 部分
   - 重新推送代码到 GitHub，下次编译就会自动上传到 TestFlight

---

## 💰 免费额度说明
- 个人免费计划：每月 500 分钟构建时间
- 每次 iOS 编译大约需要 10-15 分钟
- 每月可以免费编译 30-50 次，足够个人开发使用
- 如果超出额度，可以按需购买，价格约 $0.03/分钟

---

## 🔍 常见问题

### Q: 编译失败怎么办？
A: 查看构建日志，最常见的问题是：
1. 代码中有语法错误，修复后重新提交即可
2. 依赖包版本冲突，修改 `pubspec.yaml` 中的版本号
3. 证书配置问题，如果不需要发布到 App Store，可以使用测试证书

### Q: 如何安装 IPA 到测试设备？
A: 可以使用以下方法：
1. 使用 Xcode 连接设备直接安装
2. 使用 [Transporter](https://apps.apple.com/cn/app/transporter/id1450874784) 应用上传到 App Store Connect
3. 使用爱思助手、PP助手等第三方工具安装
4. 使用 TestFlight 进行内部测试分发

### Q: 不需要开发者账号可以编译吗？
A: 可以编译测试版，但是：
- 测试版只能安装到已经在开发者账号中注册的设备
- 如果要发布到 App Store，必须有苹果开发者账号（99美元/年）
- 国内平台 Appuploader 提供测试证书服务，可以无需开发者账号编译测试版

### Q: 编译速度慢怎么办？
A:
- Codemagic 的构建机器配置很高，通常 10-15 分钟就能完成
- 首次编译需要下载依赖，速度会慢一些，后续编译会有缓存
- 如果需要更快的速度，可以升级到付费计划，使用更快的构建机器

---

## 📞 技术支持
如果遇到问题，可以查看：
- Codemagic 官方文档：https://docs.codemagic.io/
- Flutter 官方 iOS 发布指南：https://docs.flutter.dev/deployment/ios
- 项目 Issues 页面提交问题

---

**现在你只需要将代码推送到 GitHub，然后在 Codemagic 中导入项目，点击开始编译就可以了！整个过程不需要任何 macOS 设备，完全在线完成。**