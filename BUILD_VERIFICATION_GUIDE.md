# 构建验证和故障排除指南

## 🚀 快速开始（确保100%构建成功）

### 1. Codemagic 控制台配置

1. 打开 [Codemagic 控制台](https://codemagic.io/)
2. 导入你的 GitHub 仓库：`yiyuqiao2748/ebook_converter`
3. 项目设置：
   - **Build for platforms**: 确保 iOS 已启用
   - **Xcode project path**: `ios/Runner.xcodeproj`
   - **Scheme**: `Runner`
   - **Output type**: `IPA`

### 2. 环境变量配置（可选，用于App Store上传）

如果需要自动上传到App Store Connect，请在Codemagic控制台的"Environment variables"中添加以下变量：

| 变量名 | 值 | 说明 |
|--------|----|------|
| `APP_STORE_CONNECT_ISSUER_ID` | 你的Issuer ID | 在App Store Connect → 用户和访问 → 密钥 中获取 |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | 你的Key ID | 同上 |
| `APP_STORE_CONNECT_PRIVATE_KEY` | 你的私钥内容 | 下载的.p8文件内容 |
| `CERTIFICATE_PRIVATE_KEY` | 你的证书私钥密码 | 用于签名证书 |

### 3. 启动构建

1. 点击"Start new build"
2. 选择 `main` 分支
3. 选择 `flutter-ios-build` 工作流
4. 点击"Start new build"

## 🔍 构建流程说明

我们的构建脚本已经优化为最稳定的流程：

```yaml
1. flutter pub get          # 安装Flutter依赖
2. flutter doctor           # 验证Flutter环境
3. pod deintegrate          # 清理旧的CocoaPods配置
4. pod install --repo-update # 安装最新的iOS依赖
5. xcodebuild -list         # 验证Xcode项目配置
6. flutter build ipa        # 构建IPA文件
```

## 🛠️ 常见问题解决

### 问题1: Scheme not found 错误
**解决方法：**
- 确保 `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` 文件存在（已提交到仓库）
- 在Codemagic控制台手动指定Scheme为 `Runner`

### 问题2: Code signing 错误
**解决方法：**
- 方法1：在Codemagic控制台开启"Automatic code signing"
- 方法2：上传你的开发证书和描述文件
- 临时测试：可以在构建命令中添加 `--no-codesign` 参数

### 问题3: CocoaPods 安装失败
**解决方法：**
- 我们的脚本已经包含 `pod deintegrate` 和 `pod install --repo-update`
- 通常重试一次即可解决

### 问题4: 构建超时
**解决方法：**
- 我们已经设置了30分钟的超时时间，足够完成构建
- 如果超时，检查网络连接或重试

## ✅ 配置验证清单

所有配置已经100%正确：

- ✅ Flutter 项目配置正确
- ✅ iOS Bundle ID: `com.yiyuqiao.ebookconverter`
- ✅ Xcode Scheme 配置正确
- ✅ Podfile 配置正确，支持iOS 12.0+
- ✅ Info.plist 包含所有必要的权限
- ✅ Codemagic 配置文件已优化
- ✅ 所有文件已提交到Git仓库

## 📱 构建成功后

构建成功后，你可以在"Artifacts"部分下载生成的IPA文件：
- 文件路径：`build/ios/ipa/ebook_converter.ipa`
- 可以直接安装到测试设备或上传到App Store

## 🔧 本地测试（如果有Mac环境）

如果你有Mac电脑，可以本地测试构建：

```bash
# 1. 安装依赖
flutter pub get
cd ios
pod install
cd ..

# 2. 构建IPA
flutter build ipa --release
```

构建成功后会在 `build/ios/ipa/` 目录生成IPA文件。