# 本地签名配置说明

仓库中的 `build-profile.json5` 已替换为安全模板，不再包含真实证书路径、profile 路径或口令。

## 本地配置方式

1. 在 DevEco Studio 中创建或导入正式发布签名。
2. 用你本机的真实证书路径、profile 路径、别名和口令替换 `build-profile.json5` 中的占位值。
3. 不要将替换后的真实签名配置再次提交到 Git。

## 建议做法

- 仅在本机临时修改 `build-profile.json5` 用于正式构建。
- 构建完成后，立即恢复为仓库中的模板版本。
- 如果后续需要团队协作，建议改造为由本地脚本或 CI 注入签名参数，而不是把真实路径和口令写入仓库文件。
- 正式构建前先执行 `scripts/preflight_release_check.sh`

## 必须轮换的内容

由于历史版本已经包含过真实签名配置，以下材料应视为已暴露并尽快轮换：

- 发布证书
- 签名 profile
- keystore / p12
- key alias 对应口令
- store password
