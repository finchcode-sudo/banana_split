# 构建说明

这份代码是在你的 fork（保留了中文翻译 `lib/l10n/app_zh.arb` 等）基础上，
把 android 构建工具链同步到了原作者 v0.9.0 release 的水平（Flutter 3.44 /
AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20），并加上了体积优化和正式签名配置。

## 改动了什么

- `android/gradle/wrapper/gradle-wrapper.properties` — Gradle 8.3 → 8.14
- `android/settings.gradle` — AGP 8.1.0 → 8.11.1，Kotlin 1.8.22 → 2.2.20
- `android/gradle.properties` — 加了 Flutter migrator 的两个 flag
- `android/app/build.gradle` —
  - 加 `useLegacyPackaging = true`（修复 APK 体积从 38.5MB 涨到 78.8MB 的问题）
  - 加 `signingConfigs.release`，从 `key.properties` 读取正式签名信息
  - `buildTypes.release` 加了 `minifyEnabled` / `shrinkResources`（R8 混淆+资源裁剪）
- 新增 `android/app/proguard-rules.pro`（空文件，先能编译，以后遇到反射相关的
  运行时崩溃再往里加保留规则）
- 新增 `android/key.properties.example`（签名信息模板，仅供参考，不是真密钥）
- `android/.gitignore` 加了 `key.properties` / `*.jks` / `*.keystore`，防止
  真实密钥被提交

**没有改动**：`lib/`、`pubspec.yaml`、翻译文件——你 fork 特有的东西都还在。

## 你需要做的事

### 1. 切换 Flutter SDK 到 3.44.8

targetSdk/compileSdk 是不是能到 36（Android 16），完全取决于你本地/CI 用的
Flutter SDK 版本，跟 gradle 文件本身无关。

```bash
flutter --version   # 确认是 3.44.8，不是就切换或升级
```

### 2. 生成正式签名 key（只需要做一次，做完长期保存好，丢了就没法再更新这个包名的应用了）

```bash
keytool -genkey -v -keystore ~/banana-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias banana
```

### 3. 把 `android/key.properties.example` 复制成 `android/key.properties`，填真实信息

```properties
storePassword=你的真实密码
keyPassword=你的真实密码
keyAlias=banana
storeFile=/绝对路径/banana-release-key.jks
```

**这个文件已经在 .gitignore 里了，不会被提交，但你自己也别传到任何地方。**

### 4. 编译

```bash
cd banana_split_flutter
flutter pub get
flutter build apk --release
```

产物在 `build/app/outputs/flutter-apk/app-release.apk`。

如果 `key.properties` 不存在，`buildTypes.release` 会自动退回用 debug key 签名
（保证没配置签名之前 `flutter run --release` 还能跑），但那样装出来的 APK
**不能覆盖安装**已经用正式签名发布过的旧版本，也不算真正的发布版——发布前一定要
确认 `key.properties` 配好了。
