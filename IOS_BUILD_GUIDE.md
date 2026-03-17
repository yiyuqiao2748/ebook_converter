# iOS 应用编译指南

## 📋 编译方案选择

### 方案一：本地 macOS 编译（推荐）
需要 macOS 系统 + Xcode 环境，编译流程最稳定。

#### 环境要求
- macOS 13.0 或更高版本
- Xcode 14.0 或更高版本
- Flutter SDK 3.10.0 或更高版本
- CocoaPods 1.12.0 或更高版本

---

### 方案二：在线云编译（Windows/Linux 用户推荐）
无需 macOS 设备，使用云编译平台直接在线编译 iOS 应用。

## 编译步骤

### 1. 安装 Flutter SDK
```bash
# 下载 Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
# 添加到 PATH
export PATH="$PATH:`pwd`/flutter/bin"
# 验证安装
flutter doctor
```

### 2. 安装依赖
```bash
# 进入项目目录
cd ebook_converter

# 安装 Flutter 依赖
flutter pub get

# 安装 iOS 依赖
cd ios
pod install
cd ..
```

### 3. 配置 Xcode
```bash
# 打开 Xcode 工作区
open ios/Runner.xcworkspace
```

在 Xcode 中：
1. 选择你的开发团队（Signing & Capabilities → Team）
2. 确认 Bundle Identifier（建议修改为你自己的，如 com.yourcompany.ebookconverter）
3. 确认 iOS 部署目标为 12.0 或更高

### 4. 编译 IPA 包
```bash
# 编译 release 版本
flutter build ipa --release

# 或者直接在 Xcode 中选择 Product → Archive
```

编译完成后，IPA 文件将输出到：
`build/ios/ipa/ebook_converter.ipa`

### 5. 安装到设备
- 使用 Xcode 直接安装到连接的 iOS 设备
- 或者使用 Transporter 应用上传到 App Store Connect
- 或者使用爱思助手等工具安装到测试设备

## 项目配置说明
- **应用名称**：电子书转换器
- **Bundle ID**：可在 Xcode 中自定义
- **版本号**：2.0.0 (build 1)
- **最低 iOS 版本**：iOS 12.0
- **权限配置**：已包含文件访问、相册访问等必要权限

## 常见问题
1. **CocoaPods 安装失败**：运行 `sudo gem install cocoapods` 或使用 Homebrew 安装
2. **签名错误**：确认 Xcode 中选择了正确的开发团队和证书
3. **依赖冲突**：尝试删除 `ios/Pods` 目录和 `Podfile.lock`，重新运行 `pod install`

## 测试版本
如果你需要测试版本，可以使用以下命令生成调试版：
```bash
flutter build ipa --debug
```
调试版可以安装到已注册的测试设备上。

---

## ☁️ 在线云编译详细教程

### 🌟 推荐平台对比

| 平台 | 免费额度 | 支持 Flutter | 国内访问 | 学习成本 | 推荐指数 |
|------|----------|--------------|----------|----------|----------|
| **Codemagic** | 500分钟/月免费 | ✅ 原生支持 | ❌ 需要翻墙 | 低 | ⭐⭐⭐⭐⭐ |
| **Appcircle** | 30分钟/次免费 | ✅ 原生支持 | ❌ 需要翻墙 | 中 | ⭐⭐⭐⭐ |
| **Bitrise** | 300分钟/月免费 | ✅ 支持 | ❌ 需要翻墙 | 中 | ⭐⭐⭐⭐ |
| **Appuploader** | 按次收费 | ✅ 支持 | ✅ 国内可用 | 低 | ⭐⭐⭐⭐ |
| **一门APP** | 按次收费（约30元/次） | ✅ 支持 | ✅ 国内可用 | 极低 | ⭐⭐⭐ |
| **GitHub Actions** | 500分钟/月免费 | ✅ 支持 | ✅ 国内可用 | 高 | ⭐⭐⭐ |

---

### 📖 Codemagic 在线编译教程（最推荐）
Codemagic 是专门为 Flutter 打造的 CI/CD 平台，原生支持 Flutter iOS 编译。

