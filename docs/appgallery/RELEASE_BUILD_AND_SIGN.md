# 发布签名与构建 SOP

适用分支：`release/appgallery`

## 目标

生成可提交到华为应用市场的 signed HAP，并保留版本、签名和构建记录。

## 当前项目状态

- 应用包名：`com.macto.harmonycalendar`
- 当前发布版本：`1.0.0`
- 当前版本号：`1000001`
- 项目已存在本机可用的签名配置，位于仓库根目录的 `build-profile.json5`

## 风险提示

- `build-profile.json5` 当前引用的是本机绝对路径签名材料。
- 该文件适合当前机器发布，不适合直接当作团队通用签名模板。
- 如果仓库后续需要多人协作或公开，必须替换为不包含真实签名材料路径和口令的安全方案。

## 发布前检查

- 确认当前分支为 `release/appgallery`
- 确认工作区干净
- 确认 `AppScope/app.json5` 中 `versionName` 与 `versionCode` 已更新
- 确认隐私政策、应用名称、截图、测试账号说明已准备完成

## DevEco Studio 发布方式

1. 用 DevEco Studio 打开项目根目录 `HarmonyCalendar`
2. 打开 `File > Project Structure > Signing Configs`
3. 确认 `default` 签名配置可用
4. 检查证书、profile、别名和口令是否可正常加载
5. 选择 `Build > Build Hap(s)/APP(s) > Build Hap(s)`
6. 使用 `release` 构建模式
7. 构建完成后确认生成 signed HAP

## 命令行构建方式

```bash
cd /Users/mini/mactoHarmony/HarmonyCalendar
NODE_HOME=/usr/local \
JAVA_HOME=/Users/mini/.jdk/jdk-17.0.19+10/Contents/Home \
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk/default \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
  --mode module -p module=entry@default -p product=default assembleHap --no-daemon
```

## 产物位置

- signed HAP：
  `entry/build/default/outputs/default/entry-default-signed.hap`
- unsigned HAP：
  `entry/build/default/outputs/default/entry-default-unsigned.hap`

## 发布记录建议

每次准备提交审核时，至少记录以下信息：

- Git 提交号
- 分支名
- `versionName`
- `versionCode`
- 构建日期
- HAP 文件名和大小
- 使用的签名配置名称

建议将发布记录追加到本目录的新文件中，例如 `RELEASE_LOG.md`。
