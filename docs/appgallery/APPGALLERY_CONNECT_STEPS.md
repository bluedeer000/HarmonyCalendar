# AppGallery Connect 提交流程

## 目标

将 `Macto 日历` 提交到华为应用市场审核。

## 提交前准备

- 完成开发者实名认证
- 准备 signed HAP
- 准备中文应用名称、简介、详细介绍
- 准备截图
- 准备隐私政策 URL
- 准备测试账号或测试说明

## 后台录入建议

### 1. 创建应用

- 平台选择 HarmonyOS 应用
- 应用名称填写：`Macto 日历`
- 包名填写：`com.macto.harmonycalendar`
- 默认语言选择简体中文

### 2. 应用信息

可直接参考：

- `docs/appgallery/STORE_METADATA_zh-CN.md`

建议优先填写：

- 应用名称
- 一句话简介
- 详细介绍
- 联系方式
- 隐私政策链接

### 3. 上传安装包

- 上传 signed HAP
- 确认后台识别到的版本号与本地一致：
- `versionName = 1.0.0`
- `versionCode = 1000001`

### 4. 隐私声明

参考文件：

- `docs/appgallery/PRIVACY_POLICY_zh-CN.md`
- `docs/appgallery/APPGALLERY_SUBMISSION_CHECKLIST.md`

需重点如实声明：

- 应用会连接用户主动配置的第三方 CalDAV 服务
- 应用会处理账号、密码或应用专用密码
- 应用会处理用户的日历内容与提醒信息
- 应用会在本地加密数据库中缓存数据

### 5. 测试信息

如果审核需要测试账号，建议提供：

- 一个可登录的 CalDAV 测试账号
- 服务地址
- 用户名
- 应用专用密码
- 审核操作步骤

### 6. 提交策略

建议先使用开放式测试，再进入正式审核。

开放式测试通过后，再提交正式版本，可减少一次性被退回的概率。

## 提交后跟进

- 记录提审日期
- 记录提审版本号
- 记录审核意见
- 若被驳回，保留问题单并回到 `release/appgallery` 修复