#### 操作步骤：
1. **注册账号**
   - 访问 [codemagic.io](https://codemagic.io/start/)
   - 使用 GitHub/GitLab/Bitbucket 账号注册

2. **导入项目**
   - 将你的 Flutter 项目推送到 GitHub/GitLab
   - 在 Codemagic 控制台导入项目仓库

3. **配置构建流程**
   - 选择 Flutter 作为项目类型
   - 构建目标选择 "iOS"
   - 构建类型选择 "Release"
   - 配置 iOS 开发证书（可以使用 Codemagic 自动管理）

4. **开始构建**
   - 点击 "Start build" 按钮
   - 等待约 10-15 分钟完成构建
   - 构建完成后直接下载 IPA 包

5. **特点**
   - 完全自动化，无需手动配置
   - 支持自动上传到 App Store Connect
   - 提供详细的构建日志便于排错
   - 免费额度足够个人开发者使用

---

### 🇨🇳 国内平台：Appuploader 编译教程
适合不想翻墙的国内用户。

#### 操作步骤：
1. **访问官网**
   - 访问 [www.appuploader.net](https://www.appuploader.net/)
   - 注册账号并购买编译服务

2. **上传项目**
   - 将整个 Flutter 项目打包为 ZIP 文件
   - 上传到 Appuploader 平台
   - 选择 "Flutter iOS 编译" 服务

3. **配置信息**
   - 填写 Bundle ID
   - 上传开发者证书（如果没有可以使用平台的测试证书）
   - 选择编译版本

4. **下载 IPA**
   - 等待约 20-30 分钟
   - 编译完成后下载 IPA 包

---

### 🇨🇳 国内平台：一门APP 编译教程
操作最简单，适合非技术用户。

#### 操作步骤：
1. **访问官网**
   - 访问 [www.yimenapp.com](https://www.yimenapp.com/)
   - 注册账号

2. **选择服务**
   - 选择 "iOS 云编译" 服务
   - 支付编译费用（约 30-50 元/次）

3. **上传代码**
   - 上传 Flutter 项目 ZIP 包
   - 填写基本应用信息

4. **获取 IPA**
   - 平台自动完成编译
   - 下载生成的 IPA 安装包

---

### 🔧 GitHub Actions 自托管编译（适合技术用户）
完全免费，可自定义编译流程。

#### 配置方法：
在项目中创建 `.github/workflows/ios-build.yml` 文件，内容如下：
```yaml
name: iOS Build
on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3

    - name: Install Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.0'

    - name: Install dependencies
      run: flutter pub get

    - name: Build iOS
      run: |
        cd ios
        pod install
        cd ..
        flutter build ipa --release

    - name: Upload IPA
      uses: actions/upload-artifact@v3
      with:
        name: ios-ipa
        path: build/ios/ipa/*.ipa
```

每次推送代码到 GitHub 时，会自动触发编译，完成后可以在 Actions 页面下载 IPA 文件。

---

## ⚠️ 云编译注意事项

### 开发者账号要求
- 所有云编译平台如果需要发布到 App Store，都需要你有有效的 Apple 开发者账号（$99/年）
- 如果只是测试使用，可以使用企业证书或测试证书，但无法上架 App Store

### 代码安全
- 使用第三方云编译平台时，注意保护源代码安全
- 敏感信息不要硬编码在代码中
- 推荐使用开源的 CI/CD 平台如 GitHub Actions

### 费用说明
- 国际平台（Codemagic/Bitrise）的免费额度足够个人小项目使用
- 国内平台通常按次收费，适合偶尔编译的用户
- 高频使用建议购买包月套餐

### 编译时间
- 云编译通常需要 10-30 分钟，取决于项目大小和平台负载
- 第一次编译时间较长，后续编译会有缓存加速

---

## ❓ 常见问题

**Q: 没有 Apple 开发者账号可以编译吗？**
A: 可以编译，但生成的 IPA 只能用于测试，无法上架 App Store。部分平台提供测试证书，可以安装到指定设备上测试。

**Q: 云编译安全吗？代码会不会泄露？**
A: 知名平台（Codemagic/GitHub）都有严格的安全保障，代码不会泄露。国内平台建议仔细阅读隐私政策。

**Q: 编译失败怎么办？**
A: 查看构建日志，通常失败原因是：
   - 依赖项缺失：确保 pubspec.yaml 配置正确
   - 证书问题：检查开发者证书配置
   - Flutter 版本不兼容：指定与本地开发一致的 Flutter 版本

**Q: 可以直接编译为可安装的 IPA 吗？**
A: 是的，所有平台编译完成后都会生成标准的 .ipa 文件，可以直接安装或上架。

---

## 🎯 项目状态
本项目已经完成所有 iOS 配置：
- ✅ Podfile 配置正确，iOS 版本 12.0+
- ✅ Info.plist 权限配置完整（文件访问、相册访问等）
- ✅ 应用图标和启动图已配置
- ✅ 所有依赖项已在 pubspec.yaml 中声明

无论选择哪种编译方案，项目代码都无需修改，直接上传即可编译。